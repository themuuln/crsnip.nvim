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

-----------------------
-- Utility Functions --
-----------------------

-- Logger utility
local function log(msg, level)
	if not M.config.options.debug then
		return
	end
	level = level or "info"
	vim.notify("[" .. PLUGIN_NAME .. "] " .. msg, vim.log.levels[string.upper(level)])
end

-- Ensure directory exists
local function ensure_dir(dir)
	local stat = vim.loop.fs_stat(dir)
	if not stat then
		log("Creating directory: " .. dir, "info")
		vim.fn.mkdir(dir, "p")
	end
	return true
end

-- Display a formatted message to the user
local function notify_user(message_parts)
	vim.api.nvim_echo(message_parts, true, {})
end

-- Show an error message to the user
local function show_error(message)
	vim.api.nvim_err_writeln(message)
end

-----------------------
-- Snippet Handling  --
-----------------------

-- Read existing snippets from file
local function read_snippets(file_path)
	local snippets = {}
	local file = io.open(file_path, "r")

	if not file then
		return snippets
	end

	local content = file:read("*a")
	file:close()

	if not content or content == "" then
		return snippets
	end

	local ok, decoded = pcall(vim.fn.json_decode, content)
	if not ok or type(decoded) ~= "table" then
		log("Error decoding JSON, starting a new snippet file.", "warn")
		return snippets
	end

	-- Handle old array-based snippet files
	if vim.tbl_islist(decoded) then
		for _, snippet in ipairs(decoded) do
			if snippet.name then
				snippets[snippet.name] = {
					prefix = snippet.prefix,
					body = snippet.body,
					description = snippet.description,
				}
			end
		end
	else
		snippets = decoded
	end

	return snippets
end

-- Write snippets to file
local function write_snippets(file_path, snippets)
	local file, err = io.open(file_path, "w")
	if not file then
		return false, "Error opening file for writing: " .. (err or "unknown error")
	end

	-- Use vim.json.encode with proper indentation for better formatting
	-- and compatibility with most snippet parsers
	local ok, raw_json = pcall(vim.json.encode, snippets)
	if not ok then
		-- Fallback to vim.fn.json_encode if vim.json.encode fails
		raw_json = vim.fn.json_encode(snippets)
	end

	file:write(raw_json)
	file:close()

	return true
end

-- Get current language or prompt for one
local function determine_language()
	local language = vim.bo.filetype

	if language and language ~= "" then
		return language
	end

	-- Prompt for language selection
	local langs = { "typescript", "javascript", "dart", "lua", "python" }
	local choices = { "Select language:" }

	for i, lang in ipairs(langs) do
		table.insert(choices, i .. ". " .. lang)
	end

	local choice = vim.fn.inputlist(choices)
	if choice < 1 or choice > #langs then
		return nil, "Invalid language choice"
	end

	return langs[choice]
end

-- Prompt user for snippet information
local function get_snippet_info()
	local prefix = vim.fn.input("Snippet Prefix: ")
	if prefix == "" then
		return nil, "Snippet prefix cannot be empty"
	end

	local name = vim.fn.input("Snippet Name: ")
	if name == "" then
		name = prefix -- Use prefix as name if not provided
	end

	local description = vim.fn.input("Snippet Description: ")

	return {
		name = name,
		prefix = prefix,
		description = description,
	}
end

-- Get snippet body from selection or user input
local function get_snippet_body(line1, line2)
	local snippet_text = {}

	-- If user selected text (visual mode)
	if line1 and line2 then
		snippet_text = vim.api.nvim_buf_get_lines(0, line1 - 1, line2, false)
	end

	-- If no visual selection, prompt for snippet body line by line
	if #snippet_text == 0 then
		vim.api.nvim_out_write("Enter snippet code (finish with a line containing only '.')\n")

		while true do
			local line = vim.fn.input("> ")
			if line == "." then
				break
			end
			table.insert(snippet_text, line)
		end

		if #snippet_text == 0 then
			return nil, "Snippet body cannot be empty"
		end
	end

	return snippet_text
end

-- Process and sanitize snippet body for VSCode format compatibility
local function process_snippet_body(lines)
	local processed = {}

	for _, line in ipairs(lines) do
		-- Escape special characters for VSCode snippets
		line = line:gsub("\\", "\\\\") -- Escape backslashes first
		line = line:gsub('"', '\\"') -- Escape double quotes
		line = line:gsub("%(", "\\(") -- Escape parentheses for snippet parser
		line = line:gsub("%)", "\\)")
		line = line:gsub("%$", "\\$") -- Escape dollar signs (important for variables)

		table.insert(processed, line)
	end

	return processed
end

-----------------------
-- Public Functions  --
-----------------------

-- Create a snippet
M.create_snippet = function(opts)
	opts = opts or {}

	-- Get snippet body
	local snippet_body, body_err = get_snippet_body(opts.line1, opts.line2)
	if not snippet_body then
		show_error(body_err)
		return
	end

	-- Process the snippet body for compatibility
	local processed_body = process_snippet_body(snippet_body)

	-- Get snippet info
	local snippet_info, info_err = get_snippet_info()
	if not snippet_info then
		show_error(info_err)
		return
	end

	-- Determine language
	local language, lang_err = determine_language()
	if not language then
		show_error(lang_err)
		return
	end

	-- Ensure snippet directory exists
	ensure_dir(M.config.options.snippet_dir)

	local file_path = M.config.options.snippet_dir .. "/" .. language .. ".json"

	-- Read existing snippets
	local snippets = read_snippets(file_path)

	-- Check if snippet already exists
	local existed = snippets[snippet_info.name] ~= nil

	-- Add or override snippet
	snippets[snippet_info.name] = {
		prefix = snippet_info.prefix,
		body = processed_body,
		description = snippet_info.description,
	}

	-- Write to file
	local success, err = write_snippets(file_path, snippets)
	if not success then
		show_error(err)
		return
	end

	-- Notify user of success
	local action = existed and "overridden" or "added"
	notify_user({
		{ "✅ Snippet ", "Normal" },
		{ snippet_info.name, "Special" },
		{ " " .. action .. " to ", "Normal" },
		{ file_path, "Directory" },
	})
end

-- Plugin setup
M.setup = function(opts)
	-- Merge user options with defaults
	M.config.options = vim.tbl_deep_extend("force", M.config.options, opts or {})

	-- Register commands
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
		desc = "Create a new snippet",
		range = true,
	})

	log(PLUGIN_NAME .. " initialized with snippet_dir: " .. M.config.options.snippet_dir)
end

return M
