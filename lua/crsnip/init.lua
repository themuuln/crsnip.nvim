local M = {}

-- Configuration with defaults
M.config = {
	options = {
		snippet_dir = vim.fn.stdpath("config") .. "/snippets",
		debug = false,
	},
}

-- Logger utility
local function log(msg, level)
	if not M.config.options.debug then
		return
	end
	level = level or "info"
	vim.notify("[CRSnip] " .. msg, vim.log.levels[string.upper(level)])
end

-- Ensure directory exists
local function ensure_dir(dir)
	local stat = vim.loop.fs_stat(dir)
	if not stat then
		log("Creating directory: " .. dir, "info")
		vim.fn.mkdir(dir, "p")
	end
end

-- Read existing snippets from file
local function read_snippets(file_path)
	local snippets = {}
	local file = io.open(file_path, "r")
	if file then
		local content = file:read("*a")
		file:close()
		if content and content ~= "" then
			local ok, decoded = pcall(vim.fn.json_decode, content)
			if ok and type(decoded) == "table" then
				if vim.tbl_islist(decoded) then
					-- If the old file was an array, convert it to a table by name
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
					-- Normal object-based JSON
					snippets = decoded
				end
			else
				log("Error decoding JSON, starting a new snippet file.", "warn")
			end
		end
	end
	return snippets
end

--------------------------------------------------------------------------------
-- Pretty-print a Lua table as valid JSON
--------------------------------------------------------------------------------
local function to_pretty_json(tbl)
	local function escape_str(s)
		-- %q escapes special chars, quotes, newlines, etc. for valid JSON strings
		return string.format("%q", s)
	end

	local function is_array(t)
		-- Checks if t is a "continuous" numeric sequence
		local max = 0
		for k, _ in pairs(t) do
			if type(k) ~= "number" then
				return false
			end
			if k > max then
				max = k
			end
		end
		for i = 1, max do
			if t[i] == nil then
				return false
			end
		end
		return true
	end

	local function serialize(obj, indent)
		indent = indent or 0
		local lines = {}

		if type(obj) == "table" then
			if is_array(obj) then
				table.insert(lines, "[")
				for i, v in ipairs(obj) do
					table.insert(
						lines,
						string.rep("  ", indent + 1) .. serialize(v, indent + 1) .. (i < #obj and "," or "")
					)
				end
				table.insert(lines, string.rep("  ", indent) .. "]")
			else
				table.insert(lines, "{")
				local keys = {}
				for k in pairs(obj) do
					table.insert(keys, k)
				end
				table.sort(keys, function(a, b)
					return tostring(a) < tostring(b)
				end)
				for i, k in ipairs(keys) do
					local v = obj[k]
					table.insert(
						lines,
						string.rep("  ", indent + 1)
							.. escape_str(k)
							.. ": "
							.. serialize(v, indent + 1)
							.. (i < #keys and "," or "")
					)
				end
				table.insert(lines, string.rep("  ", indent) .. "}")
			end
		elseif type(obj) == "string" then
			table.insert(lines, escape_str(obj))
		elseif type(obj) == "number" or type(obj) == "boolean" then
			table.insert(lines, tostring(obj))
		else
			-- Fallback for nil, function, etc. => JSON "null"
			table.insert(lines, "null")
		end

		return table.concat(lines, "\n")
	end

	return serialize(tbl, 0)
end

--------------------------------------------------------------------------------

-- Create a snippet
M.create_snippet = function(opts)
	opts = opts or {}
	local snippet_text = {}

	-- If user selected text (visual mode)
	if opts.line1 and opts.line2 then
		snippet_text = vim.api.nvim_buf_get_lines(0, opts.line1 - 1, opts.line2, false)
	end

	local prefix = vim.fn.input("Snippet Prefix: ")
	if prefix == "" then
		vim.api.nvim_err_writeln("Snippet prefix cannot be empty!")
		return
	end

	local name = vim.fn.input("Snippet Name: ")
	if name == "" then
		name = prefix -- Use prefix as name if not provided
	end

	local description = vim.fn.input("Snippet Description: ")

	-- Determine language
	local language = vim.bo.filetype
	if not language or language == "" then
		local langs = { "typescript", "javascript", "dart", "lua", "python" }
		local choices = { "Select language:" }
		for i, lang in ipairs(langs) do
			table.insert(choices, i .. ". " .. lang)
		end
		local choice = vim.fn.inputlist(choices)
		if choice < 1 or choice > #langs then
			vim.api.nvim_err_writeln("Invalid language choice!")
			return
		end
		language = langs[choice]
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
			vim.api.nvim_err_writeln("Snippet body cannot be empty!")
			return
		end
	end

	-- Ensure snippet directory exists
	ensure_dir(vim.fn.stdpath("config") .. "/snippets")

	local file_path = M.config.options.snippet_dir .. "/" .. language .. ".json"

	-- Read existing
	local snippets = read_snippets(file_path)

	-- Check if snippet already exists
	local existed = snippets[name] ~= nil

	-- Add or override
	snippets[name] = {
		prefix = prefix,
		body = snippet_text,
		description = description,
	}

	-- Write to file as pretty JSON
	local file_write, err = io.open(file_path, "w")
	if not file_write then
		vim.api.nvim_err_writeln("Error opening file for writing: " .. (err or "unknown error"))
		return
	end
	file_write:write(to_pretty_json(snippets))
	file_write:close()

	local action = existed and "overridden" or "added"
	vim.api.nvim_echo({
		{ "✅ Snippet ", "Normal" },
		{ name, "Special" },
		{ " " .. action .. " to ", "Normal" },
		{ file_path, "Directory" },
	}, true, {})
end

-- Plugin setup
M.setup = function(opts)
	M.config.options = vim.tbl_deep_extend("force", M.config.options, opts or {})

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
end

return M
