# CRSnip: Your Local Neovim Snippet Companion

A simple and straightforward Neovim plugin to create and manage your personal code snippets locally. `CRSnip` aims to provide an easy way to save frequently used code blocks directly from your editor, organized by filetype.

## Introduction

`CRSnip` offers a humble approach to snippet management within Neovim. It allows you to quickly capture code snippets from your current buffer (either through visual selection or manual input), assign them a prefix, name, and optional description, and then saves them in a structured JSON format. These snippets are stored locally within your Neovim configuration directory, making them easily accessible and manageable.

This plugin is designed for users who prefer a lightweight and self-contained solution for their snippet needs, without relying on external dependencies or complex configurations.

## Features

- **Effortless Snippet Creation:** Easily create new snippets from visually selected text or by manually entering the code.
- **Language-Specific Organization:** Snippets are stored in separate JSON files based on the detected (or selected) filetype, keeping your snippets organized.
- **Simple Configuration:** Minimal configuration options to adjust the snippet storage directory and enable debugging.
- **User-Friendly Commands:** Provides intuitive user commands (`:CreateSnippet` and `:CRSnip`) to initiate the snippet creation process.
- **Descriptive Snippets:** Add a name and optional description to your snippets for better identification and management.
- **Local Storage:** Snippets are stored locally within your Neovim configuration, giving you full control over your data.
- **Handles Existing Snippets:** When creating a snippet with an existing name, you'll be prompted whether to override it.

## Installation

Using a plugin manager is the recommended way to install `CRSnip`. Here are instructions for some popular options:

### lazy.nvim

Add the following to your `plugins` table:

```lua
{
  'YOUR_GITHUB_USERNAME/CRSnip',
  config = function()
    require('crsnip').setup()
  end
}
```

_(Replace `YOUR_GITHUB_USERNAME` with your actual username)_

Then, run `:Lazy sync` or restart Neovim.

### packer.nvim

Add the following to your `use` list:

```lua
use {
  'YOUR_GITHUB_USERNAME/CRSnip',
  config = function()
    require('crsnip').setup()
  end
}
```

_(Replace `YOUR_GITHUB_USERNAME` with your actual username)_

Then, run `:PackerSync` or restart Neovim.

### vim-plug

Add the following to your `~/.config/nvim/init.vim` or `~/.vimrc` file:

```vim
Plug 'YOUR_GITHUB_USERNAME/CRSnip'
```

_(Replace `YOUR_GITHUB_USERNAME` with your actual username)_

Then, run `:PlugInstall` or restart Neovim.

## Usage

`CRSnip` provides two commands to create snippets:

- **:CreateSnippet**: Use this command when you have visually selected the code you want to save as a snippet. The selected lines will be automatically used as the snippet body. You can invoke this by selecting text in visual mode and then typing `:CreateSnippet`.
- **:CRSnip**: Use this command when you haven't visually selected any text or want to manually input the snippet body. Upon running this command, you will be prompted to enter the snippet code line by line, finishing with a line containing only a single dot (`.`).

After invoking either command, you will be prompted for the following information:

1. **Snippet Prefix:** The text you'll type to trigger the snippet (e.g., `log`).
2. **Snippet Name:** A unique name for your snippet (defaults to the prefix if not provided). This helps in identifying and potentially overriding snippets later.
3. **Snippet Description:** An optional description to provide more context about the snippet.

If the filetype of the current buffer cannot be automatically determined, you will be prompted to select the language for the snippet.

Snippets are stored in JSON files within the directory specified in the configuration (default: `~/.config/nvim/snippets`). The filename will correspond to the language (e.g., `typescript.json`, `python.json`).

## Configuration

You can configure `CRSnip` by passing an optional table to the `setup` function in your Neovim configuration file (e.g., `init.lua`).

```lua
require('crsnip').setup({
  options = {
    snippet_dir = vim.fn.stdpath("config") .. "/my_custom_snippets", -- Custom snippet directory
    debug = true, -- Enable debug logging
  },
})
```

The available configuration options are:

- `snippet_dir`: The directory where snippet files will be stored. Defaults to `vim.fn.stdpath("config") .. "/snippets"`.
- `debug`: A boolean value to enable or disable debug logging. Debug messages will be displayed using `vim.notify`. Defaults to `false`.

## Contributing

While this plugin aims to be a personal tool, if you have suggestions or find any issues, feel free to open an issue on the GitHub repository.

## License

This plugin is released under the [MIT License](LICENSE) (replace with your actual license).

## Acknowledgements

This plugin was created with the intention of providing a simple local snippet solution for Neovim users.

---

Thank you for trying out `CRSnip`\! We hope it helps streamline your coding workflow.
