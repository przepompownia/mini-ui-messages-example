local notify = require('mini.notify')

local M = {}

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

local defaultFormat = notify.config.content.format

local function rawMessage(notification)
  return notification.msg
end

local function showHistory()
  notify.config.content.format = defaultFormat
  notify.show_history()
  notify.config.content.format = rawMessage
end

local level_priority = {ERROR = 6, WARN = 5, INFO = 4, DEBUG = 3, TRACE = 2, OFF = 1}

local function sort(notifArr)
  local res = vim.deepcopy(notifArr)
  table.sort(res, function (a, b)
    local a_priority, b_priority = level_priority[a.level], level_priority[b.level]
    return not (a_priority > b_priority or (a_priority == b_priority and a.ts_update > b.ts_update))
  end)

  return res
end

function M.update(id, msg)
  local notif = notify.get(id)
  if not notif or notif.ts_remove then
    return vim.notify(msg)
  end
  -- bump the timer
  return notify.update(id, {msg = msg})
end

function M.setup()
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

  vim.keymap.set('n', '<Leader>nh', showHistory)
end

return M
