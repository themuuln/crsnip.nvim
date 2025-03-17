local M = {}

M.create_snippet = function(opts)
	local snippet_text = {}

	-- Get selected lines if range is provided
	if opts.line1 and opts.line2 then
		snippet_text = vim.api.nvim_buf_get_lines(0, opts.line1 - 1, opts.line2, false)
	end

	-- Get user input for snippet details
	local prefix = vim.fn.input("Snippet Prefix: ")
	local name = vim.fn.input("Snippet Name: ")
	local description = vim.fn.input("Snippet Description: ")

	-- Determine the language (current filetype or user choice)
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

	-- If no lines were selected, allow manual input
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

	-- Construct the snippet entry
	local snippet_entry = {
		prefix = prefix,
		name = name,
		description = description,
		body = snippet_text,
	}

	-- Get snippet storage location
	local config = require("nvim-snippets.config")
	local snippet_dir = config.options.snippet_dir
	os.execute("mkdir -p " .. snippet_dir)
	local file_path = snippet_dir .. "/" .. language .. ".json"

	-- Load existing snippets
	local snippets = {}
	local file = io.open(file_path, "r")
	if file then
		local content = file:read("*a")
		file:close()
		if content ~= "" then
			local ok, decoded = pcall(vim.fn.json_decode, content)
			if ok and type(decoded) == "table" then
				snippets = decoded
			else
				vim.api.nvim_err_writeln("Error decoding JSON, starting with a new snippet file.")
			end
		end
	end

	-- Add the new snippet
	table.insert(snippets, snippet_entry)

	-- Save to JSON file
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

-- Register the command
vim.api.nvim_create_user_command("CreateSnippet", function(opts)
	M.create_snippet(opts)
end, { range = true, nargs = 0 })

return M
