# dress.nvim

> Like `dressing.nvim`, but only `vim.ui.input`, with some fixes

[showcase](./img/showcase.mp4)

This plugin exists because of two reasons:

1. I don't need the other `dressing.nvim` features
2. Even if I got `vim.ui.input` from there, it doesn't work how I want it to

So, this plugin replaces `vim.ui.input` with a custom implementation, you saw how it looks like in the video showcase above.

Differently from `dressing.nvim`, you actually get access to normal mode! \
Pressing <kbd>Escape</kbd> in insert mode puts you in normal mode,
pressing <kbd>Escape</kbd> in normal mode cancels the operation.

In other words, to cancel your input from insert mode, you have to press <kbd>Escape</kbd> twice, kinda like in telescope.

Once you press <kbd>Enter</kbd> (in either normal or insert mode), you accept the input.

[semantics](./img/semantics.mp4)

## Install

With `lazy.nvim`:
```lua
---@type LazyPluginSpec
return {
    'Axlefublr/dress.nvim',
    ---@module "dress"
    ---@type DressOpts
    opts = {},
}
```

You should use the `opts` field to pass custom options to the plugin. \
`dress.nvim` can be lazy-loaded: it has to run its `setup` function right before a `vim.ui.input` gets called. \
How you achieve that, if you even care, is up to you; the plugin startup takes around 2ms for me.

If you wish to use this custom `vim.ui.input` in your own scripts, you can call these directly, which will load the plugin automatically:
```lua
require('dress').input()
require('dress').valid_input()
```

## Options

```lua
---@class DressOpts
---@field win_opts vim.api.keyset.win_config? `opts` for `:h nvim_open_win()`
---Width of the floating window will automatically adjust to fit the title (meaning `prompt`).
---This option lets you add *this many* spaces on each side of the prompt,
---to make it not squished with the borders.
---@field title_padding integer?
---@field inject boolean? Replace `vim.ui.input` (requires the setup call)

---@type DressOpts
local plugin_opts = { -- these are all defaults. if you like them, you can keep `opts = {}`
	win_opts = {
		relative = 'cursor',
		width = 30,
		height = 1,
		row = 1,
		col = 1,
		style = 'minimal',
		border = 'double',
	},
	-- Default is not 0 because with 0, the title looks squished (by the borders).
	-- Feel free to change it, though.
	title_padding = 1,
	-- Makes sense to set to `false` if you only want to use the plugin explicitly
	-- in your own configuration via `require('dress').input()`,
	-- and want to keep the default `vim.ui.input` everywhere else.
	inject = true,
}
```
