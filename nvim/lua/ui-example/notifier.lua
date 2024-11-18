local api = vim.api
local ns = api.nvim_create_namespace('messageRedirection')

--- @alias msgHistoryItem {msg: table<integer, string, integer>[], removed: boolean}

--- @type msgHistoryItem[]
local msgHistory = {}

local hls = setmetatable({}, {
  __index = function (t, id)
    return rawget(t, id) or (rawset(t, id, vim.fn.synIDattr(id, 'name')) and rawget(t, id))
  end
})

local function composeLines()
  local line, col, newCol, msg, hlname = 0, 0, 0, nil, nil
  local lines, highlights = {}, {}

  for _, item in ipairs(msgHistory) do
    if not item.removed then
      for _, chunk in ipairs(item.msg) do
        hlname = hls[chunk[3]]
        msg = vim.split(chunk[2], '\n')
        for index, msgpart in ipairs(msg) do
          if index > 1 then
            line, col = line + 1, 0
          end
          newCol = col + #msgpart
          lines[line + 1] = (lines[line + 1] or '') .. msgpart
          highlights[#highlights + 1] = {line, col, newCol, hlname}
          col = newCol
        end
      end
      line, col = line + 1, 0
    end
  end

  return lines, highlights
end

local extmarkOpts = {end_row = 0, end_col = 0, hl_group = 'Normal', hl_eol = true, hl_mode = 'combine'}

local messageBuf
local debugBuf
local messageWin
local debugWin

local M = {}

--- @type uv.uv_timer_t[]
local removal_timers = {}

local function destroy_removal_timer(id)
  local timer = removal_timers[id]
  if not timer then
    return
  end

  timer:stop()
  timer:close()
  removal_timers[id] = nil
end

local function defer_removal(duration, id)
  local timer = assert(vim.uv.new_timer())
  timer:start(duration, duration, function ()
    M.remove(id) -- schedule it while #1341 or similar not merged
  end)
  removal_timers[id] = timer
end

local function defer_removal_again(id)
  local timer = removal_timers[id]
  if not timer then
    return
  end
  timer:again()
end

--- @class notifier.opts
local defaultOpts = {notify = true, debug = true, duration = 5000}
--- @class notifier.opts?
local realOpts

---@param opts notifier.opts
function M.setup(opts)
  --- @type notifier.opts
  realOpts = vim.tbl_extend('keep', opts or {}, defaultOpts)

  if realOpts.debug then
    debugBuf = api.nvim_create_buf(false, true)
    debugWin = api.nvim_open_win(debugBuf, false, {
      relative = 'editor',
      row = vim.go.lines - 13,
      col = vim.o.columns,
      width = 120,
      height = 14,
      anchor = 'SE',
      border = 'rounded',
      title_pos = 'center',
      title = ' unhandled messages ',
      hide = true,
      style = 'minimal',
    })
    vim.wo[debugWin].winblend = 25
    vim.wo[debugWin].number = true
  end

  if realOpts.notify then
    messageBuf = api.nvim_create_buf(false, true)
    messageWin = api.nvim_open_win(messageBuf, false, {
      relative = 'editor',
      row = vim.go.lines - 1,
      col = vim.o.columns,
      width = 100,
      height = 10,
      anchor = 'SE',
      hide = true,
      style = 'minimal',
    })
    vim.wo[messageWin].winblend = 25
  end
end

local function display()
  api.nvim_buf_clear_namespace(messageBuf, ns, 0, -1)
  api.nvim_buf_set_lines(messageBuf, 0, -1, true, {})

  local lines, highlights = composeLines()

  api.nvim_buf_set_lines(messageBuf, 0, -1, true, lines)
  for _, highlight in ipairs(highlights) do
    extmarkOpts.end_row, extmarkOpts.end_col, extmarkOpts.hl_group = highlight[1], highlight[3], highlight[4]
    api.nvim_buf_set_extmark(messageBuf, ns, highlight[1], highlight[2], extmarkOpts)
  end
  local height = (#lines < vim.o.lines - 3) and #lines or vim.o.lines - 3
  api.nvim_win_set_config(messageWin, {
    hide = height == 0,
    height = (height == 0) and 1 or height
  })
end

local function inFastEventWrapper(cb)
  if vim.in_fast_event() then
    vim.schedule(cb)
    return
  end
  cb()
end

function M.add(chunkSequence)
  local newId = #msgHistory + 1
  msgHistory[newId] = {msg = chunkSequence, removed = false}
  inFastEventWrapper(display)
  defer_removal(realOpts.duration, newId)

  return newId
end

function M.update(id, chunkSequence)
  msgHistory[id].msg = chunkSequence
  inFastEventWrapper(display)
  defer_removal_again(id)
end

function M.remove(id)
  msgHistory[id].removed = true
  destroy_removal_timer(id)
  inFastEventWrapper(display)
end

local function displayDebugMessages(msg)
  api.nvim_win_set_config(debugWin, {hide = false})
  api.nvim_buf_set_lines(debugBuf, -1, -1, true, vim.split(msg, '\n'))
end

function M.debug(msg)
  inFastEventWrapper(function ()
    displayDebugMessages(msg)
  end)
end

return M
