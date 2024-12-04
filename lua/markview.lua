--- Base module for `markview.nvim`.
--- Contains,
---     • State variables.
---     • Default autocmd group.
---     • Plugin commands implementations.
---     • Setup function.
---     • And various helper functions.
--- And other minor things!
local markview = {};
local spec = require("markview.spec");

--- Plugin state variables.
---@type markview.states
markview.state = {
	enable = true,
	hybrid_mode = true,

	autocmds = {},

	buffer_states = {},
	hybrid_states = {},

	splitview_source = nil,
	splitview_buffer = vim.api.nvim_create_buf(false, true),
	splitview_window = nil
};

--- Checks if a buffer is already attached.
---@param buffer integer
local buf_attached = function (buffer)
	local autocmds = vim.api.nvim_get_autocmds({
		group = markview.augroup, buffer = buffer
	});
	return not vim.tbl_isempty(autocmds);
end

---@type integer Autocmd group ID.
markview.augroup = vim.api.nvim_create_augroup("markview", { clear = true });

--- Cleans up invalid buffers.
markview.clean = function ()
	---+${func}
	for buffer, cmds in pairs(markview.state.autocmds) do
		if
			not buffer or
			vim.api.nvim_buf_is_loaded(buffer) == false or
			vim.api.nvim_buf_is_valid(buffer) == false
		then
			pcall(vim.api.nvim_del_autocmd, cmds.redraw);
			pcall(vim.api.nvim_del_autocmd, cmds.split_updater);

			markview.state.buffer_states[buffer] = nil;
			markview.state.hybrid_states[buffer] = nil;

			if markview.state.splitview_source == buffer then
				if vim.api.nvim_win_is_valid(markview.state.splitview_window) then
					vim.api.nvim_win_close(markview.state.splitview_window, true);
				end

				markview.state.splitview_source = nil;
			end
		end
	end
	---_
end

--- Checks if the buffer is safe.
---@param buffer integer
---@return boolean
local buf_is_safe = function (buffer)
	---+${func}
	markview.clean();

	if not buffer then
		return false;
	elseif vim.api.nvim_buf_is_valid(buffer) == false then
		return false;
	elseif vim.v.exiting ~= vim.NIL then
		return false;
	end

	return true;
	---_
end

--- Checks if the window is safe.
---@param window integer
---@return boolean
local win_is_safe = function (window)
	---+${func}
	if not window then
		return false;
	elseif vim.api.nvim_win_is_valid(window) == false then
		return false;
	elseif vim.api.nvim_win_get_tabpage(window) ~= vim.api.nvim_get_current_tabpage() then
		return false;
	end

	return true;
	---_
end

--- Checks if the buffer can be attached to.
---@param buffer integer
---@return boolean
local can_attach = function (buffer)
	---+${fund}
	markview.clean();

	if not buf_is_safe(buffer) then
		return false;
	elseif
		vim.list_contains(
			vim.tbl_keys(markview.state.buffer_states)
		)
	then
		return false;
	end

	return true;
	---_
end

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

--- Draws preview on a buffer
---@param buffer integer
---@param ignore_modes? boolean
markview.draw = function (buffer, ignore_modes)
	---+${func}
	local line_limit = spec.get({ "preview", "max_file_length" }, { fallback = 1000, ignore_enable = true });
	local draw_range = spec.get({ "preview", "render_distance" }, { fallback = vim.o.lines, ignore_enable = true });
	local edit_range = spec.get({ "preview", "edit_distance" }, { fallback = { 1, 0 }, ignore_enable = true });

	local line_count = vim.api.nvim_buf_line_count(buffer);

	local preview_modes = spec.get({ "preview", "modes" }, { fallback = {}, ignore_enable = true });
	local hybrid_modes = spec.get({ "preview", "hybrid_modes" }, { fallback = {}, ignore_enable = true });

	local mode = vim.api.nvim_get_mode().mode;

	if
		ignore_modes ~= true and
		not vim.list_contains(preview_modes, mode)
	then
		return;
	end

	local parser = require("markview.parser");
	local renderer = require("markview.renderer");
	local content = {};

	markview.clear(buffer);

	if line_count <= line_limit then
		content = parser.parse(buffer, 0, -1, true);
		renderer.render(buffer, content);
	else
		for _, window in ipairs(vim.fn.win_findbuf(buffer)) do
			local cursor = vim.api.nvim_win_get_cursor(window);

			content = parser.init(
				buffer,
				math.max(0, cursor[1] - draw_range),
				math.min(
					vim.api.nvim_buf_line_count(buffer),
					cursor[1] + draw_range
				)
			);

			local clear_from, clear_to = renderer.range(content);

			if clear_from and clear_to then
				renderer.clear(buffer, nil, clear_from, clear_to);
			end

			renderer.render(buffer, content);
		end
	end

	if not vim.list_contains(hybrid_modes, mode) then
		return;
	elseif markview.state.hybrid_mode == false then
		return;
	elseif markview.state.hybrid_states[buffer] == false then
		return;
	end

	for _, window in ipairs(vim.fn.win_findbuf(buffer)) do
		local cursor = vim.api.nvim_win_get_cursor(window);

		content = parser.init(
			buffer,
			math.max(0, cursor[1] - edit_range[1]),
			math.min(
				vim.api.nvim_buf_line_count(buffer),
				cursor[1] + edit_range[2]
			),
			false
		);

		local clear_from, clear_to = renderer.range(content);

		if clear_from and clear_to then
			renderer.clear(
				buffer,
				spec.get({ "preview", "ignore_node_classes" }, { fallback = {}, ignore_enable = true }),
				clear_from,
				clear_to == clear_from and clear_to + 1 or clear_to
			);
		end
	end
	---_
end

--- Wrapper yo clear decorations from a buffer
---@param buffer integer
markview.clear = function (buffer)
	require("markview.renderer").clear(
		buffer,
		{},
		0,
		-1
	)
end

--- Holds various functions that you can run
--- vim `:Markview ...`.
---@type { [string]: function }
markview.commands = {
	---+${class}
	["attach"] = function (buffer)
		---+${class}
		buffer = buffer or vim.api.nvim_get_current_buf();

		if not can_attach(buffer) then return; end
		local initial_state = spec.get({ "preview", "enable" }, { fallback = true });

		if buf_attached(buffer) then
			return;
		end

		markview.state.buffer_states[buffer] = initial_state;
		markview.state.autocmds[buffer] = {};

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

		debounce:start(debounce_delay, 0, vim.schedule_wrap(function ()
			local call;

			if initial_state == true then
				markview.draw(buffer);
				call = spec.get({ "preview", "callbacks", "on_attach" }, { fallback = nil, ignore_enable = true });
			else
				markview.clear(buffer);
				call = spec.get({ "preview", "callbacks", "on_detach" }, { fallback = nil, ignore_enable = true });
			end

			if call and pcall(call, buffer, vim.fn.win_findbuf(buffer)) then call(buffer, vim.fn.win_findbuf(buffer)); end

			vim.api.nvim_exec_autocmds("User", {
				pattern = initial_state == true and "MarkviewAttach" or "MarkviewDetach",
				data = {
					buffer = buffer,
					windows = vim.fn.win_findbuf(buffer)
				}
			});
		end));

		markview.state.autocmds[buffer].redraw = vim.api.nvim_create_autocmd(events, {
			group = markview.augroup,
			buffer = buffer,
			desc = "Buffer specific preview updater for `markview.nvim`.",

			callback = function ()
				debounce:stop();
				debounce:start(debounce_delay, 0, vim.schedule_wrap(function ()
					--- Drawer function
					if can_draw(buffer) == false then return; end
					markview.draw(buffer);
				end));
			end
		});
		---_
	end,
	["detach"] = function (buffer)
		---+${class}
		buffer = buffer or vim.api.nvim_get_current_buf();
		local call = spec.get({ "preview", "callbacks", "on_detach" }, { fallback = nil, ignore_enable = true });

		markview.clear(buffer);
		local cmds = markview.state.autocmds[buffer];

		pcall(vim.api.nvim_del_autocmd, cmds.redraw);
		pcall(vim.api.nvim_del_autocmd, cmds.split_updater);

		markview.state.buffer_states[buffer] = nil;
		markview.state.hybrid_states[buffer] = nil;

		if call and pcall(call, buffer, vim.fn.win_findbuf(buffer)) then call(buffer, vim.fn.win_findbuf(buffer)); end

		vim.api.nvim_exec_autocmds("User", {
			pattern = "MarkviewDetach",
			data = {
				buffer = buffer,
				windows = vim.fn.win_findbuf(buffer)
			}
		});
		---_
	end,

	["Toggle"] = function ()
		---+${class}
		if markview.state.enable == false then
			markview.commands.Enable()
		else
			markview.commands.Disable()
		end
		---_
	end,
	["Enable"] = function ()
		---+${class}
		markview.state.enable = true;
		vim.api.nvim_exec_autocmds("User", {
			pattern = "MarkviewStateChange",
			data = {
				buffers = vim.tbl_keys(markview.state.buffer_states),
				enabled = true
			}
		});

		local e_call = spec.get({ "preview", "callbacks", "on_enable" }, { fallback = nil, ignore_enable = true });

		for _, buf in ipairs(vim.tbl_keys(markview.state.buffer_states)) do
			if can_draw(buf) then
				if
					e_call and
					pcall(
						e_call,
						buf,
						vim.fn.win_findbuf(buf)
					)
				then
					e_call(buf, vim.fn.win_findbuf(buf));
				end

				markview.draw(buf);
			end

			vim.api.nvim_exec_autocmds("User", {
				pattern = "MarkviewEnable",
				data = {
					buffer = buf,
					windows = vim.fn.win_findbuf(buf)
				}
			});
		end

		local call = spec.get({ "preview", "callbacks", "on_state_change" }, { fallback = nil, ignore_enable = true });

		if
			call and
			pcall(
				call,
				vim.tbl_keys(markview.state.buffer_states),
				markview.state.enable
			)
		then
			call(vim.tbl_keys(markview.state.buffer_states), markview.state.enable);
		end

		vim.api.nvim_exec_autocmds("User", {
			pattern = "MarkviewStateChange",
			data = {
				buffers = vim.tbl_keys(markview.state.buffer_states),
				state = markview.state.enable
			}
		});
		---_
	end,
	["Disable"] = function ()
		---+${class}
		markview.state.enable = false;
		vim.api.nvim_exec_autocmds("User", {
			pattern = "MarkviewStateChange",
			data = {
				buffers = vim.tbl_keys(markview.state.buffer_states),
				enabled = false
			}
		});

		local d_call = spec.get({ "preview", "callbacks", "on_disable" }, { fallback = nil, ignore_enable = true });

		for _, buf in ipairs(vim.tbl_keys(markview.state.buffer_states)) do
			if buf_is_safe(buf) then
				if
					d_call and
					pcall(
						d_call,
						buf,
						vim.fn.win_findbuf(buf)
					)
				then
					d_call(buf, vim.fn.win_findbuf(buf));
				end

				markview.clear(buf);
			end

			vim.api.nvim_exec_autocmds("User", {
				pattern = "MarkviewDisable",
				data = {
					buffer = buf,
					windows = vim.fn.win_findbuf(buf)
				}
			});
		end

		local call = spec.get({ "preview", "callbacks", "on_state_change" }, { fallback = nil, ignore_enable = true });

		if
			call and
			pcall(
				call,
				vim.tbl_keys(markview.state.buffer_states),
				markview.state.enable
			)
		then
			call(vim.tbl_keys(markview.state.buffer_states), markview.state.enable);
		end

		vim.api.nvim_exec_autocmds("User", {
			pattern = "MarkviewStateChange",
			data = {
				buffers = vim.tbl_keys(markview.state.buffer_states),
				state = markview.state.enable
			}
		});
		---_
	end,

	["toggleAll"] = function ()
		spec.notify({
			{ " toggleAll ", "DiagnosticVirtualTextError" },
			{ " is deprecated! Use " },
			{ " Toggle ", "DiagnosticVirtualTextHint" },
			{ " instead." },
		}, { deprecated = true });
		markview.commands.Toggle();
	end,
	["enableAll"] = function ()
		spec.notify({
			{ " enableAll ", "DiagnosticVirtualTextError" },
			{ " is deprecated! Use " },
			{ " Enable ", "DiagnosticVirtualTextHint" },
			{ " instead." },
		}, { deprecated = true });
		markview.commands.Enable();
	end,
	["disableAll"] = function ()
		spec.notify({
			{ " disableAll ", "DiagnosticVirtualTextError" },
			{ " is deprecated! Use " },
			{ " Disable ", "DiagnosticVirtualTextHint" },
			{ " instead." },
		}, { deprecated = true });
		markview.commands.Disable();
	end,

	["toggle"] = function (buffer)
		---+${class}
		buffer = buffer or vim.api.nvim_get_current_buf();
		local state = markview.state.buffer_states[buffer];

		if state == nil then
			return;
		elseif state == true then
			markview.commands.disable(buffer);
		else
			markview.commands.enable(buffer);
		end
		---_
	end,
	["enable"] = function (buffer)
		---+${class}
		buffer = buffer or vim.api.nvim_get_current_buf();
		local call = spec.get({ "preview", "callbacks", "on_enable" }, { fallback = nil, ignore_enable = true });

		if markview.state.buffer_states[buffer] == nil then
			return;
		elseif buf_is_safe(buffer) == false then
			return;
		end

		markview.state.buffer_states[buffer] = true;
		markview.draw(buffer);

		if call and pcall(call, buffer, vim.fn.win_findbuf(buffer)) then call(buffer, vim.fn.win_findbuf(buffer)); end

		vim.api.nvim_exec_autocmds("User", {
			pattern = "MarkviewEnable",
			data = {
				buffer = buffer,
				windows = vim.fn.win_findbuf(buffer)
			}
		});
		---_
	end,
	["disable"] = function (buffer)
		---+${class}
		buffer = buffer or vim.api.nvim_get_current_buf();
		local call = spec.get({ "preview", "callbacks", "on_disable" }, { fallback = nil, ignore_enable = true });

		if markview.state.buffer_states[buffer] == nil then
			return;
		elseif buf_is_safe(buffer) == false then
			return;
		end

		markview.state.buffer_states[buffer] = false;
		markview.clear(buffer);

		if call and pcall(call, buffer, vim.fn.win_findbuf(buffer)) then call(buffer, vim.fn.win_findbuf(buffer)); end

		vim.api.nvim_exec_autocmds("User", {
			pattern = "MarkviewDisable",
			data = {
				buffer = buffer,
				windows = vim.fn.win_findbuf(buffer)
			}
		});
		---_
	end,

	["splitToggle"] = function ()
		---+${class}
		if
			( --- Source buffer doesn't exist or is invalid.
				markview.state.splitview_source == nil or
				buf_is_safe(markview.state.splitview_source) == false
			) or
			( --- Preview buffer doesn't exist or is invalid.
				markview.state.splitview_buffer == nil or
				buf_is_safe(markview.state.splitview_buffer) == false
			)
		then
			--- Close any open previews.
			--- Open a new preview.
			markview.commands.splitClose();
			markview.commands.splitOpen();
		elseif --- Preview window doesn't exist or is invalid.
			markview.state.splitview_window == nil or
			win_is_safe(markview.state.splitview_window) == false
		then
			markview.commands.splitClose();
			markview.commands.splitOpen();
		elseif --- Source buffer is available, close preview.
			markview.state.splitview_source
		then
			markview.commands.splitClose();
		else --- Splitview isn't being used.
			markview.commands.splitOpen();
		end
		---_
	end,

	["splitRedraw"] = function ()
		---+${class}
		if
			not markview.state.splitview_source or
			buf_is_safe(markview.state.splitview_source) == false
		then
			markview.commands.splitClose();
			return;
		elseif buf_is_safe(markview.state.splitview_buffer) == false then
			markview.commands.splitClose();
			return;
		elseif win_is_safe(markview.state.splitview_window) == false then
			markview.commands.splitClose();
			return;
		end

		local utils = require("markview.utils");

		vim.api.nvim_buf_set_lines(
			markview.state.splitview_buffer,
			0,
			-1,
			false,
			vim.api.nvim_buf_get_lines(
				markview.state.splitview_source,
				0,
				-1,
				false
			)
		);

		vim.api.nvim_win_set_cursor(
			markview.state.splitview_window,
			vim.api.nvim_win_get_cursor(
				utils.buf_getwin(markview.state.splitview_source)
			)
		);

		markview.draw(markview.state.splitview_buffer, true)
		---_
	end,

	["splitOpen"] = function (buffer)
		---+${class}
		buffer = buffer or vim.api.nvim_get_current_buf();
		local utils = require("markview.utils");

		if buf_is_safe(buffer) == false then
			return;
		end

		markview.state.splitview_source = buffer;
		markview.state.buffer_states[markview.state.splitview_source] = false;
		markview.clear(markview.state.splitview_source)

		if markview.state.buffer_states[buffer] then
			local s_call = spec.get({ "preview", "callbacks", "on_disable" }, { fallback = nil, ignore_enable = true });
			if s_call and pcall(s_call, buffer, vim.fn.win_findbuf(buffer)) then s_call(buffer, vim.fn.win_findbuf(buffer)); end

			vim.api.nvim_exec_autocmds("User", {
				pattern = "MarkviewDisable",
				data = {
					buffer = buffer,
					windows = vim.fn.win_findbuf(buffer)
				}
			});
		end

		local ft = vim.bo[buffer].filetype;

		if buf_is_safe(markview.state.splitview_buffer) == false then
			markview.state.splitview_buffer = vim.api.nvim_create_buf(false, true);
		end

		markview.state.hybrid_states[markview.state.splitview_buffer] = false;
		vim.bo[markview.state.splitview_buffer].filetype = ft;

		vim.api.nvim_buf_set_lines(
			markview.state.splitview_buffer,
			0,
			-1,
			false,
			vim.api.nvim_buf_get_lines(
				markview.state.splitview_source,
				0,
				-1,
				false
			)
		);

		if win_is_safe(markview.state.splitview_window) == false then
			local _opts = spec.get({
				"preview",
				"splitview_winopts"
			}, {
				eval = true,
				ignore_enable = true,
				args = { markview.state.splitview_buffer }
			});

			markview.state.splitview_window = vim.api.nvim_open_win(
				markview.state.splitview_buffer,
				false,

				_opts or
				{
					split = "right"
				}
			);
		end

		local win = utils.buf_getwin(markview.state.splitview_source);

		vim.wo[markview.state.splitview_window].conceallevel = 3;
		vim.wo[markview.state.splitview_window].concealcursor = "n";
		vim.wo[markview.state.splitview_window].wrap = vim.wo[win].wrap;

		vim.api.nvim_win_set_cursor(
			markview.state.splitview_window,
			vim.api.nvim_win_get_cursor(
				utils.buf_getwin(markview.state.splitview_source)
			)
		);

		local call = spec.get({ "preview", "callbacks", "splitview_open" }, { fallback = nil, ignore_enable = true });

		if
			call and
			pcall(
				call,

				buffer,
				markview.state.splitview_buffer,
				markview.state.splitview_window
			)
		then
			call(
				buffer,
				markview.state.splitview_buffer,
				markview.state.splitview_window
			);
		end

		if
			markview.state.buffer_states[markview.state.splitview_source] and
			markview.state.autocmds[markview.state.splitview_source]
		then
			pcall(vim.api.nvim_del_autocmd, markview.state.autocmds[markview.state.splitview_source].redraw)
		end

		vim.api.nvim_exec_autocmds("User", {
			pattern = "MarkviewSplitviewOpen",
			data = {
				source = buffer,
				preview_buffer = markview.state.splitview_buffer,
				preview_window = markview.state.splitview_window
			}
		});

		local debounce_delay = spec.get({ "preview", "debounce" }, { fallback = 50, ignore_enable = true });
		local debounce = vim.uv.new_timer();

		debounce:start(debounce_delay, 0, vim.schedule_wrap(function ()
			local _call = spec.get({ "preview", "callbacks", "on_detach" }, { fallback = nil, ignore_enable = true });

			markview.clear(markview.state.splitview_source);
			if _call and pcall(_call, markview.state.splitview_source, vim.fn.win_findbuf(markview.state.splitview_source)) then _call(markview.state.splitview_source, vim.fn.win_findbuf(markview.state.splitview_source)); end

			vim.api.nvim_exec_autocmds("User", {
				pattern = "MarkviewDetach",
				data = {
					buffer = buffer,
					windows = vim.fn.win_findbuf(buffer)
				}
			});
		end));

		markview.state.autocmds[markview.state.splitview_source].redraw = vim.api.nvim_create_autocmd({
			"CursorMoved", "TextChanged",
			"CursorMovedI", "TextChangedI",
		}, {
			group = markview.augroup,
			buffer = markview.state.splitview_source,
			desc = "Buffer specific preview updater for `markview.nvim`.",

			callback = function ()
				debounce:stop();
				debounce:start(debounce_delay, 0, vim.schedule_wrap(function ()
					--- Drawer function
					markview.commands.splitRedraw()
				end));
			end
		});

		markview.commands.splitRedraw()
		---_
	end,

	["splitClose"] = function ()
		---+${class}
		if not markview.state.splitview_source then return; end

		---@type integer
		local buffer = markview.state.splitview_source;
		markview.state.splitview_source = nil;

		--- Close the preview window
		if vim.api.nvim_win_is_valid(markview.state.splitview_window) then
			vim.api.nvim_win_close(markview.state.splitview_window, true);
		end

		--- Run the callback.
		local call = spec.get({ "preview", "callbacks", "splitview_close" }, { fallback = nil, ignore_enable = true });
		if call and pcall(call) then call(); end

		vim.api.nvim_exec_autocmds("User", { pattern = "MarkviewSplitviewClose" });


		--- Delete the splitview updating autocmd.
		vim.api.nvim_del_autocmd(markview.state.autocmds[buffer].redraw)

		--- If the buffer was never attached to then
		--- return.
		if markview.state.buffer_states[markview.state.splitview_source] == nil then
			return;
		end

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

		local initial_state = spec.get({ "preview", "enable", }, { fallback = true });

		debounce:start(debounce_delay, 0, vim.schedule_wrap(function ()
			local _call;

			--- Revert the state of the original buffer.
			--- TODO, Allow reverting to the actual previous
			--- state.
			markview.state.buffer_states[buffer] = initial_state;

			if initial_state == true then
				markview.draw(buffer);
				_call = spec.get({ "preview", "callbacks", "on_attach" }, { fallback = nil, ignore_enable = true });
			else
				markview.clear(buffer);
				_call = spec.get({ "preview", "callbacks", "on_detach" }, { fallback = nil, ignore_enable = true });
			end

			if _call and pcall(_call, buffer, vim.fn.win_findbuf(buffer)) then _call(buffer, vim.fn.win_findbuf(buffer)); end

			vim.api.nvim_exec_autocmds("User", {
				pattern = initial_state == true and "MarkviewAttach" or "MarkviewDetach",
				data = {
					buffer = buffer,
					windows = vim.fn.win_findbuf(buffer)
				}
			});
		end));

		--- Add the regular preview updating autocmd.
		markview.state.autocmds[buffer].redraw = vim.api.nvim_create_autocmd(events, {
			group = markview.augroup,
			buffer = buffer,
			desc = "Buffer specific preview updater for `markview.nvim`.",

			callback = function ()
				debounce:stop();
				debounce:start(debounce_delay, 0, vim.schedule_wrap(function ()
					--- Drawer function
					if can_draw(buffer) == false then return; end
					markview.draw(buffer);
				end));
			end
		});
		---_
	end
	---_
};

--- Executes the given command.
---@param cmd table
markview.exec = function (cmd)
	---+${class, Executes a given command}
	local args = cmd.fargs;

	if
		#args == 0
	then
		markview.commands.Toggle();
	elseif
		vim.list_contains(
			vim.tbl_keys(markview.commands),
			args[1]
		)
	then
		local cmd_name = table.remove(args, 1);
		markview.commands[cmd_name](unpack(args)); ---@diagnostic disable-line
	end
	---_
end

--- Cmdline completion.
---@param arg_lead string
---@param cmdline string
---@param _ integer
---@return string[]
markview.completion = function (arg_lead, cmdline, _)
	---+${class, Completion provider}
	local nargs = 0;
	local args  = {};

	for arg in cmdline:gmatch("(%S+)") do
		if arg == "Markview" then goto continue; end

		nargs = nargs + 1;
		table.insert(args, arg);

		::continue::
	end

	local results = {};

	if
		(nargs == 0) or
		(nargs == 1 and cmdline:match("%S$"))
	then
		for cmd, _ in pairs(markview.commands) do
			if cmd:match(arg_lead) then
				table.insert(results, cmd);
			end
		end
	elseif
		(nargs == 1 and cmdline:match("%s$")) or
		(
			nargs == 2 and
			cmdline:match("%S$") and
			vim.list_contains(
				vim.tbl_keys(markview.commands),
				args[1]
			)
		)
	then
		for _, buf in ipairs(vim.tbl_keys(markview.state.buffer_states)) do
			table.insert(results, tostring(buf));
		end
	end

	table.sort(results);
	return results;
	---_
end

--- Plugin setup function(optional)
---@param config table?
markview.setup = function (config)
	local highlights = require("markview.highlights");

	spec.setup(config);
	highlights.setup(spec.get({ "highlight_groups" }));
end

return markview;
