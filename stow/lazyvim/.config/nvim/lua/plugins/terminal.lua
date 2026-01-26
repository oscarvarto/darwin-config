-- Terminal keybindings (since <C-/> doesn't work in all terminals like Ghostty)
-- Detect the actual parent shell process (not $SHELL which is login shell)
local function detect_current_shell()
  local home = vim.env.HOME
  local nix_bin = home .. "/.nix-profile/bin/"

  local function resolve_xonsh_path()
    local darwin_config = vim.env.DARWIN_CONFIG_PATH or (home .. "/darwin-config")
    local pixi_xonsh = darwin_config .. "/python-env/.pixi/envs/default/bin/xonsh"
    if vim.fn.executable(pixi_xonsh) == 1 then
      return pixi_xonsh
    end
    if vim.fn.executable(nix_bin .. "xonsh") == 1 then
      return nix_bin .. "xonsh"
    end
    if vim.fn.executable("xonsh") == 1 then
      return vim.fn.exepath("xonsh")
    end
    return nix_bin .. "xonsh"
  end

  local shell_map = {
    nu = nix_bin .. "nu",
    fish = nix_bin .. "fish",
    bash = nix_bin .. "bash",
    zsh = nix_bin .. "zsh",
    xonsh = resolve_xonsh_path(),
  }

  -- Walk up the process tree to find the nearest shell ancestor
  local function find_shell_ancestor()
    local pid = vim.fn.getpid()
    for _ = 1, 10 do -- Max 10 levels up
      local handle = io.popen(string.format("ps -o ppid= -p %d 2>/dev/null", pid))
      if not handle then break end
      local ppid = handle:read("*a"):gsub("%s+", "")
      handle:close()
      if ppid == "" or ppid == "0" or ppid == "1" then break end

      handle = io.popen(string.format("ps -o comm= -p %s 2>/dev/null", ppid))
      if not handle then break end
      local comm = handle:read("*a"):gsub("%s+", "")
      handle:close()

      -- Check if this ancestor is a known shell
      for name, path in pairs(shell_map) do
        if comm:find(name) then
          return path
        end
      end
      -- Also check for python (xonsh runs as python)
      if comm:find("python") and vim.env.XONSH_VERSION then
        return resolve_xonsh_path()
      end

      pid = tonumber(ppid)
    end
    return nil
  end

  local shell = find_shell_ancestor()
  if shell then return shell end

  -- Fallback to environment variables (less reliable due to inheritance)
  if vim.env.XONSH_VERSION then
    return resolve_xonsh_path()
  end

  -- Fallback to $SHELL
  return vim.env.SHELL
end

-- Debug command to see what shell is detected
vim.api.nvim_create_user_command("DetectShell", function()
  print("Detected shell: " .. detect_current_shell())
  print("XONSH_VERSION: " .. (vim.env.XONSH_VERSION or "nil"))
  print("FISH_VERSION: " .. (vim.env.FISH_VERSION or "nil"))
  print("NU_VERSION: " .. (vim.env.NU_VERSION or "nil"))
  print("$SHELL: " .. (vim.env.SHELL or "nil"))
  -- Show process tree
  print("Process tree:")
  local pid = vim.fn.getpid()
  for i = 1, 10 do
    local handle = io.popen(string.format("ps -o ppid=,comm= -p %d 2>/dev/null", pid))
    if not handle then break end
    local output = handle:read("*a"):gsub("^%s+", "")
    handle:close()
    if output == "" then break end
    local ppid, comm = output:match("(%d+)%s+(.+)")
    if not ppid then break end
    print(string.format("  %d: %s (ppid: %s)", i, comm:gsub("%s+$", ""), ppid))
    if ppid == "0" or ppid == "1" then break end
    pid = tonumber(ppid)
  end
end, {})

return {
  {
    "folke/snacks.nvim",
    opts = {
      terminal = {
        win = {
          wo = { winbar = "" }, -- Hide winbar for cleaner look
        },
      },
    },
    keys = {
      { "<leader>tt", function()
        local shell = detect_current_shell() or vim.o.shell
        local cmd = { shell, "-i" }
        Snacks.terminal(cmd, { env = { PATH = vim.env.PATH } })
      end, desc = "Toggle Terminal" },
      { "<leader>tT", function()
        local shell = detect_current_shell() or vim.o.shell
        local cmd = { shell, "-i" }
        Snacks.terminal(cmd, { cwd = vim.fn.getcwd(), env = { PATH = vim.env.PATH } })
      end, desc = "Toggle Terminal (cwd)" },
    },
  },
}
