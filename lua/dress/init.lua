local m = {}

-- ══════════════════════════════════════════ plugin opts ═══════════════════════════════════════════

---@class DressOpts
---@field win_opts vim.api.keyset.win_config? `opts` for `:h nvim_open_win()`
---Width of the floating window will automatically adjust to fit the title (meaning `prompt`).
---This option lets you add *this many* spaces on each side of the prompt,
---to make it not squished with the borders.
---@field title_padding integer?
---@field inject boolean? Replace `vim.ui.input` (requires the setup call)

---@type DressOpts
local plugin_opts = {
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

---@param opts DressOpts?
function m.setup(opts)
	plugin_opts = vim.tbl_deep_extend('force', plugin_opts, opts or {})
	if plugin_opts.inject then
		vim.ui.input = m.input
	end
end

-- ───────────────────────────────────────────── helper ─────────────────────────────────────────────

---@return integer bufnr
local function make_unlisted_scratch_buffer() return vim.api.nvim_create_buf(false, true) end

---@param bufnr integer
local function get_buf_text(bufnr)
	local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
	return vim.fn.join(lines, '\n')
end

---@param bufnr integer
---@param text string|string[]
local function replace_buf_text(bufnr, text)
		if type(text) == 'string' then text = { text } end
	vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, text)
end

---@param bufnr integer
---@param title string?
local function make_window(bufnr, title)
	local win_opts = plugin_opts.win_opts
	---@cast win_opts -?
	local border_enabled = win_opts.border and win_opts.border ~= 'none'
	if border_enabled and title then
		local title = vim.trim(title)
		local padding = (' '):rep(plugin_opts.title_padding)
		win_opts.title = padding .. title .. padding
		win_opts.width = math.max(win_opts.width, #title + plugin_opts.title_padding * 2)
	else
		win_opts.title_pos = nil
	end
	return vim.api.nvim_open_win(bufnr, true, win_opts)
end

local function set_cursor_last_line(window)
	vim.api.nvim_win_set_cursor(window, { vim.fn.line('$', window), 0 })
end

---Makes a buffer-local mapping.
---@param mode string|string[]
---@param lhs string
---@param rhs string|function
---@param bufnr integer?
function bufmap(mode, lhs, rhs, bufnr)
	buffer = bufnr or true
	vim.keymap.set(mode, lhs, rhs, { buffer = buffer })
end

local function close_window(window)
	vim.api.nvim_win_close(window, false)
end

---@param closure fun(input: string?)
---@return function
local function accept(closure, bufnr, window)
	return function()
		local input = get_buf_text(bufnr)
		close_window(window)
		vim.cmd.stopinsert()
		closure(input)
	end
end

---@param closure fun(input: string?)
---@return function
local function disagree(closure, window)
	return function()
		close_window(window)
		vim.cmd.stopinsert()
		closure(nil)
	end
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ public ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

---See `:h vim.ui.input()`.
---@param opts { prompt: string?, default: string|string[]|nil }|string|nil TODO: `completion` and `highlight` are not supported. I have no usecase for them, so I can't bother; will happily accept a PR.
---If you pass `opts` as a string, it's assumed you mean `{ prompt = 'your_string' }`.
---@param on_confirm fun(input: string?) This function is going to be called once you save and close the buffer.
---It will be called even if you pressed escape (to follow the intent of the `vim.ui.input` api),
---so make sure to include `if not input then return end` checks, if needed.
---I wrote it this way, because some thingies that use `vim.ui.input` probably run some cleanup code
---on `nil`
function m.input(opts, on_confirm)
	local default = nil
	local prompt = nil
	if type(opts) == 'string' then
		prompt = opts
	else
		local opts = opts or {}
		default = opts.default
		prompt = opts.prompt
	end

	local bufnr = make_unlisted_scratch_buffer()

	if default then
		replace_buf_text(bufnr, default)
	end

	local window = make_window(bufnr, prompt)

	set_cursor_last_line(window)
	vim.cmd('startinsert!')

	bufmap({ 'n', 'i' }, '<CR>', accept(on_confirm, bufnr, window), bufnr)
	bufmap('n', '<Esc>', disagree(on_confirm, window), bufnr)
end

-- ╔═════════════════════════════════════════════════════════════════════════════════╗
-- ║ I copy paste the function documentation so that you can use `valid_input`       ║
-- ║ with correct lsp documentation hints, without having to cross-reference `input` ║
-- ╚═════════════════════════════════════════════════════════════════════════════════╝

---See `:h vim.ui.input()`.
---@param opts { prompt: string?, default: string|string[]|nil }|string|nil TODO: `completion` and `highlight` are not supported. I have no usecase for them, so I can't bother; will happily accept a PR.
---If you pass `opts` as a string, it's assumed you mean `{ prompt = 'your_string' }`.
---@param on_confirm fun(input: string?) This function is going to be called once you save and close the buffer.
---It will be called even if you pressed escape (to follow the intent of the `vim.ui.input` api),
---so make sure to include `if not input then return end` checks, if needed.
---I wrote it this way, because some thingies that use `vim.ui.input` probably run some cleanup code
---on `nil`
function m.valid_input(opts, on_confirm)
	local function if_accepted(input)
		if not input then return end
		on_confirm(input)
	end
	m.input(opts, if_accepted)
end

return m
