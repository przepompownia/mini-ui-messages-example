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

local function displayChunkedMessage(chunkSequences, buf)
  vim.api.nvim_buf_clear_namespace(buf, ns, 0, -1)
  vim.api.nvim_buf_set_lines(buf, 0, -1, true, {})

  local lines, highlights = composeLines(chunkSequences)

  api.nvim_buf_set_lines(buf, 0, -1, true, lines)
  for _, highlight in ipairs(highlights) do
    extmarkOpts.end_row, extmarkOpts.end_col, extmarkOpts.hl_group = highlight[1], highlight[3], highlight[4]
    api.nvim_buf_set_extmark(buf, ns, highlight[1], highlight[2], extmarkOpts)
  end
end

local function displayString(content, buf)
  vim.api.nvim_buf_set_lines(buf, -1, -1, true, {content})
end

local function redraw()
  vim.schedule(function ()
    vim.cmd.redraw()
  end)
end
api.nvim_create_autocmd('CmdlineEnter', {
  callback = function ()
    vim.ui_detach(ns)
    redraw()
  end
})

local messageBuf = api.nvim_create_buf(false, true)
-- local messageHistoryBuf = api.nvim_create_buf(false, true)
local unhandledMessageBuf = api.nvim_create_buf(false, true)
local messageWin = api.nvim_open_win(messageBuf, false, {
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

local unhandledMessageWin = api.nvim_open_win(unhandledMessageBuf, false, {
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
        displayChunkedMessage({content}, messageBuf)
        api.nvim_win_set_config(messageWin, {hide = false, title_pos = 'center', title = (' %s '):format(kind)})
      elseif event == 'msg_show' and kind == '' then -- :={x = 1, y = 1}
        bufferedContents[#bufferedContents + 1] = content
      elseif event == 'msg_clear' and kind == nil then
        displayChunkedMessage(bufferedContents, messageBuf)
        api.nvim_win_set_config(messageWin, {hide = false})
        bufferedContents = {}
      elseif event == 'msg_show' and kind == 'return_prompt' then
        api.nvim_input('\r')
      elseif event == 'msg_show' and kind == 'search_count' then
        displayChunkedMessage(content, messageBuf)
      else
        api.nvim_win_set_config(unhandledMessageWin, {hide = false})
        displayString(('ev: %s'):format(event), unhandledMessageBuf)
        displayString(('k: %s'):format(vim.inspect(kind)), unhandledMessageBuf)
        displayString(('r: %s'):format(vim.inspect(replace_last)), unhandledMessageBuf)
        displayString(vim.inspect(content), unhandledMessageBuf)
      end
      redraw()
    end)
  end
})
