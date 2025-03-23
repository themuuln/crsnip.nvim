# crsnip.nvim

CRSnip is a Neovim plugin for managing and creating code snippets with ease. It allows users to define snippets in JSON format and provides commands for quick snippet creation.

Features
• Snippet Management: Read, write, and update snippets per language.
• Auto-Detect Language: Determines the snippet file based on the current buffer.
• Visual Selection Support: Create snippets from selected text in visual mode.
• Interactive Input: Prompts the user for snippet details when needed.
• Configurable Storage: Snippets are saved in a configurable directory.

Installation

Using lazy.nvim

{
"your_username/CRSnip",
config = function()
require("CRSnip").setup({
options = {
snippet_dir = vim.fn.stdpath("config") .. "/snippets", -- Customize snippet storage
debug = false, -- Enable debug logs
},
})
end,
}

Using packer.nvim

use {
"your_username/CRSnip",
config = function()
require("CRSnip").setup({
options = {
snippet_dir = vim.fn.stdpath("config") .. "/snippets",
debug = false,
},
})
end
}

Using vim-plug

Plug 'your_username/CRSnip'

lua << EOF
require("CRSnip").setup({
options = {
snippet_dir = vim.fn.stdpath("config") .. "/snippets",
debug = false,
},
})
EOF

Usage

Create a Snippet

1. Using Visual Selection
   • Select the desired code.
   • Run:

:CreateSnippet

    • Follow the prompts to provide a prefix, name, and description.

2. Manually Creating a Snippet
   • Run:

:CreateSnippet

    • Enter the snippet details interactively.

Configuration

You can configure CRSnip by passing options to the setup function:

require("CRSnip").setup({
options = {
snippet_dir = vim.fn.stdpath("config") .. "/snippets",
debug = true, -- Enable debug logging
},
})

Available Options

Option Type Default Description
snippet_dir string "~/.config/nvim/snippets" Directory to store snippets.
debug boolean false Enables debug logging.

Commands

Command Description
:CreateSnippet Creates a new snippet interactively.
:CRSnip Alias for :CreateSnippet.

Snippet Format

Snippets are stored as JSON files per language. Example:

~/.config/nvim/snippets/javascript.json

{
"consoleLog": {
"prefix": "clg",
"body": ["console.log($1);"],
"description": "Log output to console"
}
}

License

MIT License

Contributing

Feel free to open issues or submit pull requests!
