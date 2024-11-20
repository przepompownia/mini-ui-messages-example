# mini-ui-messages-example
Playground for making use of Nvim UI messages redirection. Requires Neovim at least on https://github.com/neovim/neovim/commit/f111c32ff9

## start
```sh
nvim -u init.lua init.lua
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
### nvim
- wait for https://github.com/neovim/neovim/issues/31244
- wait for https://github.com/neovim/neovim/issues/31248
### mini
- update doesn't affect history
### redirection
- handle `:messages` and `:message clear`
