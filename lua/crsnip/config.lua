local Config = {}

-- Default configuration: always use ~/.config/nvim/snippets
Config.options = {
	snippet_dir = os.getenv("HOME") .. "/.config/nvim/snippets",
}

-- Allow user override (if desired)
Config.setup = function(user_opts)
	if user_opts and type(user_opts) == "table" then
		Config.options = vim.tbl_extend("force", Config.options, user_opts)
	end
end

return Config
