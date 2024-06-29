local parser = {};
local renderer = require("markview/renderer");

--- Function to parse the markdown document
---
---@param buffer number
---@param TStree any
parser.md = function (buffer, TStree)
	local scanned_queies = vim.treesitter.query.parse("markdown", [[
		(atx_heading [
			(atx_h1_marker)
			(atx_h2_marker)
			(atx_h3_marker)
			(atx_h4_marker)
			(atx_h5_marker)
			(atx_h6_marker)
		] @header)

		((fenced_code_block) @code)

		((block_quote) @block_quote)

		((thematic_break) @horizontal_rule)

		((pipe_table) @table)

		((task_list_marker_unchecked) @checkbox_off)
		((task_list_marker_checked) @checkbox_on)

		((list_item) @list_item)
	]]);

	-- The last 2 _ represent the metadata & query
	for capture_id, capture_node, _, _ in scanned_queies:iter_captures(TStree:root()) do
		local capture_name = scanned_queies.captures[capture_id];
		local capture_text = vim.treesitter.get_node_text(capture_node, buffer);
		local row_start, col_start, row_end, col_end = capture_node:range();

		if capture_name == "header" then
			table.insert(renderer.views[buffer], {
				type = "header",
				level = vim.fn.strchars(capture_text),

				row_start = row_start,
				row_end = row_end,

				col_start = col_start,
				col_end = col_end
			})
		elseif capture_name == "code" then
			local line_lens = {};
			local highest_len = 0;

			for i = 1,(row_end - row_start) - 2 do
				local this_code = vim.api.nvim_buf_get_lines(buffer, row_start + i, row_start + i + 1, false)[1];
				local len = vim.fn.strchars(this_code) or 0;

				if len > highest_len then
					highest_len = len;
				end

				table.insert(line_lens, len);
			end

			table.insert(renderer.views[buffer], {
				type = "code_block",
				language = vim.treesitter.get_node_text(capture_node:named_child(1), buffer),

				line_lengths = line_lens,
				largest_line = highest_len,

				row_start = row_start,
				row_end = row_end,

				col_start = col_start,
				col_end = col_end
			})
		elseif capture_name == "block_quote" then
			table.insert(renderer.views[buffer], {
				type = "block_quote",

				row_start = row_start,
				row_end = row_end,

				col_start = col_start,
				col_end = col_end
			})
		elseif capture_name == "horizontal_rule" then
			table.insert(renderer.views[buffer], {
				type = "horizontal_rule",

				row_start = row_start,
				row_end = row_end,

				col_start = col_start,
				col_end = col_end
			})
		elseif capture_name == "table" then
			local rows = {};
			local table_structure = {};

			for row in capture_node:iter_children() do
				local tmp = {};

				if row:type() == "pipe_table_header" then
					table.insert(table_structure, "header");
				elseif row:type() == "pipe_table_delimiter_row" then
					table.insert(table_structure, "seperator");
				elseif row:type() == "pipe_table_row" then
					table.insert(table_structure, "content");
				else
					table.insert(table_structure, "unknown");
				end

				for col in vim.treesitter.get_node_text(row, buffer):gmatch("%s*|([^|\n]*)") do
					if col ~= "" then
						table.insert(tmp, "|")
						table.insert(tmp, col)
					end
				end

				table.insert(tmp, "|")

				table.insert(rows, tmp)
			end

			table.insert(renderer.views[buffer], {
				type = "table",

				table_structure = table_structure;
				rows = rows,

				row_start = row_start,
				row_end = row_end,

				col_start = col_start,
				col_end = col_end
			})
		elseif capture_name == "list_item" then
			local marker = capture_node:named_child(0);

			table.insert(renderer.views[buffer], {
				type = "list_item",
				marker_symbol = vim.treesitter.get_node_text(marker, buffer),

				row_start = row_start,
				row_end = row_end,

				col_start = col_start,
				col_end = col_end
			})
		elseif capture_name == "checkbox_off" then
			table.insert(renderer.views[buffer], {
				type = "checkbox",
				checked = false,

				row_start = row_start,
				row_end = row_end,

				col_start = col_start,
				col_end = col_end
			})
		elseif capture_name == "checkbox_on" then
			table.insert(renderer.views[buffer], {
				type = "checkbox",
				checked = true,

				row_start = row_start,
				row_end = row_end,

				col_start = col_start,
				col_end = col_end
			})
		end
	end
end

--- Function to parse inline_markdown
---
---@param buffer number
---@param TStree any
parser.md_inline = function (buffer, TStree)
	local scanned_queies = vim.treesitter.query.parse("markdown_inline", [[
		((shortcut_link) @callout)

		((inline_link) @link)

		((image) @image)

		((code_span) @code)
	]]);

	-- The last 2 _ represent the metadata & query
	for capture_id, capture_node, _, _ in scanned_queies:iter_captures(TStree:root()) do
		local capture_name = scanned_queies.captures[capture_id];
		local capture_text = vim.treesitter.get_node_text(capture_node, buffer);
		local row_start, col_start, row_end, col_end = capture_node:range();

		if capture_name == "callout" then
			local line = vim.api.nvim_buf_get_lines(buffer, row_start, row_start + 1, false);
			local title = string.match(line ~= nil and line[1] or "", "%b[]%s*(.*)$")

			for _, extmark in ipairs(renderer.views[buffer]) do
				if extmark.type == "block_quote" and extmark.row_start == row_start then
					extmark.callout = string.match(capture_text, "%[!([^%]]+)%]");
					extmark.title = title;

					extmark.line_width = vim.fn.strchars(line[1])
				end
			end
		elseif capture_name == "link" then
			local link_text = string.match(capture_text, "%[(.-)%]");
			local link_address = string.match(capture_text, "%((.-)%)")

			table.insert(renderer.views[buffer], {
				type = "hyperlink",

				link_text = link_text,
				link_address = link_address,

				row_start = row_start,
				row_end = row_end,

				col_start = col_start,
				col_end = col_end
			})
		elseif capture_name == "image" then
			local link_text = string.match(capture_text, "%[(.-)%]");
			local link_address = string.match(capture_text, "%((.-)%)")

			table.insert(renderer.views[buffer], {
				type = "image",

				link_text = link_text,
				link_address = link_address,

				row_start = row_start,
				row_end = row_end,

				col_start = col_start,
				col_end = col_end
			})
		elseif capture_name == "code" then
			-- vim.print(row_start)
			table.insert(renderer.views[buffer], {
				type = "inline_code",

				text = string.gsub(capture_text, "`", ""),

				row_start = row_start,
				row_end = row_end,

				col_start = col_start,
				col_end = col_end
			})
		end
	end
end

--- Initializes the parsers on the specified buffer
--- Parsed data is stored as a "view" in renderer.lua
---
---@param buffer number
parser.init = function (buffer)
	local root_parser = vim.treesitter.get_parser(buffer);
	root_parser:parse(true);

	-- Clear the previous view
	renderer.views[buffer] = {};

	root_parser:for_each_tree(function (TStree, language_tree)
		local tree_language = language_tree:lang();

		if tree_language == "markdown" then
			parser.md(buffer, TStree)
		elseif tree_language == "markdown_inline" then
			parser.md_inline(buffer, TStree);
		end
	end)
end

return parser;
