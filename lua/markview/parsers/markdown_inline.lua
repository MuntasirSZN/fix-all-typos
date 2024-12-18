local inline = {};

--- Queried contents
---@type table[]
inline.content = {};

--- Queried contents, but sorted
inline.sorted = {}

inline.insert = function (data)
	table.insert(inline.content, data);

	if not inline.sorted[data.class] then
		inline.sorted[data.class] = {};
	end

	table.insert(inline.sorted[data.class], data);
end

--- Cached stuff
inline.cache = {
	checkbox = {},
	link_ref = {}
}

--- Checkbox parser.
---@param buffer integer
---@param range TSNode.range
inline.checkbox = function (buffer, _, _, range)
	local line = vim.api.nvim_buf_get_lines(buffer, range.row_start, range.row_start + 1, false)[1];

	local before = line:sub(0, range.col_start);
	local inner = line:sub(range.col_start + 1, range.col_end - 1);

	if not (before:match("^[%s%>]*[%-%+%*]%s$") or before:match("^[%s%>]*%d+[%.%)]%s$")) then
		return;
	end

	inline.insert({
		class = "inline_checkbox",

		text = inner:gsub("[%[%]]", ""),

		range = range
	});

	inline.cache.checkbox[range.row_start] = #inline.content;
end

--- Inline code parser.
---@param text string[]
---@param range TSNode.range
inline.code_span = function (_, _, text, range)
	inline.insert({
		class = "inline_code_span",

		text = text,
		range = range
	})
end

--- Embed file link parser.
---@param text string[]
---@param range __inline.link_range
inline.embed_file = function (_, _, text, range)
	local class = "inline_link_embed_file";
	local tmp, label;

	if text[1]:match("%#%^(.+)%]%]$") then
		class = "inline_link_block_ref";
		tmp, label = text[1]:match("^(.*)%#%^(.+)%]%]$");

		range.label_start = range.col_start + #tmp + 2;
		range.label_end = range.col_end - 2;
	else
		label = text[1]:match("%[%[([^%[+])%]%]");
	end

	inline.insert({
		class = class,
		has_file = class == "inline_link_block_ref",

		text = text,
		label = label,

		range = range
	});
end

--- Email parser.
---@param text string[]
---@param range __inline.link_range
inline.email = function (_, _, text, range)
	range.label_start = range.col_start + 1;
	range.label_end = range.col_end - 1;

	inline.insert({
		class = "inline_link_email",

		text = text[1]:sub(range.col_start, range.col_end),
		label = text[1]:sub(range.col_start + 2, range.col_end - 1),

		range = range
	})
end

--- Uri autolink parser.
---@param text string[]
---@param range TSNode.range
inline.entity = function (_, _, text, range)
	inline.insert({
		class = "inline_entity",

		text = text[1]:gsub("[^%a%d]", ""),
		range = range
	})
end

--- Uri autolink parser.
---@param text string[]
inline.escaped = function (_, _, text, range)
	inline.insert({
		class = "inline_escaped",

		text = text[1]:sub(range.col_start + 1, range.col_end - 1),
		range = range
	});
end

--- Footnote parser.
---@param text string[]
---@param range __inline.link_range
inline.footnote = function (_, _, text, range)
	inline.insert({
		class = "inline_footnote",

		text = text[1]:sub(range.col_start + 1, range.col_end - 1),
		label = text[1]:sub(range.col_start + 2, range.col_end - 1),

		range = range
	});
end

--- Highlight parser.
---@param buffer integer
---@param range TSNode.range
inline.highlights = function (buffer, _, _, range)
	local utils = require("markview.utils");
	local lines = vim.api.nvim_buf_get_lines(buffer, range.row_start, range.row_end + (range.row_end == range.row_start and 1 or 0), false);

	for l, line in ipairs(lines) do
		local _line = line;

		for highlight in line:gmatch("%=%=([^=]+)%=%=") do
			local c_s, c_e = _line:find("%=%=" .. utils.escape_string(highlight) .. "%=%=")

			inline.insert({
				class = "inline_highlight",
				text = highlight,

				range = {
					row_start = range.row_start + (l - 1),
					col_start = c_s - 1,

					row_end = range.row_start + (l - 1),
					col_end = c_e
				}
			});

			_line = _line:gsub("%=%=" .. utils.escape_string(highlight) .. "%=%=", function (s)
				return string.rep("X", vim.fn.strchars(s))
			end, 1)
		end
	end
end

--- Image link parser.
---@param TSNode table
---@param text string[]
---@param range __inline.link_range
inline.image = function (buffer, TSNode, text, range)
	if text[1]:match("^%!%[%[") and text[1]:match("%]%]$") then
		inline.embed_file(buffer, TSNode, text, range);
		return;
	end

	local link_label;
	local link_desc;

	if TSNode:named_child(0) then
		link_label = vim.treesitter.get_node_text(TSNode:named_child(0), buffer):gsub("[%[%]%(%)]", "");
		range.label = { TSNode:named_child(0):range() };
	end

	if TSNode:named_child(1) then
		link_desc = vim.treesitter.get_node_text(TSNode:named_child(1), buffer):gsub("[%[%]%(%)]", "");
		range.description = { TSNode:named_child(1):range() };
	end

	inline.insert({
		class = "inline_link_image",

		text = text,
		description = link_desc,
		label = link_label,

		range = range
	})
end

--- Hyperlink parser.
---@param buffer integer
---@param text string[]
---@param range __inline.link_range
inline.inline_link = function (buffer, TSNode, text, range)
	local link_desc;
	local link_label;

	if TSNode:named_child(0) then
		link_label = vim.treesitter.get_node_text(TSNode:named_child(0), buffer):gsub("[%[%]]", "");
		range.label = { TSNode:named_child(0):range() };
	end

	if TSNode:named_child(1) then
		link_desc = vim.treesitter.get_node_text(TSNode:named_child(1), buffer):gsub("[%[%]%(%)]", "");
		range.description = { TSNode:named_child(1):range() };
	end

	inline.insert({
		class = "inline_link_hyperlink",

		text = text,
		description = link_desc,
		label = link_label,

		range = range
	});
end

--- Uri autolink parser.
---@param text string[]
---@param range __inline.link_range
inline.internal_link = function (_, _, text, range)
	local class, alias = "inline_link_internal", nil;
	local label;

	---@diagnostic disable-next-line
	text = text[1]:gsub("[%[%]]", "");

	if text:match("%#%^(.+)$") then
		local tmp;

		class = "inline_link_block_ref";
		tmp, label = text:match("^(.*)%#%^(.+)$");

		range.label_start = range.col_start + #tmp + 2;
		range.label_end = range.col_end - 2;
	elseif text:match("%|([^%|]+)$") then
		label = text;
		range.alias_start, range.alias_end, alias = text:find("%|([^%|]+)$");

		range.alias_start = range.alias_start + range.col_start + 2;
		range.alias_end = range.alias_end + range.col_start + 2;
	end

	inline.insert({
		class = class,

		text = text,
		alias = alias,
		label = label,

		range = range
	});
end

--- Reference link parser.
---@param buffer integer
---@param TSNode table
---@param text string[]
---@param range __inline.link_range
inline.reference_link = function (buffer, TSNode, text, range)
	local link_desc;
	local link_label;

	if TSNode:named_child(0) then
		link_label = vim.treesitter.get_node_text(TSNode:named_child(0), buffer):gsub("[%[%]]", "");
		range.label = { TSNode:named_child(0):range() };
	end

	if TSNode:named_child(1) then
		link_desc = vim.treesitter.get_node_text(TSNode:named_child(1), buffer):gsub("[%[%]%(%)]", "");
		range.description = { TSNode:named_child(1):range() };
	end

	inline.insert({
		class = "inline_link_hyperlink",

		text = text,
		description = link_desc,
		label = link_label,

		range = range
	});
end

--- Shortcut link parser.
---@param buffer integer
---@param TSNode table
---@param text string[]
---@param range __inline.link_range
inline.shortcut_link = function (buffer, TSNode, text, range)
	local s_line = vim.api.nvim_buf_get_lines(buffer, range.row_start, range.row_start + 1, false)[1];
	local e_line = vim.api.nvim_buf_get_lines(buffer, range.row_end, range.row_end + 1, false)[1];

	local before = s_line:sub(0, range.col_start);
	local after  = e_line:sub(range.col_end);

	if text[1]:match("^%[%^") then
		--- Footnote
		return;
	elseif before:match("^[%s%>]*[%+%-%*]%s+$") and text[1]:match("^%[.%]$") then
		--- Checkbox
		return;
	elseif before:match("^[%s%>]*%d+[%.%)]%s+$") and text[1]:match("^%[.%]$") then
		--- Checkbox (ordered list item)
		return;
	elseif before:match("%!%[$") and after:match("^%]") then
		return;
	elseif before:match("%[$") and after:match("^%]") then
		if range.row_start ~= range.row_end then
			goto invalid_link;
		end

		text[1]     = "[" .. text[1];
		text[#text] = text[#text] .. "]";

		range.col_start = range.col_start - 1;
		range.col_end   = range.col_end + 1;

		--- Obsidian internal link
		inline.internal_link(buffer, TSNode, text, range);
		return;
	end

	::invalid_link::

	local label = "";

	for l, line in ipairs(text) do
		if l == 1 then
			line = line:gsub("^%[", "");
		elseif l == #text then
			line = line:gsub("%]$", "");
		end

		if label ~= "" then
			label = label .. "\n";
		end

		label = label .. line;
	end

	inline.insert({
		class = "inline_link_shortcut",

		text = text,
		label = label,

		range = range
	})
end

--- Uri autolink parser.
---@param TSNode table
---@param text string[]
---@param range __inline.link_range
inline.uri_autolink = function (_, TSNode, text, range)
	range.label = { range.row_start, range.col_start, range.row_end, range.col_end };

	inline.insert({
		class = "inline_link_uri_autolink",
		node = TSNode,

		text = text,
		label = text[1]:sub(range.col_start + 1, range.col_end - 1),

		range = range
	})
end

inline.parse = function (buffer, TSTree, from, to)
	inline.sorted = {};
	inline.content = {};

	local pre_queries = vim.treesitter.query.parse("markdown_inline", [[
		(
			(shortcut_link) @markdown_inline.checkbox
			(#match? @markdown_inline.checkbox "^\\[.\\]$")) ; Fix the match pattern to match literal [ & ]
	]]);

	for capture_id, capture_node, _, _ in pre_queries:iter_captures(TSTree:root(), buffer, from, to) do
		local capture_name = pre_queries.captures[capture_id];
		local r_start, c_start, r_end, c_end = capture_node:range();

		local capture_text = vim.api.nvim_buf_get_lines(buffer, r_start, r_start == r_end and r_end + 1 or r_end, false);

		inline[capture_name:gsub("^markdown_inline%.", "")](buffer, capture_node, capture_text, {
			row_start = r_start,
			col_start = c_start,

			row_end = r_end,
			col_end = c_end
		});
	end

	local scanned_queries = vim.treesitter.query.parse("markdown_inline", [[
		((inline) @markdown_inline.highlights
			(#match? @markdown_inline.highlights "\\=\\=.+\\=\\="))

		((email_autolink) @markdown_inline.email)

		((image) @markdown_inline.image)

		([
			(inline_link)
			(collapsed_reference_link)] @markdown_inline.inline_link)

		((full_reference_link
			(link_text)
			(link_label)) @markdown_inline.reference_link)

		((shortcut_link
			(link_text) @footnote.text
			(#match? @footnote.text "^\\^")) @markdown_inline.footnote)

		((shortcut_link) @markdown_inline.shortcut_link)

		((uri_autolink) @markdown_inline.uri_autolink)

		((code_span) @markdown_inline.code_span)

		([
			(entity_reference)
			(numeric_character_reference)] @markdown_inline.entity)

		((backslash_escape) @markdown_inline.escaped)
	]]);

	for capture_id, capture_node, _, _ in scanned_queries:iter_captures(TSTree:root(), buffer, from, to) do
		local capture_name = scanned_queries.captures[capture_id];

		if not capture_name:match("^markdown_inline") then
			goto continue;
		end

		local r_start, c_start, r_end, c_end = capture_node:range();
		local capture_text = vim.treesitter.get_node_text(capture_node, buffer);

		--- Doesn't end with a newline. Add it.
		if not capture_text:match("\n$") then
			capture_text = capture_text .. "\n";
		end

		local lines = {};

		for line in capture_text:gmatch("(.-)\n") do
			table.insert(lines, line);
		end

		pcall(
			inline[capture_name:gsub("^markdown_inline%.", "")],
			buffer,
			capture_node,
			lines,

			{
				row_start = r_start,
				col_start = c_start,

				row_end = r_end,
				col_end = c_end
			}
		);

	   ::continue::
	end

	return inline.content, inline.sorted;
end

return inline;
