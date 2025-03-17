local M = {}

M.create_snippet = function(opts)
	local snippet_text = {}
	if opts.line1 and opts.line2 then
		snippet_text = vim.api.nvim_buf_get_lines(0, opts.line1 - 1, opts.line2, false)
	end

	local prefix = vim.fn.input("Snippet Prefix: ")
	local name = vim.fn.input("Snippet Name: ")
	local description = vim.fn.input("Snippet Description: ")

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

	local config = require("crsnip.config")
	local snippet_dir = config.options.snippet_dir
	os.execute("mkdir -p " .. snippet_dir)
	local file_path = snippet_dir .. "/" .. language .. ".json"

	local snippets = {}
	local file = io.open(file_path, "r")
	if file then
		local content = file:read("*a")
		file:close()
		if content and content ~= "" then
			local ok, decoded = pcall(vim.fn.json_decode, content)
			if ok and type(decoded) == "table" then
				if decoded[1] then -- Array format (old)
					for _, snippet in ipairs(decoded) do
						if snippet.name then
							snippets[snippet.name] = {
								prefix = snippet.prefix,
								body = snippet.body,
								description = snippet.description,
							}
						end
					end
				else -- Object format (new)
					snippets = decoded
				end
			else
				vim.api.nvim_err_writeln("Error decoding JSON, starting a new snippet file.")
			end
		end
	end

	local existed = snippets[name] ~= nil
	snippets[name] = {
		prefix = prefix,
		body = snippet_text,
		description = description,
	}
	local action = existed and "overridden" or "added"

	local file_write, err = io.open(file_path, "w")
	if not file_write then
		vim.api.nvim_err_writeln("Error opening file for writing: " .. err)
		return
	end
	local json_snippets = vim.fn.json_encode(snippets)
	file_write:write(json_snippets)
	file_write:close()

	vim.api.nvim_out_write("✅ Snippet " .. action .. " to " .. file_path .. "\n")
end

return M
