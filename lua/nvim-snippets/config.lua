local Config = {}

Config.options = {
	snippet_dir = os.getenv("HOME") .. "/.config/nvim/snippets",
}

Config.setup = function(user_opts)
	if user_opts and type(user_opts) == "table" then
		Config.options = vim.tbl_extend("force", Config.options, user_opts)
	end
end

return Config
-- local Config = {}
--
-- -- Default configuration options
-- Config.options = {
-- 	snippet_dir = vim.fn.stdpath("config") .. "/snippets",
-- }
--
-- -- Setup function to allow user-defined config
-- Config.setup = function(user_opts)
-- 	if user_opts and type(user_opts) == "table" then
-- 		Config.options = vim.tbl_extend("force", Config.options, user_opts)
-- 	end
-- end
--
-- return Config
