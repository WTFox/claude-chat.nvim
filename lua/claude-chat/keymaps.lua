local M = {}
local state = require "claude-chat.state"
local utils = require "claude-chat.utils"
local config = require "claude-chat.config"

function M.setup_terminal_keymaps()
	local state_data = state.get()
	local buf = state_data.buf
	if not buf then
		return
	end

	local options = config.get()
	local keymaps = options.keymaps.terminal

	vim.api.nvim_buf_set_keymap(buf, "n", "q", "", {
		callback = function()
			require("claude-chat").close_chat()
		end,
		noremap = true,
		silent = true,
		desc = "Close Claude chat",
	})

	vim.api.nvim_buf_set_keymap(buf, "n", "i", "i", {
		noremap = true,
		silent = true,
		desc = "Enter insert mode to send message",
	})

	vim.api.nvim_buf_set_keymap(buf, "n", "a", "A", {
		noremap = true,
		silent = true,
		desc = "Enter insert mode at end of line",
	})

	-- Terminal mode keymaps (work from terminal insert mode)
	vim.api.nvim_buf_set_keymap(buf, "t", keymaps.interrupt, "", {
		callback = function()
			require("claude-chat").close_chat()
		end,
		noremap = true,
		silent = true,
		desc = "Close Claude chat",
	})

	-- Quick close alternative from terminal mode
	vim.api.nvim_buf_set_keymap(buf, "t", keymaps.close, "", {
		callback = function()
			require("claude-chat").close_chat()
		end,
		noremap = true,
		silent = true,
		desc = "Close Claude chat",
	})

	-- Toggle window visibility from terminal mode
	vim.api.nvim_buf_set_keymap(buf, "t", keymaps.toggle, "", {
		callback = function()
			require("claude-chat").toggle_chat_window()
		end,
		noremap = true,
		silent = true,
		desc = "Toggle Claude chat window",
	})

	vim.api.nvim_buf_set_keymap(buf, "t", keymaps.insert_file, "", {
		callback = function()
			if not state_data.job_id then
				return
			end
			local original_win = nil
			for _, win in ipairs(vim.api.nvim_list_wins()) do
				if win ~= state_data.win then
					local buf_id = vim.api.nvim_win_get_buf(win)
					if vim.bo[buf_id].buftype == "" then
						original_win = win
						break
					end
				end
			end
			if original_win then
				vim.api.nvim_set_current_win(original_win)
				local filepath = utils.get_relative_filepath()
				if filepath ~= "" then
					filepath = "File: " .. filepath .. " "
					vim.api.nvim_set_current_win(state_data.win)
					vim.fn.chansend(state_data.job_id, filepath)
				end
			end
		end,
		noremap = true,
		silent = true,
		desc = "Insert current buffer filepath",
	})

	-- More intuitive normal mode exit
	vim.api.nvim_buf_set_keymap(buf, "t", keymaps.normal_mode, "<C-\\><C-N>", {
		noremap = true,
		silent = true,
		desc = "Exit terminal insert mode",
	})

	-- Keep the original for users who prefer it
	vim.api.nvim_buf_set_keymap(buf, "t", "<C-\\><C-N>", "<C-\\><C-N>", {
		noremap = true,
		silent = true,
		desc = "Exit terminal insert mode",
	})

	-- Apply terminal window appearance immediately (TermOpen has already fired)
	local win = state_data.win
	if win and vim.api.nvim_win_is_valid(win) then
		vim.wo[win].number = false
		vim.wo[win].relativenumber = false
		vim.wo[win].signcolumn = "no"
	end

	-- Set up auto-commands for better UX
	M.setup_terminal_autocmds(buf)
end

function M.setup_terminal_autocmds(buf)
	-- Auto-enter insert mode when clicking or focusing the terminal
	vim.api.nvim_create_autocmd({ "BufEnter", "WinEnter" }, {
		buffer = buf,
		callback = function()
			-- Only auto-enter insert mode if we're in normal mode in a terminal buffer
			if vim.bo[buf].buftype == "terminal" and vim.fn.mode() == "n" then
				vim.schedule(function()
					if vim.api.nvim_buf_is_valid(buf) and vim.api.nvim_get_current_buf() == buf then
						vim.cmd "startinsert"
					end
				end)
			end
		end,
		desc = "Auto-enter insert mode in Claude terminal",
	})
end

return M
