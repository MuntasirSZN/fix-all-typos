local renderer = {};

renderer.html = require("markview.renderers.html");
renderer.markdown = require("markview.renderers.markdown");
renderer.markdown_inline = require("markview.renderers.markdown_inline");
renderer.latex = require("markview.renderers.latex");
renderer.yaml = require("markview.renderers.yaml");
renderer.typst = require("markview.renderers.typst");

renderer.cache = {};

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
