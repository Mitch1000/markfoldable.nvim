# anchorage.nvim
A simple Neovim plugin for marking folds as opened or closed.

![Anchorage](https://github.com/user-attachments/assets/6c6321cc-0d14-4bdf-9dca-976d36de2a75)

### Installation

#### Lazy

```lua
  {
    'mitch1000/anchorage.nvim',
  },
```

### Default Config

```lua
  {
    'mitch1000/anchorage.nvim',
    config = function()
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
    end
  },
```



