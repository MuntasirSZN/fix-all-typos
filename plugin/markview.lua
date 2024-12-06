local markview = require("markview");
local spec = require("markview.spec");

require("markview.highlights").setup();

--- Patch for the broken (fenced_code_block) concealment
vim.treesitter.query.add_directive("conceal-patch!", function (match, _, bufnr, predicate, metadata)
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
end)

--- Autocmd for attaching to a buffer.
vim.api.nvim_create_autocmd({ "BufAdd", "BufEnter" }, {
	group = markview.augroup,
	callback = function (event)
		local buffer = event.buf or vim.api.nvim_get_current_buf();
		local bt, ft = vim.bo[buffer].buftype, vim.bo[buffer].filetype;

		local attach_ft = spec.get({ "preview", "filetypes" }, { fallback = {}, ignore_enable = true });
		local ignore_bt = spec.get({ "preview", "filetypes" }, { fallback = {}, ignore_enable = true });

		--- Check if it's possible to attach to
		--- the buffer.
		---@return boolean
		local can_attach = function ()
			if spec.get({ "enable" }) == false or markview.state.enable == false then
				--- Plugin is disabled.
				return false;
			elseif vim.list_contains(attach_ft, ft) == false  then
				return false;
			elseif vim.list_contains(ignore_bt, bt) == true then
				return false;
			end

			return true;
		end

		if can_attach() == true then
			markview.commands.attach(event.buf);
		end
	end
});

--- Autocmd to listen to mode changes.
vim.api.nvim_create_autocmd({ "ModeChanged" }, {
	group = markview.group,
	callback = function ()
		local renderer = require("markview.renderer");

		local preview_modes = spec.get({ "preview", "modes" }, { fallback = {}, ignore_enable = true });
		local mode = vim.api.nvim_get_mode().mode;

		local call = spec.get({ "preview", "callbacks", "on_mode_change" }, { fallback = nil, ignore_enable = true });

		if markview.state.enable == false then
			return;
		elseif not preview_modes then
			return;
		end

		for buf, state in ipairs(markview.state.buffer_states) do
			---+${func, Buffer redrawing}
			renderer.clear(buf);
			if state == false then goto continue; end

			if vim.list_contains(preview_modes, mode) then
				markview.draw(buf);
			else
				renderer.clear(buf, {}, 0, -1);
			end

			if
				call and
				pcall(call, buf, vim.fn.win_findbuf(buf), mode)
			then
				call(
					buf,
					vim.fn.win_findbuf(buf),
					mode
				)
			end

			::continue::
			---_
		end
	end
});

local events = spec.get({ "preview", "redraw_events" }, { fallback = {}, ignore_enable = true });
local preview_modes = spec.get({ "preview", "modes" }, { fallback = {}, ignore_enable = true });

if
	vim.list_contains(preview_modes, "n") or
	vim.list_contains(preview_modes, "v")
then
	table.insert(events, "CursorMoved");
	table.insert(events, "TextChanged");
end

if vim.list_contains(preview_modes, "i") then
	table.insert(events, "CursorMovedI");
	table.insert(events, "TextChangedI");
end

local debounce_delay = spec.get({ "preview", "debounce" }, { fallback = 50, ignore_enable = true });
local debounce = vim.uv.new_timer();

vim.api.nvim_create_autocmd(events, {
	group = markview.group,
	callback = function (param)
		--- Checks if decorations can be drawn on a buffer.
		---@param buffer integer
		---@return boolean
		local can_draw = function (buffer)
			---+${func}
			markview.clean();

			if not buf_is_safe(buffer) then
				return false;
			elseif markview.state.enable == false then
				return false;
			elseif markview.state.buffer_states[buffer] == false then
				return false;
			end

			return true;
			---_
		end

		local attached_bufs = vim.tbl_keys(markview.state.buffer_states);
		debounce:stop();

		if vim.list_contains(attached_bufs, param.buf) == false then
			return;
		end

		debounce:start(debounce_delay, 0, vim.schedule_wrap(function ()
			--- Drawer function
			if can_draw(param.buf) == false then return; end
			markview.draw(param.buf);
		end));

	end
});

vim.api.nvim_create_user_command(
	"Markview",
	require("markview").exec,
	{
		desc = "Main command for `markview.nvim`. Toggles preview by default.",
		nargs = "*", bang = true,
		complete = markview.completion
	}
);

vim.api.nvim_create_autocmd("ColorScheme", {
	callback = function ()
		local hls = require("markview.highlights");

		hls.create(hls.groups)
	end
})

