local M = {}

M.create_snippet = function(opts)
	local snippet_text = {}

	-- If a range is given, use selected lines as the snippet body.
	if opts.line1 and opts.line2 then
		snippet_text = vim.api.nvim_buf_get_lines(0, opts.line1 - 1, opts.line2, false)
	end

	-- Ask the user for snippet metadata.
	local prefix = vim.fn.input("Snippet Prefix: ")
	local name = vim.fn.input("Snippet Name: ")
	local description = vim.fn.input("Snippet Description: ")

	-- Determine language from current filetype or ask user.
	local language = vim.bo.filetype
	if not language or language == "" then
		local langs = { "typescript", "javascript", "dart" }
		local choice = vim.fn.inputlist({
			"Select language:",
			"1. typescript",
			"2. javascript",
			"3. dart",
		})
		if choice < 1 or choice > #langs then
			vim.api.nvim_err_writeln("Invalid language choice!")
			return
		end
		language = langs[choice]
	end

	-- If no snippet body exists from selection, get manual input.
	if #snippet_text == 0 then
		vim.api.nvim_out_write("Enter snippet code, finish input with a line containing only '.'\n")
		while true do
			local line = vim.fn.input("")
			if line == "." then
				break
			end
			table.insert(snippet_text, line)
		end
	end

	-- Build the snippet entry.
	local snippet_entry = {
		prefix = prefix,
		name = name,
		description = description,
		body = snippet_text,
	}

	-- Get the snippet directory from config.
	local config = require("crsnip.config")
	local snippet_dir = config.options.snippet_dir

	-- Ensure the directory exists.
	os.execute("mkdir -p " .. snippet_dir)

	local file_path = snippet_dir .. "/" .. language .. ".json"

	-- Load existing snippets if any.
	local snippets = {}
	local file = io.open(file_path, "r")
	if file then
		local content = file:read("*a")
		file:close()
		if content and content ~= "" then
			local ok, decoded = pcall(vim.fn.json_decode, content)
			if ok and type(decoded) == "table" then
				snippets = decoded
			else
				vim.api.nvim_err_writeln("Error decoding JSON, starting a new snippet file.")
			end
		end
	end

	-- Add the new snippet.
	table.insert(snippets, snippet_entry)

	-- Save updated snippets back to the file.
	local file_write, err = io.open(file_path, "w")
	if not file_write then
		vim.api.nvim_err_writeln("Error opening file for writing: " .. err)
		return
	end

	local json_snippets = vim.fn.json_encode(snippets)
	file_write:write(json_snippets)
	file_write:close()

	vim.api.nvim_out_write("✅ Snippet saved to " .. file_path .. "\n")
end

-- Register the CreateSnippet command immediately.
vim.api.nvim_create_user_command("CreateSnippet", function(opts)
	M.create_snippet(opts)
end, { range = true, nargs = 0 })

return M
