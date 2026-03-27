local M = {}
local utils = require "claude-chat.utils"

function M.get_context(has_range, line1, line2)
	local context = {
		filepath = vim.fn.expand "%:p",
		line_start = 0,
		line_end = 0,
	}

	if has_range > 0 and line1 and line2 and line1 > 0 and line2 > 0 then
		context.line_start = line1
		context.line_end = line2
	end

	return context
end

function M.format_prompt(context, user_input, has_range)
	local has_user_input = user_input and user_input ~= ""

	if not has_user_input then
		return ""
	end

	local prompt_parts = {}
	local filename = utils.get_relative_filepath()

	if has_range > 0 and context.line_start > 0 then
		if context.line_start == context.line_end then
			table.insert(
				prompt_parts,
				string.format("File: %s (line %d). ", filename, context.line_start)
			)
		else
			table.insert(
				prompt_parts,
				string.format(
					"File: %s (lines %d-%d). ",
					filename,
					context.line_start,
					context.line_end
				)
			)
		end
	else
		table.insert(prompt_parts, string.format("File: %s. ", filename))
	end

	if has_user_input then
		table.insert(prompt_parts, string.format("Query: %s", user_input))
	end

	return table.concat(prompt_parts, " ")
end

function M.format_selection_prompt(context)
	local filename = utils.get_relative_filepath()
	if context.line_start == context.line_end then
		return string.format("File: %s (line %d). ", filename, context.line_start)
	else
		return string.format(
			"File: %s (lines %d-%d). ",
			filename,
			context.line_start,
			context.line_end
		)
	end
end

return M
