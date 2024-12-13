local typst = {};

local symbols = require("markview.symbols");
local spec = require("markview.spec");
local utils = require("markview.utils");
local languages = require("markview.languages");

local filetypes = require("markview.filetypes");
local devicons_loaded, devicons = pcall(require, "nvim-web-devicons");
local mini_loaded, MiniIcons = pcall(require, "mini.icons");

typst.cache = {
	style_regions = {
		superscripts = {},
		subscripts = {}
	},
};

typst.get_icon = function (icons, ft)
	if type(icons) ~= "string" or icons == "" then
		return "", "Normal";
	end

	if icons == "devicons" and devicons_loaded then
		return devicons.get_icon(nil, ft, { default = true })
	elseif icons == "mini" and mini_loaded then
		return MiniIcons.get("extension", ft);
	elseif icons == "internal" then
		return languages.get_icon(ft);
	end

	return "󰡯", "Normal";
end

typst.__ns = {
	__call = function (self, key)
		return self[key] or self.default;
	end
}

typst.ns = {
	default = vim.api.nvim_create_namespace("markview/typst"),
};
setmetatable(typst.ns, typst.__ns)

typst.set_ns = function ()
	local ns_pref = spec.get({ "typst", "use_seperate_ns" }, { fallback = true });
	if not ns_pref then ns_pref = true; end

	local available = vim.api.nvim_get_namespaces();
	local ns_list = {
		["headings"] = "markview/typst/headings",
		["injections"] = "markview/typst/injections",
		["links"] = "markview/typst/links",
		["symbols"] = "markview/typst/symbols",
	};

	if ns_pref == true then
		for ns, name in pairs(ns_list) do
			if vim.list_contains(available, ns) == false then
				typst.ns[ns] = vim.api.nvim_create_namespace(name);
			end
		end
	end
end

typst.custom_config = function (config, value)
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
---@param item __typst.code
typst.code = function (buffer, item)
	---+${func, Renders Code blocks}

	---@type typst.codes?
	local config = spec.get({ "typst", "codes" }, { fallback = nil, eval_args = { buffer, item } });
	local range = item.range;

	if not config then
		return;
	end

	if config.style == "simple" then
		vim.api.nvim_buf_set_extmark(buffer, typst.ns("codes"), range.row_start, range.col_start, {
			undo_restore = false, invalidate = true,

			virt_text_pos = "right_align",
			virt_text = {
				{ config.text, utils.set_hl(config.text_hl or config.hl) },
			},

			sign_text = config.sign == true and sign or nil,
			sign_hl_group = utils.set_hl(config.sign_hl or config.hl)
		});


		vim.api.nvim_buf_set_extmark(buffer, typst.ns("code_blocks"), range.row_start, range.col_start, {
			undo_restore = false, invalidate = true,
			end_row = range.row_end, end_col = range.col_end,
			line_hl_group = utils.set_hl(config.hl),
		});
	elseif config.style == "block" then
		local pad_amount = config.pad_amount or 3;
		local block_width = config.min_width - (2 * pad_amount);

		--- Get maximum length of the lines within the code block
		for l, line in ipairs(item.text) do
			if (l ~= 1 and l ~= #item.text) and vim.fn.strdisplaywidth(line) > block_width then
				block_width = vim.fn.strdisplaywidth(line);
			end
		end

		if config.text_direction == nil or config.text_direction == "left" then
			vim.api.nvim_buf_set_extmark(buffer, typst.ns("code_blocks"), range.row_start, range.col_start, {
				undo_restore = false, invalidate = true,

				virt_lines_above = true,
				virt_lines = {
					{
						{ string.rep(" ", range.col_start) },
						{ config.pad_char or " ", utils.set_hl(config.hl) },
						{ config.text or "", utils.set_hl(config.text_hl or config.hl) },
						{ string.rep(config.pad_char or " ", block_width + (pad_amount - 1) - (vim.fn.strdisplaywidth(config.text or ""))), utils.set_hl(config.hl) },
						{ string.rep(config.pad_char or " ", pad_amount), utils.set_hl(config.hl) },
					}
				},

				sign_text = config.sign,
				sign_hl_group = utils.set_hl(config.sign_hl or config.hl),
			});
		elseif config.text_direction == "right" then
			vim.api.nvim_buf_set_extmark(buffer, typst.ns("code_blocks"), range.row_start, range.col_start, {
				undo_restore = false, invalidate = true,

				virt_lines_above = true,
				virt_lines = {
					{
						{ string.rep(" ", range.col_start) },
						{ string.rep(config.pad_char or " ", pad_amount), utils.set_hl(config.hl) },
						{ string.rep(config.pad_char or " ", block_width + (pad_amount - 1) - (vim.fn.strdisplaywidth(config.text or ""))), utils.set_hl(config.hl) },
						{ config.text or "", utils.set_hl(config.text_hl or config.hl) },
						{ config.pad_char or " ", utils.set_hl(config.hl) },
					}
				},

				sign_text = config.sign,
				sign_hl_group = utils.set_hl(config.sign_hl or config.hl),
			});
		end

		vim.api.nvim_buf_set_extmark(buffer, typst.ns("code_blocks"), range.row_end, range.col_end, {
			undo_restore = false, invalidate = true,

			virt_lines = {
				{
					{ string.rep(" ", range.col_start) },
					{ string.rep(config.pad_char or " ", pad_amount), utils.set_hl(config.hl) },
					{ string.rep(config.pad_char or " ", block_width), utils.set_hl(config.hl) },
					{ string.rep(config.pad_char or " ", pad_amount), utils.set_hl(config.hl) },
				}
			}
		});

		for l = range.row_start, range.row_end, 1 do
			local line = item.text[(l + 1) - range.row_start];
			local final = line;

			--- Left padding
			vim.api.nvim_buf_set_extmark(buffer, typst.ns("code_blocks"), l, range.col_start, {
				undo_restore = false, invalidate = true,

				virt_text_pos = "inline",
				virt_text = {
					{ string.rep(config.pad_char or " ", pad_amount), utils.set_hl(config.hl) }
				},
			});

			--- Right padding
			vim.api.nvim_buf_set_extmark(buffer, typst.ns("code_blocks"), l, range.col_start + #line, {
				undo_restore = false, invalidate = true,

				virt_text_pos = "inline",
				virt_text = {
					{ string.rep(config.pad_char or " ", block_width - vim.fn.strdisplaywidth(final)), utils.set_hl(config.hl) },
					{ string.rep(config.pad_char or " ", pad_amount), utils.set_hl(config.hl) }
				},
			});

			--- Background color
			vim.api.nvim_buf_set_extmark(buffer, typst.ns("code_blocks"), l, range.col_start, {
				undo_restore = false, invalidate = true,
				end_col = range.col_start + #line,
				hl_group = utils.set_hl(config.hl)
			});
		end
	end
	---_
end

---@param buffer integer
---@param item table
typst.emphasis = function (buffer, item)
	local range = item.range;

	vim.api.nvim_buf_set_extmark(buffer, typst.ns("links"), range.row_start, range.col_start, {
		undo_restore = false, invalidate = true,
		end_col = range.col_start + 1,
		conceal = ""
	});

	vim.api.nvim_buf_set_extmark(buffer, typst.ns("links"), range.row_end, range.col_end - 1, {
		undo_restore = false, invalidate = true,
		end_col = range.col_end,
		conceal = ""
	});
end

---@param buffer integer
---@param item __typst.escaped
typst.escaped = function (buffer, item)
	---@type typst.escapes?
	local config = spec.get({ "typst", "escapes" }, { fallback = nil, eval_args = { buffer, item } });

	if not config then
		return;
	end

	local range = item.range;

	vim.api.nvim_buf_set_extmark(buffer, typst.ns("symbols"), range.row_start, range.col_start, {
		undo_restore = false, invalidate = true,
		end_col = range.col_start + 1,
		conceal = "",
	});
end

---@param buffer integer
---@param item __typst.heading
typst.heading = function (buffer, item)
	---+${func}

	---@type typst.headings?
	local main_config = spec.get({ "typst", "headings" }, { fallback = nil });

	if not main_config then
		return;
	elseif not spec.get({ "heading_" .. item.level }, { source = main_config, eval_args = { buffer, item } }) then
		return;
	end

	local range = item.range;
	---@type heading.typst
	local config = spec.get({ "heading_" .. item.level }, { source = main_config, eval_args = { buffer, item } });

	if config.style == "simple" then
		vim.api.nvim_buf_set_extmark(buffer, typst.ns("headings"), range.row_start, range.col_start, {
			undo_restore = false, invalidate = true,
			line_hl_group = utils.set_hl(config.hl)
		});
	elseif config.style == "icon" then
		vim.api.nvim_buf_set_extmark(buffer, typst.ns("headings"), range.row_start, range.col_start, {
			undo_restore = false, invalidate = true,
			end_col = range.col_start + item.level + 1,
			conceal = "",
			sign_text = config.sign,
			sign_hl_group = utils.set_hl(config.sign_hl),
			virt_text_pos = "inline",
			virt_text = {
				{ string.rep(" ", item.level * spec.get({ "typst", "headings", "shift_width" }, { fallback = 1 })) },
				{ config.icon or "", utils.set_hl(config.icon_hl or config.hl) },
			},
			line_hl_group = utils.set_hl(config.hl),

			hl_mode = "combine"
		});
	end
	---_
end

---@param buffer integer
---@param item __typst.label
typst.label = function (buffer, item)
	---+${func}

	---@type typst.labels?
	local config = spec.get({ "typst", "labels" }, { fallback = nil, eval_args = { buffer, item } });

	if not config then
		return;
	end

	local range = item.range;

	vim.api.nvim_buf_set_extmark(buffer, typst.ns("injections"), range.row_start, range.col_start, {
		undo_restore = false, invalidate = true,
		end_col = range.col_start + 1,
		conceal = "",

		virt_text_pos = "inline",
		virt_text = {
			{ config.corner_left or "", utils.set_hl(config.corner_left_hl or config.hl) },
			{ config.padding_left or "", utils.set_hl(config.padding_left_hl or config.hl) },
			{ config.icon or "", utils.set_hl(config.icon_hl or config.hl) },
		},

		hl_mode = "combine"
	});

	vim.api.nvim_buf_set_extmark(buffer, typst.ns("injections"), range.row_start, range.col_start, {
		undo_restore = false, invalidate = true,
		end_row = range.row_end,
		end_col = range.col_end,

		hl_group = utils.set_hl(config.hl),
	});

	vim.api.nvim_buf_set_extmark(buffer, typst.ns("injections"), range.row_end, range.col_end - 1, {
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
	---_
end

---@param buffer integer
---@param item __typst.reference_link
typst.link_ref = function (buffer, item)
	---+${func}

	---@type typst.links?
	local main_config = spec.get({ "typst", "reference_links" }, { fallback = nil, eval_args = { buffer, item } });

	if not main_config then
		return;
	end

	local config = utils.pattern(
		main_config,
		string.sub(item.text[1], 2),
		{
			eval_args = { buffer, item }
		}
	);

	local range = item.range;

	vim.api.nvim_buf_set_extmark(buffer, typst.ns("links"), range.row_start, range.col_start, {
		undo_restore = false, invalidate = true,
		end_col = range.col_start + 1,
		conceal = "",

		virt_text_pos = "inline",
		virt_text = {
			{ config.corner_left or "", utils.set_hl(config.corner_left_hl or config.hl) },
			{ config.padding_left or "", utils.set_hl(config.padding_left_hl or config.hl) },
			{ config.icon or "", utils.set_hl(config.icon_hl or config.hl) },
		},

		hl_mode = "combine"
	});

	vim.api.nvim_buf_set_extmark(buffer, typst.ns("links"), range.row_start, range.col_start, {
		undo_restore = false, invalidate = true,
		end_row = range.row_end,
		end_col = range.col_end,

		hl_group = utils.set_hl(config.hl),
	});

	vim.api.nvim_buf_set_extmark(buffer, typst.ns("links"), range.row_end, range.col_end, {
		undo_restore = false, invalidate = true,

		virt_text_pos = "inline",
		virt_text = {
			{ config.padding_right or "", utils.set_hl(config.padding_right_hl or config.hl) },
			{ config.corner_right or "", utils.set_hl(config.corner_right_hl or config.hl) },
		},

		hl_mode = "combine"
	});
	---_
end

---@param buffer integer
---@param item __typst.url_link
typst.link_url = function (buffer, item)
	---+${func}

	---@type typst.links?
	local main_config = spec.get({ "typst", "url_links" }, { fallback = nil });

	if not main_config then
		return;
	end

	local range = item.range;
	local config = utils.pattern(
		main_config,
		item.label,
		{
			eval_args = { buffer, item }
		}
	);


	vim.api.nvim_buf_set_extmark(buffer, typst.ns("links"), range.row_start, range.col_start, {
		undo_restore = false, invalidate = true,

		virt_text_pos = "inline",
		virt_text = {
			{ config.corner_left or "", utils.set_hl(config.corner_left_hl or config.hl) },
			{ config.padding_left or "", utils.set_hl(config.padding_left_hl or config.hl) },

			{ config.icon or "", utils.set_hl(config.icon_hl or config.hl) }
		},

		hl_mode = "combine"
	});

	vim.api.nvim_buf_set_extmark(buffer, typst.ns("links"), range.row_start, range.col_start, {
		undo_restore = false, invalidate = true,
		end_col = range.col_end,
		hl_group = utils.set_hl(config.hl)
	});

	vim.api.nvim_buf_set_extmark(buffer, typst.ns("links"), range.row_start, range.col_end, {
		undo_restore = false, invalidate = true,

		virt_text_pos = "inline",
		virt_text = {
			{ config.corner_right or "", utils.set_hl(config.corner_right_hl or config.hl) },
			{ config.padding_right or "", utils.set_hl(config.padding_right_hl or config.hl) }
		},

		hl_mode = "combine"
	});
	---_
end

---@param buffer integer
---@param item __typst.list_item
typst.list_item = function (buffer, item)
	---+${func}

	---@type typst.list_items?
	local main_config = spec.get({ "typst", "list_items" }, { fallback = nil });
	---@type list_items.typst
	local config;

	if not main_config then return; end

	if item.marker == "-" then
		config = spec.get({ "marker_minus" }, { source = main_config, eval_args = { buffer, item } });
	elseif item.marker == "+" then
		config = spec.get({ "marker_plus" }, { source = main_config, eval_args = { buffer, item } });
	elseif item.marker:match("%d+%.") then
		config = spec.get({ "marker_dot" }, { source = main_config, eval_args = { buffer, item } });
	end

	if not config then
		return;
	end

	local indent = main_config.indent_size;
	local shift  = main_config.shift_width;

	local range = item.range;

	if config.add_padding == true then
		for l = range.row_start, range.row_end do
			local line = item.text[(l - range.row_start) + 1];

			vim.api.nvim_buf_set_extmark(buffer, typst.ns("symbols"), l, math.min(#line, range.col_start - item.indent), {
				undo_restore = false, invalidate = true,
				end_col = math.min(#line, range.col_start),
				conceal = "",

				virt_text_pos = "inline",
				virt_text = {
					{ string.rep(" ", math.floor((item.indent / indent) + 1) * shift) }
				}
			});
		end
	end

	if item.marker == "-" then
		vim.api.nvim_buf_set_extmark(buffer, typst.ns("symbols"), range.row_start, range.col_start, {
			undo_restore = false, invalidate = true,
			end_col = range.col_start + 1,

			virt_text_pos = "overlay",
			virt_text = {
				{ config.text or "", utils.set_hl(config.hl) }
			}
		});
	elseif item.marker == "+" then
		vim.api.nvim_buf_set_extmark(buffer, typst.ns("symbols"), range.row_start, range.col_start, {
			undo_restore = false, invalidate = true,
			end_col = range.col_start + 1,
			conceal = "",

			virt_text_pos = "inline",
			virt_text = {
				{ string.format(config.text or "%d.", item.number), utils.set_hl(config.hl) }
			}
		});
	end
	---_
end

---@param buffer integer
---@param item __typst.math
typst.math = function (buffer, item)
	---+${func}
	local range = item.range;

	if item.inline then
		---@type typst.math_spans?
		local config = spec.get({ "typst", "math_spans" }, { fallback = nil, eval_args = { buffer, item } });
		if not config then return; end

		vim.api.nvim_buf_set_extmark(buffer, typst.ns("injections"), range.row_start, range.col_start, {
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

		if range.row_start ~= range.row_end then
			vim.api.nvim_buf_set_extmark(buffer, typst.ns("injections"), range.row_start, range.col_start + #item.text[1], {
				undo_restore = false, invalidate = true,

				virt_text_pos = "inline",
				virt_text = {
					{ config.padding_right or "", utils.set_hl(config.padding_right_hl or config.hl) }
				}
			});

			vim.api.nvim_buf_set_extmark(buffer, typst.ns("injections"), range.row_end, 0, {
				undo_restore = false, invalidate = true,

				virt_text_pos = "inline",
				virt_text = {
					{ config.padding_left or "", utils.set_hl(config.padding_left_hl or config.hl) },
				}
			});
		end

		vim.api.nvim_buf_set_extmark(buffer, typst.ns("injections"), range.row_start, range.col_start, {
			undo_restore = false, invalidate = true,
			end_row = range.row_end,
			end_col = range.col_end,

			hl_group = utils.set_hl(config.hl),
		});

		vim.api.nvim_buf_set_extmark(buffer, typst.ns("injections"), range.row_end, range.col_end - (item.closed and 1 or 0), {
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

		for l = 1, #item.text - 2 do
			vim.api.nvim_buf_set_extmark(buffer, typst.ns("injections"), range.row_start + l, math.min(#item.text[l + 1], 0), {
				undo_restore = false, invalidate = true,

				virt_text_pos = "inline",
				virt_text = {
					{ config.padding_left or "", utils.set_hl(config.padding_left_hl or config.hl) },
				}
			});

			vim.api.nvim_buf_set_extmark(buffer, typst.ns("injections"), range.row_start + l, #item.text[l + 1], {
				undo_restore = false, invalidate = true,

				virt_text_pos = "inline",
				virt_text = {
					{ config.padding_right or "", utils.set_hl(config.padding_right_hl or config.hl) }
				}
			});
		end
	else
		---@type typst.math_blocks?
		local config = spec.get({ "typst", "math_blocks" }, { fallback = nil, eval_args = { buffer, item } });
		if not config then return; end

		vim.api.nvim_buf_set_extmark(buffer, typst.ns("injections"), range.row_start, range.col_start, {
			undo_restore = false, invalidate = true,
			end_col = range.col_start + 1,
			conceal = "",

			virt_text_pos = "right_align",
			virt_text = { { config.text or "", utils.set_hl(config.text_hl or config.hl) } },

			hl_mode = "combine",
			line_hl_group = utils.set_hl(config.hl)
		});

		vim.api.nvim_buf_set_extmark(buffer, typst.ns("injections"), range.row_end, math.max(0, range.col_end - 1), {
			undo_restore = false, invalidate = true,
			end_col = range.col_end,
			conceal = "",

			line_hl_group = utils.set_hl(config.hl)
		});

		for l = 1, #item.text - 2 do
			vim.api.nvim_buf_set_extmark(buffer, typst.ns("injections"), range.row_start + l, range.col_start, {
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
---@param item __typst.raw_block
typst.raw_block = function (buffer, item)
	---+${func, Renders Code blocks}

	---@type typst.raw_blocks?
	local config = spec.get({ "typst", "raw_blocks" }, { fallback = nil, eval_args = { buffer, item } });
	local range = item.range;

	if not config then
		return;
	end

	local decorations = filetypes.get(item.language);
	local label = { string.format(" %s%s ", decorations.icon, decorations.name), decorations.icon_hl };
	local lbl_w = utils.virt_len({ label });
	local win = utils.buf_getwin(buffer);

	if
		config.style == "simple" or
		(
			vim.o.wrap == true or
			vim.wo[win].wrap == true
		)
	then
		vim.api.nvim_buf_set_extmark(buffer, typst.ns("injections"), range.row_start, range.col_start, {
			undo_restore = false, invalidate = true,
			end_col = range.col_start + 3 + vim.fn.strdisplaywidth(item.language or ""),
			conceal = "",

			virt_text_pos = config.language_direction == "left" and "right_align" or "inline",
			virt_text = { label },

			hl_mode = "combine",

			sign_text = icon,
			sign_hl_group = utils.set_hl(config.sign_hl or sign_hl)
		});

		vim.api.nvim_buf_set_extmark(buffer, typst.ns("injections"), range.row_end, range.col_end - 3, {
			undo_restore = false, invalidate = true,
			end_col = range.col_end,
			conceal = ""
		});

		for l = range.row_start + 1, range.row_end - 1, 1 do
			local pad_amount = config.pad_amount;

			--- Left padding
			vim.api.nvim_buf_set_extmark(buffer, typst.ns("code_blocks"), l, range.col_start, {
				undo_restore = false, invalidate = true,

				virt_text_pos = "inline",
				virt_text = {
					{ string.rep(config.pad_char or " ", pad_amount), utils.set_hl(config.hl) }
				},
			});
		end

		if not config.hl then return; end

		vim.api.nvim_buf_set_extmark(buffer, typst.ns("injections"), range.row_start, range.col_start, {
			undo_restore = false, invalidate = true,
			end_row = range.row_end,
			end_col = range.col_end,

			line_hl_group = utils.set_hl(config.hl)
		});
	elseif config.style == "block" then
		local pad_amount = config.pad_amount or 0;
		local block_width = config.min_width - (2 * pad_amount);

		--- Get maximum length of the lines within the code block
		for l, line in ipairs(item.text) do
			if (l ~= 1 and l ~= #item.text) and vim.fn.strdisplaywidth(line) > block_width then
				block_width = vim.fn.strdisplaywidth(line);
			end
		end

		vim.api.nvim_buf_set_extmark(buffer, typst.ns("injections"), range.row_start, range.col_start, {
			undo_restore = false, invalidate = true,
			end_col = range.col_start + 3 + vim.fn.strdisplaywidth(item.language or ""),
			conceal = "",
		});

		vim.api.nvim_buf_set_extmark(buffer, typst.ns("injections"), range.row_start, range.col_start + #item.text[1], {
			undo_restore = false, invalidate = true,

			virt_text_pos = "inline",
			virt_text = config.language_direction == "left" and {
				label,
				{ string.rep(config.pad_char or " ", block_width - lbl_w), utils.set_hl(config.hl) },
				{ string.rep(config.pad_char or " ", (2 * pad_amount)), utils.set_hl(config.hl) },
			} or {
				{ string.rep(config.pad_char or " ", (2 * pad_amount)), utils.set_hl(config.hl) },
				{ string.rep(config.pad_char or " ", block_width - lbl_w), utils.set_hl(config.hl) },
				label
			},

			hl_mode = "combine",

			sign_text = icon,
			sign_hl_group = utils.set_hl(config.sign_hl or sign_hl)
		});

		vim.api.nvim_buf_set_extmark(buffer, typst.ns("injections"), range.row_end, range.col_end - 3, {
			undo_restore = false, invalidate = true,
			end_col = range.col_end,
			conceal = "",
		});

		vim.api.nvim_buf_set_extmark(buffer, typst.ns("injections"), range.row_end, range.col_end, {
			undo_restore = false, invalidate = true,

			virt_text_pos = "inline",
			virt_text = {
				{ string.rep(config.pad_char or " ", pad_amount), utils.set_hl(config.hl) },
				{ string.rep(config.pad_char or " ", block_width), utils.set_hl(config.hl) },
				{ string.rep(config.pad_char or " ", pad_amount), utils.set_hl(config.hl) },
			},

			hl_mode = "combine"
		});

		for l = range.row_start + 1, range.row_end - 1 do
			local line = item.text[(l - range.row_start) + 1];

			vim.api.nvim_buf_set_extmark(buffer, typst.ns("injections"), l, range.col_start, {
				undo_restore = false, invalidate = true,

				virt_text_pos = "inline",
				virt_text = {
					{ string.rep(config.pad_char or " ", pad_amount), utils.set_hl(config.hl) },
				},

				hl_mode = "combine"
			});

			vim.api.nvim_buf_set_extmark(buffer, typst.ns("injections"), l, range.col_start + #line, {
				undo_restore = false, invalidate = true,

				virt_text_pos = "inline",
				virt_text = {
					{ string.rep(config.pad_char or " ", block_width - #line), utils.set_hl(config.hl) },
					{ string.rep(config.pad_char or " ", pad_amount), utils.set_hl(config.hl) },
				},

				hl_mode = "combine"
			});

			vim.api.nvim_buf_set_extmark(buffer, typst.ns("injections"), l, range.col_start, {
				undo_restore = false, invalidate = true,
				end_col = range.col_start + #line,

				hl_group = utils.set_hl(config.hl)
			});
		end
	end
	---_
end

---@param buffer integer
---@param item __typst.raw_span
typst.raw_span = function (buffer, item)
	---+${func}

	---@type typst.raw_spans?
	local config = spec.get({ "typst", "raw_spans" }, { fallback = nil, eval_args = { buffer, item } });

	if not config then
		return;
	end

	local range = item.range;

	vim.api.nvim_buf_set_extmark(buffer, typst.ns("injections"), range.row_start, range.col_start, {
		undo_restore = false, invalidate = true,
		end_col = range.col_start + 1,
		conceal = "",

		virt_text_pos = "inline",
		virt_text = {
			{ config.corner_left or "", utils.set_hl(config.corner_left_hl or config.hl) },
			{ config.padding_left or "", utils.set_hl(config.padding_left_hl or config.hl) },
			{ config.icon or "", utils.set_hl(config.icon_hl or config.hl) },
		},

		hl_mode = "combine"
	});

	vim.api.nvim_buf_set_extmark(buffer, typst.ns("injections"), range.row_start, range.col_start, {
		undo_restore = false, invalidate = true,
		end_row = range.row_end,
		end_col = range.col_end,

		hl_group = utils.set_hl(config.hl),
	});

	vim.api.nvim_buf_set_extmark(buffer, typst.ns("injections"), range.row_end, range.col_end - 1, {
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
	---_
end

---@param buffer integer
---@param item table
typst.strong = function (buffer, item)
	local range = item.range;

	vim.api.nvim_buf_set_extmark(buffer, typst.ns("links"), range.row_start, range.col_start, {
		undo_restore = false, invalidate = true,
		end_col = range.col_start + 1,
		conceal = ""
	});

	vim.api.nvim_buf_set_extmark(buffer, typst.ns("links"), range.row_end, range.col_end - 1, {
		undo_restore = false, invalidate = true,
		end_col = range.col_end,
		conceal = ""
	});
end

---@param buffer integer
---@param item __typst.style
typst.superscript = function (buffer, item)
	---+${func}

	---@type latex.styles?
	local config = spec.get({ "typst", "superscripts" }, { fallback = nil, eval_args = { buffer, item } });

	if not config then
		return;
	end

	local range = item.range;

	vim.api.nvim_buf_set_extmark(buffer, typst.ns("specials"), range.row_start, range.col_start, {
		undo_restore = false, invalidate = true,
		end_col = range.col_start + (item.parenthesis and 2 or 1),
		conceal = "",

		virt_text_pos = "inline",
		virt_text = item.preview == false and { { "↑(", utils.set_hl(config.hl) } } or nil,

		hl_mode = "combine"
	});

	if item.parenthesis then
		if item.preview then
			table.insert(typst.cache.style_regions.superscripts, item.range);
		else
			vim.api.nvim_buf_set_extmark(buffer, typst.ns("specials"), range.row_start, range.col_start, {
				undo_restore = false, invalidate = true,
				end_row = range.row_end,
				end_col = range.col_end,

				hl_group = utils.set_hl(config.hl)
			});
		end

		vim.api.nvim_buf_set_extmark(buffer, typst.ns("specials"), range.row_end, range.col_end - 1, {
			undo_restore = false, invalidate = true,
			end_col = range.col_end,
			conceal = "",

			virt_text_pos = "inline",
			virt_text = item.preview == false and { { ")", utils.set_hl(config.hl) } } or nil,

			hl_mode = "combine"
		});
	elseif symbols.superscripts[item.text[1]] then
		vim.api.nvim_buf_set_extmark(buffer, typst.ns("specials"), range.row_start, range.col_start + 1, {
			undo_restore = false, invalidate = true,
			virt_text_pos = "overlay",
			virt_text = { { symbols.superscripts[item.text[1]], utils.set_hl(config.hl) } },

			hl_mode = "combine"
		});
	end
	---_
end

---@param buffer integer
---@param item __typst.style
typst.subscript = function (buffer, item)
	---+${func}

	---@type latex.styles?
	local config = spec.get({ "typst", "subscripts" }, { fallback = nil, eval_args = { buffer, item } });

	if not config then
		return;
	end

	local range = item.range;

	vim.api.nvim_buf_set_extmark(buffer, typst.ns("specials"), range.row_start, range.col_start, {
		undo_restore = false, invalidate = true,
		end_col = range.col_start + (item.parenthesis and 2 or 1),
		conceal = "",

		virt_text_pos = "inline",
		virt_text = item.preview == false and { { "↑(", utils.set_hl(config.hl) } } or nil,

		hl_mode = "combine"
	});

	if item.parenthesis then
		if item.preview then
			table.insert(typst.cache.style_regions.subscripts, item.range);
		else
			vim.api.nvim_buf_set_extmark(buffer, typst.ns("specials"), range.row_start, range.col_start, {
				undo_restore = false, invalidate = true,
				end_row = range.row_end,
				end_col = range.col_end,

				hl_group = utils.set_hl(config.hl)
			});
		end

		vim.api.nvim_buf_set_extmark(buffer, typst.ns("specials"), range.row_end, range.col_end - 1, {
			undo_restore = false, invalidate = true,
			end_col = range.col_end,
			conceal = "",

			virt_text_pos = "inline",
			virt_text = item.preview == false and { { ")", utils.set_hl(config.hl) } } or nil,

			hl_mode = "combine"
		});
	elseif symbols.subscripts[item.text[1]] then
		vim.api.nvim_buf_set_extmark(buffer, typst.ns("specials"), range.row_start, range.col_start + 1, {
			undo_restore = false, invalidate = true,
			virt_text_pos = "overlay",
			virt_text = { { symbols.subscripts[item.text[1]], utils.set_hl(config.hl) } },

			hl_mode = "combine"
		});
	end
	---_
end

---@param buffer integer
---@param item __typst.symbol
typst.symbol = function (buffer, item)
	---+${func}

	---@type typst.symbols?
	local config = spec.get({ "typst", "symbols" }, { fallback = nil, eval_args = { buffer, item } });

	if not config then
		return;
	elseif not item.name or not symbols.typst_entries[item.name] then
		return;
	end

	local range = item.range;
	local _o, _h = "", nil;

	if
		item.style and
		spec.get({ "typst", item.style, "hl" }, { fallback = nil })
	then
		_o = symbols[item.style][item.name] or symbols.typst_entries[item.name];
		_h = spec.get({ "typst", item.style, "hl" }, { fallback = nil });
	elseif symbols.typst_shorthands[item.name] then
		_o = symbols.typst_shorthands[item.name];
		_h = config.hl;
	elseif symbols.typst_entries[item.name] then
		_o = symbols.typst_entries[item.name];
		_h = config.hl;
	else
		return;
	end


	vim.api.nvim_buf_set_extmark(buffer, typst.ns("symbols"), range.row_start, range.col_start, {
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
---@param item __typst.term
typst.term = function (buffer, item)
	---+${func}

	---@type typst.term?
	local main_config = spec.get({ "typst", "terms" }, { fallback = nil });

	if not main_config then
		return;
	end

	local config = utils.pattern(
		main_config,
		item.term,
		{
			eval_args = { buffer, item }
		}
	);

	local range = item.range;

	vim.api.nvim_buf_set_extmark(buffer, typst.ns("symbols"), range.row_start, range.col_start, {
		undo_restore = false, invalidate = true,
		end_col = range.col_start + 2,
		conceal = "",

		virt_text_pos = "inline",
		virt_text = {
			{ config.text or "", utils.set_hl(config.hl) }
		}
	});
	---_
end

---@param buffer integer
---@param item __typst.text
typst.text = function (buffer, item)
	---+${func}

	local range = item.range;
	---@type boolean, string?
	local within_style, style;

	for _, region in ipairs(typst.cache.style_regions.superscripts) do
		if utils.within_range(region, range) then
			within_style = true;
			style = "superscripts";
			break;
		end
	end

	for _, region in ipairs(typst.cache.style_regions.subscripts) do
		if utils.within_range(region, range) then
			within_style = true;
			style = "subscripts";
			break;
		end
	end

	local _o, _h = "", nil;

	if spec.get({ "typst", style }, {}) and within_style == true then
		for letter in item.text[1]:gmatch(".") do
			if symbols[style][letter] then
				_o = _o .. symbols[style][letter];
			else
				_o = _o .. letter;
			end
		end

		_h = spec.get({ "typst", style, "hl" }, { fallback = nil, eval_args = { buffer, item } });
	else
		for letter in item.text[1]:gmatch(".") do
			if symbols.fonts.default[letter] then
				_o = _o .. symbols.fonts.default[letter];
			else
				_o = _o .. letter;
			end
		end

		_h = spec.get({ "typst", "fonts", "hl" }, { fallback = nil, eval_args = { buffer, item } });
	end

	vim.api.nvim_buf_set_extmark(buffer, typst.ns("fonts"), range.row_start, range.col_start, {
		undo_restore = false, invalidate = true,
		end_row = range.row_end,
		end_col = range.col_end,

		virt_text_pos = "overlay",
		virt_text = { { _o, utils.set_hl(_h) } },
		hl_mode = "combine"
	});
	---_
end

typst.render = function (buffer, content)
	typst.cache = {
		style_regions = {
			superscripts = {},
			subscripts = {}
		},
	};

	for _, item in ipairs(content or {}) do
		if typst[item.class:gsub("^typst_", "")] then
			-- pcall(typst[item.class:gsub("^typst_", "")], buffer, item);
			typst[item.class:gsub("^typst_", "")](buffer, item);
		end
	end
end

typst.clear = function (buffer, ignore_ns, from, to)
	for name, ns in pairs(typst.ns) do
		if ignore_ns and vim.list_contains(ignore_ns, name) == false then
			vim.api.nvim_buf_clear_namespace(buffer, ns, from or 0, to or -1);
		end
	end
end

return typst;
