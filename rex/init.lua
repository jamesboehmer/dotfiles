-- Migrated from tmux, Herdr, Ghostty and iTerm2.

-- tmux (~/.tmux.conf), prefix ctrl+b
rex.bind("ctrl+b>ctrl+b", "pane.send_key", { key = "ctrl+b" })
rex.bind("ctrl+b>v", "pane.split", { direction = "right" })
rex.bind("ctrl+b>s", "pane.split", { direction = "down" })
rex.bind("ctrl+b>shift+j", "pane.resize", { amount = 5, direction = "down" })
rex.bind("ctrl+b>shift+k", "pane.resize", { amount = 5, direction = "up" })
rex.bind("ctrl+b>shift+h", "pane.resize", { amount = 5, direction = "left" })
rex.bind("ctrl+b>shift+l", "pane.resize", { amount = 5, direction = "right" })
rex.bind("ctrl+b>alt+j", "pane.resize", { direction = "down" })
rex.bind("ctrl+b>alt+k", "pane.resize", { direction = "up" })
rex.bind("ctrl+b>alt+h", "pane.resize", { direction = "left" })
rex.bind("ctrl+b>alt+l", "pane.resize", { direction = "right" })
rex.bind("ctrl+b>h", "pane.focus", { direction = "left" })
rex.bind("ctrl+b>j", "pane.focus", { direction = "down" })
rex.bind("ctrl+b>k", "pane.focus", { direction = "up" })
rex.bind("ctrl+b>l", "pane.focus", { direction = "right" })
rex.bind("alt+h", "pane.focus", { direction = "left" })
rex.bind("alt+j", "pane.focus", { direction = "down" })
rex.bind("alt+k", "pane.focus", { direction = "up" })
rex.bind("alt+l", "pane.focus", { direction = "right" })
rex.bind("alt+left", "pane.focus", { direction = "left" })
rex.bind("alt+right", "pane.focus", { direction = "right" })
rex.bind("alt+up", "pane.focus", { direction = "up" })
rex.bind("alt+down", "pane.focus", { direction = "down" })
rex.bind("shift+left", "client.tab.previous")
rex.bind("shift+right", "client.tab.next")
rex.bind("ctrl+b>r", "client.config.reload")

-- iTerm2 (Keyboard Map, profiles Dotfiles Atom One Dark, Dotfiles Default, Guake)
rex.bind("ctrl+shift+6", "pane.send_key", { key = "ctrl+shift+6" })

-- Git worktrees, kept under ~/.rex/worktrees/<repo>/<branch>
local function focused_dir(ctx)
  local terminal = "com.superlogical.terminal"
  -- The shell doesn't report its directory (OSC 7), so ask the foreground process
  local p = rex.block.call(terminal, "process", { block_id = ctx.block_id })
  if p and p.foreground and p.foreground.cwd then return p.foreground.cwd end

  local r = rex.block.call(terminal, "pwd", { block_id = ctx.block_id })
  local dir = r and r.pwd
  if dir == nil then error("Couldn't tell which directory the terminal is in", 0) end
  -- pwd can come back as a file:// URL; turn it into a plain path
  dir = dir:gsub("^file://[^/]*", ""):gsub("%%(%x%x)", function(h) return string.char(tonumber(h, 16)) end)
  return dir
end

local function git(args, cwd)
  local r, err = rex.exec(args, { cwd = cwd, timeout = 25 })
  if r == nil then error(err, 0) end
  return r
end

local function confirm(title, yes)
  return rex.ui.pick{
    title = title,
    items = {
      { id = "yes", title = yes },
      { id = "no",  title = "Cancel" },
    },
  } == "yes"
end

rex.action{
  name  = "new_worktree",
  title = "Git: New Worktree…",
  run   = function(ctx, args)
    local cwd = focused_dir(ctx)

    local top = git({ "git", "rev-parse", "--show-toplevel" }, cwd)
    if not top.ok then error("Not inside a git repo: " .. cwd, 0) end
    local root = top.stdout:gsub("%s+$", "")

    local name = rex.ui.input{
      title       = "New worktree branch",
      placeholder = "feature/…",
      confirm     = "Create worktree",
    }
    if name == nil or name == "" then return end

    local repo = root:match("([^/]+)$")
    local dir  = os.getenv("HOME") .. "/.rex/worktrees/" .. repo .. "/" .. name:gsub("/", "-")
    local r = git({ "git", "worktree", "add", "-b", name, dir }, root)
    if not r.ok then error(r.stderr, 0) end

    local w, err = rex.session.new_window{
      layout = rex.layout.block{
        flavor  = "com.superlogical.terminal.shell",
        options = { cwd = dir },
      },
    }
    if err ~= nil then error(err, 0) end
    rex.session.set_window_label{ window_id = w.window_id, label = name }
    -- focus_window only changes the server's active window; the app keeps
    -- its own selected tab, so ask it to switch too
    rex.session.focus_window{ window_id = w.window_id }
    rex.client.queue("session.select", { session_id = ctx.session_id, window_id = w.window_id })
  end,
}

rex.action{
  name  = "remove_worktree",
  title = "Git: Remove This Worktree…",
  run   = function(ctx, args)
    local cwd = focused_dir(ctx)

    local top = git({ "git", "rev-parse", "--show-toplevel" }, cwd)
    if not top.ok then error("Not inside a git repo: " .. cwd, 0) end
    local wt = top.stdout:gsub("%s+$", "")

    -- Only touch worktrees that new_worktree made
    local base = os.getenv("HOME") .. "/.rex/worktrees/"
    if wt:sub(1, #base) ~= base then
      error("Not a Rex worktree (must be under ~/.rex/worktrees): " .. wt, 0)
    end

    -- Run the removal from the main repo, not from inside the worktree
    local common = git({ "git", "rev-parse", "--path-format=absolute", "--git-common-dir" }, wt)
    local main = common.stdout:gsub("%s+$", ""):gsub("/%.git$", "")

    -- Empty when the worktree is on a detached HEAD
    local head = git({ "git", "symbolic-ref", "--quiet", "--short", "HEAD" }, wt)
    local branch = head.ok and head.stdout:gsub("%s+$", "") or nil

    local what = branch and ("worktree and branch " .. branch) or ("worktree " .. wt)
    if not confirm("Remove " .. what .. "?", "Remove and close pane") then return end

    local r = git({ "git", "worktree", "remove", wt }, main)
    if not r.ok then
      -- Usually uncommitted or untracked changes
      if not confirm("Worktree has changes. " .. r.stderr:gsub("%s+$", ""), "Discard changes and remove") then return end
      r = git({ "git", "worktree", "remove", "--force", wt }, main)
      if not r.ok then error(r.stderr, 0) end
    end

    if branch then
      r = git({ "git", "branch", "-d", branch }, main)
      if not r.ok then
        -- Usually commits that aren't merged anywhere
        if confirm("Branch " .. branch .. " isn't fully merged. Delete it anyway?", "Delete branch and its unmerged commits") then
          r = git({ "git", "branch", "-D", branch }, main)
          if not r.ok then error(r.stderr, 0) end
        end
      end
    end

    local _, err = rex.call("block.close", { session_id = ctx.session_id, block_id = ctx.block_id })
    if err ~= nil then error(err, 0) end
  end,
}

rex.bind("ctrl+b>w", "new_worktree")
rex.bind("ctrl+b>shift+w", "remove_worktree")
