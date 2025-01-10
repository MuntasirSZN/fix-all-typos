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
---@class mkv.option_maps
---
---@field html { [string]: string[] }
---@field latex { [string]: string[] }
---@field markdown { [string]: string[] }
---@field markdown_inline { [string]: string[] }
---@field typst { [string]: string[] }
---@field yaml { [string]: string[] }
renderer.option_maps = {
	---+${lua}

	html = {
		container_elements = { "html_container_element" },
		headings = { "html_heading" },
		void_elements = { "html_void_element" },
	},
	latex = {
		blocks = { "latex_block" },
		commands = { "latex_command" },
		escapes = { "latex_escaped" },
		fonts = { "latex_font" },
		inlines = { "latex_inline" },
		parenthesis = { "latex_parenthesis" },
		subscripts = { "latex_subscript" },
		superscripts = { "latex_superscript" },
		symbols = { "latex_symbol" },
		text = { "latex_text" },
	},
	markdown = {
		headings = { "markdown_atx_heading", "markdown_setext_heading" },
		block_quotes = { "markdown_block_quote" },
		code_blocks = { "markdown_code_block" },
		horizontal_rules = { "markdown_hr" },
		reference_definitions = { "markdown_link_ref_definition" },
		list_items = { "markdown_list_item" },
		metadata_minus = { "markdown_metadata_minus" },
		metadata_plus = { "markdown_metadata_plus" },
		tables = { "markdown_table" },
		checkboxes = { "markdown_checkbox" },
	},
	markdown_inline = {
		checkboxes = { "inline_checkbox" },
		inline_codes = { "inline_code_span" },
		entities = { "inline_entity" },
		escapes = { "inline_escaped" },
		footnotes = { "inline_footnote" },
		highlights = { "inline_highlight" },
		block_references = { "inline_link_block_ref" },
		embed_files = { "inline_embed_files" },
		emails = { "inline_link_email" },
		hyperlinks = { "inline_link_hyperlink", "inline_link_shortcut" },
		images = { "inline_link_hyperlink" },
		uri_autolinks = { "inline_link_uri_autolink" },
		internal_links = { "inline_link_internal" },
	},
	typst = {
		code_blocks = { "typst_code_block" },
		code_spans = { "typst_code_span" },
		escapes = { "typst_escaped" },
		headings = { "typst_heading" },
		labels = { "typst_label" },
		list_items = { "typst_list_item" },
		reference_links = { "typst_link_ref" },
		url_links = { "typst_link_url" },
		math_blocks = { "typst_math_blocks" },
		math_spans = { "typst_math_spans" },
		raw_blocks = { "typst_raw_block" },
		raw_spans = { "typst_raw_span" },
		subscripts = { "typst_subscript" },
		superscripts = { "typst_superscript" },
		symbols = { "typst_symbol" },
		terms = { "typst_terms" },
	},
	yaml = {
		properties = { "yaml_property" },
	}
	---_
};

--- Creates node class filters for hybrid mode.
---@param filter preview.ignore?
---@return { [string]: string[] }
local create_filter = function (filter)
	---+${lua}
	local spec = require("markview.spec");

	--- Ignore queries.
	---@type preview.ignore
	local filters = filter or spec.get({ "preview", "ignore_previews" }, { fallback = {} });

	--- To save time, do not recalculate these if the
	--- configuration hasn't changed.
	if vim.deep_equal(renderer.__filter_cache.config, filters) == true then
		--- Configuration has most likely not changed.
		--- Return the cached value.
		return renderer.__filter_cache.result;
	end

	--- Resulting filter.
	local _f = {};

	--- Checks if a value is valid by matching all
	--- the provided queries against it.
	---@param value string
	---@param queries string[]
	---@return boolean
	local is_valid = function (value, queries)
		---+${lua}

		for q, query in ipairs(queries or {}) do
			--- Queries that were already passed.
			local passed = vim.list_slice(queries, 0, q - 1);

			if string.match(query, "^%!") then
				if value == string.sub(query, 2) then
					--- Part of negation query.
					return false;
				elseif vim.list_contains(passed, value) then
					--- Already part of the query.
					return true;
				end
			elseif value == query then
				--- Valid value.
				return true;
			else
				--- Invalid value.
				return false;
			end
		end

		--- All conditions matched!
		return true;
		---_
	end

	--- Creates a list of valid options for {language}.
	---@param language string
	---@param options string[]
	---@return string[]
	local function language_filter (language, options)
		---+${lua}

		---@type string[] Filters for this language.
		local queries = filters[language];

		if vim.islist(queries) == false then
			--- Filter is invalid.
			return options;
		elseif #queries == 0 then
			--- Filter is empty.
			return {};
		end

		---@type string[] Valid options.
		local _m = {};

		for _, item in ipairs(options) do
			if is_valid(item, queries) == true then
				table.insert(_m, item);
			end
		end

		return _m;
		---_
	end

	--- Registers a new entry to {language}.
	---@param language string
	---@param classes string[]
	local function register (language, classes)
		---+${lua}
		if vim.islist(_f[language]) == false then
			_f[language] = {};
		end

		for _, class in ipairs(classes or {}) do
			if type(class) == "string" and vim.list_contains(_f[language], class) == false then
				table.insert(_f[language], class);
			end
		end
		---_
	end

	for language, maps in pairs(renderer.option_maps) do
		--- Copy the values as we don't want to
		--- accidentally modify the mapping table.
		local valid_options = language_filter(language, vim.tbl_keys(maps));

		if vim.islist(_f[language]) == false then
			_f[language] = {};
		end

		for _, option in ipairs(valid_options) do
			local nodes = maps[option];
			register(language, nodes);
		end
	end

	--- Cache values.
	renderer.__filter_cache.config = filters;
	renderer.__filter_cache.result = _f;

	return _f;
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
	end,
	markdown_table = function (range)
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

renderer.clear = function (buffer, from, to)
	local langs = { "html", "latex", "markdown", "markdown_inline", "typst", "yaml" };

	for _, lang in ipairs(langs) do
		if renderer[lang] then
			renderer[lang].clear(buffer, from, to);
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
