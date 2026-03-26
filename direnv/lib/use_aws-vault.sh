use_aws-vault() {
# Usage: use aws-vault <profile> [cmd[,profile] ...]
#
# Creates wrapper scripts that run commands via "aws-vault exec <profile> --".
# By default, wraps "aws". Additional commands can be specified as arguments
# or via the USE_AWS_VAULT environment variable (space-delimited).
#
# Each command arg can optionally include a comma-separated profile override:
#   cmd,other-profile  — wraps "cmd" using "other-profile" instead of the default.
#
# Examples:
#   use aws-vault myprofile                                            # wraps "aws" with myprofile
#   use aws-vault myprofile terraform sam                              # wraps "aws", "terraform", "sam" with myprofile
#   use aws-vault myprofile terraform,cicd-profile                     # wraps "aws" with myprofile, "terraform" with cicd-profile
#   USE_AWS_VAULT="terraform,cicd-profile sam" use aws-vault myprofile # same via env var
    has aws-vault || { log_error "aws-vault is not installed" && return 1; }
    [[ $# -lt 1 ]] && log_error "Usage: use aws-vault <profile> [cmd[,profile] ...]" && return 1;

    local profile="$1"; shift
    local bin_dir="$(direnv_layout_dir)/aws-vault/bin"

    # Clean slate
    rm -rf "$(direnv_layout_dir)/aws-vault"
    mkdir -p "${bin_dir}"

    # Collect commands: always include "aws" with default profile, then positional args, then USE_AWS_VAULT
    # Values are "cmd:profile" — later entries override earlier ones
    local -A cmds=()
    cmds[aws]="$profile"
    for arg in "$@"; do
        local cmd="${arg%%,*}"
        local p="${arg#*,}"
        [[ "$p" == "$arg" ]] && p="$profile"
        cmds[$cmd]="$p"
    done
    if [[ -n "${USE_AWS_VAULT:-}" ]]; then
        for arg in ${USE_AWS_VAULT}; do
            [[ -z "$arg" ]] && continue
            local cmd="${arg%%,*}"
            local p="${arg#*,}"
            [[ "$p" == "$arg" ]] && p="$profile"
            cmds[$cmd]="$p"
        done
    fi

    for cmd in "${!cmds[@]}"; do
        local cmd_profile="${cmds[$cmd]}"
        local original
        original="$(PATH="${PATH/${bin_dir}:/}" command -v "$cmd" 2>/dev/null)" || {
            log_error "use aws-vault: '$cmd' not found in PATH, skipping"
            continue
        }
        cat > "${bin_dir}/${cmd}" <<WRAPPER
#!/usr/bin/env bash
if [[ -n "\${AWS_PROFILE:-}" ]] || { [[ -n "\${AWS_ACCESS_KEY_ID:-}" ]] && [[ -n "\${AWS_SECRET_ACCESS_KEY:-}" ]]; }; then
    exec "${original}" "\$@"
else
    exec aws-vault exec "${cmd_profile}" -- "${original}" "\$@"
fi
WRAPPER
        chmod +x "${bin_dir}/${cmd}"
    done

    PATH_add "${bin_dir}"
}
