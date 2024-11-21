local thisInitFile = debug.getinfo(1).source:match('@?(.*)')
local cwd = vim.fs.dirname(thisInitFile)
local appname = vim.env.NVIM_APPNAME or 'nvim'

vim.env.XDG_CONFIG_HOME = cwd
vim.env.XDG_DATA_HOME = vim.fs.joinpath(cwd, '.xdg', 'data')
vim.env.XDG_STATE_HOME = vim.fs.joinpath(cwd, '.xdg', 'state')
vim.env.XDG_CACHE_HOME = vim.fs.joinpath(cwd, '.xdg', 'cache')
vim.fn.mkdir(vim.fs.joinpath(vim.env.XDG_CACHE_HOME, appname), 'p')
local stdPathConfig = vim.fn.stdpath('config')

vim.opt.runtimepath:prepend(stdPathConfig)
vim.opt.packpath:prepend(stdPathConfig)
local pluginsPath = vim.fs.joinpath(cwd, 'nvim/pack/plugins/opt')

--- @type plugin.install.data
local plugins = {
  ['msg-show.nvim'] = {url = 'https://github.com/przepompownia/msg-show.nvim'},
  -- ['osv'] = {url = 'https://github.com/jbyuki/one-small-step-for-vimkind'},
}

require('ui-example.plugin').install(plugins, pluginsPath)

local notifier = require('msg-show.notifier')
notifier.setup()

require('msg-show.redir').init(notifier.addUiMessage, notifier.updateUiMessage, notifier.debug)
vim.notify = notifier.notify

-- require('osv').launch {
--   host = '127.0.0.1',
--   port = 9004,
--   log = '/tmp/osv.log',
-- }
