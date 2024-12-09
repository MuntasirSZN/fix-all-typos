local markview = require("markview");
local spec = require("markview.spec");

local has_cmp, cmp = pcall(require, "cmp");

--- Sets up the highlight groups.
--- Should be called AFTER loading
--- colorschemes.
require("markview.highlights").setup();

if has_cmp == true then
	local source = require("cmp-markview");
	require('cmp').register_source("markview-cmp", source)
end

--- Patch for the broken (fenced_code_block) concealment.
--- Doesn't hide leading spaces before ```
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
		local ignore_bt = spec.get({ "preview", "ignore_buftypes" }, { fallback = {}, ignore_enable = true });

		--- Check if it's possible to attach to
		--- the buffer.
		---@return boolean
		local can_attach = function ()
			if spec.get({ "enable" }) == false or markview.state.enable == false then
				--- Plugin is disabled.
				return false;
			elseif vim.list_contains(attach_ft, ft) == false then
				return false;
			elseif vim.list_contains(ignore_bt, bt) == true then
				return false;
			end

			return true;
		end

		if can_attach() == false then
			return;
		end

		markview.commands.attach(event.buf);

		if has_cmp == true then
			local new_sources = {};

			for _, source in ipairs(cmp.get_config().sources) do
				if source.name == "markview-cmp" then
					return;
				else
					table.insert(new_sources, source);
				end
			end

			table.insert(new_sources, { name = "markview-cmp", keyword_length = 1, option = {} });
			cmp.setup.buffer { sources = new_sources }
		end
	end
});

local debounce_delay = spec.get({ "preview", "debounce" }, { fallback = 50, ignore_enable = true });
local debounce = vim.uv.new_timer();

--- Like `vim.list_contains` but on a
--- list of items.
---@param list any[]
---@param items any[]
---@return boolean
local list_contains = function (list, items)
	for _, item in ipairs(items) do
		if vim.list_contains(list, item) then
			return true;
		end
	end

	return false;
end

--- All the events where the preview
--- might be updated.
---
--- Note: I did this because `splitview`
--- doesn't follow `modes`(otherwise it
--- becomes kinda pointless to use).
vim.api.nvim_create_autocmd({
	"CursorMoved", "TextChanged",
	"CursorMovedI", "TextChangedI"
}, {
	group = markview.augroup,
	callback = function (ev)
		local event = ev.event;
		local buf = ev.buf;
		local state = markview.state;

		--- Stop any active timers
		debounce:stop();
		local preview_modes = spec.get({ "preview", "modes" }, { fallback = {}, ignore_enable = true });

		if state.enable == false or state.buffer_states[buf] ~= true then
			return;
		end

		--- Is this an event where
		--- we should render?
		local render_event = function ()
			if (event == "CursorMoved" or event == "TextChanged") and list_contains(preview_modes, { "n", "v" }) then
				return true;
			elseif (event == "CursorMovedI" or event == "TextChangedI") and list_contains(preview_modes, { "i" }) then
				return true;
			end

			return false;
		end

		debounce:start(debounce_delay, 0, vim.schedule_wrap(function ()
			if vim.list_contains(markview.state.ignore_modes, buf) == true then
				--- This buffer ignores `modes` and
				--- the events caused by them
				markview.draw(buf, true);
			elseif render_event() == true then
				--- Cursor moved or text changed.
				if buf == markview.state.splitview_source then
					markview.commands.splitRedraw();
				elseif vim.list_contains(markview.state.attached_buffers, buf) then
					markview.draw(buf);
				end
			end
		end))
	end
});

local mode_debounce = vim.uv.new_timer();

vim.api.nvim_create_autocmd({
	"ModeChanged",
}, {
	group = markview.augroup,
	callback = function (ev)
		local event = ev.event;
		local buf = ev.buf;

		local state = markview.state;

		--- Stop any active timers
		mode_debounce:stop();
		local preview_modes = spec.get({ "preview", "modes" }, { fallback = {}, ignore_enable = true });

		mode_debounce:start(event == "ModeChange" and 0 or debounce_delay, 0, vim.schedule_wrap(function ()
			local mode = vim.api.nvim_get_mode().mode;

			--- We should only toggle the preview
			--- on the current buffer as otherwise
			--- it gets distracting when multiple
			--- windows are open.
			if vim.list_contains(state.attached_buffers, buf) == false then
				--- Not an attached buffer.
				return;
			elseif markview.buf_is_safe(buf) == false then
				--- How did the buffer become invalid?
				markview.clean();
				return;
			elseif buf == markview.state.splitview_source then
				--- Update `splitview` buffer.
				markview.commands.splitRedraw();
			elseif state.enable == false or state.buffer_states[buf] ~= true then
				--- Disabled buffer.
				---
				--- Note, Check this after checking if
				--- the buffer is a splitview source
				--- as splitview also disables preview
				--- of the source buffer.
				return;
			elseif vim.list_contains(preview_modes, mode) then
				markview.draw(buf);
			else
				markview.clear(buf);
			end

			--- Call mode change callbacks.
			local callback = spec.get({ "preview", "callbacks", "on_mode_change" }, { default = nil, ignore_enable = true });

			if callback and pcall(callback, buf, vim.fn.win_findbuf(buf), mode) then
				callback(buf, vim.fn.win_findbuf(buf), mode);
			end
		end))
	end
})

--- The `:Markview` command.
vim.api.nvim_create_user_command(
	"Markview",
	require("markview").exec,
	{
		desc = "Main command for `markview.nvim`. Toggles preview by default.",
		nargs = "*", bang = true,
		complete = markview.completion
	}
);

--- Updates the highlight groups.
vim.api.nvim_create_autocmd("ColorScheme", {
	callback = function ()
		local hls = require("markview.highlights");
		hls.create(hls.groups)
	end
});

