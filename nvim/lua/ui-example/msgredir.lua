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

local debugMessage = function (content)
  error('Not configured yet')
end

local bufferedContents = {}
local msgids = {}

local previous = ''

local function handleUiMessages(event, kind, content, replace)
  -- local dm = ('ev: %s, k: %s, r: %s, c: %s, bid: %s'):format(event, vim.inspect(kind), replace, vim.inspect(content), msgids['buffered'])
  -- if dm ~= previous then
  --   debugMessage(dm)
  --   previous = dm
  -- end
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
  if event == 'msg_clear' and kind == nil then
    bufferedContents = {}
    msgids['buffered'] = nil
  elseif event == 'msg_show' then
    -- if #content == 1 and content[1][2] == '\n' then
    --   return
    -- end
    if kind == 'return_prompt' then
      api.nvim_input('\r')
    elseif
      kind == 'emsg'
      or kind == 'echo'
      or kind == 'echoerr'
      or kind == 'echomsg'
      or kind == 'lua_error'
    then
      addChMessage({content})
    elseif kind == '' then -- :={x = 1, y = 1} and search
      bufferedContents[#bufferedContents + 1] = content
      if replace and msgids['buffered'] then
        updateChMessage(msgids['buffered'], bufferedContents)
      else
        msgids['buffered'] = addChMessage(bufferedContents)
      end
    elseif kind == 'search_count' then
      bufferedContents = {}
      if replace and msgids['buffered'] then
        updateChMessage(msgids['buffered'], {content})
      else
        msgids['buffered'] = addChMessage({content})
      end
    end
  else
    debugMessage(('ev: %s, k: %s, r: %s'):format(event, vim.inspect(kind), replace))
    debugMessage(vim.inspect(content))
  end
end

local M = {}

local redirect = true

local function attach()
  if not redirect then
    return
  end
  vim.ui_attach(ns, {ext_messages = true, ext_cmdline = false}, handleUiMessages)
  -- vim.ui_attach(ns, {ext_messages = true, ext_cmdline = false}, vim.schedule_wrap(handleUiMessages))
  -- It causes waiting for <CR> input but debugging
end

local function detach()
  vim.ui_detach(ns)
  vim.schedule(function ()
    api.nvim__redraw({statusline = true})
  end)
end

api.nvim_create_user_command('MsgRedirToggle', function ()
  redirect = not redirect
  if not redirect then
    detach()
  end
end, {nargs = 0})

function M.init(addMsgCb, updateMsgCb, debugMsgCb)
  if addChMessage then
    addChMessage = addMsgCb
  end
  if updateChMessage then
    updateChMessage = updateMsgCb
  end
  if debugMsgCb then
    debugMessage = debugMsgCb
  end

  api.nvim_create_autocmd('CmdlineEnter', {callback = detach})
  api.nvim_create_autocmd({'UIEnter', 'CmdlineLeave'}, {callback = attach})
end

return M
