local yaml = {};

local spec = require("markview.spec");
local utils = require("markview.utils");

yaml.cache = {};

yaml.__ns = {
	__call = function (self, key)
		return self[key] or self.default;
	end
}

yaml.ns = {
	default = vim.api.nvim_create_namespace("markview/yaml"),
};
setmetatable(yaml.ns, yaml.__ns)

yaml.set_ns = function ()
	local ns_pref = spec.get({ "yaml", "use_seperate_ns" }, { fallback = true });
	if not ns_pref then ns_pref = true; end

	local available = vim.api.nvim_get_namespaces();
	local ns_list = {
		["properties"] = "markview/yaml/properties",
	};

	if ns_pref == true then
		for ns, name in pairs(ns_list) do
			if vim.list_contains(available, ns) == false then
				yaml.ns[ns] = vim.api.nvim_create_namespace(name);
			end
		end
	end
end

yaml.property = function (buffer, item)
	---+${func}
	local main_config = spec.get({ "yaml", "properties" }, { fallback = nil });
	local range = item.range;

	if not main_config then
		return;
	end

	local config = utils.match_pattern(
		main_config,
		item.key,
		{
			args = { buffer, item }
		}
	);


	if config.use_types == true then
		config = spec.get(
			{ "data_types", item.type },
			{
				source = main_config,
				args = { buffer, item }
			}
		) or config;

		config = utils.tostatic(
			config,
			{
				args = { buffer, item }
			}
		);
	end

	vim.api.nvim_buf_set_extmark(buffer, yaml.ns("properties"), range.row_start, range.col_start, {
		virt_text_pos = "inline",
		virt_text = {
			{
				config.text,
				utils.set_hl(config.hl and config.hl[item.type] or nil)
			}
		}
	});

	for l = range.row_start + 1, range.row_end do
		local border, border_hl;

		if
			l == range.row_end and
			config.border_bottom
		then
			border = config.border_bottom;
			border_hl = config.border_bottom_hl or config.border_hl or config.hl;
		elseif
			l == range.row_start + 1 and
			config.border_top
		then
			border = config.border_top;
			border_hl = config.border_top_hl or config.border_hl or config.hl;
		elseif config.border_middle then
			border = config.border_middle;
			border_hl = config.border_middle_hl or config.border_hl or config.hl;
		else
			border = string.rep(" ", vim.fn.strdisplaywidth(config.text[item.type]))
			border_hl = config.border_hl or config.hl;
		end

		vim.api.nvim_buf_set_extmark(buffer, yaml.ns("properties"), l, math.min(range.col_start, #item.text[(l - range.row_start) + 1]), {
			virt_text_pos = "inline",
			virt_text = {
				{ border, utils.set_hl(border_hl) }
			}
		});
	end
	---_
end

yaml.render = function (buffer, content)
	yaml.cache = {};

	for _, item in ipairs(content or {}) do
		-- pcall(yaml[item.class:gsub("^yaml_", "")], buffer, item);
		yaml[item.class:gsub("^yaml_", "")](buffer, item);
	end
end

yaml.clear = function (buffer, ignore_ns, from, to)
	for name, ns in pairs(yaml.ns) do
		if ignore_ns and vim.list_contains(ignore_ns, name) == false then
			vim.api.nvim_buf_clear_namespace(buffer, ns, from or 0, to or -1);
		end
	end
end

return yaml;
