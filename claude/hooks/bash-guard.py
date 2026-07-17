#!/usr/bin/env python3
"""
PreToolUse hook for the Bash, Write, Edit, and MultiEdit tools.

Policy (Bash):
  - allow: known read-only commands (ls, cat, grep, find -no mutating flags-, git status/log/diff/show/branch, gh pr view/list/diff/checks, gh api GET, etc.)
  - allow: commands whose ONLY file-writing effect is a shell redirection into /tmp/**
  - ask:   gh api calls using a mutating HTTP method (POST/PUT/PATCH/DELETE, in either
           `-X POST`, `-XPOST`, `--method POST`, or `--method=POST` form), gh pr merge/close
  - deny:  a short list of clearly destructive patterns (rm -rf /, sudo, fork bombs, etc.)

Policy (Write / Edit / MultiEdit):
  - allow: the target file_path resolves under /tmp/
  - otherwise: no decision (falls through to normal prompts)

  - otherwise: emit no decision at all, so Claude Code's normal settings.json /
    permission-prompt flow still applies. This hook only ever narrows what
    needs a prompt -- it never widens it beyond what you already allow.

Caveats (read before trusting this for anything sensitive):
  - Shell parsing here uses shlex, which does NOT understand pipes, subshells,
    command substitution ($(...), ``), or multiple statements chained with
    ; && ||. If any of those appear, this hook deliberately backs off and
    emits no decision (falls through to ask), rather than guessing.
  - The /tmp check for Write/Edit/MultiEdit is a path-string check, not a
    realpath resolution -- it does not follow symlinks. A file_path containing
    ".." that is passed already-normalized by Claude Code is fine, but this
    hook does not itself defend against a symlink planted at /tmp/foo that
    points elsewhere.
  - This is a defense-in-depth layer, not a sandbox. It filters the *text* of
    the command/path Claude proposes; it doesn't stop a sufficiently
    adversarial input from smuggling something else past regex-style filters.
  - Tune the SAFE_READONLY / DENY lists for your own environment before
    relying on this.
"""
import json
import os
import re
import shlex
import sys

SAFE_READONLY_CMDS = {
    "ls", "cat", "head", "tail", "wc", "pwd", "which", "file", "stat",
    "du", "df", "echo", "printenv", "env",
}

# git subcommands that are read-only
GIT_READONLY_SUBCMDS = {
    "status", "log", "diff", "show", "branch",
    "rev-parse", "rev-list", "describe", "merge-base",
    "ls-remote", "ls-files", "cat-file", "symbolic-ref",
}

# $(...) command substitution with no nested parens or backticks inside
SUBST_RE = re.compile(r'\$\(([^()`]*)\)')

# grep/find are read-only UNLESS given flags that mutate (find -delete, -exec)
DANGEROUS_FIND_FLAGS = {"-delete", "-exec", "-execdir", "-fprintf"}

DENY_PATTERNS = [
    r"\brm\s+-rf\s+/(?:\s|$|\))",    # rm -rf / (also inside $(...) )
    r"\bsudo\b",
    r":\(\)\s*\{.*:\s*\|\s*:.*\};",  # classic fork bomb
    r"\bmkfs\b",
    r"\bdd\s+.*of=/dev/",
    r"\bgit\s+push\s+.*--force\b.*\b(main|master)\b",
]

ASK_PATTERNS = [
    r"\bgh\s+pr\s+(merge|close)\b",
    r"\bgh\s+api\b.*\B(-X|--method)[\s=]*(POST|PUT|PATCH|DELETE)\b",
]


def allow(reason):
    print(json.dumps({
        "hookSpecificOutput": {
            "hookEventName": "PreToolUse",
            "permissionDecision": "allow",
            "permissionDecisionReason": reason,
        }
    }))
    sys.exit(0)


def deny(reason):
    print(json.dumps({
        "hookSpecificOutput": {
            "hookEventName": "PreToolUse",
            "permissionDecision": "deny",
            "permissionDecisionReason": reason,
        }
    }))
    sys.exit(0)


def ask(reason):
    print(json.dumps({
        "hookSpecificOutput": {
            "hookEventName": "PreToolUse",
            "permissionDecision": "ask",
            "permissionDecisionReason": reason,
        }
    }))
    sys.exit(0)


def no_decision():
    # No stdout, exit 0: normal permission rules / prompts apply.
    sys.exit(0)


def is_read_only_gh(tokens):
    # tokens like ["gh", "pr", "view", "123"] or ["gh", "api", "repos/x/y"]
    if len(tokens) < 2 or tokens[0] != "gh":
        return False
    if tokens[1] == "pr" and len(tokens) >= 3 and tokens[2] in {
        "view", "list", "diff", "checks", "status"
    }:
        return True
    if tokens[1] == "api":
        rest = tokens[2:]
        # GET is the default; only a method flag can make it mutate.
        # Handles all four forms: -X POST, -XPOST, --method POST, --method=POST
        for i, t in enumerate(rest):
            method = None
            if t in ("-X", "--method"):
                method = rest[i + 1].upper() if i + 1 < len(rest) else ""
            elif t.startswith("-X") and t != "-X":
                method = t[2:].upper()
            elif t.startswith("--method="):
                method = t.split("=", 1)[1].upper()
            if method is not None:
                return method == "GET"
        return True  # no method flag -> GET
    return False


def is_readonly_simple(tokens):
    if not tokens:
        return False
    cmd = tokens[0]
    if cmd in SAFE_READONLY_CMDS:
        return True
    if cmd in ("grep", "rg"):
        return True
    if cmd == "find":
        return not any(flag in tokens for flag in DANGEROUS_FIND_FLAGS)
    if cmd == "git" and len(tokens) >= 2:
        sub = tokens[1]
        if sub in GIT_READONLY_SUBCMDS:
            return True
        if sub == "remote":
            # Only the read-only forms: `git remote`, `git remote -v/--verbose`, and
            # `git remote show ...`. Mutating forms (add/remove/rename/set-url/prune/update)
            # deliberately fall through to a normal prompt.
            remote_args = tokens[2:]
            if not remote_args:
                return True
            if all(arg in ("-v", "--verbose") for arg in remote_args):
                return True
            if remote_args[0] == "show":
                return True
    return False


def strip_safe_substitutions(command):
    """Replace read-only $(...) substitutions with a harmless placeholder token.

    Returns (new_command, all_safe). all_safe is False if ANY substitution's inner
    command is not provably read-only, uses backticks, or is nested/unparseable, in
    which case the caller should back off (no_decision). The placeholder is never in
    any allow-list, so a substitution can never stand in as an approved command name.
    """
    if "`" in command:  # backtick substitution: too hard to reason about safely
        return command, False
    all_safe = True

    def repl(m):
        nonlocal all_safe
        try:
            inner = shlex.split(m.group(1).strip())
        except ValueError:
            all_safe = False
            return m.group(0)
        if inner and (is_readonly_simple(inner) or is_read_only_gh(inner)):
            return "__SUBST__"
        all_safe = False
        return m.group(0)

    new_command = SUBST_RE.sub(repl, command)
    if "$(" in new_command:  # leftover = nested or unparseable substitution
        all_safe = False
    return new_command, all_safe


def only_writes_to_tmp(command_str, tokens):
    """
    Very narrow check: the command has exactly one redirection operator
    (> or >>), its target starts with /tmp/, there are no shell
    metacharacters that could hide additional effects, and the base
    command itself is otherwise one of a small safe set.
    """
    metachars = [";", "&&", "||", "|", "`", "$("]
    if any(m in command_str for m in metachars):
        return False

    redirects = re.findall(r'(>{1,2})\s*(\S+)', command_str)
    if len(redirects) != 1:
        return False
    _, target = redirects[0]
    target = target.strip('"\'')
    if not target.startswith("/tmp/"):
        return False

    # strip the redirection off to see what the actual command is
    base_str = re.sub(r'>{1,2}\s*\S+', '', command_str).strip()
    try:
        base_tokens = shlex.split(base_str)
    except ValueError:
        return False
    if not base_tokens:
        return False
    return base_tokens[0] in SAFE_READONLY_CMDS | {"printf", "tee"}


def is_under_tmp(path):
    if not path:
        return False
    # Normalize without following symlinks (see caveat in module docstring).
    normalized = os.path.normpath(path)
    return normalized == "/tmp" or normalized.startswith("/tmp/")


def handle_write_edit(data):
    tool_input = data.get("tool_input") or {}
    file_path = tool_input.get("file_path", "")

    if not file_path:
        no_decision()
        return

    if is_under_tmp(file_path):
        allow(f"Write/Edit target under /tmp auto-approved by bash-guard hook: {file_path}")
        return

    no_decision()


def handle_multi_edit(data):
    tool_input = data.get("tool_input") or {}
    file_path = tool_input.get("file_path", "")

    if not file_path:
        no_decision()
        return

    if is_under_tmp(file_path):
        allow(f"MultiEdit target under /tmp auto-approved by bash-guard hook: {file_path}")
        return

    no_decision()


def handle_bash(data):
    command = (data.get("tool_input") or {}).get("command", "") or ""
    if not command.strip():
        no_decision()
        return

    for pat in DENY_PATTERNS:
        if re.search(pat, command, re.IGNORECASE):
            deny(f"Blocked by bash-guard hook: matched deny pattern {pat!r}")
            return

    for pat in ASK_PATTERNS:
        if re.search(pat, command, re.IGNORECASE):
            ask("gh api/pr command may mutate state — confirm before running")
            return

    # Resolve innocuous command substitutions (e.g. `git show $(git rev-parse HEAD)`)
    # so read-only commands that use them can still be auto-approved. DENY/ASK above
    # already ran against the original text, so dangerous content inside a substitution
    # is still caught. Anything not provably safe backs off to a normal prompt.
    if "$(" in command:
        command, subst_safe = strip_safe_substitutions(command)
        if not subst_safe:
            no_decision()
            return

    # Only attempt token-level checks on simple, single-statement commands.
    metachars = [";", "&&", "||", "|", "`", "$("]
    if any(m in command for m in metachars) and not only_writes_to_tmp(command, []):
        no_decision()
        return

    try:
        tokens = shlex.split(command)
    except ValueError:
        no_decision()
        return

    has_redirect = bool(re.search(r'>{1,2}', command))

    if not has_redirect and (is_read_only_gh(tokens) or is_readonly_simple(tokens)):
        allow("Read-only command auto-approved by bash-guard hook")
        return

    if has_redirect and only_writes_to_tmp(command, tokens):
        allow("Write confined to /tmp auto-approved by bash-guard hook")
        return

    no_decision()


def main():
    try:
        data = json.load(sys.stdin)
    except Exception:
        no_decision()
        return

    tool_name = data.get("tool_name")

    if tool_name == "Bash":
        handle_bash(data)
    elif tool_name in ("Write", "Edit"):
        handle_write_edit(data)
    elif tool_name == "MultiEdit":
        handle_multi_edit(data)
    else:
        no_decision()


if __name__ == "__main__":
    main()