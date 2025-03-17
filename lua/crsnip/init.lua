local config = require("crsnip.config")
config.setup() -- Use default options

-- Load snippets (optional)
pcall(require, "crsnip.snippets")

-- Register commands and snippet creator (this file simply ensures creator.lua runs)
require("crsnip.creator")

-- Return an empty table; all side effects have already occurred
return {}
