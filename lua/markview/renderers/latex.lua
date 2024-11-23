local latex = {};

local symbols = require("markview.symbols");
local spec = require("markview.spec");
local utils = require("markview.utils");

latex.cache = {
	font_regions = {},
	style_regions = {
		superscripts = {},
		subscripts = {}
	},
};

latex.__ns = {
	__call = function (self, key)
		return self[key] or self.default;
	end
}

latex.ns = {
	default = vim.api.nvim_create_namespace("markview/latex"),
};
setmetatable(latex.ns, latex.__ns)

latex.set_ns = function ()
	local ns_pref = spec.get({ "latex", "use_seperate_ns" }, { fallback = true });
	if not ns_pref then ns_pref = true; end

	local available = vim.api.nvim_get_namespaces();
	local ns_list = {
		["parenthesis"] = "markview/latex/parenthesis",
		["commands"] = "markview/latex/commands",
		["styles"] = "markview/latex/styles",
		["fonts"] = "markview/latex/fonts",
		["injections"] = "markview/latex/injections",
		["symbols"] = "markview/latex/symbols",
	};

	if ns_pref == true then
		for ns, name in pairs(ns_list) do
			if vim.list_contains(available, ns) == false then
				latex.ns[ns] = vim.api.nvim_create_namespace(name);
			end
		end
	end
end

latex.custom_config = function (config, value)
	if not config.custom or not value then
		return config;
	end

	for _, custom in ipairs(config.custom) do
		if custom.match_string and value:match(custom.match_string) then
			return vim.tbl_deep_extend("force", config, custom);
		end
	end

	return config;
end

---@param buffer integer
---@param item __latex.block
latex.block = function (buffer, item)
	---+${func}
	local range = item.range;

	if item.inline then
		local config = spec.get({ "latex", "inlines" }, { fallback = nil });
		if not config then return; end

		config = utils.tostatic(
			config,
			{
				args = { buffer, item }
			}
		);

		vim.api.nvim_buf_set_extmark(buffer, latex.ns("injections"), range.row_start, range.col_start, {
			undo_restore = false, invalidate = true,
			end_col = range.col_start + 2,
			conceal = "",

			virt_text_pos = "inline",
			virt_text = {
				{ config.corner_left or "", utils.set_hl(config.corner_left_hl or config.hl) },
				{ config.padding_left or "", utils.set_hl(config.padding_left_hl or config.hl) },
			},

			hl_mode = "combine"
		});

		vim.api.nvim_buf_set_extmark(buffer, latex.ns("injections"), range.row_start, range.col_start + #item.text[1], {
			undo_restore = false, invalidate = true,

			virt_text_pos = "inline",
			virt_text = {
				{ config.padding_right or "", utils.set_hl(config.padding_right_hl or config.hl) }
			}
		});

		vim.api.nvim_buf_set_extmark(buffer, latex.ns("injections"), range.row_start, range.col_start, {
			undo_restore = false, invalidate = true,
			end_row = range.row_end,
			end_col = range.col_end,

			hl_group = utils.set_hl(config.hl),
		});

		vim.api.nvim_buf_set_extmark(buffer, latex.ns("injections"), range.row_end, range.col_end - (item.closed and 2 or 0), {
			undo_restore = false, invalidate = true,
			end_col = range.col_end,
			conceal = "",

			virt_text_pos = "inline",
			virt_text = {
				{ config.padding_right or "", utils.set_hl(config.padding_right_hl or config.hl) },
				{ config.corner_right or "", utils.set_hl(config.corner_right_hl or config.hl) },
			},

			hl_mode = "combine"
		});

		vim.api.nvim_buf_set_extmark(buffer, latex.ns("injections"), range.row_end, 0, {
			undo_restore = false, invalidate = true,

			virt_text_pos = "inline",
			virt_text = {
				{ config.padding_left or "", utils.set_hl(config.padding_left_hl or config.hl) },
			}
		});

		for l = 1, #item.text - 2 do
			vim.api.nvim_buf_set_extmark(buffer, latex.ns("injections"), range.row_start + l, math.min(#item.text[l + 1], 0), {
				undo_restore = false, invalidate = true,

				virt_text_pos = "inline",
				virt_text = {
					{ config.padding_left or "", utils.set_hl(config.padding_left_hl or config.hl) },
				}
			});

			vim.api.nvim_buf_set_extmark(buffer, latex.ns("injections"), range.row_start + l, #item.text[l + 1], {
				undo_restore = false, invalidate = true,

				virt_text_pos = "inline",
				virt_text = {
					{ config.padding_right or "", utils.set_hl(config.padding_right_hl or config.hl) }
				}
			});
		end
	else
		---@type latex.blocks?
		local config = spec.get({ "latex", "blocks" }, { fallback = nil });
		if not config then return; end

		config = utils.tostatic(
			config,
			{
				args = { buffer, item }
			}
		);

		vim.api.nvim_buf_set_extmark(buffer, latex.ns("injections"), range.row_start, range.col_start, {
			undo_restore = false, invalidate = true,
			end_col = range.col_start + 2,
			conceal = "",

			virt_text_pos = "right_align",
			virt_text = { { config.text or "", utils.set_hl(config.text_hl or config.hl) } },

			hl_mode = "combine",
			line_hl_group = utils.set_hl(config.hl)
		});

		vim.api.nvim_buf_set_extmark(buffer, latex.ns("injections"), range.row_end, math.max(0, range.col_end - 2), {
			undo_restore = false, invalidate = true,
			end_col = range.col_end,
			conceal = "",

			line_hl_group = utils.set_hl(config.hl)
		});

		for l = 1, #item.text - 2 do
			vim.api.nvim_buf_set_extmark(buffer, latex.ns("injections"), range.row_start + l, math.min(#item.text[l + 1], range.col_start), {
				undo_restore = false, invalidate = true,

				virt_text_pos = "inline",
				virt_text = {
					{ string.rep(config.pad_char or "", config.pad_amount or 0), utils.set_hl(config.hl) }
				},

				line_hl_group = utils.set_hl(config.hl)
			});
		end
	end
	---_
end

---@param buffer integer
---@param item __latex.command
latex.command = function (buffer, item)
	--+${func}

	---@type latex.commands?
	local main_config = spec.get({ "latex", "commands" }, { fallback = nil });

	if not main_config then
		return;
	elseif not spec.get({ item.command.name }, { source = main_config }) then
		return;
	end

	---@type command.opts
	local config = spec.get({ item.command.name }, { source = main_config });

	if
		spec.get({ "condition" }, { source = config, args = { item } }) == false
	then
		return;
	end

	if config.on_command then
		local range = item.command.range;
		local extmark = spec.get({ "on_command" }, { source = config, args = { item.command } });

		if not extmark then
			goto invalid_extmark;
		end

		if pcall(config.command_offset, range) then range = config.command_offset(range) end

		vim.api.nvim_buf_set_extmark(buffer, latex.ns("commands"), range[1], range[2], vim.tbl_extend("force", {
			undo_restore = false, invalidate = true,
			end_row = range[3],
			end_col = range[4]
		}, extmark));

		::invalid_extmark::
	end

	if not config.on_args then return; end

	local on_args = spec.get({ "on_args" }, { source = config, args = { item.command } });

	for a, arg in ipairs(item.args) do
		if not on_args[a] then
			goto continue;
		end

		---@type command.arg_opts
		local arg_conf = on_args[a];

		if arg_conf.before then
			local b_conf = spec.get({ "before" }, { source = arg_conf, fallback = {}, args = { arg } });
			local range = arg.range;

			if pcall(arg_conf.before_offset, range) then range = arg_conf.before_offset(range) end

			vim.api.nvim_buf_set_extmark(buffer, latex.ns("commands"), range[1], range[2], vim.tbl_extend("force", {
				undo_restore = false, invalidate = true,
			}, b_conf));
		end

		if arg_conf.content then
			local c_conf = spec.get({ "content" }, { source = arg_conf, fallback = {}, args = { arg } });
			local range = arg.range;

			if pcall(arg_conf.content_offset, range) then range = arg_conf.content_offset(range) end

			vim.api.nvim_buf_set_extmark(buffer, latex.ns("commands"), range[1], range[2], vim.tbl_extend("force", {
				undo_restore = false, invalidate = true,
				end_row = arg.range[3],
				end_col = arg.range[4]
			}, c_conf));
		end

		if arg_conf.after then
			local a_conf = spec.get({ "after" }, { source = arg_conf, fallback = {}, args = { arg } });
			local range = arg.range;

			if pcall(arg_conf.after_offset, range) then range = arg_conf.after_offset(range) end

			vim.api.nvim_buf_set_extmark(buffer, latex.ns("commands"), range[3], range[4], vim.tbl_extend("force", {
				undo_restore = false, invalidate = true,
			}, a_conf));
		end

	    ::continue::
	end
	---_
end

---@param buffer integer
---@param item __latex.escaped
latex.escaped = function (buffer, item)
	---+${func}

	---@type latex.escapes?
	local config = spec.get({ "latex", "escapes" }, { fallback = nil });

	if not config then
		return;
	end

	local range = item.range;

	vim.api.nvim_buf_set_extmark(buffer, latex.ns("symbols"), range.row_start, range.col_start, {
		undo_restore = false, invalidate = true,
		end_col = range.col_start + 1,
		conceal = ""
	});

	config = utils.tostatic(
		config,
		{
			args = { buffer, item }
		}
	);

	if not config.hl then
		return;
	end

	vim.api.nvim_buf_set_extmark(buffer, latex.ns("symbols"), range.row_start, range.col_start, {
		undo_restore = false, invalidate = true,
		end_row = range.row_end,
		end_col = range.col_end,

		hl_group = utils.set_hl(
			spec.get({ "hl" }, { source = config, fallback = nil, args = { buffer, item }
		}))
	});
	---_
end

---@param buffer integer
---@param item __latex.font
latex.font = function (buffer, item)
	---+${func}

	---@type latex.fonts?
	local config = spec.get({ "latex", "fonts" }, { fallback = nil });

	if not config then
		return;
	elseif
		not symbols.fonts[item.name] or
		spec.get({ "latex", "fonts", item.name, "enable" }, { fallback = true }) == false
	then
		return;
	end

	local range = item.range;
	table.insert(latex.cache.font_regions, vim.tbl_extend("force", item.range, { name = item.name }));

	vim.api.nvim_buf_set_extmark(buffer, latex.ns("fonts"), range.row_start, range.col_start, {
		undo_restore = false, invalidate = true,
		end_col = math.min(#item.text[1], range.font_end + 1),
		conceal = "",
	});

	vim.api.nvim_buf_set_extmark(buffer, latex.ns("fonts"), range.row_end, range.col_end - 1, {
		undo_restore = false, invalidate = true,
		end_col = range.col_end,
		conceal = "",
	});
	---_
end

---@param buffer integer
---@param item __latex.inline
latex.inline = function (buffer, item)
	---+${func}

	---@type latex.inlines?
	local config = spec.get({ "latex", "inlines" }, { fallback = nil });
	local range = item.range;

	if not config then
		return;
	end

	config = utils.tostatic(
		config,
		{
			args = { buffer, item }
		}
	);

	vim.api.nvim_buf_set_extmark(buffer, latex.ns("injections"), range.row_start, range.col_start, {
		undo_restore = false, invalidate = true,
		end_col = range.col_start + 1,
		conceal = "",

		virt_text_pos = "inline",
		virt_text = {
			{ config.corner_left or "", utils.set_hl(config.corner_left_hl or config.hl) },
			{ config.padding_left or "", utils.set_hl(config.padding_left_hl or config.hl) },
		},

		hl_mode = "combine"
	});

	if #item.text > 1 then
		vim.api.nvim_buf_set_extmark(buffer, latex.ns("injections"), range.row_start, range.col_start + #item.text[1], {
			undo_restore = false, invalidate = true,

			virt_text_pos = "inline",
			virt_text = {
				{ config.padding_right or "", utils.set_hl(config.padding_right_hl or config.hl) }
			}
		});
	end

	vim.api.nvim_buf_set_extmark(buffer, latex.ns("injections"), range.row_start, range.col_start, {
		undo_restore = false, invalidate = true,
		end_row = range.row_end,
		end_col = range.col_end,

		hl_group = utils.set_hl(config.hl),
	});

	vim.api.nvim_buf_set_extmark(buffer, latex.ns("injections"), range.row_end, range.col_end - (item.closed and 1 or 0), {
		undo_restore = false, invalidate = true,
		end_col = range.col_end,
		conceal = "",

		virt_text_pos = "inline",
		virt_text = {
			{ config.padding_right or "", utils.set_hl(config.padding_right_hl or config.hl) },
			{ config.corner_right or "", utils.set_hl(config.corner_right_hl or config.hl) },
		},

		hl_mode = "combine"
	});

	if #item.text > 1 then
		vim.api.nvim_buf_set_extmark(buffer, latex.ns("injections"), range.row_end, 0, {
			undo_restore = false, invalidate = true,

			virt_text_pos = "inline",
			virt_text = {
				{ config.padding_left or "", utils.set_hl(config.padding_left_hl or config.hl) },
			}
		});
	end

	for l = 1, #item.text - 2 do
		vim.api.nvim_buf_set_extmark(buffer, latex.ns("injections"), range.row_start + l, 0, {
			undo_restore = false, invalidate = true,

			virt_text_pos = "inline",
			virt_text = {
				{ config.padding_left or "", utils.set_hl(config.padding_left_hl or config.hl) },
			}
		});

		vim.api.nvim_buf_set_extmark(buffer, latex.ns("injections"), range.row_start + l, #item.text[l + 1], {
			undo_restore = false, invalidate = true,

			virt_text_pos = "inline",
			virt_text = {
				{ config.padding_right or "", utils.set_hl(config.padding_right_hl or config.hl) }
			}
		});
	end
	---_
end

---@param buffer integer
---@param item __latex.parenthesis
latex.parenthesis = function (buffer, item)
	---+${func}

	---@type latex.parenthesis?
	local config = spec.get({ "latex", "parenthesis" }, { fallback = nil });

	if not config then
		return;
	end

	local range = item.range;

	--- Left parenthesis
	vim.api.nvim_buf_set_extmark(buffer, latex.ns("parenthesis"), range.row_start, range.col_start, {
		undo_restore = false, invalidate = true,
		end_col = range.col_start + 1,
		conceal = ""
	});

	--- Right parenthesis
	vim.api.nvim_buf_set_extmark(buffer, latex.ns("parenthesis"), range.row_end, range.col_end - 1, {
		undo_restore = false, invalidate = true,
		end_col = range.col_end,
		conceal = ""
	});
	---_
end

---@param buffer integer
---@param item __latex.style
latex.subscript = function (buffer, item)
	---+${func}

	---@type latex.styles?
	local config = spec.get({ "latex", "subscripts" }, { fallback = nil });

	if not config then
		return;
	end

	config = utils.tostatic(
		config,
		{
			args = { buffer, item }
		}
	);

	local range = item.range;

	vim.api.nvim_buf_set_extmark(buffer, latex.ns("specials"), range.row_start, range.col_start, {
		undo_restore = false, invalidate = true,
		end_col = range.col_start + (item.parenthesis and 2 or 1),
		conceal = "",

		virt_text_pos = "inline",
		virt_text = item.preview == false and { { "↓(", utils.set_hl(config.hl) } } or nil,

		hl_mode = "combine"
	});

	if item.parenthesis then
		if item.preview then
			table.insert(latex.cache.style_regions.subscripts, item.range);
		else
			vim.api.nvim_buf_set_extmark(buffer, latex.ns("specials"), range.row_start, range.col_start, {
				undo_restore = false, invalidate = true,
				end_row = range.row_end,
				end_col = range.col_end,

				hl_group = utils.set_hl(config.hl)
			});
		end

		vim.api.nvim_buf_set_extmark(buffer, latex.ns("specials"), range.row_end, range.col_end - 1, {
			undo_restore = false, invalidate = true,
			end_col = range.col_end,
			conceal = "",

			virt_text_pos = "inline",
			virt_text = item.preview == false and { { ")", utils.set_hl(config.hl) } } or nil,

			hl_mode = "combine"
		});
	elseif symbols.subscripts[item.text[1]:sub(2)] then
		vim.api.nvim_buf_set_extmark(buffer, latex.ns("specials"), range.row_start, range.col_start + 1, {
			undo_restore = false, invalidate = true,
			virt_text_pos = "overlay",
			virt_text = { { symbols.subscripts[item.text[1]:sub(2)], utils.set_hl(config.hl) } },

			hl_mode = "combine"
		});
	end
	---_
end

---@param buffer integer
---@param item __latex.style
latex.superscript = function (buffer, item)
	---+${func}

	---@type latex.styles?
	local config = spec.get({ "latex", "superscripts" }, { fallback = nil });

	if not config then
		return;
	end

	config = utils.tostatic(
		config,
		{
			args = { buffer, item }
		}
	);

	local range = item.range;

	vim.api.nvim_buf_set_extmark(buffer, latex.ns("specials"), range.row_start, range.col_start, {
		undo_restore = false, invalidate = true,
		end_col = range.col_start + (item.parenthesis and 2 or 1),
		conceal = "",

		virt_text_pos = "inline",
		virt_text = item.preview == false and { { "↑(", utils.set_hl(config.hl) } } or nil,

		hl_mode = "combine"
	});

	if item.parenthesis then
		if item.preview then
			table.insert(latex.cache.style_regions.superscripts, item.range);
		else
			vim.api.nvim_buf_set_extmark(buffer, latex.ns("specials"), range.row_start, range.col_start, {
				undo_restore = false, invalidate = true,
				end_row = range.row_end,
				end_col = range.col_end,

				hl_group = utils.set_hl(config.hl)
			});
		end

		vim.api.nvim_buf_set_extmark(buffer, latex.ns("specials"), range.row_end, range.col_end - 1, {
			undo_restore = false, invalidate = true,
			end_col = range.col_end,
			conceal = "",

			virt_text_pos = "inline",
			virt_text = item.preview == false and { { ")", utils.set_hl(config.hl) } } or nil,

			hl_mode = "combine"
		});
	elseif symbols.superscripts[item.text[1]:sub(2)] then
		vim.api.nvim_buf_set_extmark(buffer, latex.ns("specials"), range.row_start, range.col_start + 1, {
			undo_restore = false, invalidate = true,
			virt_text_pos = "overlay",
			virt_text = { { symbols.superscripts[item.text[1]:sub(2)], utils.set_hl(config.hl) } },

			hl_mode = "combine"
		});
	end
	---_
end

---@param buffer integer
---@param item __latex.symbol
latex.symbol = function (buffer, item)
	---+${func}

	---@type latex.symbols?
	local config = spec.get({ "latex", "symbols" }, { fallback = nil });

	if not config then
		return;
	elseif
		not item.name or
		not symbols.entries[item.name]
	then
		return;
	end

	config = utils.tostatic(
		config,
		{
			args = { buffer, item }
		}
	);

	local range = item.range;
	local within_font, font;

	for _, region in ipairs(latex.cache.font_regions) do
		if utils.within_range(region, range) then
			within_font = true;
			font = region.name;
			break;
		end
	end

	local _o, _h = "", nil;

	if
		item.style and
		spec.get({ "latex", item.style }, { fallback = nil })
	then
		_o = symbols[item.style][item.name] or symbols.entries[item.name];
		_h = spec.get({ "latex", item.style, "hl" }, { fallback = nil });
	elseif
		within_font == true and
		symbols.fonts[font] and
		symbols.fonts[font][item.name] and
		spec.get({ "latex", "fonts" }, { fallback = nil })
	then
		_o = symbols.fonts[font][item.name];

		_h = utils.match_pattern(
			spec.get({ "latex", "fonts" }, { fallback = nil }),
			font,
			{
				args = {
					buffer,
					{
						class = "inline_font",
						name = font,

						text = string.format("\\%s{%s}", font, symbol)
					}
				}
			}
		).hl or config.hl;
	elseif symbols.entries[item.name] then
		_o = symbols.entries[item.name];

		_h = config.hl or utils.match_pattern(
			spec.get({ "latex", "fonts" }, { fallback = nil }),
			font,
			{
				args = {
					buffer,
					{
						class = "inline_font",
						name = font,

						text = string.format("\\%s{%s}", font, symbol)
					}
				}
			}
		).hl;
	else
		return;
	end


	vim.api.nvim_buf_set_extmark(buffer, latex.ns("symbols"), range.row_start, range.col_start, {
		undo_restore = false, invalidate = true,
		end_col = range.col_end,
		conceal = "",

		virt_text_pos = "inline",
		virt_text = { { _o, utils.set_hl(_h) } },
		hl_mode = "combine"
	});
	---_
end

---@param buffer integer
---@param item __latex.text
latex.text = function (buffer, item)
	---+${func}

	---@type latex.texts?
	local config = spec.get({ "latex", "texts" }, { fallback = nil });

	if not config then
		return;
	end

	local range = item.range;

	vim.api.nvim_buf_set_extmark(buffer, latex.ns("fonts"), range.row_start, range.col_start, {
		undo_restore = false, invalidate = true,
		end_col = range.col_start + #"\\text{",
		conceal = ""
	});

	vim.api.nvim_buf_set_extmark(buffer, latex.ns("fonts"), range.row_end, range.col_end - 1, {
		undo_restore = false, invalidate = true,
		end_col = range.col_end,
		conceal = ""
	});
	---_
end

---@param buffer integer
---@param item __latex.word
latex.word = function (buffer, item)
	---+${func}

	---@type latex.fonts?
	local config = spec.get({ "latex", "fonts" }, { fallback = nil });

	if not config then
		return;
	end

	local range = item.range;
	---@type boolean, string?
	local within_font, font;
	---@type boolean, string?
	local within_style, style;

	for _, region in ipairs(latex.cache.font_regions) do
		if utils.within_range(region, range) then
			within_font = true;
			font = region.name;
			break;
		end
	end

	for _, region in ipairs(latex.cache.style_regions.superscripts) do
		if utils.within_range(region, range) then
			within_style = true;
			style = "superscripts";
			break;
		end
	end

	for _, region in ipairs(latex.cache.style_regions.subscripts) do
		if utils.within_range(region, range) then
			within_style = true;
			style = "subscripts";
			break;
		end
	end

	local _o, _h = "", nil;

	if
		within_style == true and
		spec.get({ "latex", style }, { fallback = nil })
	then
		for letter in item.text[1]:gmatch(".") do
			if symbols[style][letter] then
				_o = _o .. symbols[style][letter];
			else
				_o = _o .. letter;
			end
		end

		_h = spec.get({ "latex", style, "hl" }, { fallback = nil });
	elseif
		within_font == true and
		symbols.fonts[font] and
		spec.get({ "latex", "fonts" }, { fallback = nil })
	then
		for letter in item.text[1]:gmatch(".") do
			if symbols.fonts[font][letter] then
				_o = _o .. symbols.fonts[font][letter];
			else
				_o = _o .. letter;
			end
		end

		_h = utils.match_pattern(
			spec.get({ "latex", "fonts" }, { fallback = nil }),
			font,
			{
				args = {
					buffer,
					{
						class = "inline_font",
						name = font,

						text = string.format("\\%s{%s}", font, symbol)
					}
				}
			}
		).hl;
	else
		for letter in item.text[1]:gmatch(".") do
			if symbols.fonts.default[letter] then
				_o = _o .. symbols.fonts.default[letter];
			else
				_o = _o .. letter;
			end
		end

		_h = utils.match_pattern(
			spec.get({ "latex", "fonts" }, { fallback = nil }),
			"default",
			{
				args = {
					buffer,
					{
						class = "inline_font",
						name = font,

						text = string.format("\\%s{%s}", font, symbol)
					}
				}
			}
		).hl;
	end

	vim.api.nvim_buf_set_extmark(buffer, latex.ns("fonts"), range.row_start, range.col_start, {
		undo_restore = false, invalidate = true,
		end_row = range.row_end,
		end_col = range.col_end,

		virt_text_pos = "overlay",
		virt_text = { { _o, utils.set_hl(_h) } },
		hl_mode = "combine"
	});
	---_
end

latex.render = function (buffer, content)
	latex.cache = {
		font_regions = {},
		style_regions = {
			superscripts = {},
			subscripts = {}
		},
	};

	for _, item in ipairs(content or {}) do
		pcall(latex[item.class:gsub("^latex_", "")], buffer, item);
		-- latex[item.class:gsub("^latex_", "")](buffer, item);
	end
end

latex.clear = function (buffer, ignore_ns, from, to)
	for name, ns in pairs(latex.ns) do
		if ignore_ns and vim.list_contains(ignore_ns, name) == false then
			vim.api.nvim_buf_clear_namespace(buffer, ns, from or 0, to or -1);
		end
	end
end

return latex;
