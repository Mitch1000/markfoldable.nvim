# anchorage.nvim
A simple Neovim plugin for marking folds as opened or closed.

![Anchorage](https://github.com/user-attachments/assets/6c6321cc-0d14-4bdf-9dca-976d36de2a75)

### Installation

#### Lazy



```lua
  {
    'kevinhwang91/nvim-ufo',
    dependencies = {
      'kevinhwang91/promise-async',
      'mitch1000/anchorage.nvim'
    },
    config = function ()
      vim.o.foldcolumn = '0' 
      vim.o.foldlevel = 99 

      require('ufo').setup({
        fold_virt_text_handler = require('anchorage.ufo_handler'),
      })
    end
  },
```
Note: This plugin is an extension of the amazing `kevinhwang91/nvim-ufo` plugin.

### Default Config

```lua
  require('anchorage').setup({
    opened_icon = '',
    closed_icon = '',
    anchor_color = "#5f5f5f",
    anchor_bg = nil,
    bold = false,
    italic = false,
    underline = false,
    undercurl = false,
  })
```



