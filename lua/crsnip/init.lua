local config = require("crsnip.config")
config.setup() -- Set up with default options.

-- Load the snippet creator (this registers the :CreateSnippet command)
require("crsnip.creator")

-- You can add additional initialization here if needed.
return {}
