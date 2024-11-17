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
  ['mini-notify'] = {url = 'https://github.com/przepompownia/mini.notify', branch = 'ui-messages'},
}

require('ui-example.plugin').install(plugins, pluginsPath)
local mini = require('ui-example.mini')
mini.setup()
require('ui-example.msgredir').init(vim.notify, mini.update)
