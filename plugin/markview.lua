--- Functionality provider for `markview.nvim`.
--- Functionalities that are implementated,
---
---   + Buffer registration.
---   + Command.
---   + Dynamic highlight groups.
---
--- **Author**: MD. Mouinul Hossain Shawon (OXY2DEV)

local markview = require("markview");
local spec = require("markview.spec");

--- Was the completion source loaded?
if vim.g.markview_cmp_loaded == nil then
	vim.g.markview_cmp_loaded = false;
end

 ------------------------------------------------------------------------------------------

--- Sets up the highlight groups.
--- Should be called AFTER loading
--- colorschemes.
require("markview.highlights").setup();

--- FIX, Patch for the broken (fenced_code_block) concealment.
--- Doesn't hide leading spaces before ```.
vim.treesitter.query.add_directive("conceal-patch!", function (match, _, bufnr, predicate, metadata)
	---+${lua}
	local id = predicate[2];
	local node = match[id];

	local r_s, c_s, r_e, c_e = node:range();
	local line = vim.api.nvim_buf_get_lines(bufnr, r_s, r_s + 1, true)[1];

	if not line then
		return;
	elseif not metadata[id] then
		metadata[id] = { range = {} };
	end

	line = line:sub(c_s + 1, #line);
	local spaces = line:match("^(%s*)%S"):len();

	metadata[id].range[1] = r_s;
	metadata[id].range[2] = c_s + spaces;
	metadata[id].range[3] = r_e;
	metadata[id].range[4] = c_e;

	metadata[id].conceal = "";
	---_
end)

 ------------------------------------------------------------------------------------------

--- Registers completion sources for `markview.nvim`.
local function register_source()
	---+${lua}

	---@type boolean, table
	local has_cmp, cmp = pcall(require, "cmp");

	if has_cmp == false then
		return;
	elseif vim.g.markview_cmp_loaded == false then
		--- Completion source for `markview.nvim`.
		local mkv_src = require("cmp-markview");
		cmp.register_source("cmp-markview", mkv_src);

		vim.g.markview_cmp_loaded = true;
	end

	local old_src = cmp.get_config().sources or {};

	if vim.list_contains(old_src, "cmp-markview") then
		return;
	end

	cmp.setup.buffer({
		sources = vim.list_extend(old_src, {
			{
				name = "cmp-markview",
				keyword_length = 1,
				options = {}
			}
		})
	});
	---_
end

--- Registers buffers.
vim.api.nvim_create_autocmd({ "BufAdd", "BufEnter" }, {
	group = markview.augroup,
	callback = function (event)
		---+${lua}
		local buffer = event.buf;

		if markview.actions.__is_attached(buffer) == true then
			--- Already attached to this buffer!
			return;
		end

		---@type string, string
		local bt, ft = vim.bo[buffer].buftype, vim.bo[buffer].filetype;
		local attach_ft = spec.get({ "preview", "filetypes" }, { fallback = {}, ignore_enable = true });
		local ignore_bt = spec.get({ "preview", "ignore_buftypes" }, { fallback = {}, ignore_enable = true });

		if vim.list_contains(ignore_bt, bt) == true then
			--- Ignored buffer type.
			return;
		elseif vim.list_contains(attach_ft, ft) == false then
			--- Ignored file type.
			return;
		end

		markview.actions.attach(buffer);
		register_source();
		---_
	end
});

--- Mode changes.
vim.api.nvim_create_autocmd({ "ModeChanged" }, {
	group = markview.augroup,
	callback = function (event)
		---+${lua}
		local buffer = event.buf;
		local mode = vim.api.nvim_get_mode().mode;

		if markview.actions.__is_attached(buffer) == false then
			--- Buffer isn't attached!
			return;
		elseif buffer == markview.state.splitview_source then
			markview.splitview_render();
			return;
		elseif markview.actions.__is_enabled(buffer) == false then
			--- Markview disabled on this buffer.
			return;
		end

		---@type string[] List of modes where preview is shown.
		local modes = spec.get({ "preview", "modes" }, { fallback = {}, ignore_enable = true });

		if markview.state.enable == false then
			markview.clear(buffer);
		elseif markview.state.buffer_states[buffer] and markview.state.buffer_states[buffer].enable == false then
			markview.clear(buffer);
		elseif vim.list_contains(modes, mode) then
			markview.render(buffer);
		else
			markview.clear(buffer);
		end

		markview.actions.__exec_callback("on_mode_change", buffer, vim.fn.win_findbuf(buffer), mode)
		---_
	end
});

local timer = vim.uv.new_timer();

--- Preview updates.
vim.api.nvim_create_autocmd({
	"CursorMoved",  "TextChanged",
	"CursorMovedI", "TextChangedI"
}, {
	group = markview.augroup,
	callback = function (event)
		---+${lua}
		timer:stop();
		local buffer = event.buf;
		local name = event.event;
		local mode = vim.api.nvim_get_mode().mode;

		---@type string[] List of modes where preview is shown.
		local modes = spec.get({ "preview", "modes" }, { fallback = {}, ignore_enable = true });

		if markview.actions.__is_attached(buffer) == false then
			return;
		elseif markview.state.enable == false then
			return;
		elseif markview.actions.__is_enabled(buffer) == false then
			return;
		elseif vim.list_contains(modes, mode) == false then
			return;
		end

		local delay = spec.get({ "preview", "debounce" }, { fallback = 25, ignore_enable = true });

		local function immediate_render ()
			if vim.list_contains({ "CursorMoved", "CursorMovedI" }, name) == false then
				return false;
			end

			local utils = require("markview.utils");
			local win = utils.buf_getwin(buffer);

			if type(win) ~= "number" or markview.win_is_safe(win) == false then
				return false;
			end

			local distance_threshold = math.floor(vim.o.lines * 0.75);
			local pos_y = vim.api.nvim_win_get_cursor(win)[1];

			local old = markview.state.buffer_states[buffer].y or 0;
			local diff = math.abs(pos_y - old);

			markview.state.buffer_states[buffer].y = pos_y;

			if diff >= distance_threshold then
				return true;
			else
				return false;
			end
		end

		if buffer == markview.state.splitview_source then
			--- Splitview renderer.
			local max_l = spec.get({ "preview", "max_buf_lines" }, { fallback = 1000, ignore_enable = true });
			local lines = vim.api.nvim_buf_line_count(buffer);

			if lines >= max_l then
				if immediate_render() == true then
					markview.splitview_render(true, true);
				elseif vim.list_contains({ "CursorMoved", "CursorMovedI" }, name) then
					markview.update_splitview_cursor();
				else
					timer:start(delay, 0, vim.schedule_wrap(function ()
						if vim.v.exiting ~= vim.NIL then
							return;
						end

						markview.splitview_render(true, true);
					end));
				end
				--- Partial render is used.
			else
				markview.update_splitview_cursor();
			end
		else
			--- Normal renderer.
			if immediate_render() == true then
				markview.render(buffer);
			else
				timer:start(delay, 0, vim.schedule_wrap(function ()
					if vim.v.exiting ~= vim.NIL then
						return;
					end

					markview.render(buffer);
				end));
			end
		end
		---_
	end
});

--- Updates the highlight groups.
vim.api.nvim_create_autocmd("ColorScheme", {
	callback = function ()
		local hls = require("markview.highlights");
		hls.create(hls.groups)
	end
});

 ------------------------------------------------------------------------------------------

---@type mkv.cmd_completion
local get_complete_items = {
	default = function (str)
		---+${lua}
		if str == nil then
			local _o = vim.tbl_keys(markview.commands);
			table.sort(_o);

			return _o;
		end

		local _o = {};

		for _, key in ipairs(vim.tbl_keys(markview.commands)) do
			if string.match(key, "^" .. str) then
				table.insert(_o, key);
			end
		end

		table.sort(_o);
		return _o;
		---_
	end,

	attach = function (args, cmd)
		---+${lua}
		if #args > 3 then
			--- Too many arguments!
			return {};
		elseif #args >= 3 and string.match(cmd, "%s$") then
			--- Attempting to get completion beyond
			--- the argument count.
			return {};
		end

		local buf = args[3];
		local _o = {};

		for _, buffer in ipairs(vim.api.nvim_list_bufs()) do
			if markview.buf_is_safe(buffer) == false then
				goto continue;
			end

			if buf == nil then
				table.insert(_o, tostring(buffer));
			elseif string.match(tostring(buffer), "^" .. buf) then
				table.insert(_o, tostring(buffer));
			end

		    ::continue::
		end

		table.sort(_o);
		return _o;
		---_
	end,
	detach = function (args, cmd)
		---+${lua}
		if #args > 3 then
			--- Too many arguments!
			return {};
		elseif #args >= 3 and string.match(cmd, "%s$") then
			--- Attempting to get completion beyond
			--- the argument count.
			return {};
		end

		local buf = args[3];
		local _o = {};

		for _, buffer in ipairs(markview.state.attached_buffers) do
			if markview.buf_is_safe(buffer) == false then
				goto continue;
			end

			if buf == nil then
				table.insert(_o, tostring(buffer));
			elseif string.match(tostring(buffer), "^" .. buf) then
				table.insert(_o, tostring(buffer));
			end

		    ::continue::
		end

		table.sort(_o);
		return _o;
		---_
	end,

	enable = function (args, cmd)
		---+${lua}
		if #args > 3 then
			--- Too many arguments!
			return {};
		elseif #args >= 3 and string.match(cmd, "%s$") then
			--- Attempting to get completion beyond
			--- the argument count.
			return {};
		end

		local buf = args[3];
		local _o = {};

		for _, buffer in ipairs(markview.state.attached_buffers) do
			if markview.buf_is_safe(buffer) == false or markview.actions.__is_enabled(buffer) == true then
				goto continue;
			end

			if buf == nil then
				table.insert(_o, tostring(buffer));
			elseif string.match(tostring(buffer), "^" .. buf) then
				table.insert(_o, tostring(buffer));
			end

		    ::continue::
		end

		table.sort(_o);
		return _o;
		---_
	end,
	disable = function (args, cmd)
		---+${lua}
		if #args > 3 then
			--- Too many arguments!
			return {};
		elseif #args >= 3 and string.match(cmd, "%s$") then
			--- Attempting to get completion beyond
			--- the argument count.
			return {};
		end

		local buf = args[3];
		local _o = {};

		for _, buffer in ipairs(markview.state.attached_buffers) do
			if markview.buf_is_safe(buffer) == false or markview.actions.__is_enabled(buffer) == false then
				goto continue;
			end

			if buf == nil then
				table.insert(_o, tostring(buffer));
			elseif string.match(tostring(buffer), "^" .. buf) then
				table.insert(_o, tostring(buffer));
			end

		    ::continue::
		end

		table.sort(_o);
		return _o;
		---_
	end,

	splitOpen = function (args, cmd)
		---+${lua}
		if #args > 3 then
			--- Too many arguments!
			return {};
		elseif #args >= 3 and string.match(cmd, "%s$") then
			--- Attempting to get completion beyond
			--- the argument count.
			return {};
		end

		local buf = args[3];
		local _o = {};

		for _, buffer in ipairs(markview.state.attached_buffers) do
			if markview.buf_is_safe(buffer) == false then
				goto continue;
			end

			if buf == nil then
				table.insert(_o, tostring(buffer));
			elseif string.match(tostring(buffer), "^" .. buf) then
				table.insert(_o, tostring(buffer));
			end

		    ::continue::
		end

		table.sort(_o);
		return _o;
		---_
	end,

	render = function (args, cmd)
		---+${lua}
		if #args > 3 then
			--- Too many arguments!
			return {};
		elseif #args >= 3 and string.match(cmd, "%s$") then
			--- Attempting to get completion beyond
			--- the argument count.
			return {};
		end

		local buf = args[3];
		local _o = {};

		for _, buffer in ipairs(vim.api.nvim_list_bufs()) do
			if markview.buf_is_safe(buffer) == false then
				goto continue;
			end

			if buf == nil then
				table.insert(_o, tostring(buffer));
			elseif string.match(tostring(buffer), "^" .. buf) then
				table.insert(_o, tostring(buffer));
			end

		    ::continue::
		end

		table.sort(_o);
		return _o;
		---_
	end,
	clear = function (args, cmd)
		---+${lua}
		if #args > 3 then
			--- Too many arguments!
			return {};
		elseif #args >= 3 and string.match(cmd, "%s$") then
			--- Attempting to get completion beyond
			--- the argument count.
			return {};
		end

		local buf = args[3];
		local _o = {};

		for _, buffer in ipairs(vim.api.nvim_list_bufs()) do
			if markview.buf_is_safe(buffer) == false then
				goto continue;
			end

			if buf == nil then
				table.insert(_o, tostring(buffer));
			elseif string.match(tostring(buffer), "^" .. buf) then
				table.insert(_o, tostring(buffer));
			end

		    ::continue::
		end

		table.sort(_o);
		return _o;
		---_
	end
};

--- User command.
vim.api.nvim_create_user_command("Markview", function (cmd)
	---+${lua}

	local function exec(fun, args)
		args = args or {};
		local fargs = {};

		for _, arg in ipairs(args) do
			if tonumber(arg) then
				table.insert(fargs, tonumber(arg));
			elseif arg == "true" or arg == "false" then
				table.insert(fargs, arg == "true");
			else
				--- BUG, is this used by any functions?
				-- table.insert(fargs, arg);
			end
		end

		---@diagnostic disable-next-line
		pcall(fun, unpack(fargs));
	end

	---@type string[] Command arguments.
	local args = cmd.fargs;

	if #args == 0 then
		markview.commands.Toggle();
	elseif type(markview.commands[args[1]]) == "function" then
		--- FIXME, Change this if `vim.list_slice` becomes deprecated.
		exec(markview.commands[args[1]], vim.list_slice(args, 2))
	end
	---_
end, {
	---+${lua}
	nargs = "*",
	desc = "User command for `markview.nvim`",
	complete = function (_, cmd, cursorpos)
		local function is_subcommand(str)
			return markview.commands[str] ~= nil;
		end

		local before = string.sub(cmd, 0, cursorpos);
		local parts = {};

		for part in string.gmatch(before, "%S+") do
			table.insert(parts, part);
		end

		if #parts == 1 then
			return get_complete_items.default();
		elseif #parts == 2 and is_subcommand(parts[2]) == false then
			return get_complete_items.default(parts[2]);
		elseif is_subcommand(parts[2]) == true and get_complete_items[parts[2]] ~= nil then
			return get_complete_items[parts[2]](parts, before);
		end
	end
	---_
});
