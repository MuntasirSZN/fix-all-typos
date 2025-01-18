local inline = {};

local spec = require("markview.spec");
local utils = require("markview.utils");
local entities = require("markview.entities");

inline.ns = vim.api.nvim_create_namespace("markview/inline");

--- Render checkbox.
---@param buffer integer
---@param item __inline.checkboxes
inline.checkbox = function (buffer, item)
	---+${func, Renders Checkboxes}

	---@type inline.checkboxes?
	local main_config = spec.get({ "markdown_inline", "checkboxes" }, { fallback = nil });

	if not main_config then
		return;
	end

	---@type { text: string, hl: string?, scope_hl: string? }
	local config;
	local state = item.state or "";
	local range = item.range;

	if ( state == "X" or state == "x" ) and spec.get({ "checked" }, { source = main_config, eval_args = { buffer, item } }) then
		config = spec.get({ "checked" }, { source = main_config, eval_args = { buffer, item } });
	elseif state == " " and spec.get({ "unchecked" }, { source = main_config, eval_args = { buffer, item } }) then
		config = spec.get({ "unchecked" }, { source = main_config, eval_args = { buffer, item } });
	elseif spec.get({ state }, { source = main_config, eval_args = { buffer, item } }) then
		config = spec.get({ state }, { source = main_config, eval_args = { buffer, item } });
	else
		return;
	end

	vim.api.nvim_buf_set_extmark(buffer, inline.ns, range.row_start, range.col_start, {
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

--- Render inline codes.
---@param buffer integer
---@param item __inline.inline_codes
inline.code_span = function (buffer, item)
	---+${func, Render Inline codes}

	---@type config.inline_generic?
	local config = spec.get({ "markdown_inline", "inline_codes" }, { fallback = nil, eval_args = { buffer, item } });
	local range = item.range;

	if not config then
		return;
	end

	vim.api.nvim_buf_set_extmark(buffer, inline.ns, range.row_start, range.col_start, {
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

	vim.api.nvim_buf_set_extmark(buffer, inline.ns, range.row_start, range.col_start + 1, {
		undo_restore = false, invalidate = true,
		end_row = range.row_end,
		end_col = range.col_end - 1,
		hl_group = utils.set_hl(config.hl)
	});

	vim.api.nvim_buf_set_extmark(buffer, inline.ns, range.row_end, range.col_end - 1, {
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
			vim.api.nvim_buf_set_extmark(buffer, inline.ns, range.row_start + (l - 1), range.col_start + #line, {
				undo_restore = false, invalidate = true,

				virt_text_pos = "inline",
				virt_text = {
					{ config.padding_right or "", utils.set_hl(config.padding_right_hl or config.hl) },
				},

				hl_mode = "combine"
			});
		elseif l == #item.text then
			vim.api.nvim_buf_set_extmark(buffer, inline.ns, range.row_start + (l - 1), 0, {
				undo_restore = false, invalidate = true,
				right_gravity = true,

				virt_text_pos = "inline",
				virt_text = {
					{ config.padding_left or "", utils.set_hl(config.padding_left_hl or config.hl) },
				},

				hl_mode = "combine"
			});
		else
			vim.api.nvim_buf_set_extmark(buffer, inline.ns, range.row_start + (l - 1), 0, {
				undo_restore = false, invalidate = true,
				right_gravity = true,

				virt_text_pos = "inline",
				virt_text = {
					{ config.padding_left or "", utils.set_hl(config.padding_left_hl or config.hl) },
				},

				hl_mode = "combine"
			});
			vim.api.nvim_buf_set_extmark(buffer, inline.ns, range.row_start + (l - 1), #line, {
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

--- Render entity reference.
---@param buffer integer
---@param item __inline.entities
inline.entity = function (buffer, item)
	---+${func, Renders Character entities}
	local config = spec.get({ "markdown_inline", "entities" }, { fallback = nil });
	local range = item.range;

	if not config then
		return;
	elseif not entities.get(item.name) then
		return;
	end

	vim.api.nvim_buf_set_extmark(buffer, inline.ns, range.row_start, range.col_start, {
		undo_restore = false, invalidate = true,
		end_col = range.col_end,
		conceal = "",

		virt_text_pos = "inline",
		virt_text = {
			{ entities.get(item.name), utils.set_hl(config.hl) }
		}
	});
	---_
end

--- Render escaped characters.
---@param buffer integer
---@param item __inline.escapes
inline.escaped = function (buffer, item)
	---+${func, Render Escaped characters}

	---@type { enable: boolean }?
	local config = spec.get({ "markdown_inline", "escapes" }, { fallback = nil });
	local range = item.range;

	if not config then
		return;
	end

	vim.api.nvim_buf_set_extmark(buffer, inline.ns, range.row_start, range.col_start, {
		undo_restore = false, invalidate = true,
		end_col = range.col_start + 1,
		conceal = ""
	});
	---_
end

--- Render footnotes.
---@param buffer integer
---@param item __inline.footnotes
inline.footnote = function (buffer, item)
	---+${func}

	---@type inline.footnotes?
	local main_config = spec.get({ "markdown_inline", "footnotes" }, { fallback = nil });
	local range = item.range;

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

	if config == nil then
		return;
	end

	---+${custom, Draw the parts for the autolinks}
	vim.api.nvim_buf_set_extmark(buffer, inline.ns, range.row_start, range.col_start, {
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

	vim.api.nvim_buf_set_extmark(buffer, inline.ns, range.row_start, range.col_start, {
		undo_restore = false, invalidate = true,
		end_col = range.col_end,
		hl_group = utils.set_hl(config.hl)
	});

	vim.api.nvim_buf_set_extmark(buffer, inline.ns, range.row_start, range.col_end - 1, {
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

--- Render ==highlights==.
---@param buffer integer
---@param item __inline.highlights
inline.highlight = function (buffer, item)
	---+${func, Render Email links}

	---@type inline.highlights?
	local main_config = spec.get({ "markdown_inline", "highlights" }, { fallback = nil });
	local range = item.range;

	if not main_config then
		return;
	end

	---@type config.inline_generic?
	local config = utils.match(
		main_config,
		item.text,
		{
			eval_args = { buffer, item }
		}
	);

	if config == nil then
		return;
	end

	---+${custom, Draw the parts for the email}
	vim.api.nvim_buf_set_extmark(buffer, inline.ns, range.row_start, range.col_start, {
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

	vim.api.nvim_buf_set_extmark(buffer, inline.ns, range.row_start, range.col_start + 2, {
		undo_restore = false, invalidate = true,
		end_col = range.col_end - 2,
		hl_group = utils.set_hl(config.hl)
	});

	vim.api.nvim_buf_set_extmark(buffer, inline.ns, range.row_start, range.col_end - 2, {
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

--- Render [[#^block_references]].
---@param buffer integer
---@param item __inline.block_references
inline.link_block_ref = function (buffer, item)
	---+${func, Render Obsidian's block reference links}

	---@type inline.block_references?
	local main_config = spec.get({ "markdown_inline", "block_references" }, { fallback = nil });
	local range = item.range;

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

	---+${custom, Draw the parts for the embed file links}
	vim.api.nvim_buf_set_extmark(buffer, inline.ns, range.row_start, range.col_start, {
		undo_restore = false, invalidate = true,
		end_col = range.label[2],
		conceal = "",

		virt_text_pos = "inline",
		virt_text = {
			{ config.corner_left or "", utils.set_hl(config.corner_left_hl or config.hl) },
			{ config.padding_left or "", utils.set_hl(config.padding_left_hl or config.hl) },

			{ config.icon or "", utils.set_hl(config.icon_hl or config.hl) }
		},

		hl_mode = "combine"
	});

	vim.api.nvim_buf_set_extmark(buffer, inline.ns, range.row_start, range.col_start, {
		undo_restore = false, invalidate = true,
		end_row = range.row_end,
		end_col = range.col_end,
		hl_group = utils.set_hl(config.hl)
	});

	if config.file_hl and vim.islist(range.file) then
		vim.api.nvim_buf_set_extmark(buffer, inline.ns, range.file[1], range.file[2], {
			undo_restore = false, invalidate = true,
			end_row = range.file[3],
			end_col = range.file[4],
			hl_group = utils.set_hl(config.file_hl)
		});
	end

	if config.block_hl and vim.islist(range.block) then
		vim.api.nvim_buf_set_extmark(buffer, inline.ns, range.block[1], range.block[2], {
			undo_restore = false, invalidate = true,
			end_row = range.block[3],
			end_col = range.block[4],
			hl_group = utils.set_hl(config.block_hl)
		});
	end

	vim.api.nvim_buf_set_extmark(buffer, inline.ns, range.row_start, vim.islist(range.alias) and range.alias[4] or (range.col_end - 2), {
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

--- Render ![[embed_files]].
---@param buffer integer
---@param item __inline.embed_files
inline.link_embed_file = function (buffer, item)
	---+${func, Render Obsidian's embed file links}

	---@type inline.embed_files?
	local main_config = spec.get({ "markdown_inline", "embed_files" }, { fallback = nil });
	local range = item.range;

	if not main_config then
		return;
	end

	---@type config.inline_generic
	local config = utils.match(
		main_config,
		item.label,
		{
			eval_args = { buffer, item }
		}
	);

	---+${custom, Draw the parts for the embed file links}
	vim.api.nvim_buf_set_extmark(buffer, inline.ns, range.row_start, range.col_start, {
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

	vim.api.nvim_buf_set_extmark(buffer, inline.ns, range.row_start, range.col_start, {
		undo_restore = false, invalidate = true,
		end_col = range.col_end,
		hl_group = utils.set_hl(config.hl)
	});

	vim.api.nvim_buf_set_extmark(buffer, inline.ns, range.row_start, range.col_end - 2, {
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

--- Render <email@mail.com>.
---@param buffer integer
---@param item __inline.emails
inline.link_email = function (buffer, item)
	---+${func, Render Email links}

	---@type inline.emails?
	local main_config = spec.get({ "markdown_inline", "emails" }, { fallback = nil });
	local range = item.range;

	if not main_config then
		return;
	end

	---@type config.inline_generic
	local config = utils.match(
		main_config,
		item.label,
		{
			eval_args = { buffer, item }
		}
	);

	---+${custom, Draw the parts for the email}
	vim.api.nvim_buf_set_extmark(buffer, inline.ns, range.row_start, range.col_start, {
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

	vim.api.nvim_buf_set_extmark(buffer, inline.ns, range.row_start, range.col_start + 1, {
		undo_restore = false, invalidate = true,
		end_col = range.col_end - 1,
		hl_group = utils.set_hl(config.hl)
	});

	vim.api.nvim_buf_set_extmark(buffer, inline.ns, range.row_start, range.col_end - 1, {
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

--- Render [hyperlink].
---@param buffer integer
---@param item __inline.hyperlinks
inline.link_hyperlink = function (buffer, item)
	---+${func, Render normal links}

	---@type inline.hyperlinks?
	local main_config = spec.get({ "markdown_inline", "hyperlinks" }, { fallback = nil });
	local range = item.range;

	if not main_config then
		return;
	end

	---@type config.inline_generic
	local config = utils.match(
		main_config,
		item.description,
		{
			eval_args = { buffer, item }
		}
	);

	---@type integer[]
	local r_label = range.label;

	---+${custom, Draw the parts for the shortcut links}
	vim.api.nvim_buf_set_extmark(buffer, inline.ns, r_label[1], r_label[2] - 1, {
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

	vim.api.nvim_buf_set_extmark(buffer, inline.ns, r_label[1], r_label[2], {
		undo_restore = false, invalidate = true,
		end_row = r_label[3],
		end_col = r_label[4],
		hl_group = utils.set_hl(config.hl)
	});

	vim.api.nvim_buf_set_extmark(buffer, inline.ns, r_label[3], r_label[4], {
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
			vim.api.nvim_buf_set_extmark(buffer, inline.ns, l, range.col_start + #line, {
				undo_restore = false, invalidate = true,

				virt_text_pos = "inline",
				virt_text = {
					{ config.padding_right or "", utils.set_hl(config.padding_right_hl or config.hl) },
				},

				hl_mode = "combine"
			});
		elseif l == r_label[3] then
			vim.api.nvim_buf_set_extmark(buffer, inline.ns, l, 0, {
				undo_restore = false, invalidate = true,
				right_gravity = true,

				virt_text_pos = "inline",
				virt_text = {
					{ config.padding_left or "", utils.set_hl(config.padding_left_hl or config.hl) },
				},

				hl_mode = "combine"
			});
		else
			vim.api.nvim_buf_set_extmark(buffer, inline.ns, l, 0, {
				undo_restore = false, invalidate = true,
				right_gravity = true,

				virt_text_pos = "inline",
				virt_text = {
					{ config.padding_left or "", utils.set_hl(config.padding_left_hl or config.hl) },
				},

				hl_mode = "combine"
			});
			vim.api.nvim_buf_set_extmark(buffer, inline.ns, l, #line, {
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

--- Render ![image](image.svg).
---@param buffer integer
---@param item __inline.images
inline.link_image = function (buffer, item)
	---+${func, Render Image links}

	---@type inline.images?
	local main_config = spec.get({ "markdown_inline", "images" }, { fallback = nil });
	local range = item.range;

	if not main_config then
		return;
	end

	---@type config.inline_generic
	local config = utils.match(
		main_config,
		item.description,
		{
			eval_args = { buffer, item }
		}
	);

	---@type string[]
	local r_label = range.label;

	---+${custom, Draw the parts for the image links}
	vim.api.nvim_buf_set_extmark(buffer, inline.ns, r_label[1], r_label[2] - 1, {
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

	vim.api.nvim_buf_set_extmark(buffer, inline.ns, r_label[1], r_label[2], {
		undo_restore = false, invalidate = true,
		end_row = r_label[3],
		end_col = r_label[4],
		hl_group = utils.set_hl(config.hl)
	});

	vim.api.nvim_buf_set_extmark(buffer, inline.ns, r_label[3], r_label[4], {
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
			vim.api.nvim_buf_set_extmark(buffer, inline.ns, l, range.col_start + #line, {
				undo_restore = false, invalidate = true,

				virt_text_pos = "inline",
				virt_text = {
					{ config.padding_right or "", utils.set_hl(config.padding_right_hl or config.hl) },
				},

				hl_mode = "combine"
			});
		elseif l == r_label[3] then
			vim.api.nvim_buf_set_extmark(buffer, inline.ns, l, 0, {
				undo_restore = false, invalidate = true,
				right_gravity = true,

				virt_text_pos = "inline",
				virt_text = {
					{ config.padding_left or "", utils.set_hl(config.padding_left_hl or config.hl) },
				},

				hl_mode = "combine"
			});
		else
			vim.api.nvim_buf_set_extmark(buffer, inline.ns, l, 0, {
				undo_restore = false, invalidate = true,
				right_gravity = true,

				virt_text_pos = "inline",
				virt_text = {
					{ config.padding_left or "", utils.set_hl(config.padding_left_hl or config.hl) },
				},

				hl_mode = "combine"
			});
			vim.api.nvim_buf_set_extmark(buffer, inline.ns, l, #line, {
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

--- Render [shortcut_link].
---@param buffer integer
---@param item __inline.hyperlinks
inline.link_shortcut = function (buffer, item)
	---+${func, Render Shortcut links}

	---@type inline.hyperlinks?
	local main_config = spec.get({ "markdown_inline", "hyperlinks" }, { fallback = nil });
	local range = item.range;

	if not main_config then
		return;
	end

	---@type config.inline_generic
	local config = utils.match(
		main_config,
		item.label,
		{
			eval_args = { buffer, item }
		}
	);

	---+${custom, Draw the parts for the shortcut links}
	vim.api.nvim_buf_set_extmark(buffer, inline.ns, range.row_start, range.col_start, {
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

	vim.api.nvim_buf_set_extmark(buffer, inline.ns, range.row_start, range.col_start + 1, {
		undo_restore = false, invalidate = true,
		end_row = range.row_end,
		end_col = range.col_end - 1,
		hl_group = utils.set_hl(config.hl)
	});

	vim.api.nvim_buf_set_extmark(buffer, inline.ns, range.row_end, range.col_end - 1, {
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
			vim.api.nvim_buf_set_extmark(buffer, inline.ns, range.row_start + (l - 1), range.col_start + #line, {
				undo_restore = false, invalidate = true,

				virt_text_pos = "inline",
				virt_text = {
					{ config.padding_right or "", utils.set_hl(config.padding_right_hl or config.hl) },
				},

				hl_mode = "combine"
			});
		elseif l == #item.text then
			vim.api.nvim_buf_set_extmark(buffer, inline.ns, range.row_start + (l - 1), 0, {
				undo_restore = false, invalidate = true,
				right_gravity = true,

				virt_text_pos = "inline",
				virt_text = {
					{ config.padding_left or "", utils.set_hl(config.padding_left_hl or config.hl) },
				},

				hl_mode = "combine"
			});
		else
			vim.api.nvim_buf_set_extmark(buffer, inline.ns, range.row_start + (l - 1), 0, {
				undo_restore = false, invalidate = true,
				right_gravity = true,

				virt_text_pos = "inline",
				virt_text = {
					{ config.padding_left or "", utils.set_hl(config.padding_left_hl or config.hl) },
				},

				hl_mode = "combine"
			});
			vim.api.nvim_buf_set_extmark(buffer, inline.ns, range.row_start + (l - 1), #line, {
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

--- Render <https://uri_autolinks.com>
---@param buffer integer
---@param item __inline.uri_autolinks
inline.link_uri_autolink = function (buffer, item)
	---+${func, Render URI links}

	---@type inline.uri_autolinks?
	local main_config = spec.get({ "markdown_inline", "uri_autolinks" }, { fallback = nil });
	local range = item.range;

	if not main_config then
		return;
	end

	---@type config.inline_generic
	local config = utils.match(
		main_config,
		item.label,
		{
			eval_args = { buffer, item }
		}
	);

	---+${custom, Draw the parts for the autolinks}
	vim.api.nvim_buf_set_extmark(buffer, inline.ns, range.row_start, range.col_start, {
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

	vim.api.nvim_buf_set_extmark(buffer, inline.ns, range.row_start, range.col_start, {
		undo_restore = false, invalidate = true,
		end_row = range.row_end,
		end_col = range.col_end,
		hl_group = utils.set_hl(config.hl)
	});

	vim.api.nvim_buf_set_extmark(buffer, inline.ns, range.row_end, range.col_end - 1, {
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

--- Render [[internal_links]].
---@param buffer integer
---@param item __inline.internal_links
inline.link_internal = function (buffer, item)
	---+${func, Render Obsidian's internal links}

	---@type inline.internal_links?
	local main_config = spec.get({ "markdown_inline", "internal_links" }, { fallback = nil });
	local range = item.range;

	if not main_config then
		return;
	end

	---@type config.inline_generic
	local config = utils.match(
		main_config,
		item.label,
		{
			eval_args = { buffer, item }
		}
	);

	---+${custom, Draw the parts for the internal links}
	vim.api.nvim_buf_set_extmark(buffer, inline.ns, range.row_start, range.col_start, {
		undo_restore = false, invalidate = true,
		end_col = vim.islist(range.alias) and range.alias[2] or (range.col_start + 2),
		conceal = "",

		virt_text_pos = "inline",
		virt_text = {
			{ config.corner_left or "", utils.set_hl(config.corner_left_hl or config.hl) },
			{ config.padding_left or "", utils.set_hl(config.padding_left_hl or config.hl) },

			{ config.icon or "", utils.set_hl(config.icon_hl or config.hl) }
		},

		hl_mode = "combine"
	});

	vim.api.nvim_buf_set_extmark(buffer, inline.ns, range.row_start, range.col_start, {
		undo_restore = false, invalidate = true,
		end_col = range.col_end,
		hl_group = utils.set_hl(config.hl)
	});

	vim.api.nvim_buf_set_extmark(buffer, inline.ns, range.row_start, vim.islist(range.alias) and range.alias[4] or (range.col_end - 2), {
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

--- Renders inline markdown.
---@param buffer integer
---@param content table[]
inline.render = function (buffer, content)
	for _, item in ipairs(content or {}) do
		local success, err = pcall(inline[item.class:gsub("^inline_", "")], buffer, item);

		if success == false then
			require("markview.health").notify("trace", {
				level = 4,
				message = err
			});
		end
	end
end

--- Clears markdown inline previews.
---@param buffer integer
---@param from integer?
---@param to integer?
inline.clear = function (buffer, from, to)
	vim.api.nvim_buf_clear_namespace(buffer, inline.ns, from or 0, to or -1);
end

return inline;
