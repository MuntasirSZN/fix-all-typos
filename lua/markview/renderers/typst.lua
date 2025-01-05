local typst = {};

local symbols = require("markview.symbols");
local spec = require("markview.spec");
local utils = require("markview.utils");

local filetypes = require("markview.filetypes");

typst.cache = {
	superscripts = {},
	subscripts = {}
};

typst.ns = vim.api.nvim_create_namespace("markview/typst");

---@param buffer integer
---@param item __typst.code_block
typst.code_block = function (buffer, item)
	---+${func, Renders Code blocks}

	---@type typst.code_blocks?
	local config = spec.get({ "typst", "code_blocks" }, { fallback = nil, eval_args = { buffer, item } });
	local range = item.range;

	if not config then
		return;
	end

	if config.style == "simple" then
		vim.api.nvim_buf_set_extmark(buffer, typst.ns, range.row_start, range.col_start, {
			undo_restore = false, invalidate = true,

			virt_text_pos = "right_align",
			virt_text = {
				{ config.text, utils.set_hl(config.text_hl or config.hl) },
			},

			sign_text = config.sign == true and sign or nil,
			sign_hl_group = utils.set_hl(config.sign_hl or config.hl)
		});


		vim.api.nvim_buf_set_extmark(buffer, typst.ns, range.row_start, range.col_start, {
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
			vim.api.nvim_buf_set_extmark(buffer, typst.ns, range.row_start, range.col_start, {
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
			vim.api.nvim_buf_set_extmark(buffer, typst.ns, range.row_start, range.col_start, {
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

		vim.api.nvim_buf_set_extmark(buffer, typst.ns, range.row_end, range.col_end, {
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
			vim.api.nvim_buf_set_extmark(buffer, typst.ns, l, range.col_start, {
				undo_restore = false, invalidate = true,

				virt_text_pos = "inline",
				virt_text = {
					{ string.rep(config.pad_char or " ", pad_amount), utils.set_hl(config.hl) }
				},
			});

			--- Right padding
			vim.api.nvim_buf_set_extmark(buffer, typst.ns, l, range.col_start + #line, {
				undo_restore = false, invalidate = true,

				virt_text_pos = "inline",
				virt_text = {
					{ string.rep(config.pad_char or " ", block_width - vim.fn.strdisplaywidth(final)), utils.set_hl(config.hl) },
					{ string.rep(config.pad_char or " ", pad_amount), utils.set_hl(config.hl) }
				},
			});

			--- Background color
			vim.api.nvim_buf_set_extmark(buffer, typst.ns, l, range.col_start, {
				undo_restore = false, invalidate = true,
				end_col = range.col_start + #line,
				hl_group = utils.set_hl(config.hl)
			});
		end
	end
	---_
end

---@param buffer integer
---@param item __typst.code_spans
typst.code_span = function (buffer, item)
	---+${lua}

	---@type typst.code_spans?
	local config = spec.get({ "typst", "code_spans" }, { fallback = nil, eval_args = { buffer, item } });
	local range = item.range;

	if not config then
		return;
	end

	vim.api.nvim_buf_set_extmark(buffer, typst.ns, range.row_start, range.col_start, {
		undo_restore = false, invalidate = true,

		virt_text_pos = "inline",
		virt_text = {
			{ config.corner_left or "", utils.set_hl(config.corner_left_hl or config.hl) },
			{ config.padding_left or "", utils.set_hl(config.padding_left_hl or config.hl) }
		},

		hl_mode = "combine"
	});

	vim.api.nvim_buf_set_extmark(buffer, typst.ns, range.row_start, range.col_start, {
		undo_restore = false, invalidate = true,
		end_row = range.row_end,
		end_col = range.col_end,

		hl_group = utils.set_hl(config.hl),
	});

	vim.api.nvim_buf_set_extmark(buffer, typst.ns, range.row_end, range.col_end, {
		undo_restore = false, invalidate = true,

		virt_text_pos = "inline",
		virt_text = {
			{ config.padding_right or "", utils.set_hl(config.padding_right_hl or config.hl) },
			{ config.corner_right or "", utils.set_hl(config.corner_right_hl or config.hl) },
		},

		hl_mode = "combine"
	});

	if range.row_start == range.row_end then
		return;
	end

	for l = range.row_start, range.row_end do
		local line = item.text[(l - range.row_start) + 1];

		if l == range.row_start then
			vim.api.nvim_buf_set_extmark(buffer, typst.ns, l, range.col_start + #line, {
				undo_restore = false, invalidate = true,

				virt_text_pos = "inline",
				virt_text = {
					{ config.padding_right or "", utils.set_hl(config.padding_right_hl or config.hl) },
				},

				hl_mode = "combine"
			});
		elseif l == range.row_end then
			vim.api.nvim_buf_set_extmark(buffer, typst.ns, l, 0, {
				undo_restore = false, invalidate = true,
				right_gravity = true,

				virt_text_pos = "inline",
				virt_text = {
					{ config.padding_left or "", utils.set_hl(config.padding_left_hl or config.hl) },
				},

				hl_mode = "combine"
			});
		else
			vim.api.nvim_buf_set_extmark(buffer, typst.ns, l, 0, {
				undo_restore = false, invalidate = true,
				right_gravity = true,

				virt_text_pos = "inline",
				virt_text = {
					{ config.padding_left or "", utils.set_hl(config.padding_left_hl or config.hl) },
				},

				hl_mode = "combine"
			});
			vim.api.nvim_buf_set_extmark(buffer, typst.ns, l, #line, {
				undo_restore = false, invalidate = true,

				virt_text_pos = "inline",
				virt_text = {
					{ config.padding_right or "", utils.set_hl(config.padding_right_hl or config.hl) },
				},

				hl_mode = "combine"
			});
		end
	end
	---_
end

---@param buffer integer
---@param item __typst.emphasis
typst.emphasis = function (buffer, item)
	---+${lua}

	local range = item.range;

	vim.api.nvim_buf_set_extmark(buffer, typst.ns, range.row_start, range.col_start, {
		undo_restore = false, invalidate = true,
		end_col = range.col_start + 1,
		conceal = ""
	});

	vim.api.nvim_buf_set_extmark(buffer, typst.ns, range.row_end, range.col_end - 1, {
		undo_restore = false, invalidate = true,
		end_col = range.col_end,
		conceal = ""
	});
	---_
end

---@param buffer integer
---@param item __typst.escapes
typst.escaped = function (buffer, item)
	---+${lua}

	---@type typst.escapes?
	local config = spec.get({ "typst", "escapes" }, { fallback = nil, eval_args = { buffer, item } });

	if not config then
		return;
	end

	local range = item.range;

	vim.api.nvim_buf_set_extmark(buffer, typst.ns, range.row_start, range.col_start, {
		undo_restore = false, invalidate = true,
		end_col = range.col_start + 1,
		conceal = "",
	});
	---_
end

---@param buffer integer
---@param item __typst.headings
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
	---@type headings.typst
	local config = spec.get({ "heading_" .. item.level }, { source = main_config, eval_args = { buffer, item } });

	if config.style == "simple" then
		vim.api.nvim_buf_set_extmark(buffer, typst.ns, range.row_start, range.col_start, {
			undo_restore = false, invalidate = true,
			line_hl_group = utils.set_hl(config.hl)
		});
	elseif config.style == "icon" then
		vim.api.nvim_buf_set_extmark(buffer, typst.ns, range.row_start, range.col_start, {
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
---@param item __typst.labels
typst.label = function (buffer, item)
	---+${func}

	---@type typst.labels?
	local main_config = spec.get({ "typst", "labels" }, { fallback = nil, eval_args = { buffer, item } });

	if not main_config then
		return;
	end

	---@type config.inline_generic?
	local config = utils.match(
		main_config,
		string.sub(item.text[1], 1, #item.text[1] - 1),
		{
			eval_args = { buffer, item }
		}
	);

	if not config then
		return;
	end

	local range = item.range;

	vim.api.nvim_buf_set_extmark(buffer, typst.ns, range.row_start, range.col_start, {
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

	vim.api.nvim_buf_set_extmark(buffer, typst.ns, range.row_start, range.col_start, {
		undo_restore = false, invalidate = true,
		end_row = range.row_end,
		end_col = range.col_end,

		hl_group = utils.set_hl(config.hl),
	});

	vim.api.nvim_buf_set_extmark(buffer, typst.ns, range.row_end, range.col_end - 1, {
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
---@param item __typst.list_items
typst.list_item = function (buffer, item)
	---+${func}

	---@type typst.list_items?
	local main_config = spec.get({ "typst", "list_items" }, { fallback = nil });
	---@type list_items.ordered | list_items.unordered | nil
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

			vim.api.nvim_buf_set_extmark(buffer, typst.ns, l, math.min(#line, range.col_start - item.indent), {
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
		vim.api.nvim_buf_set_extmark(buffer, typst.ns, range.row_start, range.col_start, {
			undo_restore = false, invalidate = true,
			end_col = range.col_start + 1,

			virt_text_pos = "overlay",
			virt_text = {
				{ config.text or "", utils.set_hl(config.hl) }
			}
		});
	elseif item.marker == "+" then
		vim.api.nvim_buf_set_extmark(buffer, typst.ns, range.row_start, range.col_start, {
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
---@param item __typst.reference_links
typst.link_ref = function (buffer, item)
	---+${func}

	---@type typst.reference_links?
	local main_config = spec.get({ "typst", "reference_links" }, { fallback = nil, eval_args = { buffer, item } });

	if not main_config then
		return;
	end

	---@type config.inline_generic?
	local config = utils.match(
		main_config,
		item.label,
		{
			eval_args = { buffer, item }
		}
	);

	if not config then
		return;
	end

	local range = item.range;

	vim.api.nvim_buf_set_extmark(buffer, typst.ns, range.row_start, range.col_start, {
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

	vim.api.nvim_buf_set_extmark(buffer, typst.ns, range.row_start, range.col_start, {
		undo_restore = false, invalidate = true,
		end_row = range.row_end,
		end_col = range.col_end,

		hl_group = utils.set_hl(config.hl),
	});

	vim.api.nvim_buf_set_extmark(buffer, typst.ns, range.row_end, range.col_end, {
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
---@param item __typst.url_links
typst.link_url = function (buffer, item)
	---+${func}

	---@type typst.url_links?
	local main_config = spec.get({ "typst", "url_links" }, { fallback = nil });

	if not main_config then
		return;
	end

	---@type config.inline_generic?
	local config = utils.match(
		main_config,
		item.label,
		{
			eval_args = { buffer, item }
		}
	);

	if not config then
		return;
	end

	local range = item.range;

	vim.api.nvim_buf_set_extmark(buffer, typst.ns, range.row_start, range.col_start, {
		undo_restore = false, invalidate = true,

		virt_text_pos = "inline",
		virt_text = {
			{ config.corner_left or "", utils.set_hl(config.corner_left_hl or config.hl) },
			{ config.padding_left or "", utils.set_hl(config.padding_left_hl or config.hl) },

			{ config.icon or "", utils.set_hl(config.icon_hl or config.hl) }
		},

		hl_mode = "combine"
	});

	vim.api.nvim_buf_set_extmark(buffer, typst.ns, range.row_start, range.col_start, {
		undo_restore = false, invalidate = true,
		end_col = range.col_end,
		hl_group = utils.set_hl(config.hl)
	});

	vim.api.nvim_buf_set_extmark(buffer, typst.ns, range.row_start, range.col_end, {
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
---@param item __typst.maths
typst.math = function (buffer, item)
	---+${func}
	local range = item.range;

	if item.inline == true then
		---@type typst.math_spans?
		local config = spec.get({ "typst", "math_spans" }, { fallback = nil, eval_args = { buffer, item } });

		if not config then
			return;
		end

		vim.api.nvim_buf_set_extmark(buffer, typst.ns, range.row_start, range.col_start, {
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
			vim.api.nvim_buf_set_extmark(buffer, typst.ns, range.row_start, range.col_start + #item.text[1], {
				undo_restore = false, invalidate = true,

				virt_text_pos = "inline",
				virt_text = {
					{ config.padding_right or "", utils.set_hl(config.padding_right_hl or config.hl) }
				}
			});

			vim.api.nvim_buf_set_extmark(buffer, typst.ns, range.row_end, 0, {
				undo_restore = false, invalidate = true,

				virt_text_pos = "inline",
				virt_text = {
					{ config.padding_left or "", utils.set_hl(config.padding_left_hl or config.hl) },
				}
			});
		end

		vim.api.nvim_buf_set_extmark(buffer, typst.ns, range.row_start, range.col_start, {
			undo_restore = false, invalidate = true,
			end_row = range.row_end,
			end_col = range.col_end,

			hl_group = utils.set_hl(config.hl),
		});

		vim.api.nvim_buf_set_extmark(buffer, typst.ns, range.row_end, range.col_end - (item.closed and 1 or 0), {
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
			vim.api.nvim_buf_set_extmark(buffer, typst.ns, range.row_start + l, math.min(#item.text[l + 1], 0), {
				undo_restore = false, invalidate = true,

				virt_text_pos = "inline",
				virt_text = {
					{ config.padding_left or "", utils.set_hl(config.padding_left_hl or config.hl) },
				}
			});

			vim.api.nvim_buf_set_extmark(buffer, typst.ns, range.row_start + l, #item.text[l + 1], {
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

		if not config then
			return;
		end

		vim.api.nvim_buf_set_extmark(buffer, typst.ns, range.row_start, range.col_start, {
			undo_restore = false, invalidate = true,
			end_col = range.col_start + 1,
			conceal = "",

			virt_text_pos = "right_align",
			virt_text = { { config.text or "", utils.set_hl(config.text_hl or config.hl) } },

			hl_mode = "combine",
			line_hl_group = utils.set_hl(config.hl)
		});

		vim.api.nvim_buf_set_extmark(buffer, typst.ns, range.row_end, math.max(0, range.col_end - 1), {
			undo_restore = false, invalidate = true,
			end_col = range.col_end,
			conceal = "",

			line_hl_group = utils.set_hl(config.hl)
		});

		for l = 1, #item.text - 2 do
			vim.api.nvim_buf_set_extmark(buffer, typst.ns, range.row_start + l, range.col_start, {
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
---@param item __typst.raw_blocks
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

	if config.style == "simple" or ( vim.o.wrap == true or vim.wo[win].wrap == true ) then
		vim.api.nvim_buf_set_extmark(buffer, typst.ns, range.row_start, range.col_start, {
			undo_restore = false, invalidate = true,
			end_col = range.col_start + 3 + vim.fn.strdisplaywidth(item.language or ""),
			conceal = "",

			virt_text_pos = config.label_direction == "left" and "right_align" or "inline",
			virt_text = { label, config.label_hl or config.hl },

			hl_mode = "combine",

			sign_text = config.sign,
			sign_hl_group = utils.set_hl(config.sign_hl or sign_hl)
		});

		vim.api.nvim_buf_set_extmark(buffer, typst.ns, range.row_end, range.col_end - 3, {
			undo_restore = false, invalidate = true,
			end_col = range.col_end,
			conceal = ""
		});

		for l = range.row_start + 1, range.row_end - 1, 1 do
			local pad_amount = config.pad_amount or 0;

			--- Left padding
			vim.api.nvim_buf_set_extmark(buffer, typst.ns, l, range.col_start, {
				undo_restore = false, invalidate = true,

				virt_text_pos = "inline",
				virt_text = {
					{ string.rep(config.pad_char or " ", pad_amount), utils.set_hl(config.hl) }
				},
			});
		end

		if not config.hl then return; end

		vim.api.nvim_buf_set_extmark(buffer, typst.ns, range.row_start, range.col_start, {
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

		vim.api.nvim_buf_set_extmark(buffer, typst.ns, range.row_start, range.col_start, {
			undo_restore = false, invalidate = true,
			end_col = range.col_start + 3 + vim.fn.strdisplaywidth(item.language or ""),
			conceal = "",
		});

		vim.api.nvim_buf_set_extmark(buffer, typst.ns, range.row_start, range.col_start + #item.text[1], {
			undo_restore = false, invalidate = true,

			virt_text_pos = "inline",
			virt_text = config.label_direction == "left" and {
				label,
				{ string.rep(config.pad_char or " ", block_width - lbl_w), utils.set_hl(config.hl) },
				{ string.rep(config.pad_char or " ", (2 * pad_amount)), utils.set_hl(config.hl) },
			} or {
				{ string.rep(config.pad_char or " ", (2 * pad_amount)), utils.set_hl(config.hl) },
				{ string.rep(config.pad_char or " ", block_width - lbl_w), utils.set_hl(config.hl) },
				label
			},

			hl_mode = "combine",

			sign_text = config.sign,
			sign_hl_group = utils.set_hl(config.sign_hl or sign_hl)
		});

		vim.api.nvim_buf_set_extmark(buffer, typst.ns, range.row_end, range.col_end - 3, {
			undo_restore = false, invalidate = true,
			end_col = range.col_end,
			conceal = "",
		});

		vim.api.nvim_buf_set_extmark(buffer, typst.ns, range.row_end, range.col_end, {
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

			vim.api.nvim_buf_set_extmark(buffer, typst.ns, l, range.col_start, {
				undo_restore = false, invalidate = true,

				virt_text_pos = "inline",
				virt_text = {
					{ string.rep(config.pad_char or " ", pad_amount), utils.set_hl(config.hl) },
				},

				hl_mode = "combine"
			});

			vim.api.nvim_buf_set_extmark(buffer, typst.ns, l, range.col_start + #line, {
				undo_restore = false, invalidate = true,

				virt_text_pos = "inline",
				virt_text = {
					{ string.rep(config.pad_char or " ", block_width - #line), utils.set_hl(config.hl) },
					{ string.rep(config.pad_char or " ", pad_amount), utils.set_hl(config.hl) },
				},

				hl_mode = "combine"
			});

			vim.api.nvim_buf_set_extmark(buffer, typst.ns, l, range.col_start, {
				undo_restore = false, invalidate = true,
				end_col = range.col_start + #line,

				hl_group = utils.set_hl(config.hl)
			});
		end
	end
	---_
end

---@param buffer integer
---@param item __typst.raw_spans
typst.raw_span = function (buffer, item)
	---+${func}

	---@type typst.raw_spans?
	local config = spec.get({ "typst", "raw_spans" }, { fallback = nil, eval_args = { buffer, item } });

	if not config then
		return;
	end

	local range = item.range;

	vim.api.nvim_buf_set_extmark(buffer, typst.ns, range.row_start, range.col_start, {
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

	vim.api.nvim_buf_set_extmark(buffer, typst.ns, range.row_start, range.col_start, {
		undo_restore = false, invalidate = true,
		end_row = range.row_end,
		end_col = range.col_end,

		hl_group = utils.set_hl(config.hl),
	});

	vim.api.nvim_buf_set_extmark(buffer, typst.ns, range.row_end, range.col_end - 1, {
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
---@param item __typst.strong
typst.strong = function (buffer, item)
	---+${lua}

	local range = item.range;

	vim.api.nvim_buf_set_extmark(buffer, typst.ns, range.row_start, range.col_start, {
		undo_restore = false, invalidate = true,
		end_col = range.col_start + 1,
		conceal = ""
	});

	vim.api.nvim_buf_set_extmark(buffer, typst.ns, range.row_end, range.col_end - 1, {
		undo_restore = false, invalidate = true,
		end_col = range.col_end,
		conceal = ""
	});
	---_
end

---@param buffer integer
---@param item __typst.subscripts
typst.subscript = function (buffer, item)
	-- ---+${func}

	---@type typst.subscripts?
	local config = spec.get({ "typst", "subscripts" }, { fallback = nil, eval_args = { buffer, item } });

	if not config then
		return;
	end

	local range = item.range;
	---@type string?
	local hl;

	if type(config.hl) == "string" then
		hl = config.hl --[[ @as string ]];
	elseif vim.islist(config.hl) == true then
		hl = config.hl[utils.clamp(item.level, 1, #config.hl)];
	end

	local previewable = true;

	local invalid_symbols = vim.list_extend(vim.tbl_keys(symbols.typst_entries), vim.tbl_keys(symbols.typst_shorthands));
	local valid_symbols = vim.tbl_keys(symbols.subscripts);

	local lines = vim.deepcopy(item.text);

	lines[1] = string.gsub(lines[1], "^%{", "");
	lines[#lines] = string.gsub(lines[#lines], "%}$", "");

	for _, line in ipairs(lines) do
		if utils.str_contains(line, invalid_symbols) == true then
			previewable = false;
			break;
		elseif utils.str_contains(line, valid_symbols) == false then
			previewable = false;
			break;
		end
	end

	---+${Lua, Render markers}
	if item.parenthesis == true then
		vim.api.nvim_buf_set_extmark(buffer, typst.ns, range.row_start, range.col_start, {
			undo_restore = false, invalidate = true,
			end_col = range.col_start + 2,
			conceal = "",

			virt_text_pos = "inline",
			virt_text = previewable == false and {
				{ config.marker_left or "↓(", utils.set_hl(hl) }
			} or nil,

			hl_mode = "combine"
		});

		vim.api.nvim_buf_set_extmark(buffer, typst.ns, range.row_end, range.col_end - 1, {
			undo_restore = false, invalidate = true,
			end_col = range.col_end,
			conceal = "",

			virt_text_pos = "inline",
			virt_text = previewable == false and {
				{ config.marker_right or ")", utils.set_hl(hl) }
			} or nil,

			hl_mode = "combine"
		});
	else
		vim.api.nvim_buf_set_extmark(buffer, typst.ns, range.row_start, range.col_start, {
			undo_restore = false, invalidate = true,
			end_col = range.col_start + 1,
			conceal = "",

			virt_text_pos = "inline",
			virt_text = previewable == false and {
				{ config.marker_left or "↓", utils.set_hl(hl) }
			} or nil,

			hl_mode = "combine"
		});
	end
	---_

	if previewable == true then
		table.insert(typst.cache.subscripts, item);
	else
		vim.api.nvim_buf_set_extmark(buffer, typst.ns, range.row_start, range.col_start, {
			undo_restore = false, invalidate = true,
			end_row = range.row_end,
			end_col = range.col_end,

			hl_group = utils.set_hl(hl)
		});
	end
	-- ---_
end

---@param buffer integer
---@param item __typst.superscripts
typst.superscript = function (buffer, item)
	---+${func}

	---@type typst.superscripts?
	local config = spec.get({ "typst", "superscripts" }, { fallback = nil, eval_args = { buffer, item } });

	if not config then
		return;
	end

	local range = item.range;
	---@type string?
	local hl;

	if type(config.hl) == "string" then
		hl = config.hl --[[ @as string ]];
	elseif vim.islist(config.hl) == true then
		hl = config.hl[utils.clamp(item.level, 1, #config.hl)];
	end

	local previewable = true;

	local invalid_symbols = vim.list_extend(vim.tbl_keys(symbols.typst_entries), vim.tbl_keys(symbols.typst_shorthands));
	local valid_symbols = vim.tbl_keys(symbols.superscripts);

	local lines = vim.deepcopy(item.text);

	lines[1] = string.gsub(lines[1], "^%{", "");
	lines[#lines] = string.gsub(lines[#lines], "%}$", "");

	for _, line in ipairs(lines) do
		if utils.str_contains(line, invalid_symbols) == true then
			previewable = false;
			break;
		elseif utils.str_contains(line, valid_symbols) == false then
			previewable = false;
			break;
		end
	end

	---+${Lua, Render markers}
	if item.parenthesis == true then
		vim.api.nvim_buf_set_extmark(buffer, typst.ns, range.row_start, range.col_start, {
			undo_restore = false, invalidate = true,
			end_col = range.col_start + 2,
			conceal = "",

			virt_text_pos = "inline",
			virt_text = previewable == false and {
				{ config.marker_left or "↑(", utils.set_hl(hl) }
			} or nil,

			hl_mode = "combine"
		});

		vim.api.nvim_buf_set_extmark(buffer, typst.ns, range.row_end, range.col_end - 1, {
			undo_restore = false, invalidate = true,
			end_col = range.col_end,
			conceal = "",

			virt_text_pos = "inline",
			virt_text = previewable == false and {
				{ config.marker_right or ")", utils.set_hl(hl) }
			} or nil,

			hl_mode = "combine"
		});
	else
		vim.api.nvim_buf_set_extmark(buffer, typst.ns, range.row_start, range.col_start, {
			undo_restore = false, invalidate = true,
			end_col = range.col_start + 1,
			conceal = "",

			virt_text_pos = "inline",
			virt_text = previewable == false and {
				{ config.marker_left or "↑", utils.set_hl(hl) }
			} or nil,

			hl_mode = "combine"
		});
	end
	---_

	if previewable == true then
		table.insert(typst.cache.superscripts, item);
	else
		vim.api.nvim_buf_set_extmark(buffer, typst.ns, range.row_start, range.col_start, {
			undo_restore = false, invalidate = true,
			end_row = range.row_end,
			end_col = range.col_end,

			hl_group = utils.set_hl(hl)
		});
	end
	---_
end

---@param buffer integer
---@param item __typst.symbols
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

	vim.api.nvim_buf_set_extmark(buffer, typst.ns, range.row_start, range.col_start, {
		undo_restore = false, invalidate = true,
		end_col = range.col_end,
		conceal = "",

		virt_text_pos = "inline",
		virt_text = {
			{ symbols.typst_entries[item.name], utils.set_hl(config.hl) }
		},
		hl_mode = "combine"
	});
	---_
end

---@param buffer integer
---@param item __typst.terms
typst.term = function (buffer, item)
	---+${func}

	---@type typst.terms?
	local main_config = spec.get({ "typst", "terms" }, { fallback = nil });

	if not main_config then
		return;
	end

	---@type term.opts?
	local config = utils.match(
		main_config,
		item.label,
		{
			eval_args = { buffer, item }
		}
	);

	if not config then
		return;
	end

	local range = item.range;

	vim.api.nvim_buf_set_extmark(buffer, typst.ns, range.row_start, range.col_start, {
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
	local style;

	local function modify_style(new_style)
		if style == nil then
			return true;
		elseif new_style.range and utils.within_range(style.range, new_style.range) == true then
			return true;
		end

		return false;
	end

	--- Check for subscript styles.
	for _, node in ipairs(typst.cache.subscripts or {}) do
		if utils.within_range(node.range, range) and modify_style(node) == true then
			style = node;
			break;
		end
	end

	--- Check for superscript styles.
	for _, node in ipairs(typst.cache.superscripts or {}) do
		if utils.within_range(node.range, range) and modify_style(node) == true then
			style = node;
			break;
		end
	end

	local virt_text, virt_hl;

	if style == nil then
		--- No styles were found.
		return;
	elseif style.class == "typst_subscript" then
		local config = spec.get({ "typst", "subscripts", "hl" }, { fallback = nil, eval_args = { buffer, style } });

		virt_text = symbols.tostring("subscripts", item.text[1])
		virt_hl = config.hl;
	elseif style.class == "typst_superscript" then
		local config = spec.get({ "typst", "superscripts", "hl" }, { fallback = nil, eval_args = { buffer, style } });

		virt_text = symbols.tostring("superscripts", item.text[1])
		virt_hl = config.hl;
	else
		--- Unknown style.
		return;
	end

	vim.api.nvim_buf_set_extmark(buffer, typst.ns, range.row_start, range.col_start, {
		undo_restore = false, invalidate = true,
		end_row = range.row_end,
		end_col = range.col_end,

		virt_text_pos = "overlay",
		virt_text = {
			{ virt_text, utils.set_hl(virt_hl) }
		},
		hl_mode = "combine"
	});
	---_
end

--- Renders typst previews.
---@param buffer integer
---@param content table[]
typst.render = function (buffer, content)
	typst.cache = {
		superscripts = {},
		subscripts = {}
	};

	for _, item in ipairs(content or {}) do
		if typst[item.class:gsub("^typst_", "")] then
			pcall(typst[item.class:gsub("^typst_", "")], buffer, item);
		end
	end
end

--- Clear typst previews.
---@param buffer integer
---@param from integer?
---@param to integer?
typst.clear = function (buffer, from, to)
	vim.api.nvim_buf_clear_namespace(buffer, typst.ns, from or 0, to or -1);
end

return typst;
