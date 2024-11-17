local api = vim.api
local ns = api.nvim_create_namespace('messageRedirection')

local msgHistory = {}

local hls = setmetatable({}, {
  __index = function (t, id)
    return rawget(t, id) or (rawset(t, id, vim.fn.synIDattr(id, 'name')) and rawget(t, id))
  end
})

local function composeLines()
  local line, col, newCol, msg, hlname = 0, 0, 0, nil, nil
  local lines, highlights = {}, {}

  for _, chunkSequence in ipairs(msgHistory) do
    for _, chunk in ipairs(chunkSequence) do
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

  return lines, highlights
end

local extmarkOpts = {end_row = 0, end_col = 0, hl_group = 'Normal', hl_eol = true, hl_mode = 'combine'}

local messageBuf
local debugBuf
local messageWin
local debugWin

local M = {}

--- @class notifier.opts
local defaultOpts = {notify = true, debug = true}

---comment
---@param opts notifier.opts
function M.setup(opts)
  --- @type notifier.opts
  opts = vim.tbl_extend('keep', opts or {}, defaultOpts)

  if opts.debug then
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

  if opts.notify then
    messageBuf = api.nvim_create_buf(false, true)
    messageWin = api.nvim_open_win(messageBuf, false, {
      relative = 'editor',
      row = vim.go.lines - 1,
      col = vim.o.columns,
      width = 100,
      height = 10,
      anchor = 'SE',
      border = 'rounded',
      hide = true,
      style = 'minimal',
    })
    vim.wo[messageWin].winblend = 25
  end
end

local function display()
  vim.schedule(function ()
    api.nvim_buf_clear_namespace(messageBuf, ns, 0, -1)
    api.nvim_buf_set_lines(messageBuf, 0, -1, true, {})

    local lines, highlights = composeLines()

    api.nvim_buf_set_lines(messageBuf, 0, -1, true, lines)
    for _, highlight in ipairs(highlights) do
      extmarkOpts.end_row, extmarkOpts.end_col, extmarkOpts.hl_group = highlight[1], highlight[3], highlight[4]
      api.nvim_buf_set_extmark(messageBuf, ns, highlight[1], highlight[2], extmarkOpts)
    end
    api.nvim_win_set_config(messageWin, {
      hide = false,
      height = (#lines < vim.o.lines - 3) and #lines or vim.o.lines - 3
    })
  end)
end

function M.add(chunkSequence)
  local newId = #msgHistory + 1
  msgHistory[newId] = chunkSequence
  display()

  return newId
end

function M.update(id, chunkSequence)
  msgHistory[id] = chunkSequence
  display()
end

function M.debug(msg)
  vim.schedule(function ()
    api.nvim_win_set_config(debugWin, {hide = false})
    api.nvim_buf_set_lines(debugBuf, -1, -1, true, {msg})
  end)
end

return M
