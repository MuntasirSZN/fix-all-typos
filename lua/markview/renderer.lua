local renderer = {};

renderer.html = require("markview.renderers.html");
renderer.markdown = require("markview.renderers.markdown");
renderer.markdown_inline = require("markview.renderers.markdown_inline");
renderer.latex = require("markview.renderers.latex");
renderer.yaml = require("markview.renderers.yaml");
renderer.typst = require("markview.renderers.typst");

renderer.cache = {};

renderer.__filter_cache = {
	config = nil,
	result = nil
};

--- Maps a `class` to an option name.
renderer.opt_map = {
	---+${lua}

	html = {
		html_container_element = "container_elements",
		html_heading = "headings",
		html_void_element = "void_elements"
	},
	latex = {
		latex_block = function (item)
			return item.inline == true and "inlines" or "blocks";
		end,
		latex_command = "commands",
		latex_escaped = "escapes",
		latex_font = "fonts",
		latex_inline = "inlines",
		latex_parenthesis = "parenthesis",
		latex_subscripts = "subscripts",
		latex_superscript = "superscripts",
		latex_symbol = "symbols",
		latex_text = "texts"
	},
	markdown = {
		markdown_atx_heading = "headings",
		markdown_block_quote = "block_quotes",
		markdown_code_block = "code_blocks",
		markdown_hr = "horizontal_rules",
		markdown_link_ref_definition = "reference_definitions",
		markdown_list_item = "list_items",
		markdown_metadata_minus = "metadata_minus",
		markdown_metadata_plus = "metadata_plus",
		markdown_setext_heading = "headings",
		markdown_table = "tables"
	},
	markdown_inline = {
		inline_checkbox = "checkboxes",
		inline_code_span = "inline_codes",
		inline_entity = "entities",
		inline_escaped = "escapes",
		inline_footnote = "footnotes",
		inline_highlight = "highlights",
		inline_link_block_ref = "block_references",
		inline_link_embed_file = "embed_files",
		inline_link_email = "emails",
		inline_link_hyperlink = "hyperlinks",
		inline_link_image = "images",
		inline_link_shortcut = "hyperlinks",
		inline_link_uri_autolink = "uri_autolinks",
		inline_link_internal = "internal_links"
	},
	typst = {
		typst_code_block = "code_blocks",
		typst_code_inline = "code_inlines",
		typst_escaped = "escapes",
		typst_heading = "headings",
		typst_label = "labels",
		typst_list_item = "list_items",
		typst_link_ref = "reference_links",
		typst_link_url = "url_links",
		typst_math = function (item)
			return item.inline == true and "math_inlines" or "math_blocks";
		end,
		typst_raw_block = "raw_blocks",
		typst_raw_span = "raw_spans",
		typst_subscript = "subscripts",
		typst_superscript = "superscripts",
		typst_symbol = "symbols",
		typst_term = "terms"
	},
	yaml = {
		yaml_property = "properties",
	}
	---_
};

--- Creates node class filters for hybrid mode.
---@param filter table?
---@return table
local create_filter = function (filter)
	---+${lua}

	--- Reverse mapping function.
	---@param tbl { [string | integer]: any }
	---@param value any
	---@return ( string | integer )[]
	local function rmap (tbl, value)
		---+${lua}

		local _k = {};

		for key, val in pairs(tbl) do
			if val == value then
				table.insert(_k, key);
			end
		end

		return _k;
		---_
	end

	--- Returns items from {source} that aren't
	--- in {collected}.
	---@param source any[]
	---@param collected any[]
	---@return any[]
	local get_excluded = function (source, collected)
		---+${lua}

		local _t = {};

		for _, item in ipairs(source or {}) do
			if vim.list_contains(collected, item) == false then
				table.insert(_t, item);
			end
		end

		return _t;
		---_
	end

	local spec = require("markview.spec");
	local filters = filter or spec.get({ "preview", "ignore_previews" }, { fallback = {} });

	if renderer.__filter_cache.result ~= nil and vim.deep_equal(renderer.__filter_cache.config, filters) == true then
		return renderer.__filter_cache.result;
	else
		renderer.__filter_cache.config = filters;
	end

	--- Resulting filter.
	local _o = {};

	for lang, maps in pairs(renderer.opt_map) do
		if vim.islist(filters[lang]) == false then
			-- Filter doesn't exist. Add every
			-- node class.
			_o[lang] = vim.tbl_keys(maps);
			goto continue;
		end

		--- Temporarily store the option maps.
		--- Used for `!*` operator.
		local tmp = vim.deepcopy(maps);

		--- We need a table to insert entries.
		_o[lang] = {};

		--- Iterate over the filter items and
		--- create a list of class names.
		for _, item in ipairs(filters[lang]) do
			---+${lua}
			if item:match("^%!") then
				-- Only add nodes that aren't mapped to this item!
				local exclude = get_excluded( vim.tbl_keys(tmp), rmap(tmp, item:sub(2)) );

				for _, match in ipairs(exclude) do
					if vim.list_contains(_o[lang], match) == false then
						table.insert(_o[lang], match);
						tmp[match] = nil;
					end
				end
			else
				local matches = rmap(tmp, item);

				for _, match in ipairs(matches) do
					if vim.list_contains(_o[lang], match) == false then
						--- Only add ones we haven't added before.
						table.insert(_o[lang], match);
						tmp[match] = nil;
					end
				end
			end
			---_
		end

	    ::continue::
	end

	renderer.__filter_cache.result = _o;
	return _o;
	---_
end

--- Range modifiers for various nodes.
---@type { [string]: fun(range: node.range): node.range }
renderer.range_modifiers = {
	---+${lua}
	markdown_atx_heading = function (range)
		local _r = vim.deepcopy(range)
		_r.row_end = _r.row_end - 1;

		return _r;
	end,
	markdown_setext_heading = function (range)
		local _r = vim.deepcopy(range)
		_r.row_end = _r.row_end - 1;

		return _r;
	end,
	markdown_code_block = function (range)
		local _r = vim.deepcopy(range)
		_r.row_end = _r.row_end - 1;

		return _r;
	end,
	markdown_block_quote = function (range)
		local _r = vim.deepcopy(range)
		_r.row_end = _r.row_end - 1;

		return _r;
	end,
	markdown_hr = function (range)
		local _r = vim.deepcopy(range)
		_r.row_end = _r.row_end - 1;

		return _r;
	end,
	markdown_list_item = function (range)
		local _r = vim.deepcopy(range)
		_r.row_end = _r.row_end - 1;

		return _r;
	end,
	markdown_metadata_minus = function (range)
		local _r = vim.deepcopy(range)
		_r.row_end = _r.row_end - 1;

		return _r;
	end,
	markdown_metadata_plus = function (range)
		local _r = vim.deepcopy(range)
		_r.row_end = _r.row_end - 1;

		return _r;
	end
	---_
};

--- Fixes node ranges for `hybrid mode`.
---@param class string
---@param range node.range
---@return node.range
renderer.fix_range = function (class, range)
	if renderer.range_modifiers[class] == nil then
		return range;
	end

	return renderer.range_modifiers[class](range);
end

--- Filters provided content.
--- [Used for hybrid mode]
---@param content table
---@param filter table?
---@param clear [ integer, integer ]
---@return table
renderer.filter = function (content, filter, clear)
	---+${lua}

	--- Checks if {pos} is inside of {range}.
	---@param range node.range
	---@param pos [ integer, integer ]
	---@return boolean
	local within = function (range, pos)
		---+${lua}
		if type(range) ~= "table" then
			return false;
		elseif type(range.row_start) ~= "number" or type(range.row_end) ~= "number" then
			return false;
		elseif vim.islist(pos) == false then
			return false;
		elseif type(pos[1]) ~= "number" or type(pos[2]) ~= "number" then
			return false;
		elseif pos[1] >= range.row_start and pos[2] <= range.row_end then
			return true;
		end

		return false;
		---_
	end

	---@type [ integer, integer ] Range to clear.
	local clear_range = vim.deepcopy(clear);

	--- Updates the range to clear.
	---@param new [ integer, integer ]
	local range_update = function (new)
		---+${lua}
		if new[1] <= clear_range[1] and new[2] >= clear_range[2] then
			clear_range[1] = new[1];
			clear_range[2] = new[2];
		end
		---_
	end

	--- Node filters.
	---@type preview.ignore
	local result_filters = create_filter(filter);

	---@type { [string]: table }
	local indexes = {};

	--- Create a range to clear.
	for lang, items in pairs(content) do
		---+${lua}

		--- Filter for this language.
		---@type string[]?
		local lang_filter = result_filters[lang];

		if lang_filter == nil then
			goto continue;
		end

		indexes[lang] = {};

		for n, node in ipairs(items) do
			if vim.list_contains(lang_filter, node.class) then
				local range = renderer.fix_range(node.class, node.range);
				table.insert(indexes[lang], { n, range, node.class });

				if within(node.range, clear_range) == true then
					range_update({ range.row_start, range.row_end });
				end
			end
		end

		::continue::
		---_
	end

	--- Remove the nodes inside the `clear_range`.
	for lang, references in pairs(indexes) do
		---+${lua}

		--- Amount of nodes removed in this language.
		--- Used for offsetting the index for later nodes.
		local removed = 0;

		for _, ref in ipairs(references) do
			local range = ref[2];
			-- vim.print(range.row_start .. ":" .. range.row_end)

			if range.row_start >= clear_range[1] and range.row_end <= clear_range[2] then
				table.remove(content[lang], ref[1] - removed);
				removed = removed + 1;
			end
		end
		---_
	end

	return content;
	---_
end

--- Renders things
---@param buffer integer
renderer.render = function (buffer, parsed_content)
	renderer.cache = {};

	for lang, content in pairs(parsed_content) do
		if renderer[lang] then
			local c = renderer[lang].render(buffer, content);
			renderer.cache = vim.tbl_extend("force", renderer.cache, c or {});
		end
	end

	for lang, content in pairs(renderer.cache) do
		if renderer[lang] then
			renderer[lang].post_render(buffer, content);
		end
	end
end

renderer.clear = function (buffer, ignore, from, to)
	ignore = vim.tbl_extend("force", {
		markdown = {},
		markdown_inline = {},
		html = {},
		latex = {},
		typst = {},
		yaml = {}
	}, ignore or {});

	for lang, content in pairs(ignore) do
		if renderer[lang] then
			renderer[lang].clear(buffer, content, from, to);
		end
	end
end

renderer.range = function (content)
	local _f, _t = nil, nil;
	local range_processoer = {
		["markdown_table"] = function (range)
			local use_virt = require("markview.spec").get({ "markdown", "tables", "use_virt_lines" }, { fallback = false });

			if use_virt ~= true then
				range.row_start = range.row_start - 1;
				range.row_end = range.row_end + 1;
			end

			return range;
		end
	}

	for _, lang in pairs(content) do
		for _, item in ipairs(lang) do
			local range = vim.deepcopy(item.range);

			-- Change the range when specific options
			-- are set.
			if range_processoer[item.class] then
				range = range_processoer[item.class](range);
			end

			if not _f or item.range.row_start < _f then
				_f = item.range.row_start;
			end

			if not _t or item.range.row_end > _t then
				_t = item.range.row_end;
			end
		end
	end

	return _f, _t;
end

return renderer;
