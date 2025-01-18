local health = {};

--- Logs for health check
health.log = {};

--- Fixed version of deprecated options.
health.fixed_config = nil;

---@class health.log.deprecation
---
---@field kind "deprecation"
---@field name string
---@field command boolean
---
---@field alternative? string
---@field tip? string

health.child_indent = 0;

health.__child_indent_in = function ()
	health.child_indent = health.child_indent + 1;
end

health.__child_indent_de = function ()
	health.child_indent = math.max(0, health.child_indent - 1);
end

--- Fancy print()
---@param handler string | nil
---@param opts table
health.notify = function (handler, opts)
	---+${lua}

	--- Wrapper for tostring()
	---@param tbl string | [ string, string? ][]
	---@return string
	local function to_string(tbl)
		---+${lua}
		if vim.islist(tbl) == false then
			return tostring(tbl);
		end

		---@cast tbl [ string, string? ][]

		local _t = "";

		for _, item in ipairs(tbl) do
			if type(item[1]) == "string" then
				_t = _t .. item[1];
			end
		end

		return _t;
		---_
	end

	if handler == "deprecation" then
		---+${lua}

		local chunks = {
			{ " markview.nvim: ", "DiagnosticError" },
			{ string.format(" %s ", opts.option), "DiagnosticVirtualTextError" },
			{ " is deprecated. ", "Normal" },
		};

		---@cast opts { option: string, alter: string?, tip: string?, command: boolean? }

		if opts.alter then
			chunks = vim.list_extend(chunks, {
				{ "Use ", "Normal" },
				{ string.format(" %s ", opts.alter), "DiagnosticVirtualTextHint" },
				{ " instead.", "Normal" },
			});
		end

		if opts.tip then
			chunks = vim.list_extend(chunks, {
				{ "\n" },
				{ "  Tip: ", "DiagnosticVirtualTextWarn" },
				{ " " },
			});
			chunks = vim.list_extend(chunks, opts.tip);
		end

		vim.api.nvim_echo(chunks, true, {});

		table.insert(health.log, {
			kind = "deprecation",
			name = opts.option,
			command = opts.command,

			alternative = opts.alter,
			tip = opts.tip
		});
		---_
	elseif handler == "type" then
		---+${lua}

		---@cast opts { option: string, uses: string, got: string }

		local article_1 = "a ";
		local article_2 = "a ";

		if string.match(opts.uses, "^[aeiou]") then
			article_1 = "an ";
		elseif string.match(opts.uses, "^%A") then
			article_1 = "";
		end

		if string.match(opts.got, "^[aeiou]") then
			article_2 = "an ";
		elseif string.match(opts.got, "^%A") then
			article_2 = "";
		end

		vim.api.nvim_echo({
			{ " markview.nvim: ", "DiagnosticWarn" },
			{ string.format(" %s ", opts.option), "DiagnosticVirtualTextInfo" },
			{ " is " .. article_1, "Normal" },
			{ string.format(" %s ", opts.uses), "DiagnosticVirtualTextHint" },
			{ ", not " .. article_2, "Normal" },
			{ string.format(" %s ", opts.got), "DiagnosticVirtualTextError" },
			{ ".", "Normal" }
		}, true, {});

		table.insert(health.log, {
			kind = "type_error",
			option = opts.option,

			requires = opts.uses,
			received = opts.got
		});

		---_
	elseif handler == "hl" then
		---+${lua}

		local text = vim.split(vim.inspect(opts.value) or "", '\n', { trimempty = true });
		local lines = {};

		for l, line in ipairs(text) do
			table.insert(lines, { string.format("% " .. #text .. "d", l), "Special" });
			table.insert(lines, { " │ ", "Comment" });
			table.insert(lines, { line, "Normal" });
			table.insert(lines, { "\n" });
		end

		vim.api.nvim_echo(vim.list_extend({
			{ " markview.nvim: ", "DiagnosticWarn" },
			{ "Failed to set ", "Normal" },
			{ string.format(" %s ", opts.group), "DiagnosticVirtualTextInfo" },
			{ ",\n", "Normal" }
		}, lines), true, {});

		table.insert(health.log, {
			kind = "hl",

			group = opts.group,
			value = opts.value,

			message = opts.message
		});
		---_
	elseif handler == "trace" then
		---+${lua}

		if vim.g.__mkv_dev == true then
			local config = {
				{ "", "DiagnosticOk" },
				{ "", "DiagnosticWarn" },
				{ "", "DiagnosticOk" },

				{ "", "DiagnosticError" },
				{ "", "DiagnosticInfo" },

				{ " ", "DiagnosticHint" },
				{ " ", "DiagnosticWarn" },

				{ " ", "DiagnosticOk" },
				{ " ", "DiagnosticError" },
			};

			local icon, hl = config[opts.level or 5][1], config[opts.level or 5][2];
			local indent = string.rep("  ", opts.indent or health.child_indent);

			if vim.islist(opts.message) then
				vim.api.nvim_echo(vim.list_extend({
					{ string.format("%s%s ", indent, icon), hl },
					{ os.date("%H:%m"), "Comment" },
					{ " | ", "Comment" },
				}, opts.message), true, { verbose = true });
			else
				vim.api.nvim_echo({
					{ string.format("%s%s ", indent, icon), hl },
					{ os.date("%H:%m"), "Comment" },
					{ " | ", "Comment" },
					{ opts.message or "", hl }
				}, true, { verbose = true });
			end
		end

		if opts.child_indent then
			health.child_indent = opts.child_indent;
		end

		table.insert(health.log, {
			kind = "trace",
			ignore = true,
			indent = opts.indent or health.child_indent,

			timestamp = os.date(),
			message = to_string(opts.message),
			level = opts.level
		})
		---_
	else
		vim.api.nvim_echo(vim.list_extend({ " markview.nvim: " }, opts.message), true, {});
	end
	---_
end

--- Holds icons for different filetypes.
---@type { [string]: string }
health.supported_languages = {
	["html"] = " ",
	["latex"] = " ",
	["markdown"] = "󰍔 ",
	["markdown_inline"] = "󰍔 ",
	["typst"] = " ",
	["yaml"] = "󰬠 "
}

--- Health check function.
health.check = function ()
	---+${lua}

	local spec = require("markview.spec");
	local symbols = require("markview.symbols");
	local utils = require("markview.utils");

	local ver = vim.version();

 ------------------------------------------------------------------------------------------ 

	vim.health.start("💻 Neovim:")

	if vim.fn.has("nvim-0.10.1") == 1 then
		vim.health.ok(
			"Version: " .. string.format( "`%d.%d.%d`", ver.major, ver.minor, ver.patch )
		);
	elseif ver.major == 0 and ver.minor == 10 and ver.patch == 0 then
		vim.health.warn(
			"Version(may experience bugs): " .. string.format( "`%d.%d.%d`", ver.major, ver.minor, ver.patch )
		);
	else
		vim.health.error(
			"Version(unsupported): " .. string.format( "`%d.%d.%d`", ver.major, ver.minor, ver.patch ) .. " <= 0.10.1"
		);
	end

 ------------------------------------------------------------------------------------------ 

	vim.health.start("💡 Parsers:")

	if pcall(require, "nvim-treesitter") then
		vim.health.ok("`nvim-treesitter/nvim-treesitter` found.");
	else
		vim.health.warn("`nvim-treesitter/nvim-treesitter` wasn't found.");
	end

	for parser, icon in pairs(health.supported_languages) do
		if utils.parser_installed(parser) then
			vim.health.ok("`" .. icon .. parser .. "`" .. " parser was found.");
		else
			vim.health.warn("`" .. icon .. parser .. "`" .. " parser wasn't found.");
		end
	end

 ------------------------------------------------------------------------------------------ 

	vim.health.start("✨ Icon providers:");

	if pcall(require, "nvim-web-devicons") then
		vim.health.ok("`nvim-tree/nvim-web-devicons` found.");
	else
		vim.health.warn("`nvim-tree/nvim-web-devicons` not found.");
	end

	if pcall(require, "mini.icons") then
		vim.health.ok("`echasnovski/mini.icons` found.");
	else
		vim.health.warn("`echasnovski/mini.icons` not found.");
	end

	if pcall(require, "markview.filetypes") then
		vim.health.ok("`Internal icon provider` found.")
	else
		vim.health.error("`Internal icon provider` not found.");
	end

 ------------------------------------------------------------------------------------------ 

	vim.health.start("🚧 Configuration::");

	if #spec.warnings == 0 then
		vim.health.ok("No errors in user configuration found!");
	else
		for _, msg in ipairs(spec.warnings) do
			local _c = msg.deprecated and vim.health.error or vim.health.warn;

			if msg.class == "markview_opt_name_change" then
				_c("Deprecated option found, `" .. msg.old .. "` → `" .. msg.new .. "`");
			elseif msg.class == "markview_opt_deprecated" then
				_c("Deprecated option found, `" .. msg.name .. "`. Please see the documentation!");
			elseif msg.class == "markview_opt_invalid_type" then
				_c("Invalid value type, `" .. msg.name .. "`, should be a `" .. msg.should_be .. "` instead it is a `" .. msg.is .. "`!");
			end
		end
	end

 ------------------------------------------------------------------------------------------ 

	vim.health.start("💬 Symbols:")
	vim.health.info("📖 If any of the symbols aren't showing up then your font doesn't support it! You may want to `update your font`!");

	vim.health.start("📐 LaTeX math symbols:");

	for _ = 1, 5 do
		local keys = vim.tbl_keys(symbols.entries);
		local key  = keys[math.floor(math.random() * #keys)];

		vim.health.info( string.format("%-40s", "`" .. key .. "`" ) .. symbols.entries[key])
	end

	vim.health.start("📐 Typst math symbols:");

	for _ = 1, 5 do
		local keys = vim.tbl_keys(symbols.typst_entries);
		local key  = keys[math.floor(math.random() * #keys)];

		vim.health.info( string.format("%-40s", "`" .. key .. "`" ) .. symbols.typst_entries[key])
	end

	vim.health.start("🔤 Text styles:");

	vim.health.info("`Subscript`         " .. symbols.tostring("subscripts", "ABCDEFGHIJKLMNOPQRSTUVWXYZ abcdefghijklmnopqrstuvwxyz 0123456789 + () ="));
	vim.health.info("`Superscript`       " .. symbols.tostring("superscripts", "ABCDEFGHIJKLMNOPQRSTUVWXYZ abcdefghijklmnopqrstuvwxyz 0123456789 + () ="));

	vim.health.start("🔢 Math fonts:");

	for font, _ in pairs(symbols.fonts) do
		vim.health.info(string.format("%-20s" , "`" .. font .. "`") .. symbols.tostring(font, "ABCDEFGHIJKLMNOPQRSTUVWXYZ abcdefghijklmnopqrstuvwxyz 0123456789"));
	end
	---_
end

return health;
