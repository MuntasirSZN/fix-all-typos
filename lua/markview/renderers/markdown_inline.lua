local inline = {};

local spec = require("markview.spec");
local utils = require("markview.utils");
local entities = require("markview.entities");

inline.__ns = {
	__call = function (self, key)
		return self[key] or self.default;
	end
}

inline.ns = {
	default = vim.api.nvim_create_namespace("markview/inline"),
};
setmetatable(inline.ns, inline.__ns)

inline.set_ns = function ()
	local ns_pref = spec.get({ "markdown_inline", "use_seperate_ns" }, { fallback = true });

	local available = vim.api.nvim_get_namespaces();
	local ns_list = {
		["block_references"] = "markview/markdown_inline/block_references",
		["checkboxes"] = "markview/markdown_inline/checkboxes",
		["emails"] = "markview/markdown_inline/emails",
		["embed_files"] = "markview/markdown_inline/embed_files",
		["entities"] = "markview/markdown_inline/entities",
		["escapes"] = "markview/markdown_inline/escapes",
		["footnotes"] = "markview/markdown_inline/footnotes",
		["highlights"] = "markview/markdown_inline/highlights",
		["hyperlinks"] = "markview/markdown_inline/hyperlinks",
		["images"] = "markview/markdown_inline/images",
		["inline_codes"] = "markview/markdown_inline/inline_codes",
		["internal_links"] = "markview/markdown_inline/internal_links",
		["uri_autolinks"] = "markview/markdown_inline/uri_autolinks",
	};

	if ns_pref == true then
		for ns, name in pairs(ns_list) do
			if vim.list_contains(available, ns) == false then
				inline.ns[ns] = vim.api.nvim_create_namespace(name);
			end
		end
	end
end

inline.custom_config = function (config, value)
	if not config.patterns or not value then
		return config.default;
	end

	for _, pattern in ipairs(config.patterns) do
		if pattern.match_string and value:match(pattern.match_string) then
			return vim.tbl_deep_extend("force", config.default or {}, pattern);
		end
	end

	return config.default;
end

---@param buffer integer
---@param item __inline.link
inline.link_block_ref = function (buffer, item)
	---+${func, Render Obsidian's block reference links}

	---@type inline.item?
	local main_config = spec.get({ "markdown_inline", "block_references" }, { fallback = nil });
	local range = item.range;

	if not main_config then
		return;
	end

	---@type inline.item_config?
	local config = utils.pattern(
		main_config,
		item.label,
		{
			eval_args = { buffer, item }
		}
	);

	if not config then
		return;
	end

	---+${custom, Draw the parts for the embed file links}
	vim.api.nvim_buf_set_extmark(buffer, inline.ns("block_references"), range.row_start, range.col_start, {
		undo_restore = false, invalidate = true,
		end_col = range.col_start + (item.has_file and 2 or 4),
		conceal = "",

		virt_text_pos = "inline",
		virt_text = {
			{ config.corner_left or "", utils.set_hl(config.corner_left_hl or config.hl) },
			{ config.padding_left or "", utils.set_hl(config.padding_left_hl or config.hl) },

			{ config.icon or "", utils.set_hl(config.icon_hl or config.hl) }
		},

		hl_mode = "combine"
	});

	vim.api.nvim_buf_set_extmark(buffer, inline.ns("block_references"), range.row_start, range.col_start, {
		undo_restore = false, invalidate = true,
		end_col = range.col_end,
		hl_group = utils.set_hl(config.hl)
	});

	vim.api.nvim_buf_set_extmark(buffer, inline.ns("block_references"), range.row_start, range.alias_end or (range.col_end - 2), {
		undo_restore = false, invalidate = true,
		end_col = range.col_end,
		conceal = "",

		virt_text_pos = "inline",
		virt_text = {
			{ config.padding_right or "", utils.set_hl(config.padding_right_hl or config.hl) },
			{ config.corner_right or "", utils.set_hl(config.corner_right_hl or config.hl) }
		},

		hl_mode = "combine"
	});
	---_
	---_
end

---@param buffer integer
---@param item __inline.checkbox
inline.checkbox = function (buffer, item)
	---+${func, Renders Checkboxes}

	---@type inline.checkboxes?
	local main_config = spec.get({ "markdown_inline", "checkboxes" }, { fallback = nil });

	if not main_config then
		return;
	end

	---@type { text: string, hl: string?, scope_hl: string? }
	local config;
	local range = item.range;

	if ( item.text == "X" or item.text == "x" ) and spec.get({ "checked" }, { source = main_config, eval_args = { buffer, item } }) then
		config = spec.get({ "checked" }, { source = main_config, eval_args = { buffer, item } });
	elseif item.text == " " and spec.get({ "unchecked" }, { source = main_config, eval_args = { buffer, item } }) then
		config = spec.get({ "unchecked" }, { source = main_config, eval_args = { buffer, item } });
	elseif spec.get({ item.text }, { source = main_config, eval_args = { buffer, item } }) then
		config = spec.get({ item.text }, { source = main_config, eval_args = { buffer, item } });
	else
		return;
	end

	vim.api.nvim_buf_set_extmark(buffer, inline.ns("checkboxes"), range.row_start, range.col_start, {
		undo_restore = false, invalidate = true,
		end_col = range.col_end,
		conceal = "",

		virt_text_pos = "inline",
		virt_text = {
			{ config.text, utils.set_hl(config.hl) }
		}
	});
	---_
end

---@param buffer integer
---@param item __inline.inline_code
inline.code_span = function (buffer, item)
	---+${func, Render Inline codes}

	---@type inline.item_config?
	local config = spec.get({ "markdown_inline", "inline_codes" }, { fallback = nil, eval_args = { buffer, item } });
	local range = item.range;

	if not config then
		return;
	end

	vim.api.nvim_buf_set_extmark(buffer, inline.ns("inline_codes"), range.row_start, range.col_start, {
		undo_restore = false, invalidate = true,
		end_col = range.col_start + 1,
		conceal = "",

		virt_text_pos = "inline",
		virt_text = {
			{ config.corner_left or "", utils.set_hl(config.corner_left_hl or config.hl) },
			{ config.padding_left or "", utils.set_hl(config.padding_left_hl or config.hl) }
		},

		hl_mode = "combine"
	});

	vim.api.nvim_buf_set_extmark(buffer, inline.ns("inline_codes"), range.row_start, range.col_start + 1, {
		undo_restore = false, invalidate = true,
		end_row = range.row_end,
		end_col = range.col_end - 1,
		hl_group = utils.set_hl(config.hl)
	});

	vim.api.nvim_buf_set_extmark(buffer, inline.ns("inline_codes"), range.row_end, range.col_end - 1, {
		undo_restore = false, invalidate = true,
		end_col = range.col_end,
		conceal = "",

		virt_text_pos = "inline",
		virt_text = {
			{ config.corner_right or "", utils.set_hl(config.corner_right_hl or config.hl) },
			{ config.padding_right or "", utils.set_hl(config.padding_right_hl or config.hl) }
		},

		hl_mode = "combine"
	});

	if range.row_start == range.row_end then
		return;
	end

	for l, line in ipairs(item.text) do
		if l == 1 then
			vim.api.nvim_buf_set_extmark(buffer, inline.ns("inline_codes"), range.row_start + (l - 1), range.col_start + #line, {
				undo_restore = false, invalidate = true,

				virt_text_pos = "inline",
				virt_text = {
					{ config.padding_right or "", utils.set_hl(config.padding_right_hl or config.hl) },
				},

				hl_mode = "combine"
			});
		elseif l == #item.text then
			vim.api.nvim_buf_set_extmark(buffer, inline.ns("inline_codes"), range.row_start + (l - 1), 0, {
				undo_restore = false, invalidate = true,
				right_gravity = true,

				virt_text_pos = "inline",
				virt_text = {
					{ config.padding_left or "", utils.set_hl(config.padding_left_hl or config.hl) },
				},

				hl_mode = "combine"
			});
		else
			vim.api.nvim_buf_set_extmark(buffer, inline.ns("inline_codes"), range.row_start + (l - 1), 0, {
				undo_restore = false, invalidate = true,
				right_gravity = true,

				virt_text_pos = "inline",
				virt_text = {
					{ config.padding_left or "", utils.set_hl(config.padding_left_hl or config.hl) },
				},

				hl_mode = "combine"
			});
			vim.api.nvim_buf_set_extmark(buffer, inline.ns("inline_codes"), range.row_start + (l - 1), #line, {
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
---@param item __inline.link
inline.highlight = function (buffer, item)
	---+${func, Render Email links}

	---@type inline.item?
	local main_config = spec.get({ "markdown_inline", "highlights" }, { fallback = nil });
	local range = item.range;

	if not main_config then
		return;
	end

	---@type inline.item_config
	local config = utils.pattern(
		main_config,
		item.text,
		{
			eval_args = { buffer, item }
		}
	);

	---+${custom, Draw the parts for the email}
	vim.api.nvim_buf_set_extmark(buffer, inline.ns("highlights"), range.row_start, range.col_start, {
		undo_restore = false, invalidate = true,
		end_col = range.col_start + 2,
		conceal = "",

		virt_text_pos = "inline",
		virt_text = {
			{ config.corner_left or "", utils.set_hl(config.corner_left_hl or config.hl) },
			{ config.padding_left or "", utils.set_hl(config.padding_left_hl or config.hl) },

			{ config.icon or "", utils.set_hl(config.icon_hl or config.hl) }
		},

		hl_mode = "combine"
	});

	vim.api.nvim_buf_set_extmark(buffer, inline.ns("highlights"), range.row_start, range.col_start + 2, {
		undo_restore = false, invalidate = true,
		end_col = range.col_end - 2,
		hl_group = utils.set_hl(config.hl)
	});

	vim.api.nvim_buf_set_extmark(buffer, inline.ns("highlights"), range.row_start, range.col_end - 2, {
		undo_restore = false, invalidate = true,
		end_col = range.col_end,
		conceal = "",

		virt_text_pos = "inline",
		virt_text = {
			{ config.corner_right or "", utils.set_hl(config.corner_right_hl or config.hl) },
			{ config.padding_right or "", utils.set_hl(config.padding_right_hl or config.hl) }
		},

		hl_mode = "combine"
	});
	---_
	---_
end

---@param buffer integer
---@param item __inline.link
inline.link_email = function (buffer, item)
	---+${func, Render Email links}

	---@type inline.item?
	local main_config = spec.get({ "markdown_inline", "emails" }, { fallback = nil });
	local range = item.range;

	if not main_config then
		return;
	end

	---@type inline.item_config
	local config = utils.pattern(
		main_config,
		item.label,
		{
			eval_args = { buffer, item }
		}
	);

	---+${custom, Draw the parts for the email}
	vim.api.nvim_buf_set_extmark(buffer, inline.ns("emails"), range.row_start, range.col_start, {
		undo_restore = false, invalidate = true,
		end_col = range.col_start + 1,
		conceal = "",

		virt_text_pos = "inline",
		virt_text = {
			{ config.corner_left or "", utils.set_hl(config.corner_left_hl or config.hl) },
			{ config.padding_left or "", utils.set_hl(config.padding_left_hl or config.hl) },

			{ config.icon or "", utils.set_hl(config.icon_hl or config.hl) }
		},

		hl_mode = "combine"
	});

	vim.api.nvim_buf_set_extmark(buffer, inline.ns("emails"), range.row_start, range.col_start + 1, {
		undo_restore = false, invalidate = true,
		end_col = range.col_end - 1,
		hl_group = utils.set_hl(config.hl)
	});

	vim.api.nvim_buf_set_extmark(buffer, inline.ns("emails"), range.row_start, range.col_end - 1, {
		undo_restore = false, invalidate = true,
		end_col = range.col_end,
		conceal = "",

		virt_text_pos = "inline",
		virt_text = {
			{ config.corner_right or "", utils.set_hl(config.corner_right_hl or config.hl) },
			{ config.padding_right or "", utils.set_hl(config.padding_right_hl or config.hl) }
		},

		hl_mode = "combine"
	});
	---_
	---_
end

---@param buffer integer
---@param item __inline.link
inline.link_embed_file = function (buffer, item)
	---+${func, Render Obsidian's embed file links}

	---@type inline.item?
	local main_config = spec.get({ "markdown_inline", "embed_files" }, { fallback = nil });
	local range = item.range;

	if not main_config then
		return;
	end

	---@type inline.item_config
	local config = utils.pattern(
		main_config,
		item.label,
		{
			eval_args = { buffer, item }
		}
	);

	---+${custom, Draw the parts for the embed file links}
	vim.api.nvim_buf_set_extmark(buffer, inline.ns("embed_files"), range.row_start, range.col_start, {
		undo_restore = false, invalidate = true,
		end_col = range.col_start + 2,
		conceal = "",

		virt_text_pos = "inline",
		virt_text = {
			{ config.corner_left or "", utils.set_hl(config.corner_left_hl or config.hl) },
			{ config.padding_left or "", utils.set_hl(config.padding_left_hl or config.hl) },

			{ config.icon or "", utils.set_hl(config.icon_hl or config.hl) }
		},

		hl_mode = "combine"
	});

	vim.api.nvim_buf_set_extmark(buffer, inline.ns("embed_files"), range.row_start, range.col_start, {
		undo_restore = false, invalidate = true,
		end_col = range.col_end,
		hl_group = utils.set_hl(config.hl)
	});

	vim.api.nvim_buf_set_extmark(buffer, inline.ns("embed_files"), range.row_start, range.col_end - 2, {
		undo_restore = false, invalidate = true,
		end_col = range.col_end,
		conceal = "",

		virt_text_pos = "inline",
		virt_text = {
			{ config.padding_right or "", utils.set_hl(config.padding_right_hl or config.hl) },
			{ config.corner_right or "", utils.set_hl(config.corner_right_hl or config.hl) }
		},

		hl_mode = "combine"
	});
	---_
	---_
end

---@param buffer integer
---@param item __inline.link
inline.link_hyperlink = function (buffer, item)
	---+${func, Render normal links}

	---@type inline.item?
	local main_config = spec.get({ "markdown_inline", "hyperlinks" }, { fallback = nil });
	local range = item.range;

	if not main_config then
		return;
	end

	---@type inline.item_config
	local config = utils.pattern(
		main_config,
		item.label,
		{
			eval_args = { buffer, item }
		}
	);

	local r_label = range.label;

	---+${custom, Draw the parts for the shortcut links}
	vim.api.nvim_buf_set_extmark(buffer, inline.ns("hyperlinks"), r_label[1], r_label[2] - 1, {
		undo_restore = false, invalidate = true,
		end_col = r_label[2],
		conceal = "",

		virt_text_pos = "inline",
		virt_text = {
			{ config.corner_left or "", utils.set_hl(config.corner_left_hl or config.hl) },
			{ config.padding_left or "", utils.set_hl(config.padding_left_hl or config.hl) },

			{ config.icon or "", utils.set_hl(config.icon_hl or config.hl) }
		},

		hl_mode = "combine"
	});

	vim.api.nvim_buf_set_extmark(buffer, inline.ns("hyperlinks"), r_label[1], r_label[2], {
		undo_restore = false, invalidate = true,
		end_row = r_label[3],
		end_col = r_label[4],
		hl_group = utils.set_hl(config.hl)
	});

	vim.api.nvim_buf_set_extmark(buffer, inline.ns("hyperlinks"), r_label[3], r_label[4], {
		undo_restore = false, invalidate = true,
		end_row = range.row_end,
		end_col = range.col_end,
		conceal = "",

		virt_text_pos = "inline",
		virt_text = {
			{ config.padding_right or "", utils.set_hl(config.padding_right_hl or config.hl) },
			{ config.corner_right or "", utils.set_hl(config.corner_right_hl or config.hl) }
		},

		hl_mode = "combine"
	});
	---_

	if r_label[1] == r_label[3] then
		return;
	end

	for l = r_label[1], r_label[3] do
		local line = item.text[(l - range.row_start) + 1];

		if l == r_label[1] then
			vim.api.nvim_buf_set_extmark(buffer, inline.ns("hyperlinks"), l, range.col_start + #line, {
				undo_restore = false, invalidate = true,

				virt_text_pos = "inline",
				virt_text = {
					{ config.padding_right or "", utils.set_hl(config.padding_right_hl or config.hl) },
				},

				hl_mode = "combine"
			});
		elseif l == r_label[3] then
			vim.api.nvim_buf_set_extmark(buffer, inline.ns("hyperlinks"), l, 0, {
				undo_restore = false, invalidate = true,
				right_gravity = true,

				virt_text_pos = "inline",
				virt_text = {
					{ config.padding_left or "", utils.set_hl(config.padding_left_hl or config.hl) },
				},

				hl_mode = "combine"
			});
		else
			vim.api.nvim_buf_set_extmark(buffer, inline.ns("hyperlinks"), l, 0, {
				undo_restore = false, invalidate = true,
				right_gravity = true,

				virt_text_pos = "inline",
				virt_text = {
					{ config.padding_left or "", utils.set_hl(config.padding_left_hl or config.hl) },
				},

				hl_mode = "combine"
			});
			vim.api.nvim_buf_set_extmark(buffer, inline.ns("hyperlinks"), l, #line, {
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
---@param item __inline.link
inline.link_image = function (buffer, item)
	---+${func, Render Image links}

	---@type inline.item?
	local main_config = spec.get({ "markdown_inline", "images" }, { fallback = nil });
	local range = item.range;

	if not main_config then
		return;
	end

	---@type inline.item_config
	local config = utils.pattern(
		main_config,
		item.label,
		{
			eval_args = { buffer, item }
		}
	);

	local r_label = range.label;

	---+${custom, Draw the parts for the image links}
	vim.api.nvim_buf_set_extmark(buffer, inline.ns("images"), r_label[1], r_label[2] - 1, {
		undo_restore = false, invalidate = true,
		end_col = r_label[2],
		conceal = "",

		virt_text_pos = "inline",
		virt_text = {
			{ config.corner_left or "", utils.set_hl(config.corner_left_hl or config.hl) },
			{ config.padding_left or "", utils.set_hl(config.padding_left_hl or config.hl) },

			{ config.icon or "", utils.set_hl(config.icon_hl or config.hl) }
		},

		hl_mode = "combine"
	});

	vim.api.nvim_buf_set_extmark(buffer, inline.ns("images"), r_label[1], r_label[2], {
		undo_restore = false, invalidate = true,
		end_row = r_label[3],
		end_col = r_label[4],
		hl_group = utils.set_hl(config.hl)
	});

	vim.api.nvim_buf_set_extmark(buffer, inline.ns("images"), r_label[3], r_label[4], {
		undo_restore = false, invalidate = true,
		end_row = range.row_end,
		end_col = range.col_end,
		conceal = "",

		virt_text_pos = "inline",
		virt_text = {
			{ config.padding_right or "", utils.set_hl(config.padding_right_hl or config.hl) },
			{ config.corner_right or "", utils.set_hl(config.corner_right_hl or config.hl) }
		},

		hl_mode = "combine"
	});
	---_

	if r_label[1] == r_label[3] then
		return;
	end

	for l = r_label[1], r_label[3] do
		local line = item.text[(l - range.row_start) + 1];

		if l == r_label[1] then
			vim.api.nvim_buf_set_extmark(buffer, inline.ns("images"), l, range.col_start + #line, {
				undo_restore = false, invalidate = true,

				virt_text_pos = "inline",
				virt_text = {
					{ config.padding_right or "", utils.set_hl(config.padding_right_hl or config.hl) },
				},

				hl_mode = "combine"
			});
		elseif l == r_label[3] then
			vim.api.nvim_buf_set_extmark(buffer, inline.ns("images"), l, 0, {
				undo_restore = false, invalidate = true,
				right_gravity = true,

				virt_text_pos = "inline",
				virt_text = {
					{ config.padding_left or "", utils.set_hl(config.padding_left_hl or config.hl) },
				},

				hl_mode = "combine"
			});
		else
			vim.api.nvim_buf_set_extmark(buffer, inline.ns("images"), l, 0, {
				undo_restore = false, invalidate = true,
				right_gravity = true,

				virt_text_pos = "inline",
				virt_text = {
					{ config.padding_left or "", utils.set_hl(config.padding_left_hl or config.hl) },
				},

				hl_mode = "combine"
			});
			vim.api.nvim_buf_set_extmark(buffer, inline.ns("images"), l, #line, {
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
---@param item __inline.link
inline.link_shortcut = function (buffer, item)
	---+${func, Render Shortcut links}

	---@type inline.item?
	local main_config = spec.get({ "markdown_inline", "hyperlinks" }, { fallback = nil });
	local range = item.range;

	if not main_config then
		return;
	end

	---@type inline.item_config
	local config = utils.pattern(
		main_config,
		item.label,
		{
			eval_args = { buffer, item }
		}
	);

	---+${custom, Draw the parts for the shortcut links}
	vim.api.nvim_buf_set_extmark(buffer, inline.ns("hyperlinks"), range.row_start, range.col_start, {
		undo_restore = false, invalidate = true,
		end_col = range.col_start + 1,
		conceal = "",

		virt_text_pos = "inline",
		virt_text = {
			{ config.corner_left or "", utils.set_hl(config.corner_left_hl or config.hl) },
			{ config.padding_left or "", utils.set_hl(config.padding_left_hl or config.hl) },

			{ config.icon or "", utils.set_hl(config.icon_hl or config.hl) }
		},

		hl_mode = "combine"
	});

	vim.api.nvim_buf_set_extmark(buffer, inline.ns("hyperlinks"), range.row_start, range.col_start + 1, {
		undo_restore = false, invalidate = true,
		end_row = range.row_end,
		end_col = range.col_end - 1,
		hl_group = utils.set_hl(config.hl)
	});

	vim.api.nvim_buf_set_extmark(buffer, inline.ns("hyperlinks"), range.row_end, range.col_end - 1, {
		undo_restore = false, invalidate = true,
		end_col = range.col_end,
		conceal = "",

		virt_text_pos = "inline",
		virt_text = {
			{ config.padding_right or "", utils.set_hl(config.padding_right_hl or config.hl) },
			{ config.corner_right or "", utils.set_hl(config.corner_right_hl or config.hl) }
		},

		hl_mode = "combine"
	});
	---_

	if range.row_start == range.row_end then
		return;
	end

	for l, line in ipairs(item.text) do
		if l == 1 then
			vim.api.nvim_buf_set_extmark(buffer, inline.ns("hyperlinks"), range.row_start + (l - 1), range.col_start + #line, {
				undo_restore = false, invalidate = true,

				virt_text_pos = "inline",
				virt_text = {
					{ config.padding_right or "", utils.set_hl(config.padding_right_hl or config.hl) },
				},

				hl_mode = "combine"
			});
		elseif l == #item.text then
			vim.api.nvim_buf_set_extmark(buffer, inline.ns("hyperlinks"), range.row_start + (l - 1), 0, {
				undo_restore = false, invalidate = true,
				right_gravity = true,

				virt_text_pos = "inline",
				virt_text = {
					{ config.padding_left or "", utils.set_hl(config.padding_left_hl or config.hl) },
				},

				hl_mode = "combine"
			});
		else
			vim.api.nvim_buf_set_extmark(buffer, inline.ns("hyperlinks"), range.row_start + (l - 1), 0, {
				undo_restore = false, invalidate = true,
				right_gravity = true,

				virt_text_pos = "inline",
				virt_text = {
					{ config.padding_left or "", utils.set_hl(config.padding_left_hl or config.hl) },
				},

				hl_mode = "combine"
			});
			vim.api.nvim_buf_set_extmark(buffer, inline.ns("hyperlinks"), range.row_start + (l - 1), #line, {
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
---@param item __inline.link
inline.link_uri_autolink = function (buffer, item)
	---+${func, Render URI links}

	---@type inline.item?
	local main_config = spec.get({ "markdown_inline", "uri_autolinks" }, { fallback = nil });
	local range = item.range;

	if not main_config then
		return;
	end

	---@type inline.item_config
	local config = utils.pattern(
		main_config,
		item.label,
		{
			eval_args = { buffer, item }
		}
	);

	local r_label = range.label;

	---+${custom, Draw the parts for the autolinks}
	vim.api.nvim_buf_set_extmark(buffer, inline.ns("uri_autolinks"), r_label[1], r_label[2], {
		undo_restore = false, invalidate = true,
		end_col = r_label[2] + 1,
		conceal = "",

		virt_text_pos = "inline",
		virt_text = {
			{ config.corner_left or "", utils.set_hl(config.corner_left_hl or config.hl) },
			{ config.padding_left or "", utils.set_hl(config.padding_left_hl or config.hl) },

			{ config.icon or "", utils.set_hl(config.icon_hl or config.hl) }
		},

		hl_mode = "combine"
	});

	vim.api.nvim_buf_set_extmark(buffer, inline.ns("uri_autolinks"), range.row_start, range.col_start, {
		undo_restore = false, invalidate = true,
		end_row = range.row_end,
		end_col = range.col_end,
		hl_group = utils.set_hl(config.hl)
	});

	vim.api.nvim_buf_set_extmark(buffer, inline.ns("uri_autolinks"), r_label[3], r_label[4] - 1, {
		undo_restore = false, invalidate = true,
		end_col = r_label[4],
		conceal = "",

		virt_text_pos = "inline",
		virt_text = {
			{ config.padding_right or "", utils.set_hl(config.padding_right_hl or config.hl) },
			{ config.corner_right or "", utils.set_hl(config.corner_right_hl or config.hl) }
		},

		hl_mode = "combine"
	});
	---_
	---_
end

---@param buffer integer
---@param item __inline.link
inline.link_internal = function (buffer, item)
	---+${func, Render Obsidian's internal links}

	---@type inline.item?
	local main_config = spec.get({ "markdown_inline", "internal_links" }, { fallback = nil });
	local range = item.range;

	if not main_config then
		return;
	end

	---@type inline.item_config
	local config = utils.pattern(
		main_config,
		item.label,
		{
			eval_args = { buffer, item }
		}
	);

	---+${custom, Draw the parts for the internal links}
	vim.api.nvim_buf_set_extmark(buffer, inline.ns("internal_links"), range.row_start, range.col_start, {
		undo_restore = false, invalidate = true,
		end_col = range.alias_start or (range.col_start + 2),
		conceal = "",

		virt_text_pos = "inline",
		virt_text = {
			{ config.corner_left or "", utils.set_hl(config.corner_left_hl or config.hl) },
			{ config.padding_left or "", utils.set_hl(config.padding_left_hl or config.hl) },

			{ config.icon or "", utils.set_hl(config.icon_hl or config.hl) }
		},

		hl_mode = "combine"
	});

	vim.api.nvim_buf_set_extmark(buffer, inline.ns("internal_links"), range.row_start, range.col_start, {
		undo_restore = false, invalidate = true,
		end_col = range.col_end,
		hl_group = utils.set_hl(config.hl)
	});

	vim.api.nvim_buf_set_extmark(buffer, inline.ns("internal_links"), range.row_start, range.alias_end or (range.col_end - 2), {
		undo_restore = false, invalidate = true,
		end_col = range.col_end,
		conceal = "",

		virt_text_pos = "inline",
		virt_text = {
			{ config.padding_right or "", utils.set_hl(config.padding_right_hl or config.hl) },
			{ config.corner_right or "", utils.set_hl(config.corner_right_hl or config.hl) }
		},

		hl_mode = "combine"
	});
	---_
	---_
end

---@param buffer integer
---@param item { class: "inline_escaped", text: string, range: TSNode.range }
inline.escaped = function (buffer, item)
	---+${func, Render Escaped characters}

	---@type { enable: boolean }?
	local config = spec.get({ "markdown_inline", "escapes" }, { fallback = nil });
	local range = item.range;

	if not config then
		return;
	end

	vim.api.nvim_buf_set_extmark(buffer, inline.ns("escapes"), range.row_start, range.col_start, {
		undo_restore = false, invalidate = true,
		end_col = range.col_start + 1,
		conceal = ""
	});
	---_
end

---@param buffer integer
---@param item { class: "inline_escaped", text: string, range: TSNode.range }
inline.entity = function (buffer, item)
	---+${func, Renders Character entities}
	local config = spec.get({ "markdown_inline", "entities" }, { fallback = nil });
	local range = item.range;

	if not config then
		return;
	elseif not entities.get(item.text) then
		return;
	end

	vim.api.nvim_buf_set_extmark(buffer, inline.ns("entities"), range.row_start, range.col_start, {
		undo_restore = false, invalidate = true,
		end_col = range.col_end,
		conceal = "",

		virt_text_pos = "inline",
		virt_text = {
			{ entities.get(item.text), utils.set_hl(config.hl) }
		}
	});
	---_
end

---@param buffer integer
---@param item __inline.link
inline.footnote = function (buffer, item)
	---+${func}

	---@type inline.item?
	local main_config = spec.get({ "markdown_inline", "footnotes" }, { fallback = nil });
	local range = item.range;

	if not main_config then
		return;
	end

	---@type inline.item_config
	local config = utils.pattern(
		main_config,
		item.label,
		{
			eval_args = { buffer, item }
		}
	);

	---+${custom, Draw the parts for the autolinks}
	vim.api.nvim_buf_set_extmark(buffer, inline.ns("footnotes"), range.row_start, range.col_start, {
		undo_restore = false, invalidate = true,
		end_col = range.col_start + 2,
		conceal = "",

		virt_text_pos = "inline",
		virt_text = {
			{ config.corner_left or "", utils.set_hl(config.corner_left_hl or config.hl) },
			{ config.padding_left or "", utils.set_hl(config.padding_left_hl or config.hl) },

			{ config.icon or "", utils.set_hl(config.icon_hl or config.hl) }
		},

		hl_mode = "combine"
	});

	vim.api.nvim_buf_set_extmark(buffer, inline.ns("footnotes"), range.row_start, range.col_start, {
		undo_restore = false, invalidate = true,
		end_col = range.col_end,
		hl_group = utils.set_hl(config.hl)
	});

	vim.api.nvim_buf_set_extmark(buffer, inline.ns("footnotes"), range.row_start, range.col_end - 1, {
		undo_restore = false, invalidate = true,
		end_col = range.col_end,
		conceal = "",

		virt_text_pos = "inline",
		virt_text = {
			{ config.padding_right or "", utils.set_hl(config.padding_right_hl or config.hl) },
			{ config.corner_right or "", utils.set_hl(config.corner_right_hl or config.hl) }
		},

		hl_mode = "combine"
	});
	---_
	---_
end

inline.render = function (buffer, content)
	inline.set_ns();

	for _, item in ipairs(content or {}) do
		pcall(inline[item.class:gsub("^inline_", "")], buffer, item);
		-- inline[item.class:gsub("^inline_", "")](buffer, item);
	end
end

inline.clear = function (buffer, ignore_ns, from, to)
	for name, ns in pairs(inline.ns) do
		if ignore_ns and vim.list_contains(ignore_ns, name) == false then
			vim.api.nvim_buf_clear_namespace(buffer, ns, from or 0, to or -1);
		end
	end
end

return inline;
