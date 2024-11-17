--- @alias plugin.install.data table<string, {url:string, branch: string?}>

local function gitClone(url, installPath, branch)
  if vim.fn.isdirectory(installPath) ~= 0 then
    return
  end

  local command = {'git', 'clone', '--', url, installPath}
  if branch then
    table.insert(command, 3, '--branch')
    table.insert(command, 4, branch)
  end

  vim.notify(('Cloning %s dependency into %s...'):format(url, installPath), vim.log.levels.INFO, {})
  local sysObj = vim.system(command, {}):wait()
  if sysObj.code ~= 0 then
    error(sysObj.stderr)
  end
  vim.notify(sysObj.stdout)
  vim.notify(sysObj.stderr, vim.log.levels.WARN)
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
