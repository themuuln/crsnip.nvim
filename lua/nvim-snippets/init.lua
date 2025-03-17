local M = {}

-- Automatically run setup when the plugin is loaded
local config = require("nvim-snippets.config")
config.setup() -- Load config

require("nvim-snippets.snippets").load() -- Load snippets
require("nvim-snippets.creator") -- Ensure commands are registered

return M -- ✅ Ensure this returns a valid module
