local config = require("crsnip.config")
config.setup() -- Use default configuration options

-- Optionally load other components:
pcall(require, "crsnip.snippets")

-- Register snippet creator and its command.
require("crsnip.creator")

return {}
