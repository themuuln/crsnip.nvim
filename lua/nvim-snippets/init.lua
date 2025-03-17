local M = {}

M.setup = function(user_opts)
	local config = require("nvim-snippets.config")
	config.setup(user_opts)
	require("nvim-snippets.snippets").load()
end

M.create_snippet = require("nvim-snippets.creator").create_snippet

return M
