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
-- vim.api.nvim_create_autocmd({ "ModeChanged" }, {
-- 	group = markview.group,
-- 	callback = function ()
-- 		local renderer = require("markview.renderer");
--
-- 		local mode = vim.api.nvim_get_mode().mode;
--
-- 		local call = spec.get({ "preview", "callbacks", "on_mode_change" }, { fallback = nil, ignore_enable = true });
--
-- 		if markview.state.enable == false then
-- 			return;
-- 		elseif not preview_modes then
-- 			return;
-- 		end
--
-- 		for buf, state in ipairs(markview.state.buffer_states) do
-- 			---+${func, Buffer redrawing}
-- 			renderer.clear(buf);
-- 			if state == false then goto continue; end
--
-- 			if vim.list_contains(preview_modes, mode) then
-- 				-- markview.draw(buf);
-- 			else
-- 				renderer.clear(buf, {}, 0, -1);
-- 			end
--
-- 			if
-- 				call and
-- 				pcall(call, buf, vim.fn.win_findbuf(buf), mode)
-- 			then
-- 				call(
-- 					buf,
-- 					vim.fn.win_findbuf(buf),
-- 					mode
-- 				)
-- 			end
--
-- 			::continue::
-- 			---_
-- 		end
-- 	end
-- });
--
-- -- local events = spec.get({ "preview", "redraw_events" }, { fallback = {}, ignore_enable = true });
--
-- vim.api.nvim_create_autocmd({ "CursorMoved", "CursorMovedI", "TextChanged", "TextChangedI" }, {
-- 	group = markview.group,
-- 	callback = function (param)
-- 		--- Checks if decorations can be drawn on a buffer.
-- 		---@param buffer integer
-- 		---@return boolean
-- 		local buf_is_safe = function (buffer)
-- 			---+${func}
-- 			markview.clean();
--
-- 			if markview.state.enable == false then
-- 				return false;
-- 			elseif markview.state.buffer_states[buffer] == false then
-- 				return false;
-- 			end
--
-- 			return true;
-- 			---_
-- 		end
--
-- 		local can_render = function ()
-- 			local ev = param.event;
-- 			local modes = spec.get({ "preview", "modes" }, { fallback = {}, ignore_enable = true });
--
-- 			if (ev == "CursorMoved" or ev == "TextChanged") and (vim.list_contains(modes, "n") or vim.list_contains(modes, "v")) then
-- 				return true;
-- 			elseif (ev == "CursorMovedI" or ev == "TextChangedI") and vim.list_contains(modes, "i") then
-- 				return true;
-- 			end
--
-- 			return false;
-- 		end
--
-- 		if can_render() == false then
-- 			return;
-- 		end
--
-- 		local attached_bufs = vim.tbl_keys(markview.state.buffer_states);
-- 		debounce:stop();
--
-- 		if vim.list_contains(attached_bufs, param.buf) == false then
-- 			return;
-- 		end
--
-- 		debounce:start(debounce_delay, 0, vim.schedule_wrap(function ()
-- 			--- Drawer function
-- 			if buf_is_safe(param.buf) == false then return; end
-- 		end));
--
-- 	end
-- });


local debounce_delay = spec.get({ "preview", "debounce" }, { fallback = 50, ignore_enable = true });
local debounce = vim.uv.new_timer();

local list_contains = function (list, items)
	for _, item in ipairs(items) do
		if vim.list_contains(list, item) then
			return true;
		end
	end

	return false;
end

vim.api.nvim_create_autocmd({
	"ModeChanged",
	"CursorMoved", "TextChanged",
	"CursorMovedI", "TextChangedI"
}, {
	group = markview.augroup,
	callback = function (ev)
		local event = ev.event;
		local buf = ev.buf;
		local mode = vim.api.nvim_get_mode().mode;

		local state = markview.state;

		--- Stop any active timers
		debounce:stop();
		local preview_modes = spec.get({ "preview", "modes" }, { fallback = {}, ignore_enable = true });

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
				markview.draw(buf, true);
			elseif event == "ModeChanged" then
				if vim.list_contains(state.attached_buffers, buf) == false then
					return;
				elseif markview.buf_is_safe(buf) == false then
					markview.clean();
					return;
				elseif buf == markview.state.splitview_source then
					markview.commands.splitRedraw();
				elseif vim.list_contains(preview_modes, mode) then
					markview.draw(buf);
				else
					markview.clear(buf);
				end
			elseif render_event() == true then
				if buf == markview.state.splitview_source then
					markview.commands.splitRedraw();
				else
					markview.draw(buf);
				end
			end
		end))
	end
})

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

