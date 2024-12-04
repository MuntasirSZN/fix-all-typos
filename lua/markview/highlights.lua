--- *Dynamic* highlight group related methods
--- for `markview.nvim`.
--- 
local highlights = {};
local utils = require("markview.utils");

local lerp = utils.lerp;
local clamp = utils.clamp;

---+${func, Helper functions}

--- Returns RGB value from the provided input.
--- Supported input types,
---     • Hexadecimal values(`#FFFFFF` & `FFFFFF`).
---     • Number value of the hexadecimal color(from `nvim_get_hl()`).
---     • Color name(e.g. `red`, `green`).
--- 
---@param input string | number[]
---@return number[]?
highlights.rgb = function (input)
	---+${func}

	--- Lookup table for the regular color names.
	--- For example,
	---     • `red` → `#FF0000`.
	---     • `green` → `#00FF00`.
	--- 
	---@type { [string]: string }
	local lookup = {
		---+ ${class, Color name lookup table}
		["red"] = "#FF0000",        ["lightred"] = "#FFBBBB",      ["darkred"] = "#8B0000",
		["green"] = "#00FF00",      ["lightgreen"] = "#90EE90",    ["darkgreen"] = "#006400",    ["seagreen"] = "#2E8B57",
		["blue"] = "#0000FF",       ["lightblue"] = "#ADD8E6",     ["darkblue"] = "#00008B",     ["slateblue"] = "#6A5ACD",
		["cyan"] = "#00FFFF",       ["lightcyan"] = "#E0FFFF",     ["darkcyan"] = "#008B8B",
		["magenta"] = "#FF00FF",    ["lightmagenta"] = "#FFBBFF",  ["darkmagenta"] = "#8B008B",
		["yellow"] = "#FFFF00",     ["lightyellow"] = "#FFFFE0",   ["darkyellow"] = "#BBBB00",   ["brown"] = "#A52A2A",
		["grey"] = "#808080",       ["lightgrey"] = "#D3D3D3",     ["darkgrey"] = "#A9A9A9",
		["gray"] = "#808080",       ["lightgray"] = "#D3D3D3",     ["darkgray"] = "#A9A9A9",
		["black"] = "#000000",      ["white"] = "#FFFFFF",
		["orange"] = "#FFA500",     ["purple"] = "#800080",        ["violet"] = "#EE82EE"
		---_
	};

	--- Lookup table for the Neovim-specific color names.
	--- For example,
	---     • `nvimdarkblue` → `#004C73`.
	---     • `nvimdarkred` → `#590008`.
	--- 
	---@type { [string]: string }
	local lookup_nvim = {
		---+ ${class, Neovim's color lookup table}
		["nvimdarkblue"] = "#004C73",    ["nvimlightblue"] = "#A6DBFF",
		["nvimdarkcyan"] = "#007373",    ["nvimlightcyan"] = "#8CF8F7",
		["nvimdarkgray1"] = "#07080D",   ["nvimlightgray1"] = "#EEF1F8",
		["nvimdarkgray2"] = "#14161B",   ["nvimlightgray2"] = "#E0E2EA",
		["nvimdarkgray3"] = "#2C2E33",   ["nvimlightgray3"] = "#C4C6CD",
		["nvimdarkgray4"] = "#4F5258",   ["nvimlightgray4"] = "#9B9EA4",
		["nvimdarkgrey1"] = "#07080D",   ["nvimlightgrey1"] = "#EEF1F8",
		["nvimdarkgrey2"] = "#14161B",   ["nvimlightgrey2"] = "#E0E2EA",
		["nvimdarkgrey3"] = "#2C2E33",   ["nvimlightgrey3"] = "#C4C6CD",
		["nvimdarkgrey4"] = "#4F5258",   ["nvimlightgrey4"] = "#9B9EA4",
		["nvimdarkgreen"] = "#005523",   ["nvimlightgreen"] = "#B3F6C0",
		["nvimdarkmagenta"] = "#470045", ["nvimlightmagenta"] = "#FFCAFF",
		["nvimdarkred"] = "#590008",     ["nvimlightred"] = "#FFC0B9",
		["nvimdarkyellow"] = "#6B5300",  ["nvimlightyellow"] = "#FCE094",
		---_
	};

	if type(input) == "string" then
		--- Match cases,
		---     • RR GG BB, # is optional.
		---     • R G B, # is optional.
		---     • Color name.
		---     • HSL values(as `{ h, s, l }`)

		if input:match("^%#?(%x%x?)(%x%x?)(%x%x?)$") then
			--- Pattern explanation:
			---     #? RR? GG? BB?
			--- String should have **3** parts & each part
			--- should have a minimum of *1* & a maximum
			--- of *2* characters.
			---
			--- # is optional.
			---
			---@type string, string, string
			local r, g, b = input:match("^%#?(%x%x?)(%x%x?)(%x%x?)$");

			return { tonumber(r, 16), tonumber(g, 16), tonumber(b, 16) };
		elseif lookup[input] then
			local r, g, b = lookup[input]:match("(%x%x)(%x%x)(%x%x)$");

			return { tonumber(r, 16), tonumber(g, 16), tonumber(b, 16) };
		elseif lookup_nvim[input] then
			local r, g, b = lookup_nvim[input]:match("(%x%x)(%x%x)(%x%x)$");

			return { tonumber(r, 16), tonumber(g, 16), tonumber(b, 16) };
		end
	elseif type(input) == "number" then
		--- Format the number into a hexadecimal string.
		--- Then get the **r**, **g**, **b** parts.
		--- 
		---@type string, string, string
		local r, g, b = string.format("%06x", input):match("(%x%x)(%x%x)(%x%x)$");

		return { tonumber(r, 16), tonumber(g, 16), tonumber(b, 16) };
	elseif vim.islist(input) then
		return highlights.hsl_to_rgb(input);
	end
	---_
end

--- Simple RGB *color-mixer* function.
--- Supports mixing colors by % values.
---
--- NOTE: `per_1` & `per_2` are between
--- **0** & **1**.
--- 
---@param c_1 number[]
---@param c_2 number[]
---@param per_1 number
---@param per_2 number
---@return number[]
highlights.mix = function (c_1, c_2, per_1, per_2)
	local _r = (c_1[1] * per_1) + (c_2[1] * per_2);
	local _g = (c_1[2] * per_1) + (c_2[2] * per_2);
	local _b = (c_1[3] * per_1) + (c_2[3] * per_2);

	return { math.floor(_r), math.floor(_g), math.floor(_b) };
end

--- RGB to hexadecimal string converter.
---
---@param color number[]
---@return string
highlights.hex = function (color)
	return string.format("#%02x%02x%02x", math.floor(color[1]), math.floor(color[2]), math.floor(color[3]))
end

--- RGB to HSL converter.
--- Input should be a list (as `{ R, G, B }`).
--- Returns a list(as `{ H, S, L }`).
---@param color number[]
---@param literal? boolean
---@return number[]
highlights.rgb_to_hsl = function (color, literal)
	---+${func}

	local RGB = vim.deepcopy(color);

	for c, channel in ipairs(RGB) do
		if literal ~= false then
			RGB[c] = channel / 255;
		end
	end

	---@diagnostic disable-next-line
	local minRGB, maxRGB = math.min(unpack(RGB)), math.max(unpack(RGB));

	local HSL = { 0, 0, 0 };
	HSL[3] = (minRGB + maxRGB) / 2;

	if minRGB == maxRGB then
		HSL[2] = 0;
	elseif HSL[3] <= 0.5 then
		HSL[2] = (maxRGB - minRGB) / (maxRGB + minRGB);
	else
		HSL[2] = (maxRGB - minRGB) / (2 - maxRGB - minRGB);
	end

	local delta = maxRGB - minRGB

	if delta == RGB[1] then
		HSL[1] = (RGB[2] - RGB[3]) / (maxRGB - minRGB);
	elseif delta == RGB[2] then
		HSL[1] = 2 + (RGB[3] - RGB[1]) / (maxRGB - minRGB);
	else
		HSL[1] = 4 + (RGB[1] - RGB[2]) / (maxRGB - minRGB);
	end

	HSL[1] = HSL[1] * 60;

	return HSL;
	---_
end

highlights.hsl_to_rgb = function (color)
	---+${func}

	local HSL = vim.deepcopy(color);
	local C = ( 1 - math.abs((2 * HSL[3]) - 1) ) * HSL[2];
	local X;

	local h = HSL[1] / 60;
	X = C * (1 - math.abs((h % 2) - 1));

	local m = HSL[3] - (C / 2);
	local RGB = {};

	if 0 <= h and h <= 1 then
		RGB = { C, X, 0};
	elseif 1 <= h and h <= 2 then
		RGB = { X, C, 0 };
	elseif 2 <= h and h <= 3 then
		RGB = { 0, C, X };
	elseif 3 <= h and h <= 4 then
		RGB = { 0, X, C };
	elseif 4 <= h and h <= 5 then
		RGB = { X, 0, C };
	else
		RGB = { C, 0, X };
	end

	return {
		(RGB[1] + m) * 255,
		(RGB[2] + m) * 255,
		(RGB[3] + m) * 255,
	};
	---_
end

highlights.hsl = function (rgb)
	vim.notify("[ markview.nvim ]: highlights.hsl is deprecated. Use 'highlights.rgb_to_hsl' instead", vim.log.levels.WARN);
	highlights.rgb_to_hsl(rgb);
end

--- Gets the luminosity of a RGB value.
---
---@param input number[]
---@param literal? boolean
---@return number
highlights.lumen = function (input, literal)
	local rgb = vim.deepcopy(input);

	for c, val in ipairs(rgb) do
		if literal ~= false then
			rgb[c] = val / 255;
		end
	end

	local min, max = math.min(rgb[1], rgb[2], rgb[3]), math.max(rgb[1], rgb[2], rgb[3]);
	return (min + max) / 2;
end

--- Mixes a color with it's background based on
--- the provided `alpha`(between 0 & 1).
---
---@param fg number[]
---@param bg number[]
---@param alpha number
---@return number[]
---@deprecated
highlights.opacify = function (fg, bg, alpha)
	vim.notify("[ markview.nvim ]: highlights.opacify is deprecated. Use 'highlights.mix' instead", vim.log.levels.WARN);
	return {
		math.floor((fg[1] * alpha) + (bg[1] * (1 - alpha))),
		math.floor((fg[2] * alpha) + (bg[2] * (1 - alpha))),
		math.floor((fg[3] * alpha) + (bg[3] * (1 - alpha))),
	}
end

--- Turns RGB color-space into XYZ.
---@param color number[]
---@param literal? boolean
---@return number[]
highlights.rgb_to_xyz = function (color, literal)
	---+${func}

	local RGB = vim.deepcopy(color);

	for c, channel in ipairs(RGB) do
		if literal ~= false then
			channel = channel / 255;
		end

		if channel > 0.04045 then
			RGB[c] = ( ( channel + 0.055 ) / 1.055 ) ^ 2.4;
		else
			RGB[c] = channel / 12.92;
		end

		RGB[c] = RGB[c] * 100;
	end

	return {
		RGB[1] * 0.4124 + RGB[2] * 0.3576 + RGB[3] * 0.1805,
		RGB[1] * 0.2126 + RGB[2] * 0.7152 + RGB[3] * 0.0722,
		RGB[1] * 0.0193 + RGB[2] * 0.1192 + RGB[3] * 0.9505
	};
	---_
end

--- Turns XYZ color-space into RGB.
---@param color number[]
---@param literal? boolean
---@return number[]
highlights.xyz_to_rgb = function (color, literal)
	---+${func}

	local XYZ = vim.deepcopy(color);

	for c, channel in ipairs(XYZ) do
		if literal ~= false then
			XYZ[c] = channel / 100;
		end
	end

	local RGB = {
		XYZ[1] * 3.2406 + XYZ[2] * -1.5372 + XYZ[3] * -0.4986,
		XYZ[1] * -0.9689 + XYZ[2] * 1.8758 + XYZ[3] * 0.0415,
		XYZ[1] * 0.0557 + XYZ[2] * -0.2040 + XYZ[3] * 1.0570,
	};

	for c, channel in ipairs(RGB) do
		if channel > 0.0031308 then
			RGB[c] = ( 1.055 * (channel ^ ( 1 / 2.4 ) ) ) - 0.055;
		else
			RGB[c] = 12.92 * channel;
		end
	end

	return {
		utils.clamp(RGB[1] * 255, 0, 255),
		utils.clamp(RGB[2] * 255, 0, 255),
		utils.clamp(RGB[3] * 255, 0, 255)
	};
	---_
end

--- Turns XYZ color-space into Lab.
---@param color number[]
---@return number[]
highlights.xyz_to_lab = function (color)
	---+${func}

	local XYZ = vim.deepcopy(color);
	local RXYZ = { 94.811, 100, 107.304 };

	for c, channel in ipairs(XYZ) do
		channel = channel / RXYZ[c];

		if channel > 0.008856 then
			XYZ[c] = channel ^ ( 1 / 3);
		else
			XYZ[c] = ( 7.787 * channel ) + ( 16 / 116 );
		end
	end

	return {
		( 116 * XYZ[2] ) - 16,
		500 * ( XYZ[1] - XYZ[2] ),
		200 * ( XYZ[2] - XYZ[3] )
	};
	---_
end

--- Turns Lab color-space into XYZ.
---@param color number[]
---@return number[]
highlights.lab_to_xyz = function (color)
	---+${func}

	local LAB = vim.deepcopy(color);
	local RXYZ = { 94.811, 100, 107.304 };

	local VXYZ = {};

	VXYZ[2] = ( LAB[1] + 16 ) / 116;
	VXYZ[1] = LAB[2] / 500 + VXYZ[2];
	VXYZ[3] = VXYZ[2] - LAB[3] / 200;

	for c, channel in ipairs(VXYZ) do
		if channel > 0.008856 then
			VXYZ[c] = channel ^ 3;
		else
			VXYZ[c] = ( channel - 16 / 116 ) / 7.787
		end
	end

	return {
		VXYZ[1] * RXYZ[1],
		VXYZ[2] * RXYZ[2],
		VXYZ[3] * RXYZ[3],
	};
	---_
end

--- Turns RGB color-space into Lab.
---@param RGB number[]
---@return number[]
highlights.rgb_to_lab = function (RGB)
	local XYZ = highlights.rgb_to_xyz(RGB);
	return highlights.xyz_to_lab(XYZ);
end

--- Turns Lab color-space into RGB.
---@param Lab number[]
---@return number[]
highlights.lab_to_rgb = function (Lab)
	local XYZ = highlights.lab_to_xyz(Lab);
	return highlights.xyz_to_rgb(XYZ);
end
---_

--- Holds info about highlight groups.
---@type string[]
highlights.created = {};

--- Creates highlight groups from an array of tables
---@param array { [string]: table }
highlights.create = function (array)
	if type(array) == "string" then
		if not highlights[array] then
			return;
		end

		array = highlights[array];
	end

	local hls = vim.tbl_keys(array) or {};
	table.sort(hls);

	for _, hl in ipairs(hls) do
		local value = array[hl];

		if not hl:match("^Markview") then
			hl = "Markview" .. hl;
		end

		if type(value) == "table" then
			vim.api.nvim_set_hl(0, hl, value);
		else
			local val = value();

			if vim.islist(val) then
				for _, item in ipairs(val) do
					vim.api.nvim_set_hl(0, item.group_name, item.value);
				end
			else
				vim.api.nvim_set_hl(0, hl, val);
			end
		end
	end
end

local is_dark = function (on_light, on_dark)
	return vim.o.background == "dark" and (on_dark or true) or (on_light or false);
end

highlights.get_property = function (property, groups, light, dark)
	local val;

	for _, item in ipairs(groups) do
		if
			vim.fn.hlexists(item) and
			vim.api.nvim_get_hl(0, { name = item, link = false })[property]
		then
			val = vim.api.nvim_get_hl(0, { name = item, link = false })[property];
			break;
		end
	end

	if val then
		return vim.list_contains({ "fg", "bg", "sp" }, property) and highlights.rgb(val) or val;
	end

	return vim.list_contains({ "fg", "bg", "sp" }, property) and highlights.rgb(is_dark(light, dark)) or is_dark(light, dark);
end

---@deprecated
highlights.color = function (opt, fallback, on_light, on_dark)
	vim.notify("[ markview.nvim ]: highlights.color is deprecated. Use 'highlights.get_property' instead", vim.log.levels.WARN);
	highlights.get_property(opt, fallback, on_light, on_dark);
end

--- Generates a heading
highlights.generate_heading = function (opts)
	local vim_bg = highlights.rgb_to_lab(highlights.get_property(
		"bg",
		opts.bg_fallbacks or { "Normal" },
		opts.light_bg or "#FFFFFF",
		opts.dark_bg or "#000000"
	));
	local h_fg = highlights.rgb_to_lab(highlights.get_property(
		"fg",
		opts.fallbacks,
		opts.light_fg or "#000000",
		opts.dark_fg or "#FFFFFF"
	));

	local l_bg = highlights.lumen(highlights.lab_to_rgb(vim_bg));
	local alpha = opts.alpha or (l_bg > 0.5 and 0.15 or 0.25);

	local res_bg = highlights.lab_to_rgb(highlights.mix(h_fg, vim_bg, alpha, 1 - alpha));

	vim_bg = highlights.lab_to_rgb(vim_bg);
	h_fg = highlights.lab_to_rgb(h_fg);

	return {
		bg = highlights.hex(res_bg),
		fg = highlights.hex(h_fg)
	};
end

highlights.hl_generator = function (opts)
	local hi = highlights.get_property(
		opts.source_opt or "fg",
		opts.source or { "Normal" },
		opts.fallback_light or "#000000",
		opts.fallback_dark or "#FFFFFF"
	);

	return vim.tbl_extend("force", {
		[opts.output_opt or "fg"] = highlights.hex(hi)
	}, opts.hl_opts or {})
end

highlights.dynamic = {
	["0P"] = function ()
		---+${hl}
		local vim_bg = highlights.rgb_to_lab(highlights.get_property(
			"bg",
			{ "Normal" },
			"#1E1E2E",
			"#EFF1F5"
		));
		local h_fg = highlights.rgb_to_lab(highlights.get_property(
			"fg",
			{ "Comment" },
			"#9CA0B0",
			"#6C7086"
		));

		local l_bg = highlights.lumen(highlights.lab_to_rgb(vim_bg));
		local alpha = vim.g.__mkv_palette_alpha or (l_bg > 0.5 and 0.15 or 0.25);

		local nr_bg = vim.api.nvim_get_hl(0, { name = "LineNr", link = false }).bg
		local res_bg = highlights.lab_to_rgb(highlights.mix(h_fg, vim_bg, alpha, 1 - alpha));

		vim_bg = highlights.lab_to_rgb(vim_bg);
		h_fg = highlights.lab_to_rgb(h_fg);

		return {
			{
				group_name = "MarkviewPalette0",
				value = {
					default = true,

					bg = highlights.hex(res_bg),
					fg = highlights.hex(h_fg)
				}
			},
			{
				group_name = "MarkviewPalette0Fg",
				value = {
					default = true,

					fg = highlights.hex(h_fg)
				}
			},
			{
				group_name = "MarkviewPalette0Bg",
				value = {
					default = true,

					bg = highlights.hex(res_bg),
				}
			},
			{
				group_name = "MarkviewPalette0Sign",
				value = {
					default = true,

					bg = nr_bg,
					fg = highlights.hex(h_fg)
				}
			}
		};
		---_
	end,
	["1P"] = function ()
		---+${hl}
		local vim_bg = highlights.rgb_to_lab(highlights.get_property(
			"bg",
			{ "Normal" },
			"#1E1E2E",
			"#EFF1F5"
		));
		local h_fg = highlights.rgb_to_lab(highlights.get_property(
			"fg",
			{ "markdownH1", "@markup.heading.1.markdown", "@markup.heading" },
			"#F38BA8",
			"#D20F39"
		));

		local l_bg = highlights.lumen(highlights.lab_to_rgb(vim_bg));
		local alpha = vim.g.__mkv_palette_alpha or (l_bg > 0.5 and 0.15 or 0.25);

		local nr_bg = vim.api.nvim_get_hl(0, { name = "LineNr", link = false }).bg
		local res_bg = highlights.lab_to_rgb(highlights.mix(h_fg, vim_bg, alpha, 1 - alpha));

		vim_bg = highlights.lab_to_rgb(vim_bg);
		h_fg = highlights.lab_to_rgb(h_fg);

		return {
			{
				group_name = "MarkviewPalette1",
				value = {
					default = true,

					bg = highlights.hex(res_bg),
					fg = highlights.hex(h_fg)
				}
			},
			{
				group_name = "MarkviewPalette1Fg",
				value = {
					default = true,

					fg = highlights.hex(h_fg)
				}
			},
			{
				group_name = "MarkviewPalette1Bg",
				value = {
					default = true,

					bg = highlights.hex(res_bg),
				}
			},
			{
				group_name = "MarkviewPalette1Sign",
				value = {
					default = true,

					bg = nr_bg,
					fg = highlights.hex(h_fg)
				}
			}
		};
		---_
	end,
	["2P"] = function ()
		---+${hl}
		local vim_bg = highlights.rgb_to_lab(highlights.get_property(
			"bg",
			{ "Normal" },
			"#1E1E2E",
			"#EFF1F5"
		));
		local h_fg = highlights.rgb_to_lab(highlights.get_property(
			"fg",
			{ "markdownH2", "@markup.heading.2.markdown", "@markup.heading" },
			"#FE640B",
			"#FAB387"
		));

		local l_bg = highlights.lumen(highlights.lab_to_rgb(vim_bg));
		local alpha = vim.g.__mkv_palette_alpha or (l_bg > 0.5 and 0.15 or 0.25);

		local nr_bg = vim.api.nvim_get_hl(0, { name = "LineNr", link = false }).bg
		local res_bg = highlights.lab_to_rgb(highlights.mix(h_fg, vim_bg, alpha, 1 - alpha));

		vim_bg = highlights.lab_to_rgb(vim_bg);
		h_fg = highlights.lab_to_rgb(h_fg);

		return {
			{
				group_name = "MarkviewPalette2",
				value = {
					default = true,

					bg = highlights.hex(res_bg),
					fg = highlights.hex(h_fg)
				}
			},
			{
				group_name = "MarkviewPalette2Fg",
				value = {
					default = true,

					fg = highlights.hex(h_fg)
				}
			},
			{
				group_name = "MarkviewPalette2Bg",
				value = {
					default = true,

					bg = highlights.hex(res_bg),
				}
			},
			{
				group_name = "MarkviewPalette2Sign",
				value = {
					default = true,

					bg = nr_bg,
					fg = highlights.hex(h_fg)
				}
			}
		};
		---_
	end,
	["3P"] = function ()
		---+${hl}
		local vim_bg = highlights.rgb_to_lab(highlights.get_property(
			"bg",
			{ "Normal" },
			"#1E1E2E",
			"#EFF1F5"
		));
		local h_fg = highlights.rgb_to_lab(highlights.get_property(
			"fg",
			{ "markdownH3", "@markup.heading.3.markdown", "@markup.heading" },
			"#F9E2AF",
			"#DF8E1D"
		));

		local l_bg = highlights.lumen(highlights.lab_to_rgb(vim_bg));
		local alpha = vim.g.__mkv_palette_alpha or (l_bg > 0.5 and 0.15 or 0.25);

		local nr_bg = vim.api.nvim_get_hl(0, { name = "LineNr", link = false }).bg
		local res_bg = highlights.lab_to_rgb(highlights.mix(h_fg, vim_bg, alpha, 1 - alpha));

		vim_bg = highlights.lab_to_rgb(vim_bg);
		h_fg = highlights.lab_to_rgb(h_fg);

		return {
			{
				group_name = "MarkviewPalette3",
				value = {
					default = true,

					bg = highlights.hex(res_bg),
					fg = highlights.hex(h_fg)
				}
			},
			{
				group_name = "MarkviewPalette3Fg",
				value = {
					default = true,

					fg = highlights.hex(h_fg)
				}
			},
			{
				group_name = "MarkviewPalette3Bg",
				value = {
					default = true,

					bg = highlights.hex(res_bg),
				}
			},
			{
				group_name = "MarkviewPalette3Sign",
				value = {
					default = true,

					bg = nr_bg,
					fg = highlights.hex(h_fg)
				}
			}
		};
		---_
	end,
	["4P"] = function ()
		---+${hl}
		local vim_bg = highlights.rgb_to_lab(highlights.get_property(
			"bg",
			{ "Normal" },
			"#1E1E2E",
			"#EFF1F5"
		));
		local h_fg = highlights.rgb_to_lab(highlights.get_property(
			"fg",
			{ "markdownH4", "@markup.heading.4.markdown", "@markup.heading" },
			"#A6E3A1",
			"#40A02B"
		));

		local l_bg = highlights.lumen(highlights.lab_to_rgb(vim_bg));
		local alpha = vim.g.__mkv_palette_alpha or (l_bg > 0.5 and 0.15 or 0.25);

		local nr_bg = vim.api.nvim_get_hl(0, { name = "LineNr", link = false }).bg
		local res_bg = highlights.lab_to_rgb(highlights.mix(h_fg, vim_bg, alpha, 1 - alpha));

		vim_bg = highlights.lab_to_rgb(vim_bg);
		h_fg = highlights.lab_to_rgb(h_fg);

		return {
			{
				group_name = "MarkviewPalette4",
				value = {
					default = true,

					bg = highlights.hex(res_bg),
					fg = highlights.hex(h_fg)
				}
			},
			{
				group_name = "MarkviewPalette4Fg",
				value = {
					default = true,

					fg = highlights.hex(h_fg)
				}
			},
			{
				group_name = "MarkviewPalette4Bg",
				value = {
					default = true,

					bg = highlights.hex(res_bg),
				}
			},
			{
				group_name = "MarkviewPalette4Sign",
				value = {
					default = true,

					bg = nr_bg,
					fg = highlights.hex(h_fg)
				}
			}
		};
		---_
	end,
	["5P"] = function ()
		---+${hl}
		local vim_bg = highlights.rgb_to_lab(highlights.get_property(
			"bg",
			{ "Normal" },
			"#1E1E2E",
			"#EFF1F5"
		));
		local h_fg = highlights.rgb_to_lab(highlights.get_property(
			"fg",
			{ "markdownH5", "@markup.heading.5.markdown", "@markup.heading" },
			"#74C7EC",
			"#209FB5"
		));

		local l_bg = highlights.lumen(highlights.lab_to_rgb(vim_bg));
		local alpha = vim.g.__mkv_palette_alpha or (l_bg > 0.5 and 0.15 or 0.25);

		local nr_bg = vim.api.nvim_get_hl(0, { name = "LineNr", link = false }).bg
		local res_bg = highlights.lab_to_rgb(highlights.mix(h_fg, vim_bg, alpha, 1 - alpha));

		vim_bg = highlights.lab_to_rgb(vim_bg);
		h_fg = highlights.lab_to_rgb(h_fg);

		return {
			{
				group_name = "MarkviewPalette5",
				value = {
					default = true,

					bg = highlights.hex(res_bg),
					fg = highlights.hex(h_fg)
				}
			},
			{
				group_name = "MarkviewPalette5Fg",
				value = {
					default = true,

					fg = highlights.hex(h_fg)
				}
			},
			{
				group_name = "MarkviewPalette5Bg",
				value = {
					default = true,

					bg = highlights.hex(res_bg),
				}
			},
			{
				group_name = "MarkviewPalette5Sign",
				value = {
					default = true,

					bg = nr_bg,
					fg = highlights.hex(h_fg)
				}
			}
		};
		---_
	end,
	["6P"] = function ()
		---+${hl}
		local vim_bg = highlights.rgb_to_lab(highlights.get_property(
			"bg",
			{ "Normal" },
			"#1E1E2E",
			"#EFF1F5"
		));
		local h_fg = highlights.rgb_to_lab(highlights.get_property(
			"fg",
			{ "markdownH6", "@markup.heading.6.markdown", "@markup.heading" },
			"#B4BEFE",
			"#7287FD"
		));

		local l_bg = highlights.lumen(highlights.lab_to_rgb(vim_bg));
		local alpha = vim.g.__mkv_palette_alpha or (l_bg > 0.5 and 0.15 or 0.25);

		local nr_bg = vim.api.nvim_get_hl(0, { name = "LineNr", link = false }).bg
		local res_bg = highlights.lab_to_rgb(highlights.mix(h_fg, vim_bg, alpha, 1 - alpha));

		vim_bg = highlights.lab_to_rgb(vim_bg);
		h_fg = highlights.lab_to_rgb(h_fg);

		return {
			{
				group_name = "MarkviewPalette6",
				value = {
					default = true,

					bg = highlights.hex(res_bg),
					fg = highlights.hex(h_fg)
				}
			},
			{
				group_name = "MarkviewPalette6Fg",
				value = {
					default = true,

					fg = highlights.hex(h_fg)
				}
			},
			{
				group_name = "MarkviewPalette6Bg",
				value = {
					default = true,

					bg = highlights.hex(res_bg),
				}
			},
			{
				group_name = "MarkviewPalette6Sign",
				value = {
					default = true,

					bg = nr_bg,
					fg = highlights.hex(h_fg)
				}
			}
		};
		---_
	end,

	---+${hl, Block quotes}
	["BlockQuoteDefault"] = function ()
		return {
			default = true,
			link = "MarkviewPalette0Fg"
		};
	end,

	["BlockQuoteError"] = function ()
		return {
			default = true,
			link = "MarkviewPalette1Fg"
		};
	end,

	["BlockQuoteNote"] = function ()
		return {
			default = true,
			link = "MarkviewPalette5Fg"
		};
	end,

	["BlockQuoteOk"] = function ()
		return {
			default = true,
			link = "MarkviewPalette4Fg"
		};
	end,

	["BlockQuoteSpecial"] = function ()
		return {
			default = true,
			link = "MarkviewPalette3Fg"
		};
	end,

	["BlockQuoteWarn"] = function ()
		return {
			default = true,
			link = "MarkviewPalette2Fg"
		};
	end,
	---_
	---+${hl, Checkboxes}
	["CheckboxCancelled"] = function ()
		return {
			default = true,
			link = "MarkviewPalette0Fg"
		};
	end,
	["CheckboxChecked"] = function ()
		return {
			default = true,
			link = "MarkviewPalette4Fg"
		};
	end,
	["CheckboxPending"] = function ()
		return {
			default = true,
			link = "MarkviewPalette2Fg"
		};
	end,
	["CheckboxProgress"] = function ()
		return {
			default = true,
			link = "MarkviewPalette6Fg"
		};
	end,
	["CheckboxUnchecked"] = function ()
		return {
			default = true,
			link = "MarkviewPalette1Fg"
		};
	end,
	["CheckboxStriked"] = function ()
		return {
			default = true,
			strikethrough = true,
			fg = vim.api.nvim_get_hl(0, { name = "MarkviewPalette0Fg" }).fg
		};
	end,
	---_
	---+${hl, Code blocks & Inline codes/Injections}
	["Code"] = function ()
		local vim_bg = highlights.rgb_to_hsl(highlights.get_property(
			"bg",
			{ "Normal" },
			"#FFFFFF",
			"#000000"
		));

		if vim_bg[3] > 0.5 then
			vim_bg[3] = clamp(vim_bg[3] - 0.05, 0.1, 0.9);
		else
			vim_bg[3] = clamp(vim_bg[3] + 0.05, 0.1, 0.9);
		end

		---@diagnostic disable
		vim_bg = highlights.hsl_to_rgb(vim_bg);

		return {
			bg = highlights.hex(vim_bg)
		};
		---@diagnostic enable
	end,
	["CodeInfo"] = function ()
		local vim_bg = highlights.rgb_to_hsl(highlights.get_property(
			"bg",
			{ "Normal" },
			"#FFFFFF",
			"#000000"
		));
		local code_fg = highlights.get_property(
			"fg",
			{ "Comment" },
			"#9CA0B0",
			"#6C7086"
		);

		if vim_bg[3] > 0.5 then
			vim_bg[3] = clamp(vim_bg[3] - 0.05, 0.1, 0.9);
		else
			vim_bg[3] = clamp(vim_bg[3] + 0.05, 0.1, 0.9);
		end

		---@diagnostic disable
		vim_bg = highlights.hsl_to_rgb(vim_bg);

		return {
			bg = highlights.hex(vim_bg),
			fg = highlights.hex(code_fg)
		};
		---@diagnostic enable
	end,
	["CodeFg"] = function ()
		local vim_bg = highlights.rgb_to_hsl(highlights.get_property(
			"bg",
			{ "Normal" },
			"#FFFFFF",
			"#000000"
		));

		if vim_bg[3] > 0.5 then
			vim_bg[3] = clamp(vim_bg[3] - 0.05, 0.1, 0.9);
		else
			vim_bg[3] = clamp(vim_bg[3] + 0.05, 0.1, 0.9);
		end

		---@diagnostic disable
		vim_bg = highlights.hsl_to_rgb(vim_bg);

		return {
			fg = highlights.hex(vim_bg)
		};
		---@diagnostic enable
	end,
	["InlineCode"] = function ()
		local vim_bg = highlights.rgb_to_hsl(highlights.get_property(
			"bg",
			{ "Normal" },
			"#FFFFFF",
			"#000000"
		));

		if vim_bg[3] > 0.5 then
			vim_bg[3] = clamp(vim_bg[3] - 0.1, 0.1, 0.9);
		else
			vim_bg[3] = clamp(vim_bg[3] + 0.1, 0.1, 0.9);
		end

		---@diagnostic disable
		vim_bg = highlights.hsl_to_rgb(vim_bg);

		return {
			bg = highlights.hex(vim_bg)
		};
		---@diagnostic enable
	end,


	["Icon0"] = function ()
		return highlights.hl_generator({
			source = { "MarkviewPalette0" },
			light_fg = "#FE640B",
			dark_fg = "#FAB387",

			hl_opts = {
				bg = vim.api.nvim_get_hl(0, { name = "MarkviewCode", link = false }).bg
			}
		});
	end,

	["Icon1"] = function ()
		return highlights.hl_generator({
			source = { "MarkviewPalette1" },
			light_fg = "#FE640B",
			dark_fg = "#FAB387",

			hl_opts = {
				bg = vim.api.nvim_get_hl(0, { name = "MarkviewCode", link = false }).bg
			}
		});
	end,

	["Icon2"] = function ()
		return highlights.hl_generator({
			source = { "MarkviewPalette2" },
			light_fg = "#FE640B",
			dark_fg = "#FAB387",

			hl_opts = {
				bg = vim.api.nvim_get_hl(0, { name = "MarkviewCode", link = false }).bg
			}
		});
	end,

	["Icon3"] = function ()
		return highlights.hl_generator({
			source = { "MarkviewPalette3" },
			light_fg = "#F9E2AF",
			dark_fg = "#DF8E1D",

			hl_opts = {
				bg = vim.api.nvim_get_hl(0, { name = "MarkviewCode", link = false }).bg
			}
		});
	end,

	["Icon4"] = function ()
		return highlights.hl_generator({
			source = { "MarkviewPalette4" },
			light_fg = "#A6E3A1",
			dark_fg = "#40A02B",

			hl_opts = {
				bg = vim.api.nvim_get_hl(0, { name = "MarkviewCode", link = false }).bg
			}
		});
	end,

	["Icon5"] = function ()
		return highlights.hl_generator({
			source = { "MarkviewPalette5" },
			light_fg = "#74C7EC",
			dark_fg = "#209FB5",

			hl_opts = {
				bg = vim.api.nvim_get_hl(0, { name = "MarkviewCode", link = false }).bg
			}
		});
	end,

	["Icon6"] = function ()
		return highlights.hl_generator({
			source = { "MarkviewPalette6" },
			light_fg = "#B4BEFE",
			dark_fg = "#7287FD",

			hl_opts = {
				bg = vim.api.nvim_get_hl(0, { name = "MarkviewCode", link = false }).bg
			}
		});
	end,
	---_
	---+${hl, Headings}
	["Heading1"] = function ()
		return {
			default = true,
			link = "MarkviewPalette1"
		};
	end,
	["Heading2"] = function ()
		return {
			default = true,
			link = "MarkviewPalette2"
		};
	end,
	["Heading3"] = function ()
		return {
			default = true,
			link = "MarkviewPalette3"
		};
	end,
	["heading4"] = function ()
		return {
			default = true,
			link = "MarkviewPalette4"
		};
	end,
	["Heading5"] = function ()
		return {
			default = true,
			link = "MarkviewPalette5"
		};
	end,
	["Heading6"] = function ()
		return {
			default = true,
			link = "MarkviewPalette6"
		};
	end,


	["Heading1Sign"] = function ()
		return {
			default = true,
			link = "MarkviewPalette1Sign"
		};
	end,
	["Heading2Sign"] = function ()
		return {
			default = true,
			link = "MarkviewPalette2Sign"
		};
	end,
	["Heading3Sign"] = function ()
		return {
			default = true,
			link = "MarkviewPalette3Sign"
		};
	end,
	["heading4Sign"] = function ()
		return {
			default = true,
			link = "MarkviewPalette4Sign"
		};
	end,
	["Heading5Sign"] = function ()
		return {
			default = true,
			link = "MarkviewPalette5Sign"
		};
	end,
	["Heading6Sign"] = function ()
		return {
			default = true,
			link = "MarkviewPalette6Sign"
		};
	end,
	---_

	["Gradient0"] = function ()
		local from = highlights.get_property("bg", { "Normal" }, "#1E1E2E", "#CDD6F4");

		return {
			default = true,
			fg = highlights.hex(from);
		};
	end,
	["Gradient1"] = function ()
		local from = highlights.get_property("bg", { "Normal" }, "#1E1E2E", "#CDD6F4");
		local to   = highlights.get_property("fg", { "Title" }, "#1e66f5", "#89b4fa");

		return {
			default = true,
			fg = highlights.hex({
				lerp(from[1], to[1], 1 / 9),
				lerp(from[2], to[2], 1 / 9),
				lerp(from[3], to[3], 1 / 9),
			});
		};
	end,
	["Gradient2"] = function ()
		local from = highlights.get_property("bg", { "Normal" }, "#1E1E2E", "#CDD6F4");
		local to   = highlights.get_property("fg", { "Title" }, "#1e66f5", "#89b4fa");

		return {
			default = true,
			fg = highlights.hex({
				lerp(from[1], to[1], 2 / 9),
				lerp(from[2], to[2], 2 / 9),
				lerp(from[3], to[3], 2 / 9),
			});
		};
	end,
	["Gradient3"] = function ()
		local from = highlights.get_property("bg", { "Normal" }, "#1E1E2E", "#CDD6F4");
		local to   = highlights.get_property("fg", { "Title" }, "#1e66f5", "#89b4fa");

		return {
			default = true,
			fg = highlights.hex({
				lerp(from[1], to[1], 3 / 9),
				lerp(from[2], to[2], 3 / 9),
				lerp(from[3], to[3], 3 / 9),
			});
		};
	end,
	["Gradient4"] = function ()
		local from = highlights.get_property("bg", { "Normal" }, "#1E1E2E", "#CDD6F4");
		local to   = highlights.get_property("fg", { "Title" }, "#1e66f5", "#89b4fa");

		return {
			default = true,
			fg = highlights.hex({
				lerp(from[1], to[1], 4 / 9),
				lerp(from[2], to[2], 4 / 9),
				lerp(from[3], to[3], 4 / 9),
			});
		};
	end,
	["Gradient5"] = function ()
		local from = highlights.get_property("bg", { "Normal" }, "#1E1E2E", "#CDD6F4");
		local to   = highlights.get_property("fg", { "Title" }, "#1e66f5", "#89b4fa");

		return {
			default = true,
			fg = highlights.hex({
				lerp(from[1], to[1], 5 / 9),
				lerp(from[2], to[2], 5 / 9),
				lerp(from[3], to[3], 5 / 9),
			});
		};
	end,
	["Gradient6"] = function ()
		local from = highlights.get_property("bg", { "Normal" }, "#1E1E2E", "#CDD6F4");
		local to   = highlights.get_property("fg", { "Title" }, "#1e66f5", "#89b4fa");

		return {
			default = true,
			fg = highlights.hex({
				lerp(from[1], to[1], 6 / 9),
				lerp(from[2], to[2], 6 / 9),
				lerp(from[3], to[3], 6 / 9),
			});
		};
	end,
	["Gradient7"] = function ()
		local from = highlights.get_property("bg", { "Normal" }, "#1E1E2E", "#CDD6F4");
		local to   = highlights.get_property("fg", { "Title" }, "#1e66f5", "#89b4fa");

		return {
			default = true,
			fg = highlights.hex({
				lerp(from[1], to[1], 7 / 9),
				lerp(from[2], to[2], 7 / 9),
				lerp(from[3], to[3], 7 / 9),
			});
		};
	end,
	["Gradient8"] = function ()
		local from = highlights.get_property("bg", { "Normal" }, "#1E1E2E", "#CDD6F4");
		local to   = highlights.get_property("fg", { "Title" }, "#1e66f5", "#89b4fa");

		return {
			default = true,
			fg = highlights.hex({
				lerp(from[1], to[1], 8 / 9),
				lerp(from[2], to[2], 8 / 9),
				lerp(from[3], to[3], 8 / 9),
			});
		};
	end,
	["Gradient9"] = function ()
		local to   = highlights.get_property("fg", { "Title" }, "#1e66f5", "#89b4fa");

		return {
			default = true,
			fg = highlights.hex(to);
		};
	end,

	---+${hl, Links}
	["Hyperlink"] = function ()
		return {
			default = true,
			link = "@markup.link.label.markdown_inline"
		}
	end,

	["Image"] = function ()
		return {
			default = true,
			link = "@markup.link.label.markdown_inline"
		}
	end,

	["Email"] = function ()
		return {
			default = true,
			link = "@markup.link.url.markdown_inline"
		}
	end,
	---_
	---+${hl, Latex}
	["LatexSubscript"] = function ()
		return {
			default = true,
			link = "MarkviewPalette3Fg"
		};
	end,
	["LatexSuperscript"] = function ()
		return {
			default = true,
			link = "MarkviewPalette6Fg"
		};
	end,
	---_
	---+${hl, List Items}
	["ListItemMinus"] = function ()
		return {
			default = true,
			link = "MarkviewPalette2Fg"
		};
	end,
	["ListItemPlus"] = function ()
		return {
			default = true,
			link = "MarkviewPalette4Fg"
		};
	end,
	["ListItemStar"] = function ()
		return {
			default = true,
			link = "MarkviewPalette6Fg"
		};
	end,
	---_
	---+${hl, Tables}
	["TableHeader"] = function ()
		return {
			default = true,
			link = "@markup.heading.markdown"
		};
	end,

	["TableBorder"] = function ()
		return {
			default = true,
			link = "MarkviewPalette5Fg"
		};
	end,

	["TableAlignLeft"] = function ()
		return {
			default = true,
			link = "@markup.heading.markdown"
		}
	end,

	["TableAlignCenter"] = function ()
		return {
			default = true,
			link = "@markup.heading.markdown"
		}
	end,

	["TableAlignRight"] = function ()
		return {
			default = true,
			link = "@markup.heading.markdown"
		}
	end,
	---_
};

highlights.groups = highlights.dynamic;

highlights.setup = function (opt)
	if vim.islist(opt) then
		highlights.groups = vim.tbl_extend("force", highlights.groups, opt);
	end

	highlights.create(highlights.groups);
end

return highlights;
