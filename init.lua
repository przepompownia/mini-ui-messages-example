local thisInitFile = debug.getinfo(1).source:match('@?(.*)')
local cwd = vim.fs.dirname(thisInitFile)
local appname = vim.env.NVIM_APPNAME or 'nvim'
local api = vim.api

vim.env.XDG_CONFIG_HOME = cwd
vim.env.XDG_DATA_HOME = vim.fs.joinpath(cwd, '.xdg', 'data')
vim.env.XDG_STATE_HOME = vim.fs.joinpath(cwd, '.xdg', 'state')
vim.env.XDG_CACHE_HOME = vim.fs.joinpath(cwd, '.xdg', 'cache')
vim.fn.mkdir(vim.fs.joinpath(vim.env.XDG_CACHE_HOME, appname), 'p')
local stdPathConfig = vim.fn.stdpath('config')

vim.opt.runtimepath:prepend(stdPathConfig)
vim.opt.packpath:prepend(stdPathConfig)

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

local pluginsPath = vim.fs.joinpath(cwd, 'nvim/pack/plugins/opt')
vim.fn.mkdir(pluginsPath, 'p')
pluginsPath = vim.uv.fs_realpath(pluginsPath)

--- @type table<string, {url:string, branch: string?}>
local plugins = {
  ['mini-notify'] = {url = 'https://github.com/przepompownia/mini.notify', branch = 'ui-messages'},
}

for name, repo in pairs(plugins) do
  local installPath = vim.fs.joinpath(pluginsPath, name)
  gitClone(repo.url, installPath, repo.branch)
  -- vim.opt.runtimepath:append(installPath)
  vim.cmd.packadd({args = {name}, bang = true})
end

local miniWinConfig = function ()
  local hasStatusline = vim.o.laststatus > 0
  local pad = vim.o.cmdheight + (hasStatusline and 1 or 0)
  return {
    anchor = 'SE',
    col = vim.o.columns,
    row = vim.o.lines - pad,
    border = 'none',
  }
end

local notify = require('mini.notify')

local level_priority = {ERROR = 6, WARN = 5, INFO = 4, DEBUG = 3, TRACE = 2, OFF = 1}

local function sort(notifArr)
  local res = vim.deepcopy(notifArr)
  table.sort(res, function (a, b)
    local a_priority, b_priority = level_priority[a.level], level_priority[b.level]
    return not (a_priority > b_priority or (a_priority == b_priority and a.ts_update > b.ts_update))
  end)

  return res
end

local defaultFormat = notify.config.content.format

local function rawMessage(notification)
  return notification.msg
end

notify.setup({
  content = {
    sort = sort,
    format = rawMessage
  },
  window = {
    config = miniWinConfig,
    max_width_share = 0.7,
  },
  lsp_progress = {
    duration_last = 1000,
  },
})

vim.notify = notify.make_notify()

local function showHistory()
  notify.config.content.format = defaultFormat
  notify.show_history()
  notify.config.content.format = rawMessage
end

vim.keymap.set('n', '<Leader>nh', showHistory)

local function redraw()
  vim.schedule(function ()
    vim.cmd.redraw()
  end)
end

local ns = api.nvim_create_namespace('messageRedirection')
api.nvim_create_autocmd('CmdlineEnter', {
  callback = function ()
    vim.ui_detach(ns)
    redraw()
  end
})

local bufferedContents = {}
api.nvim_create_autocmd({'UIEnter', 'CmdlineLeave'}, {
  callback = function ()
    vim.ui_attach(ns, {ext_messages = true, ext_cmdline = false}, function (event, kind, content, replace_last)
      if
        event == 'grid_destroy'
        or event == 'msg_showmode'
        or event == 'msg_ruler'
        or event == 'msg_showcmd'
        or event == 'cmdline_show'
        or event == 'cmdline_hide'
        or event == 'msg_history_show'
        or event == 'msg_history_clear'
      then
        return
      end
      if
        (event == 'msg_showcmd' or event == 'msg_show')
        and (
          kind == 'emsg'
          or kind == 'echo'
          or kind == 'echomsg'
          or kind == 'echoerr'
          or kind == 'lua_error'
        ) then
        vim.notify({content})
      elseif event == 'msg_show' and kind == '' then -- :={x = 1, y = 1}
        bufferedContents[#bufferedContents + 1] = content
      elseif event == 'msg_clear' and kind == nil then
        -- fix too late redraw with mini.notify
        vim.notify(bufferedContents)
        bufferedContents = {}
      elseif event == 'msg_show' and kind == 'return_prompt' then
        api.nvim_input('\r')
      elseif event == 'msg_show' and kind == 'search_count' then
        vim.notify({content})
      else
        -- it shouldn't be called in normal use
        vim.notify(('ev: %s'):format(event), 'WARN')
        vim.notify(('k: %s'):format(vim.inspect(kind)), 'WARN')
        vim.notify(('r: %s'):format(vim.inspect(replace_last)), 'WARN')
        vim.notify(vim.inspect(content), 'WARN')
      end
      redraw()
    end)
  end
})
