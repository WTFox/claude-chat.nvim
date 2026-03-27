local M = {}

---@type claude-chat.Config
M.defaults = {
	split = "vsplit",
	position = "right", --ignored for float
	width = 0.4, -- percentage of screen width (for vsplit or float)
	height = 0.8, -- percentage of screen height (for split or float)
	claude_cmd = "claude", -- command to invoke Claude Code
	float_opts = {
		relative = "editor",
		border = "rounded",
		title = " Claude Chat ",
		title_pos = "center",
	},
	keymaps = {
		global = nil, -- Global keymap for ClaudeChat command (nil = no default, set in your config)
		terminal = {
			close = "<C-q>", -- Close chat from terminal mode
			toggle = "<C-q>", -- Toggle chat window visibility
			normal_mode = "<Esc><Esc>", -- Exit terminal mode to normal mode
			insert_file = "<C-f>", -- Insert current file path
			interrupt = "<C-c>", -- Interrupt/close chat
		},
	},
}

M.options = {}

function M.setup(opts)
	M.options = vim.tbl_deep_extend("force", M.defaults, opts or {})
end

function M.get()
	return M.options
end

return M
