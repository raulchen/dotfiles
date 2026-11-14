local fugitive = {
  "tpope/vim-fugitive",
  cmd = { "Git", "G" },
  keys = { "<leader>gg", "<cmd>Git<CR>", desc = "Git status" },
}

local function setup_gitsigns()
  require('gitsigns').setup {
    signcolumn = false,
    numhl = true,
    on_attach = function(bufnr)
      local gs = package.loaded.gitsigns

      local function map(mode, l, r, desc, opts)
        opts = opts or {}
        opts.desc = desc
        opts.buffer = bufnr
        vim.keymap.set(mode, l, r, opts)
      end

      -- Navigation
      map('n', ']c', function()
        if vim.wo.diff then
          return ']c'
        else
          gs.nav_hunk('next')
          return ''
        end
      end, "Next change/hunk", { expr = true })

      map('n', '[c', function()
        if vim.wo.diff then
          return '[c'
        else
          gs.nav_hunk('prev')
          return ''
        end
      end, "Previous change/hunk", { expr = true })

      -- Actions
      map('n', '<leader>gs', gs.stage_hunk, "Stage hunk")
      map('n', '<leader>gu', gs.undo_stage_hunk, "Undo stage hunk")
      map('n', '<leader>gr', gs.reset_hunk, "Reset hunk")
      map('v', '<leader>gs', function() gs.stage_hunk { vim.fn.line('.'), vim.fn.line('v') } end, "Stage hunk")
      map('v', '<leader>gr', function() gs.reset_hunk { vim.fn.line('.'), vim.fn.line('v') } end, "Reset hunk")
      map('n', '<leader>gS', gs.stage_buffer, "Stage buffer")
      map('n', '<leader>gR', gs.reset_buffer, "Reset buffer")
      map('n', '<leader>gp', gs.preview_hunk, "Preview hunk")
      map('n', '<leader>gb', function() gs.blame_line { full = true } end, "Blame line")
      map('n', '<leader>gB', gs.blame, "Blame buffer")
      map('n', '<leader>gq', gs.setqflist, "Show buffer hunks in quickfix")
      map('n', '<leader>gQ', function() gs.setqflist('all') end, "Show all hunks in quickfix")

      -- Text object
      map({ 'o', 'x' }, 'ih', ':<C-U>Gitsigns select_hunk<CR>', "Git hunk")
    end
  }
end

local gitsigns = {
  "lewis6991/gitsigns.nvim",
  event = { "BufReadPre", "BufNewFile" },
  config = setup_gitsigns,
}

-- Fuzzy file switcher shared by the Octo PR review layout and Diffview, built
-- on snacks.picker. Both plugins expose an ordered list of changed files and a
-- "jump to this file" call; this wraps them in a fuzzy picker so you can hop
-- straight to any file instead of cycling with <tab>/<s-tab> or [q/]q.
--
-- `opts.items` is a list of { file, path, status, additions, deletions } and
-- `opts.on_choice` receives the chosen item to perform the jump.
local function changed_file_picker(opts)
  if #opts.items == 0 then
    vim.notify("No changed files", vim.log.levels.WARN)
    return
  end

  local devicons = require("nvim-web-devicons")
  local status_hl = { A = "Added", D = "Removed", M = "Changed", R = "Changed" }

  for i, item in ipairs(opts.items) do
    item.idx = i
    item.text = item.path -- fuzzy-match/sort against the repo-relative path
  end

  require("snacks.picker").pick({
    title = opts.title,
    items = opts.items,
    preview = "none",
    layout = "select",
    format = function(item)
      local ret = {}
      local ext = item.path:match("%.([^./]+)$")
      local icon, icon_hl = devicons.get_icon(item.path, ext, { default = true })
      local parent, basename = item.path:match("^(.*/)([^/]+)$")
      basename = basename or item.path

      -- Marker for the file currently open in the review / diff.
      ret[#ret + 1] = { item.current and "● " or "  ", "Special" }
      ret[#ret + 1] = { item.status or " ", status_hl[item.status] or "Comment" }
      ret[#ret + 1] = { " " .. icon .. " ", icon_hl }
      if parent then
        ret[#ret + 1] = { parent, "SnacksPickerDir" }
      end
      ret[#ret + 1] = { basename }
      if (item.additions or 0) > 0 then
        ret[#ret + 1] = { "  +" .. item.additions, "Added" }
      end
      if (item.deletions or 0) > 0 then
        ret[#ret + 1] = { " -" .. item.deletions, "Removed" }
      end
      return ret
    end,
    confirm = function(picker, item)
      picker:close()
      if item then
        opts.on_choice(item)
      end
    end,
    -- Start the cursor on the file currently open in the review / diff.
    on_show = function(picker)
      for i, item in ipairs(picker:items()) do
        if item.current then
          picker.list:view(i)
          Snacks.picker.actions.list_scroll_center(picker)
          break
        end
      end
    end,
  })
end

-- Build a picker item from a plugin's file entry. `entry` is kept by reference
-- because both plugins match the selected file by object identity.
local function make_file_item(entry, stats)
  return {
    file = entry,
    path = entry.path,
    status = (entry.status and entry.status ~= " ") and entry.status or nil,
    additions = stats and stats.additions,
    deletions = stats and stats.deletions,
  }
end

-- Fuzzy switch between files in the current Octo PR review layout.
local function pick_octo_review_file()
  local ok, reviews = pcall(require, "octo.reviews")
  if not ok then return end
  local review = reviews.get_current_review()
  if not review or not review.layout then
    vim.notify("No active Octo review", vim.log.levels.WARN)
    return
  end
  local layout = review.layout
  local current = layout:get_current_file()

  local items = {}
  for _, f in ipairs(layout.files) do
    local item = make_file_item(f, f.stats)
    item.current = f == current
    items[#items + 1] = item
  end

  changed_file_picker({
    title = "PR review files",
    items = items,
    on_choice = function(item)
      layout:set_current_file(item.file)
    end,
  })
end

-- Fuzzy switch between files in the current Diffview.
local function pick_diffview_file()
  local ok, lib = pcall(require, "diffview.lib")
  if not ok then return end
  local DiffView = require("diffview.scene.views.diff.diff_view").DiffView
  local view = lib.get_current_view()
  if not (view and view:instanceof(DiffView)) then
    vim.notify("No active Diffview", vim.log.levels.WARN)
    return
  end

  local current = view.panel and view.panel.cur_file
  local items = {}
  for _, f in view.files:iter() do
    local item = make_file_item(f, f.stats)
    item.current = f == current
    items[#items + 1] = item
  end

  changed_file_picker({
    title = "Diffview files",
    items = items,
    on_choice = function(item)
      view:set_file(item.file, true, true) -- focus diff buffers + highlight in panel
    end,
  })
end

-- Dump the current Diffview's rev range (or the selected commit, in a file
-- history view) into a single flat unified-diff buffer.
local function open_flat_diff()
  local ok, lib = pcall(require, "diffview.lib")
  if not ok then return end
  local view = lib.get_current_view()
  if not view then
    vim.notify("No active Diffview", vim.log.levels.WARN)
    return
  end

  local adapter = view.adapter
  -- FilePanel has no `cur_item`; only the file history panel does.
  local entry = view.panel and view.panel.cur_item and view.panel.cur_item[1]
  local args, title

  if entry and entry.commit then
    args = { "show", "--no-ext-diff", entry.commit.hash }
    title = entry.commit.hash:sub(1, 8)
  else
    if not (view.left and view.right) then
      vim.notify("This view has no rev range to flatten", vim.log.levels.WARN)
      return
    end

    local RevType = require("diffview.vcs.rev").RevType
    local rev_args = adapter:rev_to_args(view.left, view.right)

    if view.left.type == RevType.STAGE and view.right.type == RevType.LOCAL then
      -- Plain `:DiffviewOpen`: the panel lists staged changes as well, while
      -- `rev_to_args` yields the unstaged half only. Diff against HEAD so the
      -- patch covers both (untracked files can't show up in a patch either way).
      rev_args, title = { "HEAD" }, "HEAD"
    elseif view.right.type == RevType.STAGE then
      title = (view.left:abbrev() or "HEAD") .. " (staged)"
    else
      -- Nil for anything else that tracks HEAD, hence the fallbacks below.
      title = view.rev_arg or adapter:rev_to_pretty_string(view.left, view.right)
    end

    if not title or title == "" then
      title = #rev_args > 0 and table.concat(rev_args, " ") or "working tree"
    end

    args = vim.list_extend({ "diff", "--no-ext-diff" }, rev_args)
  end

  local path_args = (entry and entry.path_args) or view.path_args
  if path_args and #path_args > 0 then
    table.insert(args, "--")
    vim.list_extend(args, path_args)
  end

  local out, code, stderr = adapter:exec_sync(args, adapter.ctx.toplevel)
  if code ~= 0 then
    vim.notify("git " .. table.concat(args, " ") .. " failed:\n"
      .. table.concat(stderr or {}, "\n"), vim.log.levels.ERROR)
    return
  end

  -- Refresh the buffer from a previous run instead of stacking up tabs (and
  -- reusing the name would throw E95 anyway).
  local name = "flat-diff://" .. title
  local buf
  for _, b in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_get_name(b) == name then
      buf = b
      break
    end
  end

  if buf then
    local win = vim.fn.win_findbuf(buf)[1]
    if win then
      vim.api.nvim_set_current_win(win) -- switches tabpage too
    else
      vim.cmd("tabnew")
      vim.api.nvim_win_set_buf(0, buf)
    end
  else
    vim.cmd("tabnew")
    buf = vim.api.nvim_get_current_buf()
    vim.api.nvim_buf_set_name(buf, name)
  end

  vim.bo[buf].modifiable = true
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, out)
  vim.bo[buf].filetype = "diff"
  vim.bo[buf].buftype = "nofile"
  vim.bo[buf].modifiable = false
end

local function worktree_head(path)
  local result = vim.system({
    "git", "-C", path, "rev-parse", "HEAD",
  }, { text = true }):wait()

  if result.code ~= 0 then
    vim.notify(result.stderr or "Unable to resolve worktree HEAD", vim.log.levels.ERROR)
    return
  end
  return vim.trim(result.stdout)
end

local function open_worktree_diff(local_side)
  local bufname = vim.api.nvim_buf_get_name(0)
  local cwd = bufname ~= "" and vim.fs.dirname(bufname) or vim.fn.getcwd()
  local toplevel = vim.system({
    "git", "-C", cwd, "rev-parse", "--show-toplevel",
  }, { text = true }):wait()

  if toplevel.code ~= 0 then
    vim.notify(toplevel.stderr or "Current buffer is not in a Git worktree", vim.log.levels.ERROR)
    return
  end

  local current_path = vim.fs.normalize(vim.trim(toplevel.stdout))
  local result = vim.system({
    "git", "-C", cwd, "worktree", "list", "--porcelain",
  }, { text = true }):wait()

  if result.code ~= 0 then
    vim.notify(result.stderr or "Unable to list Git worktrees", vim.log.levels.ERROR)
    return
  end

  local worktrees = {}
  for path in result.stdout:gmatch("worktree ([^\n]+)") do
    path = vim.fs.normalize(path)
    if path ~= current_path then
      worktrees[#worktrees + 1] = {
        path = path,
        name = vim.fs.basename(path),
      }
    end
  end

  if #worktrees == 0 then
    vim.notify("No other Git worktrees", vim.log.levels.WARN)
    return
  end

  vim.ui.select(worktrees, {
    prompt = "Select worktree:",
    format_item = function(item)
      return ("%s  %s"):format(item.name, item.path)
    end,
  }, function(choice)
    if not choice then return end
    vim.schedule(function()
      local revision_path = local_side == "current" and choice.path or current_path
      local local_path = local_side == "current" and current_path or choice.path
      local revision = worktree_head(revision_path)
      if not revision then return end

      vim.api.nvim_cmd({
        cmd = "DiffviewOpen",
        args = { revision, "-C" .. local_path },
      }, {})
    end)
  end)
end

local TRUNK = "origin/HEAD"

-- Candidate bases for a branch diff of `head` (default HEAD): the branches
-- stacked between the trunk and `head` (nearest first), then the trunk
-- itself. `base` is the commit to diff `head`'s working tree against.
local function stack_bases(head)
  head = head or "HEAD"
  local mb = vim.fn.trim(vim.fn.system({ "git", "merge-base", TRUNK, head }))
  if vim.v.shell_error ~= 0 then
    vim.notify("No merge base between " .. head .. " and " .. TRUNK, vim.log.levels.ERROR)
    return
  end
  local head_hash = vim.fn.trim(vim.fn.system({ "git", "rev-parse", head }))

  -- One line per decorated commit in mb..head, with full ref names so local
  -- branches can be told apart from remote ones (`--decorate-refs` doesn't
  -- filter `%D` on older git).
  local lines = vim.fn.systemlist({
    "git", "log", "--format=%H %D", "--decorate=full",
    "--simplify-by-decoration", mb .. ".." .. head,
  })
  local bases = {}
  for _, line in ipairs(lines) do
    local hash, refs = line:match("^(%x+) ?(.*)$")
    if hash and hash ~= head_hash then -- branches at head would give an empty diff
      for ref in vim.gsplit(refs, ", ", { plain = true }) do
        -- The checked-out branch is decorated as "HEAD -> refs/heads/<name>".
        local branch = ref:match("^refs/heads/(.+)$") or ref:match("^HEAD %-> refs/heads/(.+)$")
        if branch then
          bases[#bases + 1] = { name = branch, base = branch }
        end
      end
    end
  end
  bases[#bases + 1] = { name = TRUNK, base = mb }
  return bases
end

-- Pass a base for `head` (default HEAD), chosen from stack_bases(), to
-- `open`, prompting only when there are stacked branches to choose from.
local function choose_base(head, open)
  local bases = stack_bases(head)
  if not bases then return end

  if #bases == 1 then
    open(bases[1])
    return
  end
  vim.ui.select(bases, {
    prompt = ("Diff %s against:"):format(head or "HEAD"),
    format_item = function(item) return item.name end,
  }, function(choice)
    if choice then open(choice) end
  end)
end

-- Diff the branch against a base chosen from stack_bases().
local function open_branch_diff(committed)
  choose_base(nil, function(choice)
    -- Every base is an ancestor of HEAD (or the trunk, via its merge base), so
    -- "<name>...HEAD" is exactly the commits on top of it.
    vim.cmd("DiffviewOpen " .. (committed and choice.name .. "...HEAD" or choice.base))
  end)
end

-- Local branches on the current stack, i.e. below HEAD (in its history) or
-- above it (built on it) and not yet in the trunk, top of the stack first.
local function stack_branches()
  -- A HEAD already in the trunk has no stack: every branch would be above it.
  vim.fn.system({ "git", "merge-base", "--is-ancestor", "HEAD", TRUNK })
  if vim.v.shell_error == 0 then return {} end

  local height, branches = {}, {}
  for _, filter in ipairs({ "--merged=HEAD", "--contains=HEAD" }) do
    for _, branch in ipairs(vim.fn.systemlist({
      "git", "for-each-ref", "--format=%(refname:lstrip=2)", filter, "--no-merged=" .. TRUNK, "refs/heads/",
    })) do
      if not height[branch] then
        height[branch] = tonumber(vim.fn.system({ "git", "rev-list", "--count", TRUNK .. ".." .. branch })) or 0
        branches[#branches + 1] = branch
      end
    end
  end
  table.sort(branches, function(a, b)
    if height[a] ~= height[b] then return height[a] > height[b] end
    return a < b
  end)
  return branches
end

-- Map of branch name -> path of the worktree it is checked out in.
local function branch_worktrees()
  local worktrees, path = {}, nil
  for _, line in ipairs(vim.fn.systemlist({ "git", "worktree", "list", "--porcelain" })) do
    path = line:match("^worktree (.+)$") or path
    local branch = line:match("^branch refs/heads/(.+)$")
    if branch then worktrees[branch] = path end
  end
  return worktrees
end

-- Diff two branches of the current stack: pick the branch to review, then its
-- base. Opens in the reviewed branch's worktree when it has one (real files,
-- so LSP and uncommitted changes), otherwise diffs its commits.
local function open_stack_diff()
  local branches = stack_branches()
  if #branches == 0 then
    vim.notify("No stacked branches: HEAD is already in " .. TRUNK, vim.log.levels.WARN)
    return
  end
  local worktrees = branch_worktrees()
  local current = vim.fn.trim(vim.fn.system({ "git", "branch", "--show-current" }))

  vim.ui.select(branches, {
    prompt = "Review branch:",
    format_item = function(branch)
      local path = worktrees[branch]
      return (branch == current and "● " or "  ") .. branch .. (path and "  " .. path or "")
    end,
  }, function(head)
    if not head then return end
    vim.schedule(function()
      choose_base(head, function(choice)
        local path = worktrees[head]
        if path then
          vim.api.nvim_cmd({ cmd = "DiffviewOpen", args = { choice.base, "-C" .. path } }, {})
        else
          vim.cmd("DiffviewOpen " .. choice.name .. "..." .. head)
        end
      end)
    end)
  end)
end

local function open_diffview()
  -- Define the diff options with their corresponding action functions
  local diff_options = {
    {
      name = "Index (Working tree)",
      action = function() vim.cmd("DiffviewOpen") end
    },
    {
      name = "Branch changes (working tree)",
      action = function() open_branch_diff(false) end
    },
    {
      name = "Branch changes (committed)",
      action = function() open_branch_diff(true) end
    },
    {
      name = "Stack: compare two branches",
      action = open_stack_diff,
    },
    {
      name = "Compare worktree (current local)",
      action = function() open_worktree_diff("current") end,
    },
    {
      name = "Compare worktree (other local)",
      action = function() open_worktree_diff("other") end,
    },
    {
      name = "Pick a commit",
      action = function()
        require("snacks.picker").git_log({
          title = "Select commit for diff",
          -- Show ref names (branches, tags) in front of the commit message.
          -- snacks' own `--pretty` omits `%d`; git honours the last one, and
          -- `cmd_args` is appended after the built-in args, so this wins.
          cmd_args = { "--pretty=format:%h%d %s (%ch) <%an>" },
          confirm = function(picker, item)
            picker:close()
            -- `:DiffviewOpen` runs git synchronously via `vim.wait`, which pumps
            -- the event loop mid-teardown: the picker has already cleared its
            -- matcher while the finder is still streaming, and the finder then
            -- indexes it. Defer so teardown completes first.
            vim.schedule(function() vim.cmd("DiffviewOpen " .. item.commit) end)
          end,
        })
      end
    },
    {
      name = "Manually specify",
      action = function() vim.api.nvim_feedkeys(":DiffviewOpen ", "c", true) end
    }
  }

  -- Show the selector
  vim.ui.select(diff_options, {
    prompt = "Select git revision for diff:",
    format_item = function(item) return item.name end,
  }, function(choice, idx)
    if not choice then return end

    -- Execute the action function
    choice.action()
  end)
end

local diffview_keys = {
  { '<leader>gd', mode = 'n', open_diffview, desc = "Toggle diff view" },
  { '<leader>gh', '<cmd>DiffviewFileHistory % --max-count=1000<CR>', mode = 'n', desc = 'Current file history' },
  { '<leader>gh', ':DiffviewFileHistory --max-count=1000<CR>', mode = 'x', desc = 'File range history' },
  { '<leader>gl', '<cmd>DiffviewFileHistory --max-count=1000<CR>', mode = 'n', desc = 'Git log' },
}

local function setup_diffview()
  local keymaps = require("diffview.config").defaults.keymaps
  keymaps = vim.deepcopy(keymaps)

  for _, v in pairs(keymaps) do
    if type(v) == "table" then
      for _, keymap in ipairs(v) do
        if keymap[2] and keymap[2]:find("<leader>") then
          keymap[2] = keymap[2]:gsub("<leader>", "<localleader>")
        end
      end
    end
  end
  keymaps.disable_defaults = true

  -- Add [q/]q to switch files and [Q/]Q to jump to the first/last file,
  -- across the diff windows, the file panel, and the file-history panel.
  local actions = require("diffview.actions")
  local file_nav = {
    { "n", "]q", actions.select_next_entry,  { desc = "Open the diff for the next file" } },
    { "n", "[q", actions.select_prev_entry,  { desc = "Open the diff for the previous file" } },
    { "n", "]Q", actions.select_last_entry,  { desc = "Open the diff for the last file" } },
    { "n", "[Q", actions.select_first_entry, { desc = "Open the diff for the first file" } },
  }
  for _, ctx in ipairs({ "view", "file_panel", "file_history_panel" }) do
    for _, m in ipairs(file_nav) do
      table.insert(keymaps[ctx], m)
    end
  end

  -- Fuzzy file switcher across the diff windows and the file panel.
  for _, ctx in ipairs({ "view", "file_panel" }) do
    table.insert(keymaps[ctx],
      { "n", "<leader>ff", pick_diffview_file, { desc = "Fuzzy switch changed file" } })
  end

  -- Flatten the whole view into one unified-diff buffer.
  for _, ctx in ipairs({ "view", "file_panel", "file_history_panel" }) do
    table.insert(keymaps[ctx],
      { "n", "<leader>gD", open_flat_diff, { desc = "Flat unified diff of this view" } })
  end

  local diffview_opts = {
    file_panel = {
      win_config = {
        type = "split",
        position = "bottom",
        height = 12,
      },
    },
    keymaps = keymaps,
    hooks = {
      ---@diagnostic disable-next-line
      view_enter = function(view)
        -- Save the current view
        vim.g.diffview_open = true
      end,
      ---@diagnostic disable-next-line
      view_leave = function(view)
        vim.g.diffview_open = false
      end,
    },
  }
  require("diffview").setup(diffview_opts)
end

local diffview = {
  "sindrets/diffview.nvim",
  cmd = {
    "DiffviewOpen",
    "DiffviewFileHistory",
  },
  keys = diffview_keys,
  config = setup_diffview,
}

-- Open a review (via the given Octo command), enabling LSP on the reviewed
-- code when the working tree is checked out at the PR head.
local function open_review(cmd)
  -- octo's use_local_fs swaps the right (head) diff side for the real on-disk
  -- file (=> LSP), but it only checks the branch name, never the commit. Enable
  -- it only at the exact PR head; otherwise the diff and comments would target
  -- the wrong content, so fall back to octo's virtual buffers (no LSP). Only
  -- the right side is ever a real file -- the left/base side stays virtual.
  --
  -- PLUGIN-PATCH(octo.nvim): mutates config at runtime. Drop once octo
  -- checks the head commit itself before using local files.
  local buffer = require("octo.utils").get_current_buffer()
  local node = buffer and buffer:isPullRequest() and buffer:pullRequest()
  local head = vim.fn.systemlist("git rev-parse HEAD")[1]
  local at_head = node and vim.v.shell_error == 0 and head == node.headRefOid or false
  require("octo.config").values.use_local_fs = at_head
  if at_head then
    vim.notify("octo: review using local files (LSP enabled)", vim.log.levels.INFO)
  else
    vim.notify("octo: review using virtual buffers (no LSP)", vim.log.levels.WARN)
  end
  vim.cmd(cmd)
end

local function setup_octo()
  local mappings = {}

  for _, buf_type in pairs({ "issue", "pull_request" }) do
    mappings[buf_type] = {
      reload = { lhs = "<localleader>or" },
      open_in_browser = { lhs = "<localleader>ob" },
      copy_url = { lhs = "<localleader>oy" },
    }
  end

  -- Disable octo's builtin review start/resume so our own vs (which enables
  -- use_local_fs first, see set_pr_keys) can bind buffer-locally without octo
  -- clobbering it -- octo applies its mappings after setting the filetype.
  mappings.pull_request.review_start = { lhs = "" }
  mappings.pull_request.review_resume = { lhs = "" }

  for _, buf_type in pairs({ "review_thread", "review_diff", "file_panel" }) do
    mappings[buf_type] = {
      -- Disable closing review tabs with ctrl-c.
      close_review_tab = { lhs = "" },
    }
  end

  require("octo").setup({
    enable_builtin = true,
    picker = "snacks",
    default_merge_method = "squash",
    mappings = mappings,
    suppress_missing_scope = {
      projects_v2 = true,
    },
  })
  vim.treesitter.language.register('markdown', 'octo')

  -- Octo defaults to "]q"/"[q" for file navigation. Octo only allows a single
  -- lhs per action, so add "<tab>"/"<s-tab>" as extra keys alongside them.
  local function set_file_nav_keys(buf)
    local m = require("octo.mappings")
    vim.keymap.set("n", "<tab>", m.select_next_entry,
      { silent = true, noremap = true, buffer = buf, desc = "Select next changed file" })
    vim.keymap.set("n", "<s-tab>", m.select_prev_entry,
      { silent = true, noremap = true, buffer = buf, desc = "Select previous changed file" })
    vim.keymap.set("n", "<leader>ff", pick_octo_review_file,
      { silent = true, noremap = true, buffer = buf, desc = "Fuzzy switch changed file" })
  end

  -- PR overview keymaps beyond octo's builtins.
  local function set_pr_keys(buf)
    local keys = {
      -- Browse the review read-only; octo has no builtin for this.
      { "<localleader>vb", function() open_review("Octo review browse") end, "Browse review (no pending review)" },
      -- Start or resume a review (bare "Octo review"), replacing octo's
      -- separate start/resume mappings (disabled above).
      { "<localleader>vs", function() open_review("Octo review") end,        "Start/resume review" },
    }
    for _, k in ipairs(keys) do
      vim.keymap.set("n", k[1], k[2], { silent = true, noremap = true, buffer = buf, desc = k[3] })
    end
  end

  local function set_which_key(buf)
    require('which-key').add({
      buffer = buf,
      { "<localleader>a", group = "assignee", icon = { icon = " ", color = "blue" }, },
      { "<localleader>c", group = "comment", icon = { icon = " ", color = "blue" }, },
      { "<localleader>g", group = "goto", icon = { icon = " ", color = "blue" }, },
      { "<localleader>i", group = "issue", icon = { icon = " ", color = "blue" }, },
      { "<localleader>l", group = "label", icon = { icon = "󰌕 ", color = "blue" }, },
      { "<localleader>o", group = "operation", icon = { icon = " ", color = "blue" }, },
      { "<localleader>p", group = "pr", icon = { icon = " ", color = "blue" }, },
      { "<localleader>r", group = "react", icon = { icon = "󰞅 ", color = "blue" }, },
      { "<localleader>s", group = "suggest", icon = { icon = "󱀡 ", color = "blue" }, },
      { "<localleader>v", group = "review", icon = { icon = " ", color = "blue" }, },
    })
  end

  -- For PR review buffers ("octo") and file panel buffers ("octo_panel").
  -- NOTE: "octo://*" file name pattern can also match the PR review buffers.
  -- But that will lead to a weird behavior where the <localleader> mappings
  -- are not usable until <leader> is pressed once.
  vim.api.nvim_create_autocmd("FileType", {
    pattern = { "octo", "octo_panel" },
    callback = function(ev)
      set_which_key(ev.buf)
      -- Only the file panel navigates between files, not the PR overview.
      if vim.bo[ev.buf].filetype == "octo_panel" then
        set_file_nav_keys(ev.buf)
      end
      -- Extra keymaps for the PR overview buffer.
      if vim.api.nvim_buf_get_name(ev.buf):match("octo://.*/pull/") then
        set_pr_keys(ev.buf)
      end
    end,
  })

  -- For file review buffers.
  vim.api.nvim_create_autocmd("BufEnter", {
    pattern = { "octo://*/review/*" },
    callback = function(ev)
      if not vim.b[ev.buf].octo_setup_done then
        vim.b[ev.buf].octo_setup_done = true
        set_which_key(ev.buf)
        set_file_nav_keys(ev.buf)
      end
    end,
  })

  -- Octo's buffers ("octo://..." for PRs/issues/review files, and the
  -- "octo/null" diff placeholder) are virtual, API-backed buffers, not real
  -- files, so a swapfile is meaningless. On a swap collision (e.g. two nvim
  -- instances on the same PR) Neovim only prints a non-interactive warning:
  -- the swapfile is created outside a file-open, so SwapExists never fires and
  -- there is no prompt to recover from. Disable the swapfile so one is never
  -- created and instances never collide.
  --
  -- Both events are needed, one per way Octo names a buffer:
  --   BufFilePost -- ":file octo://..." on a fresh buffer ("Octo pr list")
  --   BufAdd      -- ":e octo://...", loaded by Octo's BufReadCmd
  --                  ("Octo pr edit"), where BufFilePost never fires
  --
  -- PLUGIN-PATCH(octo.nvim): drop once octo disables swapfiles on its
  -- virtual buffers.
  vim.api.nvim_create_autocmd({ "BufAdd", "BufFilePost" }, {
    pattern = { "octo://*", "octo/null", "*/octo/null" },
    callback = function(ev)
      vim.bo[ev.buf].swapfile = false
    end,
  })

  -- Octo's TabClosed handler passes the tab *number* (<afile>) to
  -- reviews.close(), which looks reviews up by tabpage *handle*, so closed
  -- reviews usually leak their buffers. Those buffers then get reused, stale,
  -- by the next review (browse always uses id -1). Close any review whose tab
  -- is gone.
  --
  -- PLUGIN-PATCH(octo.nvim): drop once octo's TabClosed handler closes
  -- reviews by tabpage handle.
  vim.api.nvim_create_autocmd("TabClosed", {
    callback = function()
      local reviews = require("octo.reviews")
      for tab in pairs(reviews.reviews) do
        if not vim.api.nvim_tabpage_is_valid(tonumber(tab)) then
          reviews.close(tonumber(tab))
        end
      end
    end,
  })
end

local octo_keys = {
  {
    "<leader>gO",
    "",
    desc = "+octo",
  },
  {
    "<leader>gOp",
    "<cmd>Octo pr search author:@me<CR>",
    desc = "Search repo: my PRs",
  },
  {
    "<leader>gOr",
    "<cmd>Octo pr search is:open assignee:@me<CR>",
    desc = "Search repo: PRs to review",
  },
  {
    "<leader>gOi",
    "<cmd>Octo issue search author:@me<CR>",
    desc = "Search repo: issues created by me",
  },
  {
    "<leader>gOa",
    "<cmd>Octo issue search is:open assignee:@me<CR>",
    desc = "Search repo: open issues assigned to me",
  },
  {
    "<leader>gOP",
    "<cmd>Octo search is:pr author:@me<CR>",
    desc = "Search global: my PRs",
  },
  {
    "<leader>gOR",
    "<cmd>Octo search is:pr is:open assignee:@me<CR>",
    desc = "Search global: PRs to review",
  },
  {
    "<leader>gOI",
    "<cmd>Octo search is:issue author:@me<CR>",
    desc = "Search global: issues created by me",
  },
  {
    "<leader>gOA",
    "<cmd>Octo search is:issue is:open assignee:@me<CR>",
    desc = "Search global: open issues assigned to me",
  },
}

local octo = {
  'pwntester/octo.nvim',
  dependencies = {
    'nvim-lua/plenary.nvim',
    'nvim-tree/nvim-web-devicons',
  },
  cmd = { "Octo" },
  keys = octo_keys,
  config = setup_octo,
}

return {
  fugitive,
  gitsigns,
  diffview,
  octo,
}
