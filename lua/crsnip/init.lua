local M = {}

-- Module constants
local PLUGIN_NAME = "CRSnip"

-- Configuration with defaults
M.config = {
	options = {
		snippet_dir = vim.fn.stdpath("config") .. "/snippets",
		debug = false,
	},
}

-------------------
-- Debug Logging --
-------------------

local function log(msg, level)
	if not M.config.options.debug then
		return
	end
	level = level or "info"
	vim.notify("[" .. PLUGIN_NAME .. "] " .. msg, vim.log.levels[string.upper(level)])
end

-------------------
-- File Handling --
-------------------

-- Ensure directory exists
local function ensure_dir(dir)
	local stat = vim.loop.fs_stat(dir)
	if not stat then
		log("Creating directory: " .. dir, "info")
		vim.fn.mkdir(dir, "p")
	end
	return true
end

-- Read file contents
local function read_file(file_path)
	local file = io.open(file_path, "r")
	if not file then
		return nil
	end

	local content = file:read("*a")
	file:close()

	return content
end

-- Write to file
local function write_file(file_path, content)
	local file, err = io.open(file_path, "w")
	if not file then
		return false, "Error opening file for writing: " .. (err or "unknown error")
	end

	file:write(content)
	file:close()

	return true
end

-------------------
-- User Interface --
-------------------

-- Display a message to the user
local function notify_user(message_parts)
	vim.api.nvim_echo(message_parts, true, {})
end

-- Show an error message
local function show_error(message)
	vim.api.nvim_err_writeln("[" .. PLUGIN_NAME .. " Error] " .. message)
end

------------------------
-- Snippet Management --
------------------------

-- Format a snippet body for VSCode compatibility
local function format_snippet_body(lines)
	-- Handle empty input
	if not lines or #lines == 0 then
		return {}
	end

	-- For VSCode snippets, we need to keep the array format
	return lines
end

-- Load snippets from a file
local function load_snippets(file_path)
	local snippets = {}
	local content = read_file(file_path)

	if not content or content == "" then
		return snippets
	end

	local ok, decoded = pcall(function()
		return vim.json.decode(content)
	end)

	if not ok or type(decoded) ~= "table" then
		log("Failed to parse snippets file: " .. file_path, "warn")
		return snippets
	end

	return decoded
end

-- Save snippets to a file
local function save_snippets(file_path, snippets)
	-- Convert to proper VSCode snippet format if needed
	local vscode_snippets = {}

	for name, snippet in pairs(snippets) do
		vscode_snippets[name] = {
			prefix = snippet.prefix,
			body = snippet.body,
			description = snippet.description or "",
		}
	end

	-- Use vim.json.encode for better formatting
	local json_str
	local ok, result = pcall(function()
		return vim.json.encode(vscode_snippets)
	end)

	if ok then
		json_str = result
	else
		-- Fallback to basic json encoding
		json_str = vim.fn.json_encode(vscode_snippets)
	end

	-- Write to file
	local success, err = write_file(file_path, json_str)
	if not success then
		return false, err
	end

	return true
end

-----------------------
-- Snippet Creation  --
-----------------------

-- Determine language for snippet
local function determine_language()
	local filetype = vim.bo.filetype

	if filetype and filetype ~= "" then
		return filetype
	end

	-- Prompt user to select language
	local langs = { "typescript", "javascript", "dart", "lua", "python", "html", "css" }
	local choices = { "Select language:" }

	for i, lang in ipairs(langs) do
		table.insert(choices, i .. ". " .. lang)
	end

	local choice = vim.fn.inputlist(choices)
	if choice < 1 or choice > #langs then
		return nil, "Invalid language selection"
	end

	return langs[choice]
end

-- Get snippet information from user
local function get_snippet_info()
	local prefix = vim.fn.input("Snippet Prefix: ")
	if prefix == "" then
		return nil, "Snippet prefix cannot be empty"
	end

	local name = vim.fn.input("Snippet Name (default: " .. prefix .. "): ")
	if name == "" then
		name = prefix
	end

	local description = vim.fn.input("Snippet Description (optional): ")

	return {
		name = name,
		prefix = prefix,
		description = description,
	}
end

-- Get snippet body from selection or input
local function get_snippet_body(line1, line2)
	local lines = {}

	-- Get selected text if available
	if line1 and line2 and line1 <= line2 then
		lines = vim.api.nvim_buf_get_lines(0, line1 - 1, line2, false)
	end

	-- If no selection, prompt for input
	if #lines == 0 then
		vim.api.nvim_out_write("Enter snippet body (end with a line containing only '.')\n")

		while true do
			local line = vim.fn.input("> ")
			if line == "." then
				break
			end
			table.insert(lines, line)
		end
	end

	-- Validate
	if #lines == 0 then
		return nil, "Snippet body cannot be empty"
	end

	return lines
end

-----------------------
-- Public Functions  --
-----------------------

-- Create a new snippet
M.create_snippet = function(opts)
	opts = opts or {}

	-- Step 1: Get snippet body
	local body, body_err = get_snippet_body(opts.line1, opts.line2)
	if not body then
		show_error(body_err)
		return
	end

	-- Step 2: Get snippet info
	local info, info_err = get_snippet_info()
	if not info then
		show_error(info_err)
		return
	end

	-- Step 3: Determine language
	local language, lang_err = determine_language()
	if not language then
		show_error(lang_err)
		return
	end

	-- Step 4: Format snippet body
	local formatted_body = format_snippet_body(body)

	-- Step 5: Ensure snippet directory exists
	local snippet_dir = M.config.options.snippet_dir
	ensure_dir(snippet_dir)

	-- Step 6: Create snippet file path
	local file_path = snippet_dir .. "/" .. language .. ".json"

	-- Step 7: Load existing snippets
	local snippets = load_snippets(file_path)

	-- Step 8: Check if snippet already exists
	local existed = snippets[info.name] ~= nil

	-- Step 9: Add or update snippet
	snippets[info.name] = {
		prefix = info.prefix,
		body = formatted_body,
		description = info.description,
	}

	-- Step 10: Save snippets
	local success, err = save_snippets(file_path, snippets)
	if not success then
		show_error("Failed to save snippet: " .. err)
		return
	end

	-- Step 11: Notify user
	local action = existed and "updated" or "created"
	notify_user({
		{ "✅ Snippet ", "Normal" },
		{ info.name, "Special" },
		{ " " .. action .. " in ", "Normal" },
		{ file_path, "Directory" },
	})

	log("Snippet " .. info.name .. " " .. action .. " successfully", "info")
end

-- Plugin setup function
M.setup = function(opts)
	-- Merge user options with defaults
	M.config.options = vim.tbl_deep_extend("force", M.config.options, opts or {})

	-- Register plugin commands
	vim.api.nvim_create_user_command("CreateSnippet", function(cmd_opts)
		M.create_snippet({
			line1 = cmd_opts.line1,
			line2 = cmd_opts.line2,
		})
	end, {
		desc = "Create a new snippet",
		range = true,
	})

	vim.api.nvim_create_user_command("CRSnip", function(cmd_opts)
		M.create_snippet({
			line1 = cmd_opts.line1,
			line2 = cmd_opts.line2,
		})
	end, {
		desc = "Create a new snippet (alias)",
		range = true,
	})

	log("Plugin initialized with snippet_dir: " .. M.config.options.snippet_dir)
end

return M
