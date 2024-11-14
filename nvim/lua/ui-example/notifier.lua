local api = vim.api
local ns = api.nvim_create_namespace('messageRedirection')

local hls = setmetatable({}, {
  __index = function (t, id)
    return rawget(t, id) or (rawset(t, id, vim.fn.synIDattr(id, 'name')) and rawget(t, id))
  end
})

local function composeLines(chunkSequences, startLine)
  local line, col, newCol, msg, hlname = startLine or 0, 0, 0, nil, nil
  local lines, highlights = {}, {}

  for _, chunkSequence in ipairs(chunkSequences) do
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
  end

  return lines, highlights
end

local extmarkOpts = {end_row = 0, end_col = 0, hl_group = 'Normal', hl_eol = true, hl_mode = 'combine'}

local messageBuf
local unhandledMessageBuf
local messageWin
local unhandledMessageWin

local M = {}

function M.setup()
  messageBuf = api.nvim_create_buf(false, true)
  -- messageHistoryBuf = api.nvim_create_buf(false, true)
  unhandledMessageBuf = api.nvim_create_buf(false, true)
  messageWin = api.nvim_open_win(messageBuf, false, {
    relative = 'editor',
    row = vim.go.lines - 1,
    col = vim.o.columns,
    width = 60,
    height = 10,
    anchor = 'SE',
    border = 'rounded',
    hide = true,
    style = 'minimal',
  })
  vim.wo[messageWin].winblend = 25

  unhandledMessageWin = api.nvim_open_win(unhandledMessageBuf, false, {
    relative = 'editor',
    row = vim.go.lines - 13,
    col = vim.o.columns,
    width = 60,
    height = 14,
    anchor = 'SE',
    border = 'rounded',
    title_pos = 'center',
    title = ' unhandled messages ',
    hide = true,
    style = 'minimal',
  })
  vim.wo[unhandledMessageWin].winblend = 25
  vim.wo[unhandledMessageWin].number = true
end

function M.add(chunkSequences, title)
  api.nvim_win_set_config(messageWin, {hide = false, title_pos = title and 'center', title = title or ''})

  api.nvim_buf_clear_namespace(messageBuf, ns, 0, -1)
  api.nvim_buf_set_lines(messageBuf, 0, -1, true, {})

  local lines, highlights = composeLines(chunkSequences)

  api.nvim_buf_set_lines(messageBuf, 0, -1, true, lines)
  for _, highlight in ipairs(highlights) do
    extmarkOpts.end_row, extmarkOpts.end_col, extmarkOpts.hl_group = highlight[1], highlight[3], highlight[4]
    api.nvim_buf_set_extmark(messageBuf, ns, highlight[1], highlight[2], extmarkOpts)
  end

  return 1
end

function M.debug(msg)
  api.nvim_win_set_config(unhandledMessageWin, {hide = false})
  api.nvim_buf_set_lines(unhandledMessageBuf, -1, -1, true, {msg})
end

return M
