local Snippets = {}

Snippets.load = function()
	local config = require("crsnip.config")
	local snippet_dir = config.options.snippet_dir
	local language = vim.bo.filetype
	local file_path = snippet_dir .. "/" .. language .. ".json"

	local file = io.open(file_path, "r")
	if not file then
		vim.api.nvim_out_write("No snippets found for " .. language .. "\n")
		return
	end

	local content = file:read("*a")
	file:close()

	if content and content ~= "" then
		local ok, snippets = pcall(vim.fn.json_decode, content)
		if ok and type(snippets) == "table" then
			vim.api.nvim_out_write("Loaded " .. #snippets .. " snippets for " .. language .. "\n")
		else
			vim.api.nvim_err_writeln("Error loading snippets for " .. language)
		end
	end
end

return Snippets
