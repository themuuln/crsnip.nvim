local Snippets = {}

Snippets.load = function()
	local home = os.getenv("HOME")
	local snippet_dir = home .. "/.config/nvim/snippets/"
	local language = vim.bo.filetype
	local file_path = snippet_dir .. language .. ".json"

	local file = io.open(file_path, "r")
	if not file then
		vim.api.nvim_out_write("No snippets found for " .. language .. "\n")
		return
	end

	local content = file:read("*a")
	file:close()

	if content ~= "" then
		local ok, snippets = pcall(vim.fn.json_decode, content)
		if ok and type(snippets) == "table" then
			vim.api.nvim_out_write("Loaded " .. #snippets .. " snippets for " .. language .. "\n")
		else
			vim.api.nvim_err_writeln("Error loading snippets for " .. language)
		end
	end
end

return Snippets
