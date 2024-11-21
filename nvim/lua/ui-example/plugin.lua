--- @alias plugin.install.data table<string, {url:string, branch: string?}>

local function safeNotify(msg, level)
  if vim.trim(msg) == '' then
    return
  end
  -- https://github.com/neovim/neovim/issues/22914
  vim.api.nvim_create_autocmd('SafeState', {
    once = true,
    callback = function () vim.notify(msg, level) end,
  })
end

local function executeCommand(command)
  local sysObj = vim.system(command, {}):wait()
  if sysObj.code ~= 0 then
    error(sysObj.stderr)
  end
  safeNotify(sysObj.stdout)
  safeNotify(sysObj.stderr, vim.log.levels.WARN)
end

local function gitUpdate(installPath, branch)
  safeNotify(('Uptating %s branch on %s...'):format(branch and ('%s'):format(branch) or 'default', installPath), vim.log.levels.INFO)
  local command = {'git', '-C', installPath, 'pull'}
  executeCommand(command)
end

local function gitClone(url, installPath, branch)
  if vim.fn.isdirectory(installPath) ~= 0 then
    gitUpdate(installPath, branch)
    return
  end

  local command = {'git', 'clone', '--', url, installPath}
  if branch then
    table.insert(command, 3, '--branch')
    table.insert(command, 4, branch)
  end

  vim.notify(('Cloning %s dependency into %s...'):format(url, installPath), vim.log.levels.INFO, {})
  executeCommand(command)
end

local M = {}

--- @param plugins plugin.install.data
function M.install(plugins, pluginsPath)
  vim.fn.mkdir(pluginsPath, 'p')
  pluginsPath = vim.uv.fs_realpath(pluginsPath)

  for name, repo in pairs(plugins) do
    local installPath = vim.fs.joinpath(pluginsPath, name)
    gitClone(repo.url, installPath, repo.branch)
    -- vim.opt.runtimepath:append(installPath)
    vim.cmd.packadd({args = {name}, bang = true})
  end
end

return M
