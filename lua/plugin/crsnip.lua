local crsnip = require("crsnip")
vim.api.nvim_create_user_command("CreateSnippet", function(opts)
	crsnip.create_snippet(opts)
end, { range = true, nargs = 0 })
