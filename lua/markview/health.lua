local health = {};

health.supported_languages = {
	["html"] = " ",
	["latex"] = " ",
	["markdown"] = " ",
	["markdown_inline"] = " ",
	["typst"] = " ",
	["yaml"] = " "
}

health.check = function ()
	local spec = require("markview.spec");
	local symbols = require("markview.symbols");
	local utils = require("markview.utils");

	local ver = vim.version();

	vim.health.start("💻 Checking essentials:")

	if vim.fn.has("nvim-0.10.1") == 1 then
		vim.health.ok(
			"Neovim version: " ..
			string.format(
				"`%d.%d.%d`",
				ver.major,
				ver.minor,
				ver.patch
			)
		);
	elseif ver.major == 0 and ver.minor == 10 and ver.patch == 0 then
		vim.health.warn(
			"Neovim version(may experience errors): " ..
			string.format(
				"`%d.%d.%d`",
				ver.major,
				ver.minor,
				ver.patch
			)
		);
	else
		vim.health.error(
			"Neovim version(unsupported): " ..
			string.format(
				"`%d.%d.%d`",
				ver.major,
				ver.minor,
				ver.patch
			) ..
			" <= 0.10.1"
		);
	end

	if pcall(require, "nvim-treesitter") then
		vim.health.ok("`nvim-treesitter/nvim-treesitter` found!")
	else
		vim.health.warn("`nvim-treesitter/nvim-treesitter` wasn't found! Ignore this if you manually installed the parsers!")
	end

	vim.health.start("Checking parsers:")

	for parser, icon in pairs(health.supported_languages) do
		if utils.parser_installed(parser) then
			vim.health.ok(icon .. "`" .. parser .. "`" .. " was found!");
		else
			vim.health.warn(icon .. "`" .. parser .. "`" .. " wasn't found.");
		end
	end

	vim.health.start("Checking icon providers:");

	if pcall(require, "nvim-web-devicons") then
		vim.health.ok("`nvim-tree/nvim-web-devicons` found!");
	elseif pcall(require, "mini.icons") then
		vim.health.ok("`echasnovski/mini.icons` found!");
	else
		vim.health.warn("External icon providers weren't found! Using internal icon providers instead.")
	end

	vim.health.start("Checking configuration:");

	if #spec.warnings == 0 then
		vim.health.ok("No errors in configuration table found!");
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

	vim.health.start("Checking symbols:");
	vim.health.info("📖 If any of the symbols aren't showing up then your font doesn't support it! You may want to update your font!");

	vim.health.start("Checking LaTeX math symbols:");

	for _ = 1, 5 do
		local keys = vim.tbl_keys(symbols.entries);
		local key  = keys[math.floor(math.random() * #keys)];

		vim.health.info("`" .. key .. "` → " .. symbols.entries[key])
	end

	vim.health.start("Checking typst math symbols:");

	for _ = 1, 5 do
		local keys = vim.tbl_keys(symbols.typst_entries);
		local key  = keys[math.floor(math.random() * #keys)];

		vim.health.info("`" .. key .. "` → " .. symbols.typst_entries[key])
	end

	vim.health.start("Checking text styles:");

	vim.health.info("`Subscript`,   A" .. symbols.tostring("subscripts", "ABCDEFGHIJKLMNOPQRSTUVWXYZ abcdefghijklmnopqrstuvwxyz 0123456789 + () ="));
	vim.health.info("`Superscript`, A" .. symbols.tostring("superscripts", "ABCDEFGHIJKLMNOPQRSTUVWXYZ abcdefghijklmnopqrstuvwxyz 0123456789 + () ="));

	vim.health.start("Checking math fonts:");

	for font, _ in pairs(symbols.fonts) do
		vim.health.info(string.format("%-15s" , "`" .. font .. "`, ") .. symbols.tostring(font, "ABCDEFGHIJKLMNOPQRSTUVWXYZ abcdefghijklmnopqrstuvwxyz 0123456789"));
	end
end

return health;
