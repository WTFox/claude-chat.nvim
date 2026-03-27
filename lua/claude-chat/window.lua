local M = {}
local config = require "claude-chat.config"
local state = require "claude-chat.state"
local keymaps = require "claude-chat.keymaps"

function M.create_chat_window()
	local state_data = state.get()
	if state_data.win and vim.api.nvim_win_is_valid(state_data.win) then
		vim.api.nvim_set_current_win(state_data.win)
		return
	end

	local width = vim.o.columns
	local height = vim.o.lines
	local options = config.get()

	if options.split == "float" then
		M.create_float_window()
	elseif options.split == "vsplit" then
		local split_width = math.floor(width * options.width)
		if options.position == "right" then
			vim.cmd("botright " .. split_width .. "vsplit")
		else
			vim.cmd("topleft " .. split_width .. "vsplit")
		end
	else
		local split_height = math.floor(height * options.height)
		if options.position == "bottom" then
			vim.cmd("botright " .. split_height .. "split")
		else
			vim.cmd("topleft " .. split_height .. "split")
		end
	end

	local win = vim.api.nvim_get_current_win()
	state.get().win = win
end

function M.create_float_window()
	local width = vim.o.columns
	local height = vim.o.lines
	local options = config.get()

	local float_width = math.floor(width * options.width)
	local float_height = math.floor(height * options.height)
	local row = math.floor((height - float_height) / 2)
	local col = math.floor((width - float_width) / 2)

	local buf = vim.api.nvim_create_buf(false, true)

	local float_opts = vim.tbl_deep_extend("force", {
		relative = "editor",
		width = float_width,
		height = float_height,
		row = row,
		col = col,
		style = "minimal",
	}, options.float_opts or {})

	local win = vim.api.nvim_open_win(buf, true, float_opts)
	state.get().win = win
	state.get().buf = buf
end

function M.hide_chat_window()
	local state_data = state.get()
	if state_data.win and vim.api.nvim_win_is_valid(state_data.win) then
		-- Try to close the window, catch the error if it's the last window
		local success, err = pcall(vim.api.nvim_win_close, state_data.win, false)
		if not success and err:match "E444" then
			-- This is the last window, we can't close it
			-- Instead, just mark as hidden and leave window/buffer as-is
			-- The restore function will handle switching back to Claude buffer
			state.set_hidden(true)
			return
		end
		state.get().win = nil
		state.set_hidden(true)
	end
end

function M.restore_chat_window()
	local state_data = state.get()
	if not state_data.buf or not vim.api.nvim_buf_is_valid(state_data.buf) then
		return
	end

	-- If window exists but is showing a different buffer, reset window state
	if state_data.win and vim.api.nvim_win_is_valid(state_data.win) then
		if vim.api.nvim_win_get_buf(state_data.win) ~= state_data.buf then
			state.get().win = nil -- Reset so create_chat_window creates a new split
		end
	end

	local options = config.get()
	if options.split == "float" then
		local width = vim.o.columns
		local height = vim.o.lines
		local float_width = math.floor(width * options.width)
		local float_height = math.floor(height * options.height)
		local row = math.floor((height - float_height) / 2)
		local col = math.floor((width - float_width) / 2)
		local float_opts = vim.tbl_deep_extend("force", {
			relative = "editor",
			width = float_width,
			height = float_height,
			row = row,
			col = col,
			style = "minimal",
		}, options.float_opts or {})
		local win = vim.api.nvim_open_win(state_data.buf, true, float_opts)
		state.get().win = win
	else
		M.create_chat_window()
		local win = state.get().win
		vim.api.nvim_win_set_buf(win, state_data.buf)
	end

	state.set_hidden(false)
	vim.api.nvim_set_current_win(state.get().win)
	keymaps.setup_terminal_keymaps()
end

function M.setup_file_watcher()
	local state_data = state.get()
	if not state_data.original_buf or not vim.api.nvim_buf_is_valid(state_data.original_buf) then
		return
	end

	state.set_original_updatetime(vim.o.updatetime)
	vim.o.updatetime = 100
	vim.o.autoread = true

	local group = vim.api.nvim_create_augroup("ClaudeChatFileWatcher", { clear = true })
	vim.api.nvim_create_autocmd({ "CursorHold", "CursorHoldI", "FocusGained", "BufEnter" }, {
		group = group,
		callback = function()
			vim.cmd "checktime"
		end,
		desc = "Auto-reload file changes for Claude chat",
	})

	local timer = vim.loop.new_timer()
	timer:start(
		1000,
		1000,
		vim.schedule_wrap(function()
			if state_data.job_id and vim.api.nvim_buf_is_valid(state_data.original_buf) then
				vim.cmd "checktime"
			else
				if timer then
					timer:stop()
					timer:close()
					timer = nil
				end
			end
		end)
	)
	state.set_timer(timer)
end

function M.start_claude_terminal(prompt)
	local current_win = vim.api.nvim_get_current_win()
	local current_buf = vim.api.nvim_get_current_buf()
	state.set_original_context(current_win, current_buf)

	M.create_chat_window()

	local options = config.get()
	local cmd = options.claude_cmd
	if prompt and prompt ~= "" then
		cmd = cmd .. " " .. vim.fn.shellescape(prompt)
	end

	local buf, job_id, win
	if options.split == "float" then
		buf = state.get().buf
		win = state.get().win
		vim.api.nvim_buf_call(buf, function()
			vim.cmd("terminal " .. cmd)
		end)
		job_id = vim.api.nvim_buf_get_var(buf, "terminal_job_id")
	else
		vim.cmd("terminal " .. cmd)
		buf = vim.api.nvim_get_current_buf()
		job_id = vim.b.terminal_job_id
		win = vim.api.nvim_get_current_win()
	end

	state.set_terminal_info(buf, win, job_id)

	vim.bo[buf].bufhidden = "hide"
	vim.bo[buf].buflisted = false
	vim.wo[win].statusline = " "

	vim.cmd "stopinsert"

	keymaps.setup_terminal_keymaps()
	M.setup_file_watcher()
end

return M
