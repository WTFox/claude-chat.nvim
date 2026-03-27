local M = {}

local config = require "claude-chat.config"
local state = require "claude-chat.state"
local context = require "claude-chat.context"
local window = require "claude-chat.window"

function M.setup(opts)
	config.setup(opts)

	vim.api.nvim_create_user_command("ClaudeChat", function(cmd_opts)
		if cmd_opts.args and cmd_opts.args ~= "" then
			M.ask_claude(cmd_opts.args, cmd_opts.range, cmd_opts.line1, cmd_opts.line2)
		else
			if state.is_session_active() then
				M.toggle_chat_window()
			else
				local ok, input = pcall(vim.fn.input, "Ask Claude: ")
				if not ok then
					return
				end
				M.ask_claude(input, cmd_opts.range, cmd_opts.line1, cmd_opts.line2)
			end
		end
	end, {
		nargs = "?",
		range = true,
		desc = "Ask Claude about the current file or selection",
	})
end

function M.ask_claude(user_input, has_range, line1, line2)
	-- Prevent multiple Claude instances
	if state.is_session_active() then
		if state.is_window_visible() then
			-- Already visible, just focus it
			vim.api.nvim_set_current_win(state.get().win)
		else
			-- Session exists but window hidden, restore it
			window.restore_chat_window()
		end
		return
	end

	local ctx = context.get_context(has_range, line1, line2)

	if #user_input == 0 and has_range == 0 then
		window.start_claude_terminal(nil)
		return
	end

	local prompt
	if #user_input == 0 and has_range > 0 and ctx.line_start > 0 then
		prompt = context.format_selection_prompt(ctx)
	else
		prompt = context.format_prompt(ctx, user_input, has_range)
	end

	window.start_claude_terminal(prompt)
end

function M.toggle_chat_window()
	if state.is_window_visible() then
		window.hide_chat_window()
	else
		window.restore_chat_window()
	end
end

function M.close_chat()
	local state_data = state.get()

	if state_data.win and vim.api.nvim_win_is_valid(state_data.win) then
		-- Try to close the window, catch the error if it's the last window
		local success, err = pcall(vim.api.nvim_win_close, state_data.win, true)
		if not success and err:match "E444" then
			-- This is the last window, we can't close it
			-- Create a new empty buffer to replace the Claude buffer
			local empty_buf = vim.api.nvim_create_buf(false, true)
			vim.api.nvim_win_set_buf(state_data.win, empty_buf)
		end
	end

	if state_data.job_id then
		vim.fn.jobstop(state_data.job_id)
	end

	state.cleanup_timer()
	state.restore_updatetime()
	state.reset()
end

function M.get_state()
	return state.get()
end

return M
