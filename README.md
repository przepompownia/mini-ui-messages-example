# mini-ui-messages-example
Playground for making use of Nvim UI messages redirection. Requires Neovim at least on https://github.com/neovim/neovim/commit/1b6442034f6a821d357fe59cd75fdae47a7f7cff

## start
```sh
nvim -u init.lua init.lua
```

## examples
```lua
vim.api.nvim_echo({ {'Error ', 'ErrorMsg'}, {'Warning\n', 'WarningMsg'}, {'Added ', 'DiffAdd'}, {'Changed', 'DiffChange'} }, false, {})
```
![nvim_echo](assets/nvim-echo.png)
```vim
:Inspect
```
![inspect](assets/inspect.png)

## todo
### redirection
- handle `:messages` and `:message clear`
### notifier
- allow pause/recreate deletion timers
- transparent background
- right padding
- test message kinds added in https://github.com/neovim/neovim/pull/31279
- squash adjacent duplicates
