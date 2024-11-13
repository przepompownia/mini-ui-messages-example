# mini-ui-messages-example
Playground for making use of Nvim UI messages redirection, especially with [mini-notify](https://github.com/echasnovski/mini.notify) ([modified for these needs](https://github.com/przepompownia/mini.notify/tree/ui-messages)). Requires Neovim at least on [neovim/neovim@72a1df60652f20f5f47bf120ee0bc08466837f31](https://github.com/neovim/neovim/commit/72a1df60652f20f5f47bf120ee0bc08466837f31)

## start
- example with plugin: in particular it will install `mini.notify` in this project subdirectory
```sh
nvim -u init.lua init.lua
```
- minimal:
```sh
nvim -u minimal.lua init.lua
```

## examples with mini.notify
```lua
vim.api.nvim_echo({ {'Error ', 'ErrorMsg'}, {'Warning\n', 'WarningMsg'}, {'Added ', 'DiffAdd'}, {'Changed', 'DiffChange'} }, false, {})
```
![nvim_echo](assets/nvim-echo.png)
```vim
:Inspect
```
![inspect](assets/inspect.png)

## todo
### `ext_messages`
- missing `redraw()` for `:=1` output
- replace search count messages instead of displaying separate notifications
- probably fix lots other issues
