local utils = {};

local ts_available, treesitter_parsers = pcall(require, "nvim-treesitter.parsers");
local ts_utils = require("nvim-treesitter.ts_utils");

--- Checks if a parser is available or not
---@param parser_name string
---@return boolean
utils.parser_installed = function (parser_name)
	return (ts_available and treesitter_parsers.has_parser(parser_name)) or pcall(vim.treesitter.query.get, parser_name, "highlights")
end

utils.within_range = function (range, pos)
	if pos.row_start < range.row_start then
		return false;
	elseif pos.row_end > range.row_end then
		return false;
	elseif
		(pos.row_start == range.row_start and pos.row_end == range.row_end) and
		(pos.col_start < range.col_start or pos.col_end > range.col_end)
	then
		return false;
	end

	return true;
end

--- Escapes magic characters from a string
---@param input string
---@return string
utils.escape_string = function (input)
	input = input:gsub("%%", "%%%%");

	input = input:gsub("%(", "%%(");
	input = input:gsub("%)", "%%)");

	input = input:gsub("%.", "%%.");
	input = input:gsub("%+", "%%+");
	input = input:gsub("%-", "%%-");
	input = input:gsub("%*", "%%*");
	input = input:gsub("%?", "%%?");
	input = input:gsub("%^", "%%^");
	input = input:gsub("%$", "%%$");

	input = input:gsub("%[", "%%[");
	input = input:gsub("%]", "%%]");

	return input;
end

--- Clamps a value between a range
---@param val number
---@param min number
---@param max number
---@return number
utils.clamp = function (val, min, max)
	return math.min(math.max(val, min), max);
end

--- Linear interpolation between 2 values
---@param x number
---@param y number
---@param t number
---@return number
utils.lerp = function (x, y, t)
	return x + ((y - x) * t);
end

--- Checks if a highlight group exists or not
---@param hl string
---@return boolean
utils.hl_exists = function (hl)
	if not vim.tbl_isempty(vim.api.nvim_get_hl(0, { name = hl })) then
		return true;
	elseif not vim.tbl_isempty(vim.api.nvim_get_hl(0, { name = "Markview" .. hl })) then
		return true;
	end

	return false;
end

--- Checks if a highlight group exists or not
---@param hl string?
---@return string?
utils.set_hl = function (hl)
	if type(hl) ~= "string" then
		return;
	end

	if vim.fn.hlexists("Markview" .. hl) == 1 then
		return "Markview" .. hl;
	elseif vim.fn.hlexists("Markview_" .. hl) == 1 then
		return "Markview_" .. hl;
	else
		return hl;
	end
end

--- Gets attached windows from a buffer ID
---@param buf integer
---@return integer[]
utils.find_attached_wins = function (buf)
	local attached_wins = {};

	for _, win in ipairs(vim.api.nvim_list_wins()) do
		if vim.api.nvim_win_get_buf(win) == buf then
			table.insert(attached_wins, win);
		end
	end

	return attached_wins;
end

utils.buf_getwin = function (buffer)
	local wins = vim.fn.win_findbuf(buffer);

	if vim.list_contains(wins, vim.api.nvim_get_current_win()) then
		return vim.api.nvim_get_current_win();
	end

	return wins[1];
end

--- Gets the start & stop line for a range from the cursor
---@param buffer integer
---@param window integer
---@return integer
---@return integer
utils.get_cursor_range = function (buffer, window)
	local cursor = vim.api.nvim_win_get_cursor(window or 0);
	local lines = vim.api.nvim_buf_line_count(buffer);

	return math.max(0, cursor[1] - 1), math.min(lines, cursor[1]);
end

utils.virt_len = function (virt_texts)
	if not virt_texts then
		return 0;
	end

	local _l = 0;

	for _, text in ipairs(virt_texts) do
		_l = _l + vim.fn.strdisplaywidth(text[1]);
	end

	return _l;
end

utils.tostatic = function (tbl, opts)
	if not opts then opts = {}; end
	local _o = {};

	for k, v in pairs(tbl or {}) do
		---@diagnostic disable
		if
			pcall(v, unpack(opts.args or {}))
		then
			_o[k] = v(unpack(opts.args or {}));
		---@diagnostic enable
		elseif type(v) ~= "function" then
			_o[k] = v;
		end
	end

	return _o;
end

utils.pattern = function (main_config, txt, opts)
	--- Checks if we can do pattern matching
	---@return boolean
	local has_pattern = function ()
		if type(main_config) ~= "table" then
			return false;
		elseif vim.islist(main_config.patterns) == false then
			return false;
		elseif type(opts.pattern) ~= "string" then
			return false;
		elseif txt == nil then
			return false;
		end

		return true;
	end

	local spec = require("markview.spec");
	local default  = spec.get({ "default" }, { source = main_config, fallback = {}, eval_args = opts.eval_args });
	--- NOTE, Pattern items can also be dynamic.
	local patterns = spec.get({ "patterns" }, { source = main_config, fallback = {}, eval_args = opts.eval_args });
	local custom = {};

	if has_pattern() == false then
		return default;
	end

	--- Iterate over the items
	for _, entry in ipairs(patterns) do
		if entry.match_string and txt:match(entry.match_string) then
			--- FIXME, Do we remove the `match_string` entry?
			custom = entry;
			break;
		end
	end

	--- Oh yeah, the entry can also be dynamic.
	custom = spec.get({}, { source = custom, eval_args = opts.eval_args });
	return vim.tbl_deep_extend("force", default, custom);
end

utils.create_user_command_class = function (config)
	local class = {};

	class.config = config;

	function class.exec (self, params)
		local sub = params.fargs[1];

		local function exec_subcommand ()
			if config.sub_commands == nil then
				return false;
			elseif config.sub_commands[sub] == nil then
				return false;
			elseif config.sub_commands[sub].action == nil then
				return false;
			end

			return true;
		end

		if sub == nil and self.config.default and self.config.default.action then
			self.config.default.action(params);
		elseif exec_subcommand() == true then
			self.config.sub_commands[sub].action(params);
		end
	end

	function class.comp (self, arg_lead, cmdline, cursor_pos)
		---+${lua}

		local is_subcommand = function (text)
			local cmds = vim.tbl_keys(self.config.sub_commands or {});
			return vim.list_contains(cmds, text);
		end

		local matches_subcommand = function (text)
			if is_subcommand(text) then
				return false;
			end

			for key, _ in pairs(self.config.sub_commands or {}) do
				if key:match(text) then
					return true;
				end
			end

			return false;
		end

		local nargs = 0;
		local args  = {};

		local text = cmdline:sub(0, cursor_pos);

		for arg in text:gmatch("(%S+)") do
			nargs = nargs + 1;
			table.insert(args, arg);
		end

		table.remove(args, 1);
		nargs = nargs - 1;

		local item;

		if nargs == 0 or (nargs == 1 and matches_subcommand(args[1])) then
			item = self.config.default;
		elseif is_subcommand(args[1]) and self.config.sub_commands and self.config.sub_commands[args[1]] then
			item = self.config.sub_commands[args[1]];
		else
			return {};
		end

		if vim.islist(item.completion) then
			return item.completion --[[ @as string[] ]];
		elseif pcall(item.completion, arg_lead, cmdline, cursor_pos) then
			---@type string[]
			return item.completion(arg_lead, cmdline, cursor_pos);
		end
		---_
	end

	-- class = setmetatable(class, class);
	return class;
end

--- Gets a config from a list of config tables.
--- NOTE, {name} will be used to index the config.
---@param config table
---@param name string
---@param opts { eval_args: any[], ignore_keys?: any[] }
---@return any
utils.match = function (config, name, opts)
	local spec = require("markview.spec");
	local keys = vim.tbl_keys(config or {});
	local _o;

	if vim.list_contains(opts.ignore_keys or {}, name) then
		_o = spec.get({ "default" }, { source = config, eval_args = opts.eval_args })
	elseif vim.list_contains(keys, string.lower(name)) then
		_o = spec.get({ string.lower(name) }, { source = config, eval_args = opts.eval_args })
	elseif vim.list_contains(keys, string.upper(name)) then
		_o = spec.get({ string.upper(name) }, { source = config, eval_args = opts.eval_args })
	elseif vim.list_contains(keys, name) then
		_o = spec.get({ name }, { source = config, eval_args = opts.eval_args })
	end

	return _o;
end

return utils;
