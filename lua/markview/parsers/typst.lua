local typst = {};
local utils = require("markview.utils");

typst.cache = {
	list_item_number = 0
};

--- Queried contents
---@type table[]
typst.content = {};

--- Queried contents, but sorted
typst.sorted = {}

typst.insert = function (data)
	table.insert(typst.content, data);

	if not typst.sorted[data.class] then
		typst.sorted[data.class] = {};
	end

	table.insert(typst.sorted[data.class], data);
end

--- Typst code parser.
---@param TSNode table
---@param text string[]
---@param range TSNode.range
typst.code = function (_, TSNode, text, range)
	---+${func}
	local node = TSNode:parent();

	while node do
		if node:type() == "code" then return; end

		node = node:parent();
	end

	for l, line in ipairs(text) do
		if l ==1 then goto continue; end

		text[l] = line:sub(range.col_start + 1);

		::continue::
	end

	typst.insert({
		class = "typst_code",
		inline = range.row_start == range.row_end,

		text = text,
		range = range
	});
	---_
end

--- Typst escaped character parser.
---@param TSNode table
---@param text string[]
---@param range TSNode.range
typst.escaped = function (_, TSNode, text, range)
	---+${func}
	local node = TSNode:parent();

	while node do
		if node:type() == "code" then return; end

		node = node:parent();
	end

	typst.insert({
		class = "typst_escaped",

		text = text,
		range = range
	});
	---_
end

--- Typst heading parser.
---@param text string[]
---@param range TSNode.range
typst.heading = function (_, _, text, range)
	---+${func}
	local level = text[1]:match("^(%=+)"):len();

	typst.insert({
		class = "typst_heading",
		level = level,

		text = text,
		range = range
	});
	---_
end

--- Typst label parser.
---@param text string[]
---@param range TSNode.range
typst.label = function (_, _, text, range)
	typst.insert({
		class = "typst_label",

		text = text,
		range = range
	});
end

--- Typst list item parser.
---@param buffer integer
---@param TSNode table
---@param text string[]
---@param range TSNode.range
typst.list_item = function (buffer, TSNode, text, range)
	---+${func}
	local line = vim.api.nvim_buf_get_lines(buffer, range.row_start, range.row_start + 1, false)[1]:sub(0, range.col_start);
	local marker = text[1]:match("^([%-%+])") or text[1]:match("^(%d+%.)");
	local number;

	if marker == "+" then
		local prev_item = TSNode:prev_sibling();
		local item_text = prev_item and vim.treesitter.get_node_text(prev_item, buffer) or "";

		if
			not prev_item or
			(
				prev_item:type() == "item" and
				item_text:match("^(%+)")
			)
		then
			typst.cache.list_item_number = typst.cache.list_item_number + 1;
		else
			typst.cache.list_item_number = 1;
		end

		number = typst.cache.list_item_number;
	end

	local row_end = range.row_start - 1;

	for l, ln in ipairs(text) do
		if
			l ~= 1 and
			(
				ln:match("^%s*([%+%-])") or
				ln:match("^%s*(%d)%.")
			)
		then
			break
		end

		row_end = row_end + 1;
	end

	range.row_end = row_end;

	typst.insert({
		class = "typst_list_item",
		indent = line:match("(%s*)$"):len(),
		marker = marker,
		number = number,

		text = text,
		range = range
	});
	---_
end

--- Typst list item parser.
---@param buffer integer
---@param text string[]
---@param range TSNode.range
typst.math = function (buffer, _, text, range)
	---+${func}
	local from, to = vim.api.nvim_buf_get_lines(buffer, range.row_start, range.row_start + 1, false)[1]:sub(0, range.col_start), vim.api.nvim_buf_get_lines(buffer, range.row_end, range.row_end + 1, false)[1]:sub(0, range.col_end);
	local inline, closed = false, true;

	if
		not from:match("^(%s*)$") or not to:match("^(%s*)%$$")
	then
		inline = true;
	elseif
		not text[1]:match("%$$")
	then
		inline = true;
	end

	if not text[#text]:match("%$$") then
		closed = false;
	end

	typst.insert({
		class = "typst_math",
		inline = inline,
		closed = closed,

		text = text,
		range = range
	});
	---_
end

--- Typst url links parser.
---@param text string[]
---@param range TSNode.range
typst.link_url = function (_, _, text, range)
	typst.insert({
		class = "typst_link_url",
		label = text,

		text = text,
		range = range
	});
end

--- Typst inline code parser.
---@param text string[]
---@param range TSNode.range
typst.raw_span = function (_, _, text, range)
	typst.insert({
		class = "typst_raw_span",

		text = text,
		range = range
	});
end

--- Typst code block parser.
---@param buffer integer
---@param TSNode table
---@param text string[]
---@param range TSNode.range
typst.raw_block = function (buffer, TSNode, text, range)
	---+${func}
	local lang_node = TSNode:field("lang")[1];
	local language;

	if lang_node then
		language = vim.treesitter.get_node_text(lang_node, buffer);
	end

	for l, line in ipairs(text) do
		if l == 1 then goto continue; end
		text[l] = line:sub(range.col_start + 1);
	    ::continue::
	end

	typst.insert({
		class = "typst_raw_block",
		language = language,

		text = text,
		range = range
	});
	---_
end

--- Typst strong text parser.
---@param TSNode table
---@param text string[]
---@param range TSNode.range
typst.strong = function (_, TSNode, text, range)
	local _n = TSNode:parent();

	while _n do
		if vim.list_contains({ "raw_span", "raw_blck", "code", "field" }, _n:type()) then
			return;
		end

		_n = _n:parent();
	end

	typst.insert({
		class = "typst_strong",

		text = text,
		range = range
	});
end

--- Typst emphasized text parser.
---@param TSNode table
---@param text string[]
---@param range TSNode.range
typst.emphasis = function (_, TSNode, text, range)
	local _n = TSNode:parent();

	while _n do
		if vim.list_contains({ "raw_span", "raw_blck", "code", "field" }, _n:type()) then
			return;
		end

		_n = _n:parent();
	end

	typst.insert({
		class = "typst_emphasis",

		text = text,
		range = range
	});
end

--- Typst reference link parser.
---@param text string[]
---@param range TSNode.range
typst.link_ref = function (_, _, text, range)
	typst.insert({
		class = "typst_link_ref",

		text = text,
		range = range
	});
end

--- Typst code block parser.
---@param buffer integer
---@param TSNode table
---@param text string[]
---@param range TSNode.range
typst.term = function (buffer, TSNode, text, range)
	for l, line in ipairs(text) do
		if l == 1 then goto continue; end
		text[l] = line:sub(range.col_start + 1);
	    ::continue::
	end

	typst.insert({
		class = "typst_term",
		term = vim.treesitter.get_node_text(
			TSNode:field("term")[1],
			buffer
		),

		text = text,
		range = range
	});
end


--- Typst single word symbol parser.
---@param TSNode table
---@param text string[]
---@param range TSNode.range
typst.idet = function (_, TSNode, text, range)
	---+${funx}
	local symbols = require("markview.symbols");
	if not symbols.typst_entries[text[1]] then return; end

	local _n = TSNode:parent();

	while _n do
		if vim.list_contains({ "raw_span", "raw_blck", "code", "field" }, _n:type()) then
			return;
		end

		_n = _n:parent();
	end

	typst.insert({
		class = "typst_symbol",
		name = text[1],

		text = text,
		range = range
	});
	---_
end


--- Typst subscript parser.
---@param TSNode table
---@param text string[]
---@param range TSNode.range
typst.subscript = function (_, TSNode, text, range)
	---+${func}
	local par = TSNode:type() == "group";
	local lvl = 0;
	local pre = true;

	local _n = TSNode;

	while _n do
		if _n:field("sub")[1] then
			lvl = lvl + 1;
		end

		_n = _n:parent();
	end

	range.col_start = range.col_start - 1;

	typst.insert({
		class = "typst_subscript",
		parenthesis = par,

		preview = pre,
		level = lvl,

		text = text,
		range = range
	});
	---_
end


--- Typst superscript parser.
---@param TSNode table
---@param text string[]
---@param range TSNode.range
typst.superscript = function (_, TSNode, text, range)
	---+${func}
	local par = TSNode:type() == "group";
	local lvl = 0;
	local pre = true;

	local _n = TSNode;

	while _n do
		if _n:field("sup")[1] then
			lvl = lvl + 1;
		end

		_n = _n:parent();
	end

	range.col_start = range.col_start - 1;

	typst.insert({
		class = "typst_superscript",
		parenthesis = par,

		preview = pre,
		level = lvl,

		text = text,
		range = range
	});
	---_
end


--- Typst symbol parser.
---@param TSNode table
---@param text string[]
---@param range TSNode.range
typst.symbol = function (_, TSNode, text, range)
	---+${func}
	for _, line in ipairs(text) do
		if not line:match("^[%a%.]+$") then
			return;
		end
	end

	local _n = TSNode:parent();

	while _n do
		if vim.list_contains({ "raw_span", "raw_blck", "code", "field" }, _n:type()) then
			return;
		end

		_n = _n:parent();
	end

	typst.insert({
		class = "typst_symbol",
		name = text[1],

		text = text,
		range = range
	});
	---_
end

--- Typst regular text parser.
---@param text string[]
---@param range TSNode.range
typst.text = function (_, _, text, range)
	typst.insert({
		class = "typst_text",

		text = text,
		range = range
	})
end


typst.parse = function (buffer, TSTree, from, to)
	typst.cache = {
		list_item_number = 0
	};

	-- Clear the previous contents
	typst.sorted = {};
	typst.content = {};

	local scanned_queries = vim.treesitter.query.parse("typst", [[
		((attach
			sub: (_) @typst.subscript))

		((attach
			sup: (_) @typst.superscript))

		((field) @typst.symbol)

		([
			(number)
			(symbol)
			(letter)
			] @typst.text)

		((ident) @typst.idet)

		((heading) @typst.heading)
		((escape) @typst.escaped)
		((item) @typst.list_item)

		((code) @typst.code)
		((math) @typst.math)

		((url) @typst.link_url)

		((strong) @typst.strong)
		((emph) @typst.emphasis)
		((raw_span) @typst.raw_span)
		((raw_blck) @typst.raw_block)

		((label) @typst.label)
		((ref) @typst.link_ref)
		((term) @typst.term)
	]]);

	for capture_id, capture_node, _, _ in scanned_queries:iter_captures(TSTree:root(), buffer, from, to) do
		local capture_name = scanned_queries.captures[capture_id];
		local r_start, c_start, r_end, c_end = capture_node:range();

		if not capture_name:match("^typst%.") then
			goto continue
		end

		local capture_text = vim.treesitter.get_node_text(capture_node, buffer);

		if not capture_text:match("\n$") then
			capture_text = capture_text .. "\n";
		end

		local lines = {};

		for line in capture_text:gmatch("(.-)\n") do
			table.insert(lines, line);
		end

		pcall(
			typst[capture_name:gsub("^typst%.", "")],

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

	return typst.content, typst.sorted;
end

return typst;
