## About

> [!WARNING]
> This is under active development and highly unstable. Breaking changes will occur without warning.

Zellij integration for [smart-splits.nvim](https://github.com/mrjones2014/smart-splits.nvim)

## Install

### Lazy package manager

```lua
{
  "smart-splits-nvim/smart-splits.nvim",
  branch = "v3",
  opts = {
    mux = {
      backend = "smart-splits-backend-zellij-lua",
    },
  },
  dependencies = {
    {
      "smart-splits-nvim/backend-zellij-lua",
      opts = {
        -- Add zellij specific configuration here
      },
    },
  },
}
```

## Configuration

### Default

> [!WARNING]
> **EXPERIMENTAL** configs are not stable and may break or be removed without warning.

```lua
opts = {
  -- General behavior when moving cursor.
  move_cursor = {
    pane_or_tab = false,            -- Go to the next tab when navigating to an edge.
  },

  -- Behavior when at_edge is 'split'
  split = {
    left = true,    -- Whether to create a split when navigating to this edge.
    right = true,
    up = true,
    down = true,
  }

  -- Behavior when zellij is in fullscreen
  fullscreen = {
    block_nav = false,          -- Block navigation if the current pane is fullscreen
  },
}
```

## Lua API

TODO...

## Contributing

See [CONTRIBUTING.md](./CONTRIBUTING.md) for documentation.
