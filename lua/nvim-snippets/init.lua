local M = {}

M.setup = function(user_opts)
	local config = require("nvim-snippets.config")
	config.setup(user_opts) -- Apply user options (if any)

	require("nvim-snippets.snippets").load()
	require("nvim-snippets.creator") -- Ensure the command is registered
end

return M
