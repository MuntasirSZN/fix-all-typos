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
	attached_buffers = {},
	ignore_modes = {},

	buffer_states = {},
	hybrid_states = {},

	splitview_source = nil,
	splitview_buffer = vim.api.nvim_create_buf(false, true),
	splitview_window = nil
};

--- Checks if a buffer is already attached.
---@param buffer integer
local buf_attached = function (buffer)
	return vim.list_contains(markview.state.attached_buffers, buffer);
end

---@type integer Autocmd group ID.
markview.augroup = vim.api.nvim_create_augroup("markview", { clear = true });

--- Cleans up invalid buffers.
markview.clean = function ()
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
	for buffer, _ in pairs(markview.state.autocmds) do
		if should_clean(buffer) == true then
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
---@param window integer
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
	if markview.buf_is_safe(buffer) == false then
		markview.clean();
		return;
	end

	local line_limit = spec.get({ "preview", "max_file_length" }, { fallback = 1000, ignore_enable = true });
	local draw_range = spec.get({ "preview", "render_distance" }, { fallback = vim.o.lines, ignore_enable = true });
	local edit_range = spec.get({ "preview", "edit_distance" }, { fallback = { 1, 0 }, ignore_enable = true });

	local line_count = vim.api.nvim_buf_line_count(buffer);

	local preview_modes = spec.get({ "preview", "modes" }, { fallback = {}, ignore_enable = true });
	local hybrid_modes = spec.get({ "preview", "hybrid_modes" }, { fallback = {}, ignore_enable = true });
	local linewise_hybrid_mode = spec.get({ "preview", "linewise_hybrid_mode" }, { fallback = false, ignore_enable = true })

	local mode = vim.api.nvim_get_mode().mode;

	if
		ignore_modes ~= true and
		not vim.list_contains(preview_modes, mode)
	then
		return;
	end

	local parser = require("markview.parser");
	local renderer = require("markview.renderer");

	markview.clear(buffer);

	if line_count <= line_limit then
		local content = parser.parse(buffer, 0, -1, true);
		renderer.render(buffer, content);
	else
		for _, window in ipairs(vim.fn.win_findbuf(buffer)) do
			local cursor = vim.api.nvim_win_get_cursor(window);

			local content = parser.init(
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
		local clear_from, clear_to;

		if linewise_hybrid_mode == false then
			local hidden_content = parser.init(
				buffer,
				math.max(0, cursor[1] - edit_range[1]),
				math.min(
					vim.api.nvim_buf_line_count(buffer),
					cursor[1] + edit_range[2]
				),
				false
			);

			clear_from, clear_to = renderer.range(hidden_content);
		else
			clear_from = cursor[1] - edit_range[1];
			clear_to = cursor[1] + edit_range[2];
		end

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

--- Wrapper to clear decorations from a buffer
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
	["attach"] = function (buffer, ignore_modes)
		---+${class}
		buffer = buffer or vim.api.nvim_get_current_buf();

		if not markview.can_attach(buffer) then return; end
		local initial_state = spec.get({ "preview", "enable" }, { fallback = true });

		if buf_attached(buffer) then
			return;
		elseif ignore_modes == true then
			table.insert(markview.state.ignore_modes, buffer);
		end

		table.insert(markview.state.attached_buffers, buffer);
		markview.state.buffer_states[buffer] = initial_state;

		local call;

		if initial_state == true then
			markview.draw(buffer);
			call = spec.get({ "preview", "callbacks", "on_attach" }, { fallback = nil, ignore_enable = true });
		else
			markview.clear(buffer);
			call = spec.get({ "preview", "callbacks", "on_detach" }, { fallback = nil, ignore_enable = true });
		end

		--- Run the callback function.
		if call and pcall(call, buffer, vim.fn.win_findbuf(buffer)) then call(buffer, vim.fn.win_findbuf(buffer)); end

		--- Execute the autocmd.
		vim.api.nvim_exec_autocmds("User", {
			pattern = initial_state == true and "MarkviewAttach" or "MarkviewDetach",
			data = {
				buffer = buffer,
				windows = vim.fn.win_findbuf(buffer)
			}
		});

		markview.draw(buffer, ignore_modes ~= nil);
		---_
	end,
	["detach"] = function (buffer)
		---+${class}
		buffer = buffer or vim.api.nvim_get_current_buf();
		local call = spec.get({ "preview", "callbacks", "on_detach" }, { fallback = nil, ignore_enable = true });

		markview.clear(buffer);

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
			if markview.can_draw(buf) then
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
			if markview.buf_is_safe(buf) then
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
	["Redraw"] = function ()
		for _, buf in ipairs(vim.tbl_keys(markview.state.buffer_states)) do
			if markview.buf_is_safe(buf) then
				markview.draw(buf, true);
			end
		end
	end,
	["Clear"] = function ()
		for _, buf in ipairs(vim.tbl_keys(markview.state.buffer_states)) do
			if markview.buf_is_safe(buf) then
				markview.clear(buf);
			end
		end
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
		elseif markview.buf_is_safe(buffer) == false then
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
		elseif markview.buf_is_safe(buffer) == false then
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
	["redraw"] = function (buffer)
		buffer = buffer or vim.api.nvim_get_current_buf();

		if markview.buf_is_safe(buffer) then
			markview.draw(buffer, true);
		end
	end,
	["clear"] = function (buffer)
		buffer = buffer or vim.api.nvim_get_current_buf();

		if markview.buf_is_safe(buffer) then
			markview.clear(buffer);
		end
	end,

	["splitToggle"] = function ()
		---+${class}
		if
			( --- Source buffer doesn't exist or is invalid.
				markview.state.splitview_source == nil or
				markview.buf_is_safe(markview.state.splitview_source) == false
			) or
			( --- Preview buffer doesn't exist or is invalid.
				markview.state.splitview_buffer == nil or
				markview.buf_is_safe(markview.state.splitview_buffer) == false
			)
		then
			--- Close any open previews.
			--- Open a new preview.
			markview.commands.splitClose();
			markview.commands.splitOpen();
		elseif --- Preview window doesn't exist or is invalid.
			markview.state.splitview_window == nil or
			markview.win_is_safe(markview.state.splitview_window) == false
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
			markview.buf_is_safe(markview.state.splitview_source) == false
		then
			markview.commands.splitClose();
			return;
		elseif markview.buf_is_safe(markview.state.splitview_buffer) == false then
			markview.commands.splitClose();
			return;
		elseif markview.win_is_safe(markview.state.splitview_window) == false then
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

		if markview.buf_is_safe(buffer) == false then
			return;
		end

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

		markview.state.splitview_source = buffer;
		markview.state.buffer_states[markview.state.splitview_source] = false;
		markview.clear(markview.state.splitview_source)

		local ft = vim.bo[buffer].filetype;

		if markview.buf_is_safe(markview.state.splitview_buffer) == false then
			markview.state.splitview_buffer = vim.api.nvim_create_buf(false, true);
		end

		markview.state.hybrid_states[markview.state.splitview_buffer] = false;
		vim.bo[markview.state.splitview_buffer].filetype = ft;

		local buf_lines = vim.api.nvim_buf_get_lines(markview.state.splitview_source, 0, -1, false)

		vim.api.nvim_buf_set_lines(
			markview.state.splitview_buffer,
			0,
			-1,
			false,
			buf_lines
		);

		if markview.win_is_safe(markview.state.splitview_window) == false then
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

			markview.draw(buffer)

		--- Run the callback.
		local call = spec.get({ "preview", "callbacks", "splitview_close" }, { fallback = nil, ignore_enable = true });
		if call and pcall(call) then call(); end

		vim.api.nvim_exec_autocmds("User", { pattern = "MarkviewSplitviewClose" });

		--- If the buffer was never attached to then
		--- return.
		if markview.state.buffer_states[buffer] == nil then
			return;
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

markview.__completion = {
	default = {
		completion = function (arg_lead)
			local comp = {};

			for _, item in ipairs(vim.tbl_keys(markview.commands)) do
				if item:match(arg_lead) then
					table.insert(comp, item);
				end
			end

			table.sort(comp);
			return comp;
		end,
		action = function ()
			print("hi")
		end
	},
	sub_commands = {
		["Disable"] = {
			action = function ()
				print("hi")
			end
		},
		["Enable"] = {
			action = function ()
				print("hi")
			end
		},
		["Toggle"] = {
			action = function ()
				print("hi")
			end
		},

		["disable"] = {
			completion = function (arg_lead)
				local cmp = {};

				for buf, state in pairs(markview.state.buffer_states) do
					if state == true and tostring(buf):match(arg_lead) then
						table.insert(cmp, tostring(buf));
					end
				end

				return cmp;
			end,
			action = function ()
				print("hi")
			end
		},
		["enable"] = {
			completion = function (arg_lead)
				local cmp = {};

				for buf, state in pairs(markview.state.buffer_states) do
					if state == false and tostring(buf):match(arg_lead) then
						table.insert(cmp, tostring(buf));
					end
				end

				return cmp;
			end,
			action = function ()
				print("hi")
			end
		},
		["toggle"] = {
			completion = function (arg_lead)
				local cmp = {};

				for buf, _ in pairs(markview.state.buffer_states) do
					if tostring(buf):match(arg_lead) then
						table.insert(cmp, tostring(buf));
					end
				end

				return cmp;
			end,
			action = function ()
				print("hi")
			end
		},
	}
};

--- Cmdline completion.
---@param arg_lead string
---@param cmdline string
---@param cursor_pos integer
---@return string[]?
markview.completion = function (arg_lead, cmdline, cursor_pos)
	---+${class, Completion provider}
	local is_subcommand = function (text)
		local cmds = vim.tbl_keys(markview.commands);
		return vim.list_contains(cmds, text);
	end

	local matches_subcommand = function (text)
		if is_subcommand(text) then
			return false;
		end

		for key, _ in pairs(markview.commands) do
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
		if arg == "Markview" then goto continue; end

		nargs = nargs + 1;
		table.insert(args, arg);

		::continue::
	end

	local config;

	if nargs == 0 or (nargs == 1 and matches_subcommand(args[1])) then
		config = markview.__completion.default;
	elseif is_subcommand(args[1]) and markview.__completion.sub_commands[args[1]] then
		config = markview.__completion.sub_commands[args[1]];
	else
		return {};
	end

	if vim.islist(config.completion) then
		return config.completion --[[ @as string[] ]];
	elseif pcall(config.completion, arg_lead, cmdline, cursor_pos) then
		---@type string[]
		local val = config.completion(arg_lead, cmdline, cursor_pos);
		return val;
	end
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
