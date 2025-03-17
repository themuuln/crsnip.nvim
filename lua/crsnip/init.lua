local M = {}

-- Configuration with defaults
M.config = {
	options = {
		snippet_dir = vim.fn.stdpath("config") .. "/snippets",
		debug = false,
	},
}

-- Enhanced logger utility with timestamp
local function log(msg, level)
	if not M.config.options.debug then
		return
	end
	level = level or "info"
	local timestamp = os.date("%H:%M:%S")
	vim.notify(string.format("[CRSnip %s] %s", timestamp, msg), vim.log.levels[string.upper(level)])
end

-- Enhanced directory creation with error handling
local function ensure_dir(dir)
	local ok, err = pcall(function()
		local stat = vim.loop.fs_stat(dir)
		if not stat then
			log("Creating directory: " .. dir, "info")
			vim.fn.mkdir(dir, "p")
		end
	end)

	if not ok then
		error(string.format("Failed to create directory %s: %s", dir, err))
	end
end

-- Improved JSON reading with better error handling
local function read_snippets(file_path)
	local snippets = {}
	local ok, content = pcall(function()
		local file = io.open(file_path, "r")
		if not file then
			return nil
		end
		local content = file:read("*a")
		file:close()
		return content
	end)

	if not ok or not content or content == "" then
		return snippets
	end

	ok, snippets = pcall(function()
		local decoded = vim.fn.json_decode(content)
		if type(decoded) ~= "table" then
			return {}
		end

		-- Convert array format to object format if needed
		if vim.tbl_islist(decoded) then
			local converted = {}
			for _, snippet in ipairs(decoded) do
				if snippet.name then
					converted[snippet.name] = {
						prefix = snippet.prefix,
						body = snippet.body,
						description = snippet.description,
					}
				end
			end
			return converted
		end
		return decoded
	end)

	if not ok then
		log("Error parsing snippets file: " .. file_path, "error")
		return {}
	end

	return snippets
end

-- Improved JSON formatting with better string handling
local function format_json(obj)
	local function escape_string(str)
		local escaped = str:gsub("([^%w])", function(c)
			local escapes = {
				['"'] = '\\"',
				["\\"] = "\\\\",
				["\b"] = "\\b",
				["\f"] = "\\f",
				["\n"] = "\\n",
				["\r"] = "\\r",
				["\t"] = "\\t",
			}
			return escapes[c] or c
		end)
		return escaped
	end

	local function serialize(val, depth)
		depth = depth or 0
		local indent = string.rep("  ", depth)

		if type(val) == "table" then
			if vim.tbl_islist(val) then
				local items = {}
				for _, v in ipairs(val) do
					table.insert(items, serialize(v, depth + 1))
				end
				return "[\n" .. indent .. "  " .. table.concat(items, ",\n" .. indent .. "  ") .. "\n" .. indent .. "]"
			else
				local items = {}
				for k, v in pairs(val) do
					table.insert(items, string.format('"%s": %s', escape_string(k), serialize(v, depth + 1)))
				end
				return "{\n" .. indent .. "  " .. table.concat(items, ",\n" .. indent .. "  ") .. "\n" .. indent .. "}"
			end
		elseif type(val) == "string" then
			return string.format('"%s"', escape_string(val))
		else
			return tostring(val)
		end
	end

	return serialize(obj)
end

-- Enhanced snippet creation with input validation
M.create_snippet = function(opts)
	opts = opts or {}
	local snippet_text = {}

	-- Get selected text if in visual mode
	if opts.line1 and opts.line2 then
		snippet_text = vim.api.nvim_buf_get_lines(0, opts.line1 - 1, opts.line2, false)
	end

	-- Enhanced input collection with validation
	local function get_validated_input(prompt, required)
		local input = vim.fn.input(prompt)
		if required and input == "" then
			error(prompt:gsub(":.*", "") .. " cannot be empty!")
		end
		return input
	end

	local prefix = get_validated_input("Snippet Prefix: ", true)
	local name = get_validated_input("Snippet Name (press Enter to use prefix): ", false)
	name = name ~= "" and name or prefix
	local description = get_validated_input("Snippet Description: ", false)

	-- Enhanced language detection
	local language = vim.bo.filetype
	if not language or language == "" then
		local langs = { "typescript", "javascript", "dart", "lua", "python" }
		local choices = { "Select language:" }
		for i, lang in ipairs(langs) do
			table.insert(choices, i .. ". " .. lang)
		end

		local choice = vim.fn.inputlist(choices)
		if choice < 1 or choice > #langs then
			error("Invalid language choice!")
		end
		language = langs[choice]
	end

	-- Get snippet content if not provided through selection
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
			error("Snippet body cannot be empty!")
		end
	end

	-- Save snippet with error handling
	local ok, err = pcall(function()
		ensure_dir(M.config.options.snippet_dir)
		local file_path = M.config.options.snippet_dir .. "/" .. language .. ".json"
		local snippets = read_snippets(file_path)
		local existed = snippets[name] ~= nil

		snippets[name] = {
			prefix = prefix,
			body = snippet_text,
			description = description,
		}

		local file = assert(io.open(file_path, "w"))
		file:write(format_json(snippets))
		file:close()

		local action = existed and "overridden" or "added"
		vim.api.nvim_echo({
			{ "✅ Snippet ", "Normal" },
			{ name, "Special" },
			{ " " .. action .. " to ", "Normal" },
			{ file_path, "Directory" },
		}, true, {})
	end)

	if not ok then
		error(string.format("Failed to save snippet: %s", err))
	end
end

-- Enhanced setup function with validation
M.setup = function(opts)
	local ok, err = pcall(function()
		M.config.options = vim.tbl_deep_extend("force", M.config.options, opts or {})

		-- Validate configuration
		if type(M.config.options.snippet_dir) ~= "string" then
			error("snippet_dir must be a string")
		end

		-- Create commands
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

		log("CRSnip initialized with snippet_dir: " .. M.config.options.snippet_dir)
	end)

	if not ok then
		error(string.format("Failed to setup CRSnip: %s", err))
	end
end

return M
