local yaml = {};

local spec = require("markview.spec");
local utils = require("markview.utils");

yaml.cache = {};

yaml.ns = vim.api.nvim_create_namespace("markview/yaml");

---@param buffer integer
---@param item __yaml.properties
yaml.property = function (buffer, item)
	---+${func}
	local main_config = spec.get({ "yaml", "properties" }, { fallback = nil });
	local range = item.range;

	if not main_config then
		return;
	end

	local config = utils.pattern(
		main_config,
		item.key,
		{
			eval_args = { buffer, item }
		}
	);

	if config == nil then
		return;
	elseif config.use_types == true then
		config = spec.get(
			{ "data_types", item.type },
			{
				source = main_config,
				eval_args = { buffer, item }
			}
		) or config;
	end

	vim.api.nvim_buf_set_extmark(buffer, yaml.ns, range.row_start, range.col_start, {
		virt_text_pos = "inline",
		virt_text = {
			{
				config.text or "",
				utils.set_hl(config.hl)
			}
		}
	});

	for l = range.row_start + 1, range.row_end do
		local border, border_hl;

		if l == range.row_end and config.border_bottom then
			border = config.border_bottom;
			border_hl = config.border_bottom_hl or config.border_hl or config.hl;
		elseif l == range.row_start + 1 and config.border_top then
			border = config.border_top;
			border_hl = config.border_top_hl or config.border_hl or config.hl;
		elseif config.border_middle then
			border = config.border_middle;
			border_hl = config.border_middle_hl or config.border_hl or config.hl;
		else
			border = string.rep(" ", vim.fn.strdisplaywidth(config.text[item.type]))
			border_hl = config.border_hl or config.hl;
		end

		vim.api.nvim_buf_set_extmark(buffer, yaml.ns, l, math.min(range.col_start, #item.text[(l - range.row_start) + 1]), {
			virt_text_pos = "inline",
			virt_text = {
				{ border or "", utils.set_hl(border_hl) }
			}
		});
	end
	---_
end

yaml.render = function (buffer, content)
	yaml.cache = {};

	for _, item in ipairs(content or {}) do
		pcall(yaml[item.class:gsub("^yaml_", "")], buffer, item);
	end
end

yaml.clear = function (buffer, _, from, to)
	vim.api.nvim_buf_clear_namespace(buffer, yaml.ns, from or 0, to or -1);
end

return yaml;
