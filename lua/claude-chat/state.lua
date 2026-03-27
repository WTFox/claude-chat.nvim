local M = {}

local state = {
	buf = nil,
	win = nil,
	job_id = nil,
	original_win = nil,
	original_buf = nil,
	timer = nil,
	original_updatetime = nil,
	hidden = false,
}

function M.get()
	return state
end

function M.reset()
	state.win = nil
	state.buf = nil
	state.job_id = nil
	state.original_win = nil
	state.original_buf = nil
	state.hidden = false
	state.timer = nil
	state.original_updatetime = nil
end

function M.set_terminal_info(buf, win, job_id)
	state.buf = buf
	state.win = win
	state.job_id = job_id
end

function M.set_original_context(win, buf)
	state.original_win = win
	state.original_buf = buf
end

function M.set_timer(timer)
	state.timer = timer
end

function M.set_original_updatetime(updatetime)
	state.original_updatetime = updatetime
end

function M.cleanup_timer()
	if state.timer then
		state.timer:stop()
		state.timer:close()
		state.timer = nil
	end
end

function M.restore_updatetime()
	if state.original_updatetime then
		vim.o.updatetime = state.original_updatetime
		state.original_updatetime = nil
	end
end

function M.is_session_active()
	return state.job_id ~= nil and state.buf ~= nil and vim.api.nvim_buf_is_valid(state.buf)
end

function M.is_window_visible()
	return state.win ~= nil
		and vim.api.nvim_win_is_valid(state.win)
		and not state.hidden
		and state.buf ~= nil
		and vim.api.nvim_buf_is_valid(state.buf)
		and vim.api.nvim_win_get_buf(state.win) == state.buf
end

function M.set_hidden(hidden)
	state.hidden = hidden
end

return M
