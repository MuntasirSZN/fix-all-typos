local renderer = {};

renderer.html = require("markview.renderers.html");
renderer.markdown = require("markview.renderers.markdown");
renderer.markdown_inline = require("markview.renderers.markdown_inline");
renderer.latex = require("markview.renderers.latex");
renderer.yaml = require("markview.renderers.yaml");
renderer.typst = require("markview.renderers.typst");

renderer.cache = {};

--- Range modifiers for various nodes.
---@type { [string]: fun(range: table): table }
renderer.range_modifiers = {};

--- Filters provided content.
--- [Used for hybrid mode]
---@param content table
---@param filter table?
---@param clear [ integer, integer ]
---@return table
renderer.filter = function (content, filter, clear)
	local spec = require("markview.spec");
	filter = filter or spec.get({ "preview", "ignore_previews" }, { fallback = {} });

	if not clear then
		--- No clear region.
		return content;
	end

	---@type integer?, integer?
	local cl_from, cl_to;

	--- Checks if a range contains the clear range.
	---@param range { row_start: integer, row_end: integer }
	---@return boolean
	local function in_range(range)
		if vim.islist(clear) == false then
			--- Not within range
			return false;
		elseif clear[1] >= range.row_start and clear[2] <= range.row_end then
			return true;
		else
			return false;
		end
	end

	--- Updates the final clearing range.
	---@param range { row_start: integer, row_end: integer }
	local function update_range(range)
		if type(cl_from) ~= "number" then
			cl_from = range.row_start;
		elseif range.row_start < cl_from then
			cl_from = range.row_start;
		end

		if type(cl_to) ~= "number" then
			cl_to = range.row_end;
		elseif range.row_start < cl_to then
			cl_to = range.row_end;
		end
	end

	for lang, items in pairs(content) do
		local lang_filter = spec.get({ lang }, { source = filter });

		for _, item in ipairs(items) do
			local class = item.class;
			local range = item.range;

			if renderer.range_modifiers[class] then
				range = renderer.range_modifiers[class](range);
			end

			class = class:gsub("^" .. lang, "");

			if vim.tbl_islist(lang_filter) == false and in_range(range) == true then
				update_range(range);
			elseif (inverse == true and vim.list_contains(lang_filter, item.class)) and in_range(range) == true then
				update_range(range);
			elseif vim.list_contains(lang_filter, item.class) == false and in_range(range) == true then
				update_range(range);
			end
		end
	end

	local filtered = {};

	for lang, items in pairs(content) do
		local lang_filter = spec.get({ lang }, { source = filter });

		if filtered[lang] == nil then
			filtered[lang] = {};
		end

		for _, item in ipairs(items) do
			local class = item.class;
			local range = item.range;

			if renderer.range_modifiers[class] then
				range = renderer.range_modifiers[class](range);
			end

			class = class:gsub("^" .. lang, "");

			if vim.tbl_islist(lang_filter) == false and in_range(range) == true then
				goto skip_item;
			elseif (inverse == true and vim.list_contains(lang_filter, item.class)) and in_range(range) == true then
				goto skip_item;
			elseif vim.list_contains(lang_filter, item.class) == false and in_range(range) == true then
				goto skip_item;
			end

			table.insert(filtered[lang], item);

			::skip_item::
		end
	end

	return filtered;
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
