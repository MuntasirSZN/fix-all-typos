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
---@type mkv.state
markview.state = {
	attached_buffers = {},
	buffer_states = {},

	splitview_buffer = nil,
	splitview_cstate = nil,
	splitview_source = nil,
	splitview_window = nil
};

---@type integer Autocmd group ID.
markview.augroup = vim.api.nvim_create_augroup("markview", { clear = true });

 ------------------------------------------------------------------------------------------

--- Cleans up invalid buffers.
markview.clean = function ()
	---+${lua}

	--- Should a buffer be cleaned?
	---@param bufnr integer
	---@return boolean
	local function should_clean(bufnr)
		if not bufnr then
			return true;
		elseif vim.api.nvim_buf_is_loaded(bufnr) == false then
			return true;
		elseif vim.api.nvim_buf_is_valid(bufnr) == false then
			return true;
		end

		return false;
	end

	---+${func}
	for index, buffer in ipairs(markview.state.attached_buffers) do
		if should_clean(buffer) == true then
			table.remove(markview.state.attached_buffers, index);
			markview.state.buffer_states[buffer] = nil;

			if markview.state.splitview_source == buffer then
				markview.actions.splitClose();
			end
		end
	end
	---_
	---_
end

--- Checks if the buffer is safe.
---@param buffer integer?
---@return boolean
markview.buf_is_safe = function (buffer)
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
---@param window integer?
---@return boolean
markview.win_is_safe = function (window)
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
markview.can_attach = function (buffer)
	---+${fund}
	markview.clean();

	if not markview.buf_is_safe(buffer) then
		return false;
	elseif vim.list_contains(markview.state.attached_buffers, buffer) then
		return false;
	end

	return true;
	---_
end

--- Checks if decorations can be drawn on a buffer.
---@param buffer integer
---@return boolean
markview.can_draw = function (buffer)
	---+${func}
	markview.clean();

	if not markview.buf_is_safe(buffer) then
		return false;
	elseif markview.state.buffer_states[buffer] == false then
		return false;
	end

	return true;
	---_
end

--- Wrapper to clear decorations from a buffer
---@param buffer integer
markview.clear = function (buffer)
	require("markview.renderer").clear(buffer, 0, -1);
end

--- Renders preview.
---@param buffer integer?
---@param state { enable: boolean, hybrid_mode: boolean? }?
markview.render = function (buffer, state)
	---+${lua}

	---@type integer
	buffer = buffer or vim.api.nvim_get_current_buf();

	local parser = require("markview.parser");
	local renderer = require("markview.renderer");

	---@type integer Number of lines a buffer can have to be fully rendered.
	local line_limit = spec.get({ "preview", "max_buf_lines" }, { fallback = 1000, ignore_enable = true });
	---@type [ integer, integer ] Number of lines to draw on large buffers.
	local draw_range = spec.get({ "preview", "draw_range" }, { fallback = { vim.o.lines, vim.o.lines }, ignore_enable = true });
	---@type [ integer, integer ] Number of lines to be considered being edited.
	local edit_range = spec.get({ "preview", "edit_range" }, { fallback = { 1, 0 }, ignore_enable = true });

	---@type integer Buffer's line count.
	local line_count = vim.api.nvim_buf_line_count(buffer);

	---@type string[] List of modes where to use hybrid_mode.
	local hybrid_modes = spec.get({ "preview", "hybrid_modes" }, { fallback = {}, ignore_enable = true });
	---@type boolean Is line-wise hybrid mode enabled?
	local linewise_hybrid_mode = spec.get({ "preview", "linewise_hybrid_mode" }, { fallback = false, ignore_enable = true })

	---@type string Current mode shorthand.
	local mode = vim.api.nvim_get_mode().mode;

	state = state or markview.state.buffer_states[buffer];

	local function hybrid_mode()
		if type(state) == "table" and state.hybrid_mode == false then
			return false;
		else
			return vim.list_contains(hybrid_modes, mode);
		end
	end
	local content;

	markview.clear(buffer);

	if line_count <= line_limit then
		content, _ = parser.parse(buffer, 0, -1, true);

		if hybrid_mode() == true and linewise_hybrid_mode == false then
			for _, win in ipairs(vim.fn.win_findbuf(buffer)) do
				---@type [ integer, integer ] Cursor position.
				local cursor = vim.api.nvim_win_get_cursor(win);
				--- 1-index → 0-index
				cursor[1] = cursor[1] - 1;

				content = renderer.filter(content, nil, {
					math.max(0, cursor[1] - edit_range[1]),
					math.min(cursor[1] + edit_range[2], line_count)
				});
			end

			renderer.render(buffer, content);
		elseif hybrid_mode() == true then
			renderer.render(buffer, content);

			for _, win in ipairs(vim.fn.win_findbuf(buffer)) do
				---@type [ integer, integer ] Cursor position.
				local cursor = vim.api.nvim_win_get_cursor(win);
				--- 1-index → 0-index
				cursor[1] = cursor[1] - 1;

				renderer.clear(buffer,
					math.max(0, cursor[1] - edit_range[1]),
					math.min(cursor[1] + 1 + edit_range[2], line_count)
				);
			end
		else
			renderer.render(buffer, content);
		end
	else
		for _, win in ipairs(vim.fn.win_findbuf(buffer)) do
			---@type [ integer, integer ] Cursor position.
			local cursor = vim.api.nvim_win_get_cursor(win);
			--- 1-index → 0-index
			cursor[1] = cursor[1] - 1;

			content, _ = parser.parse(buffer, math.max(0, cursor[1] - draw_range[1]), math.min(line_count, cursor[1] + draw_range[2]), true);

			if hybrid_mode() == true and linewise_hybrid_mode == false then
				content = renderer.filter(content, nil, {
					math.max(0, cursor[1] - edit_range[1]),
					math.min(cursor[1] + edit_range[2], line_count)
				});
				renderer.render(buffer, content);
			elseif hybrid_mode() == true then
				renderer.render(buffer, content);

				renderer.clear(buffer,
					math.max(0, cursor[1] - edit_range[1]),
					math.min(cursor[1] + 1 + edit_range[2], line_count)
				);
			else
				renderer.render(buffer, content);
			end
		end
	end
	---_
end

--- Updates cursor position in splitview.
markview.update_splitview_cursor = function ()
	---+${lua}

	local utils = require("markview.utils");
	local buffer = markview.state.splitview_source;

	if markview.buf_is_safe(buffer) == false then
		--- Buffer isn't safe.
		-- markview.state.splitview_source = nil;
		pcall(markview.actions.splitClose);
		return;
	elseif markview.win_is_safe(utils.buf_getwin(buffer)) == false then
		--- Buffer doesn't have any windows attached.
		pcall(markview.actions.splitClose);
		return;
	end

	--- In case the preview buffer/window got
	--- deleted, we should regenerate them.
	markview.actions.__splitview_setup();

	local pre_win = markview.state.splitview_window;

	local cursor = vim.api.nvim_win_get_cursor(utils.buf_getwin(buffer));
	pcall(vim.api.nvim_win_set_cursor, pre_win, cursor);

	---_
end

markview.splitview_render = function (update_content, update_preview)
	---+${lua}

	local utils = require("markview.utils");
	local buffer = markview.state.splitview_source;

	if markview.buf_is_safe(buffer) == false then
		--- Buffer isn't safe.
		-- markview.state.splitview_source = nil;
		pcall(markview.actions.splitClose);
		return;
	elseif markview.win_is_safe(utils.buf_getwin(buffer)) == false then
		--- Buffer doesn't have any windows attached.
		pcall(markview.actions.splitClose);
		return;
	end

	--- In case the preview buffer/window got
	--- deleted, we should regenerate them.
	markview.actions.__splitview_setup();

	local pre_buf = markview.state.splitview_buffer;
	local pre_win = markview.state.splitview_window;

	if update_content ~= false then
		local lines = vim.api.nvim_buf_get_lines(buffer, 0, -1, false);
		vim.api.nvim_buf_set_lines(pre_buf, 0, -1, false, lines);
	end

	local cursor = vim.api.nvim_win_get_cursor(utils.buf_getwin(buffer));
	pcall(vim.api.nvim_win_set_cursor, pre_win, cursor);

	if update_preview ~= false then
		markview.render(pre_buf, {
			enable = true,
			hybrid_mode = false
		});
	end
	---_
end

 ------------------------------------------------------------------------------------------

--- Various actions(provides core functionalities of `markview.nvim`).
markview.actions = {
	---+${lua}

	["__exec_callback"] = function (autocmd, ...)
		if vim.list_contains({ "string", "integer" }, type(autocmd)) == false then
			--- Invalid data type.
			return;
		end

		local callbacks = spec.get({ "preview", "callbacks" }, { fallback = nil, ignore_enable = true });
		pcall(callbacks[autocmd], ...);
	end,
	["__is_attached"] = function (buffer)
		buffer = buffer or vim.api.nvim_get_current_buf();
		return vim.list_contains(markview.state.attached_buffers, buffer);
	end,
	["__is_enabled"] = function (buffer)
		buffer = buffer or vim.api.nvim_get_current_buf();

		if vim.list_contains(markview.state.attached_buffers, buffer) == false then
			return false;
		elseif type(markview.state.buffer_states[buffer]) ~= "table" then
			return false;
		else
			return markview.state.buffer_states[buffer].enable;
		end
	end,
	["__splitview_setup"] = function ()
		--+${lua}

		if markview.buf_is_safe(markview.state.splitview_source) == false then
			return;
		end

		local utils = require("markview.utils");
		local win = utils.buf_getwin(markview.state.splitview_source);

		if markview.win_is_safe(win) == false then
			markview.actions.splitClose();
			return;
		end

		if markview.buf_is_safe(markview.state.splitview_buffer) == false then
			pcall(vim.api.nvim_buf_delete, markview.state.splitview_buffer, { force = true });
			markview.state.splitview_buffer = vim.api.nvim_create_buf(false, true);
		end

		vim.bo[markview.state.splitview_buffer].ft = vim.bo[markview.state.splitview_source].ft;

		if markview.win_is_safe(markview.state.splitview_window) == false then
			pcall(vim.api.nvim_win_close, markview.state.splitview_window, true);
			markview.state.splitview_window = vim.api.nvim_open_win(
				markview.state.splitview_buffer,
				false,
				spec.get({ "preview", "splitview_winopts", }, {
					fallback = { split = "right" }
				})
			);
		end

		vim.wo[markview.state.splitview_window].wrap = vim.wo[win].wrap;
		vim.wo[markview.state.splitview_window].linebreak = vim.wo[win].linebreak;

		---_
	end,

	--- Registers a buffer to be preview-able.
	---@param buffer integer?
	["attach"] = function (buffer, state)
		---+${lua}

		---@type integer
		buffer = buffer or vim.api.nvim_get_current_buf();

		if markview.can_attach(buffer) == false then
			--- Failed to attach.
			return;
		end

		---@type boolean Should preview be enabled on the buffer?
		local enable = spec.get({ "preview", "enable" }, { fallback = true, ignore_enable = true });
		---@type boolean Should hybrid mode be enabled on the buffer?
		local hm_enable = spec.get({ "preview", "enable_hybrid_mode" }, { fallback = true, ignore_enable = true });

		table.insert(markview.state.attached_buffers, buffer);

		if state then
			markview.state.buffer_states[buffer] = state;
		elseif markview.state.buffer_states[buffer] == nil then
			markview.state.buffer_states[buffer] = {
				enable = enable,
				events = true,
				hybrid_mode = hm_enable,
			};
		end

		vim.api.nvim_buf_set_keymap(buffer, "n", "gx", "<CMD>Markview open<CR>", { desc = "Tree-sitter based link opener from `markview.nvim`." });

		--- Execute the attaching autocmd.
		markview.actions.__exec_callback("on_attach", buffer, vim.fn.win_findbuf(buffer))
		--- Execute the autocmd too.
		vim.api.nvim_exec_autocmds("User", {
			pattern = "MarkviewAttach",
			data = {
				buffer = buffer,
				windows = vim.fn.win_findbuf(buffer)
			}
		});

		if enable == true then
			markview.actions.__exec_callback("on_enable", buffer, vim.fn.win_findbuf(buffer))
			markview.render(buffer);
		else
			markview.actions.__exec_callback("on_disable", buffer, vim.fn.win_findbuf(buffer))
			markview.clear(buffer);
		end

		--- Execute the enable/disable one too.
		vim.api.nvim_exec_autocmds("User", {
			pattern = enable == true and "MarkviewEnable" or "MarkviewDisable",
			data = {
				buffer = buffer,
				windows = vim.fn.win_findbuf(buffer)
			}
		});

		if enable == true then
			local mode = vim.api.nvim_get_mode().mode;
			---@type string[]
			local hybd_modes = spec.get({ "preview", "hybrid_modes" }, { fallback = {} });

			if hm == true and vim.list_contains(hybd_modes, mode) then
				--- Execute the attaching autocmd.
				markview.actions.__exec_callback("on_hybrid_enable", buffer, vim.fn.win_findbuf(buffer))
				--- Execute the autocmd too.
				vim.api.nvim_exec_autocmds("User", {
					pattern = "MarkviewHybridEnable",
					data = {
						buffer = buffer,
						windows = vim.fn.win_findbuf(buffer)
					}
				});
			else
				--- Execute the attaching autocmd.
				markview.actions.__exec_callback("on_hybrid_disable", buffer, vim.fn.win_findbuf(buffer))
				--- Execute the autocmd too.
				vim.api.nvim_exec_autocmds("User", {
					pattern = "MarkviewHybridDisable",
					data = {
						buffer = buffer,
						windows = vim.fn.win_findbuf(buffer)
					}
				});
			end

			markview.render(buffer);
		end
		---_
	end,
	--- Detaches previewer from a buffer.
	---@param buffer integer?
	["detach"] = function (buffer)
		---+${lua}

		---@type integer
		buffer = buffer or vim.api.nvim_get_current_buf();

		if markview.buf_is_safe(buffer) == false then
			--- Something went wrong.
			return;
		elseif markview.can_attach(buffer) == true then
			--- This buffer hasn't been attached to.
			return;
		end

		--- Execute the attaching autocmd.
		markview.actions.__exec_callback("on_detach", buffer, vim.fn.win_findbuf(buffer))
		--- Execute the autocmd too.
		vim.api.nvim_exec_autocmds("User", {
			pattern = "MarkviewDetach",
			data = {
				buffer = buffer,
				windows = vim.fn.win_findbuf(buffer)
			}
		});

		--- Remove the entry.
		--- DON'T REMOVE THE STATES THOUGH!
		--- (We may need them in the future)
		for i, buf in ipairs(markview.state.attached_buffers) do
			if buf == buffer then
				table.remove(markview.state.attached_buffers, i);
			end
		end

		--- Clear decorations too!
		markview.clear(buffer);
		---_
	end,

	["disable"] = function (buffer)
		---+${lua}
		---@type integer
		buffer = buffer or vim.api.nvim_get_current_buf();

		if markview.actions.__is_attached(buffer) == false then
			return;
		elseif type(markview.state.buffer_states[buffer]) ~= "table" then
			markview.state.buffer_states[buffer] = nil;
			return;
		end

		markview.state.buffer_states[buffer].enable = false;
		markview.clear(buffer);

		--- Execute the attaching autocmd.
		markview.actions.__exec_callback("on_disable", buffer, vim.fn.win_findbuf(buffer))
		--- Execute the autocmd too.
		vim.api.nvim_exec_autocmds("User", {
			pattern = "MarkviewDisable",
			data = {
				buffer = buffer,
				windows = vim.fn.win_findbuf(buffer)
			}
		});

		local mode = vim.api.nvim_get_mode().mode;
		---@type string[]
		local hybd_modes = spec.get({ "preview", "hybrid_modes" }, { fallback = {} });

		if vim.list_contains(hybd_modes, mode) == false then
			return;
		end

		--- Execute the attaching autocmd.
		markview.actions.__exec_callback("on_hybrid_disable", buffer, vim.fn.win_findbuf(buffer))
		--- Execute the autocmd too.
		vim.api.nvim_exec_autocmds("User", {
			pattern = "MarkviewHybridDisable",
			data = {
				buffer = buffer,
				windows = vim.fn.win_findbuf(buffer)
			}
		});
		---_
	end,
	["enable"] = function (buffer)
		---+${lua}
		---@type integer
		buffer = buffer or vim.api.nvim_get_current_buf();

		if markview.actions.__is_attached(buffer) == false then
			return;
		elseif type(markview.state.buffer_states[buffer]) ~= "table" then
			markview.state.buffer_states[buffer] = nil;
			return;
		end

		markview.state.buffer_states[buffer].enable = true;

		local mode = vim.api.nvim_get_mode().mode;
		---@type string[]
		local prev_modes = spec.get({ "preview", "modes" }, { fallback = {} });
		---@type string[]
		local hybd_modes = spec.get({ "preview", "hybrid_modes" }, { fallback = {} });

		if vim.list_contains(prev_modes, mode) == false then
			return;
		end

		markview.render(buffer);

		--- Execute the attaching autocmd.
		markview.actions.__exec_callback("on_enable", buffer, vim.fn.win_findbuf(buffer))
		--- Execute the autocmd too.
		vim.api.nvim_exec_autocmds("User", {
			pattern = "MarkviewEnable",
			data = {
				buffer = buffer,
				windows = vim.fn.win_findbuf(buffer)
			}
		});

		if vim.list_contains(hybd_modes, mode) == false then
			return;
		end

		--- Execute the attaching autocmd.
		markview.actions.__exec_callback("on_hybrid_enable", buffer, vim.fn.win_findbuf(buffer))
		--- Execute the autocmd too.
		vim.api.nvim_exec_autocmds("User", {
			pattern = "MarkviewHybridEnable",
			data = {
				buffer = buffer,
				windows = vim.fn.win_findbuf(buffer)
			}
		});
		---_
	end,

	["hybridEnable"] = function (buffer)
		---+${lua}

		buffer = buffer or vim.api.nvim_get_current_buf();

		if markview.actions.__is_attached(buffer) == false then
			return;
		elseif markview.state.buffer_states[buffer] then
			markview.state.buffer_states[buffer].hybrid_mode = true;

			if markview.state.buffer_states[buffer].enable == false then
				return;
			elseif buffer == markview.state.splitview_source then
				return;
			end

			markview.render(buffer);

			local mode = vim.api.nvim_get_mode().mode;
			---@type string[]
			local hybd_modes = spec.get({ "preview", "hybrid_modes" }, { fallback = {} });

			if vim.list_contains(hybd_modes, mode) == false then
				return;
			end

			--- Execute the attaching autocmd.
			markview.actions.__exec_callback("on_hybrid_enable", buffer, vim.fn.win_findbuf(buffer))
			--- Execute the autocmd too.
			vim.api.nvim_exec_autocmds("User", {
				pattern = "MarkviewHybridEnable",
				data = {
					buffer = buffer,
					windows = vim.fn.win_findbuf(buffer)
				}
			});
		end

		---_
	end,

	["hybridDisable"] = function (buffer)
		--+${lua}

		buffer = buffer or vim.api.nvim_get_current_buf();

		if markview.actions.__is_attached(buffer) == false then
			return;
		elseif markview.state.buffer_states[buffer] then
			markview.state.buffer_states[buffer].hybrid_mode = false;

			if markview.state.buffer_states[buffer].enable == false then
				return;
			elseif buffer == markview.state.splitview_source then
				return;
			end

			markview.render(buffer);

			local mode = vim.api.nvim_get_mode().mode;
			---@type string[]
			local hybd_modes = spec.get({ "preview", "hybrid_modes" }, { fallback = {} });

			if vim.list_contains(hybd_modes, mode) == false then
				return;
			end

			--- Execute the attaching autocmd.
			markview.actions.__exec_callback("on_hybrid_disable", buffer, vim.fn.win_findbuf(buffer))
			--- Execute the autocmd too.
			vim.api.nvim_exec_autocmds("User", {
				pattern = "MarkviewHybridDisable",
				data = {
					buffer = buffer,
					windows = vim.fn.win_findbuf(buffer)
				}
			});
		end

		---_
	end,

	["splitOpen"] = function (buffer)
		--++${lua}

		---@type integer
		buffer = buffer or vim.api.nvim_get_current_buf();

		if markview.buf_is_safe(buffer) == false then
			return;
		end

		markview.actions.splitClose();

		if markview.actions.__is_enabled(buffer) == true then
			markview.actions.__exec_callback("on_disable", buffer, vim.fn.win_findbuf(buffer));
			vim.api.nvim_exec_autocmds("User", {
				pattern = "MarkviewDisable",
				data = {
					buffer = buffer,
					windows = vim.fn.win_findbuf(buffer)
				}
			});
		end

		markview.state.splitview_source = buffer;
		markview.actions.__splitview_setup();
		markview.clear(buffer);

		markview.actions.__exec_callback("on_splitview_open", buffer, markview.state.splitview_buffer, markview.state.splitview_window);
		vim.api.nvim_exec_autocmds("User", {
			pattern = "MarkviewSplitviewOpen",
			data = {
				source = buffer,
				preview_buffer = markview.state.splitview_buffer,
				preview_window = markview.state.splitview_window
			}
		});

		markview.splitview_render();
		---_
	end,
	["splitClose"] = function ()
		---+${lua}
		if type(markview.state.splitview_source) ~= "number" then
			--- Splitview's source buffer isn't a number. Why?
			--- Assuming it's `nil`, we should stop here.
			return;
		end

		--- FEAT, Allow `on_splitview_close` to take arguments
		--- regarding splitview.
		markview.actions.__exec_callback("on_splitview_close", buffer, markview.state.splitview_buffer, markview.state.splitview_window);
		vim.api.nvim_exec_autocmds("User", {
			pattern = "MarkviewSplitviewClose",
			data = {
				source = markview.state.splitview_source,
				preview_buffer = markview.state.splitview_buffer,
				preview_window = markview.state.splitview_window
			}
		});

		--- Attempt to close the window.
		--- Also remove the reference to that window.
		pcall(vim.api.nvim_win_close, markview.state.splitview_window, true);
		markview.state.splitview_window = nil;

		--- We should also clean up the preview buffer(if possible).
		if markview.buf_is_safe(markview.state.splitview_buffer) == true then
			markview.clear(markview.state.splitview_buffer);
			vim.api.nvim_buf_set_lines(markview.state.splitview_buffer, 0, -1, false, {});
		end

		---@type integer
		local buffer = markview.state.splitview_source;
		markview.state.splitview_source = nil;

		if markview.buf_is_safe(buffer) == false then
			--- Source buffer isn't safe for `markview` to work.
			return;
		elseif type(markview.state.buffer_states[buffer]) ~= "table" then
			--- We never attached to the source buffer.
			return;
		end

		markview.actions.__exec_callback("on_enable", buffer, vim.fn.win_findbuf(buffer));
		vim.api.nvim_exec_autocmds("User", {
			pattern = "MarkviewEnable",
			data = {
				buffer = buffer,
				windows = vim.fn.win_findbuf(buffer)
			}
		});

		--- Don't forget to render the preview if possible.
		if markview.state.buffer_states[buffer].enable == true then
			markview.render(buffer);
		end
		---_
	end

	---_
};

--- Holds various functions that you can run
--- vim `:Markview ...`.
---@type { [string]: function }
markview.commands = {
	---+${class}
	["attach"] = function (buffer)
		markview.actions.attach(buffer);
	end,
	["detach"] = function (buffer)
		markview.actions.detach(buffer);
	end,

	["Toggle"] = function ()
		---+${class}
		markview.clean();

		for _, buf in ipairs(markview.state.attached_buffers) do
			markview.commands.toggle(buf);
		end
		---_
	end,
	["Enable"] = function ()
		markview.clean();

		for _, buf in ipairs(markview.state.attached_buffers) do
			markview.actions.enable(buf);
		end
	end,
	["Disable"] = function ()
		markview.clean();

		for _, buf in ipairs(markview.state.attached_buffers) do
			markview.actions.disable(buf);
		end
	end,

	["Render"] = function ()
		markview.clean();

		for _, buf in ipairs(markview.state.attached_buffers) do
			if markview.actions.__is_enabled(buf) then
				markview.render(buf);
			end
		end
	end,
	["Clear"] = function ()
		markview.clean();

		for _, buf in ipairs(markview.state.attached_buffers) do
			if markview.actions.__is_enabled(buf) then
				markview.clear(buf);
			end
		end
	end,

	["render"] = function (buffer)
		markview.clean();
		buffer = buffer or vim.api.nvim_get_current_buf();

		markview.render(buffer);
	end,
	["clear"] = function (buffer)
		markview.clean();
		buffer = buffer or vim.api.nvim_get_current_buf();

		markview.clear(buffer);
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
		markview.clean();

		local state = markview.state.buffer_states[buffer];

		if state == nil then
			return;
		elseif state.enable == true then
			markview.commands.disable(buffer);
		else
			markview.commands.enable(buffer);
		end
		---_
	end,
	["enable"] = function (buffer)
		markview.actions.enable(buffer)
	end,
	["disable"] = function (buffer)
		markview.actions.disable(buffer)
	end,

	["hybridToggle"] = function (buffer)
		buffer = buffer or vim.api.nvim_get_current_buf();

		if markview.actions.__is_attached(buffer) == false then
			return;
		elseif type(markview.state.buffer_states[buffer]) ~= "table" then
			return;
		elseif markview.state.buffer_states[buffer].hybrid_mode == true then
			markview.actions.hybridDisable(buffer);
		else
			markview.actions.hybridEnable(buffer);
		end
	end,
	["hybridDisable"] = function (buffer)
		markview.actions.hybridDisable(buffer);
	end,
	["hybridEnable"] = function (buffer)
		markview.actions.hybridEnable(buffer);
	end,

	["HybridToggle"] = function ()
		markview.clean();

		for _, buf in ipairs(markview.state.attached_buffers) do
			markview.commands.hybridToggle(buf);
		end
	end,

	["HybridDisable"] = function ()
		markview.clean();

		for _, buf in ipairs(markview.state.attached_buffers) do
			markview.commands.hybridDisable(buf);
		end
	end,

	["HybridEnable"] = function ()
		markview.clean();

		for _, buf in ipairs(markview.state.attached_buffers) do
			markview.commands.hybridEnable(buf);
		end
	end,

	["splitToggle"] = function ()
		---+${class}

		if type(markview.state.splitview_source) ~= "number" then
			markview.actions.splitOpen();
		elseif markview.win_is_safe(markview.state.splitview_window) == false then
			markview.actions.splitClose();
			markview.actions.splitOpen();
		else
			markview.actions.splitClose();
		end
		---_
	end,

	["splitRedraw"] = function ()
		markview.splitview_render();
	end,

	["splitOpen"] = function (buffer)
		markview.actions.splitOpen(buffer)
	end,

	["splitClose"] = function ()
		markview.actions.splitClose()
	end,

	["open"] = function ()
		require("markview.links").open();
	end
	---_
};

 ------------------------------------------------------------------------------------------

--- Plugin setup function(optional)
---@param config table?
markview.setup = function (config)
	local highlights = require("markview.highlights");

	spec.setup(config);
	highlights.setup(spec.get({ "highlight_groups" }, { fallback = {} }));
	markview.commands.Render();
end

return markview;
