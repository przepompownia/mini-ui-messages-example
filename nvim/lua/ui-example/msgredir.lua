local api = vim.api
local ns = api.nvim_create_namespace('messageRedirection')

--- @param content [integer, string, integer][][]
--- @param title string?
--- @return integer message ID
local addChMessage = function (content, title)
  error('Not configured yet')
end

--- @param content [integer, string, integer][][]
--- @param title string?
local updateChMessage = function (msgId, content, title)
  error('Not configured yet')
end

local bufferedContents = {}

local function handleUiMessages(event, kind, content, replace)
  if
    event == 'cmdline_hide'
    or event == 'cmdline_show'
    or event == 'grid_destroy'
    or event == 'msg_history_clear'
    or event == 'msg_history_show'
    or event == 'msg_ruler'
    or event == 'msg_showcmd'
    or event == 'msg_showmode'
  then
    return
  end
  -- debug(('ev: %s, k: %s, r: %s, buffered: %s'):format(event, vim.inspect(kind), replace, vim.inspect(bufferedContents)))
  if
    event == 'msg_show'
    and (
      kind == 'emsg'
      or kind == 'echo'
      or kind == 'echoerr'
      or kind == 'echomsg'
      or kind == 'lua_error'
    ) then
    addChMessage({content})
  elseif event == 'msg_show' and kind == '' then         -- :={x = 1, y = 1}
    bufferedContents[#bufferedContents + 1] = content
    addChMessage(bufferedContents)
  elseif event == 'msg_clear' and kind == nil then
    bufferedContents = {}
  elseif event == 'msg_show' and kind == 'return_prompt' then
    api.nvim_input('\r')
  elseif event == 'msg_show' and kind == 'search_count' then
    addChMessage(content)
  else
    debug(('ev: %s, k: %s, r: %s'):format(event, vim.inspect(kind), replace))
    debug(vim.inspect(content))
  end

  -- todo
  -- `:hi` from keymap
  -- updateMsg
end

local M = {}

function M.init(addMsgCb, updateMsgCb)
  addChMessage = addMsgCb
  updateChMessage = updateMsgCb

  api.nvim_create_autocmd('CmdlineEnter', {
    callback = function ()
      vim.ui_detach(ns)
      vim.schedule(function ()
        api.nvim__redraw({statusline = true})
      end)
    end
  })

  api.nvim_create_autocmd({'UIEnter', 'CmdlineLeave'}, {
    callback = function ()
      vim.ui_attach(ns, {ext_messages = true, ext_cmdline = false}, handleUiMessages)
    end
  })
end

return M
