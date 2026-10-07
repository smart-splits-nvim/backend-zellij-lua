## About

Zellij integration for [smart-splits.nvim](https://github.com/mrjones2014/smart-splits.nvim).

This project is currently being rewritten in rust [here](https://github.com/smart-splits-nvim/backend-zellij-rs), and it is therefore considered feature complete.
Users can expect bugs to be fixed, but not new features to be implemented.

## Install

### Lazy package manager

```lua
{
  "smart-splits-nvim/smart-splits.nvim",
  version = '^3.0.0',
  lazy = false,
  dependencies = {
    {
      "smart-splits-nvim/backend-zellij-lua",
      main = "smart-splits-backend-zellij-lua",
      opts = {
        -- Add zellij specific configuration here
      },
    },
  },
  opts = {
    mux = { backend = "smart-splits-backend-zellij-lua" },
    -- Add smart splits core configuration here
  },
}
```

## Configuration

### Default

```lua
opts = {
  -- General behavior when moving cursor.
  move_cursor = {
    pane_or_tab = false,    -- Go to the next tab when navigating to an edge.
  },

  -- Behavior when at_edge is 'split'
  split = {
    left = true,            -- Whether to create a split when navigating to this edge.
    right = true,
    up = true,
    down = true,
  }

  -- Behavior when zellij is in fullscreen
  fullscreen = {
    block_nav = false,      -- Block navigation if the current pane is fullscreen
  },
}
```

## Troubleshooting

Check health of plugin:

```
:checkhealth smart-splits
```

## Contributing

Pull requests that add new features will be rejected.

Bug fixes are welcome as long as they don't rock the boat too much.

See [CONTRIBUTING.md](./CONTRIBUTING.md) for technical documentation.
