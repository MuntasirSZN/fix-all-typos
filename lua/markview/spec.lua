--- Configuration specification file
--- for `markview.nvim`.
---
--- It has the following tasks,
---    • Maintain backwards compatibility
---    • Check for issues with config
local spec = {};
local symbols = require("markview.symbols");

--- Creates a configuration table for a LaTeX command.
---@param name string Command name(Text to show).
---@param text_pos? "overlay" | "inline" `virt_text_pos` extmark options.
---@param cmd_conceal? integer Characters to conceal.
---@param cmd_hl? string Highlight group for the command.
---@return commands.opts
local operator = function (name, text_pos, cmd_conceal, cmd_hl)
	---+${func}
	return {
		condition = function (item)
			return #item.args == 1;
		end,


		on_command = function (item)
			return {
				end_col = item.range[2] + (cmd_conceal or 1),
				conceal = "",

				virt_text_pos = text_pos or "overlay",
				virt_text = {
					{ symbols.tostring("default", name), cmd_hl or "@keyword.function" }
				},

				hl_mode = "combine"
			}
		end,

		on_args = {
			{
				on_before = function (item)
					return {
						end_col = item.range[2] + 1,

						virt_text_pos = "overlay",
						virt_text = {
							{ "(", "@punctuation.bracket" }
						},

						hl_mode = "combine"
					}
				end,

				after_offset = function (range)
					return { range[1], range[2], range[3], range[4] - 1 };
				end,

				on_after = function (item)
					return {
						end_col = item.range[4],

						virt_text_pos = "overlay",
						virt_text = {
							{ ")", "@punctuation.bracket" }
						},

						hl_mode = "combine"
					}
				end
			}
		}
	};
	---_
end

spec.warnings = {};

--- `vim.notify()` with extra steps.
---@param chunks [ string, string? ][]
---@param opts { silent: boolean, level: integer? }
spec.notify = function (chunks, opts)
	if not opts then opts = {}; end

	local highlights = {
		[vim.log.levels.DEBUG] = "DiagnosticInfo",
		[vim.log.levels.ERROR] = "DiagnosticError",
		[vim.log.levels.INFO] = "DiagnosticInfo",
		[vim.log.levels.OFF] = "Comment",
		[vim.log.levels.TRACE] = "DiagnosticInfo",
		[vim.log.levels.WARN] = "DiagnosticWarn"
	};

	vim.api.nvim_echo(
		vim.list_extend(
			{
				{
					"█ markview",
					highlights[opts.level or vim.log.levels.WARN]
				},
				{ ": " }
			},
			chunks
		),
		true,
		{}
	);

	if opts.silent ~= true then
		table.insert(spec.warnings, opts);
	end
end

---@type mkv.config
spec.default = {
	---+${conf}

	experimental = {
		---+${conf}

		read_chunk_size = 1024,

		file_open_command = "tabnew",
		list_empty_line_tolerance = 3,

		date_formats = {
			"^%d%d%d%d%-%d%d%-%d%d$",                   --- YYYY-MM-DD
			"^%d%d%-%d%d%-%d%d%d%d$",                   --- DD-MM-YYYY, MM-DD-YYYY
			"^%d%d%-%d%d%-%d%d$",                       --- DD-MM-YY, MM-DD-YY, YY-MM-DD

			"^%d%d%d%d%/%d%d%/%d%d$",                   --- YYYY/MM/DD
			"^%d%d%/%d%d%/%d%d%d%d$",                   --- DD/MM/YYYY, MM/DD/YYYY

			"^%d%d%d%d%.%d%d%.%d%d$",                   --- YYYY.MM.DD
			"^%d%d%.%d%d%.%d%d%d%d$",                   --- DD.MM.YYYY, MM.DD.YYYY

			"^%d%d %a+ %d%d%d%d$",                      --- DD Month YYYY
			"^%a+ %d%d %d%d%d%d$",                      --- Month DD, YYYY
			"^%d%d%d%d %a+ %d%d$",                      --- YYYY Month DD

			"^%a+%, %a+ %d%d%, %d%d%d%d$",              --- Day, Month DD, YYYY
		},

		date_time_formats = {
			"^%a%a%a %a%a%a %d%d %d%d%:%d%d%:%d%d ... %d%d%d%d$", --- UNIX date time
			"^%d%d%d%d%-%d%d%-%d%dT%d%d%:%d%d%:%d%dZ$",           --- ISO 8601
		}

		---_
	};

	highlight_groups = {},

	preview = {
		---+${conf}

		enable = true,

		callbacks = {
			---+${func}

			on_attach = function (_, wins)
				---+${lua}

				--- Initial state for attached buffers.
				---@type string
				local attach_state = spec.get({ "preview", "enable" }, { fallback = true, ignore_enable = true });

				if attach_state == false then
					--- Attached buffers will not have their previews
					--- enabled.
					--- So, don't set options.
					return;
				end

				---@type string[]
				local prev_modes = spec.get({ "preview", "modes" }, { fallback = {} });
				---@type string[]
				local hybd_modes = spec.get({ "preview", "hybrid_modes" }, { fallback = {} });

				--- Concealcursor option.
				local concealcursor = "";

				for _, mode in ipairs(prev_modes) do
					if vim.list_contains(hybd_modes, mode) == false and vim.list_contains({ "n", "v", "i", "c" }, mode) then
						--- Only add modes that aren't used by hybrid mode
						--- and are inside the valid modes for concealcursor.
						concealcursor = concealcursor .. mode;
					end
				end

				for _, win in ipairs(wins) do
					--- Preferred conceal level should
					--- be 3.
					vim.wo[win].conceallevel = 3;
					vim.wo[win].concealcursor = concealcursor;
				end

				---_
			end,
			on_detach = function (_, wins)
				---+${lua}
				for _, win in ipairs(wins) do
					--- Conceallevel & concealcursor
					--- should be reset for every
					--- window.
					vim.wo[win].conceallevel = 0;
					vim.wo[win].concealcursor = "";
				end
				---_
			end,

			on_enable = function (_, wins)
				---+${lua}

				---@type string[]
				local prev_modes = spec.get({ "preview", "modes" }, { fallback = {} });
				---@type string[]
				local hybd_modes = spec.get({ "preview", "hybrid_modes" }, { fallback = {} });

				local concealcursor = "";

				for _, mode in ipairs(prev_modes) do
					if vim.list_contains(hybd_modes, mode) == false and vim.list_contains({ "n", "v", "i", "c" }, mode) then
						concealcursor = concealcursor .. mode;
					end
				end

				for _, win in ipairs(wins) do
					vim.wo[win].conceallevel = 3;
					vim.wo[win].concealcursor = concealcursor;
				end
				---_
			end,
			on_disable = function (_, wins)
				---+${lua}
				for _, win in ipairs(wins) do
					vim.wo[win].conceallevel = 0;
					vim.wo[win].concealcursor = "";
				end
				---_
			end,

			on_mode_change = function (_, wins, current_mode)
				---+${lua}

				---@type string[]
				local preview_modes = spec.get({ "preview", "modes" }, { fallback = {} });
				---@type string[]
				local hybrid_modes = spec.get({ "preview", "hybrid_modes" }, { fallback = {} });

				local concealcursor = "";

				for _, mode in ipairs(preview_modes) do
					if vim.list_contains(hybrid_modes, mode) == false and vim.list_contains({ "n", "v", "i", "c" }, mode) then
						concealcursor = concealcursor .. mode;
					end
				end

				for _, win in ipairs(wins) do
					if vim.list_contains(preview_modes, current_mode) and require("markview").state.enable == true then
						vim.wo[win].conceallevel = 3;
						vim.wo[win].concealcursor = concealcursor;
					else
						vim.wo[win].conceallevel = 0;
						vim.wo[win].concealcursor = "";
					end
				end
				---_
			end,

			on_splitview_open = function (_, _, win)
				---+${lua}
				vim.wo[win].conceallevel = 3;
				vim.wo[win].concealcursor = "n";
				---_
			end
			---_
		},
		debounce = 150,
		icon_provider = "internal",

		draw_range = { 2 * vim.o.lines, 2 * vim.o.lines },
		edit_range = { 0, 0 },

		modes = { "n", "no", "c" },
		hybrid_modes = {},
		linewise_hybrid_mode = false,
		max_buf_lines = 1000,

		filetypes = { "markdown", "quarto", "rmd", "typst" },
		ignore_buftypes = { "nofile" },
		ignore_previews = {},

		splitview_winopts = {
			split = "right"
		}

		---_
	},

	renderers = {},

	markdown = {
		---+${lua}

		enable = true,

		block_quotes = {
			---+${class}
			enable = true,
			wrap = true,

			default = {
				border = "▋",
				hl = "MarkviewBlockQuoteDefault"
			},

			---+${conf}
			["ABSTRACT"] = {
				preview = "󱉫 Abstract",
				hl = "MarkviewBlockQuoteNote",

				title = true,
				icon = "󱉫",

				border = "▋"
			},
			["SUMMARY"] = {
				hl = "MarkviewBlockQuoteNote",
				preview = "󱉫 Summary",

				title = true,
				icon = "󱉫",

				border = "▋"
			},
			["TLDR"] = {
				hl = "MarkviewBlockQuoteNote",
				preview = "󱉫 Tldr",

				title = true,
				icon = "󱉫",

				border = "▋"
			},
			["TODO"] = {
				hl = "MarkviewBlockQuoteNote",
				preview = " Todo",

				title = true,
				icon = "",

				border = "▋"
			},
			["INFO"] = {
				hl = "MarkviewBlockQuoteNote",
				preview = " Info",

				custom_title = true,
				icon = "",

				border = "▋"
			},
			["SUCCESS"] = {
				hl = "MarkviewBlockQuoteOk",
				preview = "󰗠 Success",

				title = true,
				icon = "󰗠",

				border = "▋"
			},
			["CHECK"] = {
				hl = "MarkviewBlockQuoteOk",
				preview = "󰗠 Check",

				title = true,
				icon = "󰗠",

				border = "▋"
			},
			["DONE"] = {
				hl = "MarkviewBlockQuoteOk",
				preview = "󰗠 Done",

				title = true,
				icon = "󰗠",

				border = "▋"
			},
			["QUESTION"] = {
				hl = "MarkviewBlockQuoteWarn",
				preview = "󰋗 Question",

				title = true,
				icon = "󰋗",

				border = "▋"
			},
			["HELP"] = {
				hl = "MarkviewBlockQuoteWarn",
				preview = "󰋗 Help",

				title = true,
				icon = "󰋗",

				border = "▋"
			},
			["FAQ"] = {
				hl = "MarkviewBlockQuoteWarn",
				preview = "󰋗 Faq",

				title = true,
				icon = "󰋗",

				border = "▋"
			},
			["FAILURE"] = {
				hl = "MarkviewBlockQuoteError",
				preview = "󰅙 Failure",

				title = true,
				icon = "󰅙",

				border = "▋"
			},
			["FAIL"] = {
				hl = "MarkviewBlockQuoteError",
				preview = "󰅙 Fail",

				title = true,
				icon = "󰅙",

				border = "▋"
			},
			["MISSING"] = {
				hl = "MarkviewBlockQuoteError",
				preview = "󰅙 Missing",

				title = true,
				icon = "󰅙",

				border = "▋"
			},
			["DANGER"] = {
				hl = "MarkviewBlockQuoteError",
				preview = " Danger",

				title = true,
				icon = "",

				border = "▋"
			},
			["ERROR"] = {
				hl = "MarkviewBlockQuoteError",
				preview = " Error",

				title = true,
				icon = "",

				border = "▋"
			},
			["BUG"] = {
				hl = "MarkviewBlockQuoteError",
				preview = " Bug",

				title = true,
				icon = "",

				border = "▋"
			},
			["EXAMPLE"] = {
				hl = "MarkviewBlockQuoteSpecial",
				preview = "󱖫 Example",

				title = true,
				icon = "󱖫",

				border = "▋"
			},
			["QUOTE"] = {
				hl = "MarkviewBlockQuoteDefault",
				preview = " Quote",

				title = true,
				icon = "",

				border = "▋"
			},
			["CITE"] = {
				hl = "MarkviewBlockQuoteDefault",
				preview = " Cite",

				title = true,
				icon = "",

				border = "▋"
			},
			["HINT"] = {
				hl = "MarkviewBlockQuoteOk",
				preview = " Hint",

				title = true,
				icon = "",

				border = "▋"
			},
			["ATTENTION"] = {
				hl = "MarkviewBlockQuoteWarn",
				preview = " Attention",

				title = true,
				icon = "",

				border = "▋"
			},


			["NOTE"] = {
				match_string = "NOTE",
				hl = "MarkviewBlockQuoteNote",
				preview = "󰋽 Note",

				border = "▋"
			},
			["TIP"] = {
				match_string = "TIP",
				hl = "MarkviewBlockQuoteOk",
				preview = " Tip",

				border = "▋"
			},
			["IMPORTANT"] = {
				match_string = "IMPORTANT",
				hl = "MarkviewBlockQuoteSpecial",
				preview = " Important",

				border = "▋"
			},
			["WARNING"] = {
				match_string = "WARNING",
				hl = "MarkviewBlockQuoteWarn",
				preview = " Warning",

				border = "▋"
			},
			["CAUTION"] = {
				match_string = "CAUTION",
				hl = "MarkviewBlockQuoteError",
				preview = "󰳦 Caution",

				border = "▋"
			}
			---_

			---_
		},

		code_blocks = {
			---+${conf, Code blocks}

			enable = true,

			style = "block",

			label_direction = "right",
			hl = "MarkviewCode",
			info_hl = "MarkviewCodeInfo",

			min_width = 60,
			pad_amount = 3,
			pad_char = " ",

			sign = true

			---_
		},

		headings = {
			---+ ${class, Headings}

			enable = true,

			shift_width = 1,

			org_indent = false,
			org_indent_wrap = true,
			org_shift_char = " ",
			org_shift_width = 1,

			heading_1 = {
				---+ ${conf, Heading 1}
				style = "icon",
				sign = "󰌕 ", sign_hl = "MarkviewHeading1Sign",

				icon = "󰼏  ", hl = "MarkviewHeading1",
				---_
			},
			heading_2 = {
				---+ ${conf, Heading 2}
				style = "icon",
				sign = "󰌖 ", sign_hl = "MarkviewHeading2Sign",

				icon = "󰎨  ", hl = "MarkviewHeading2",
				---_
			},
			heading_3 = {
				---+ ${conf, Heading 3}
				style = "icon",

				icon = "󰼑  ", hl = "MarkviewHeading3",
				---_
			},
			heading_4 = {
				---+ ${conf, Heading 4}
				style = "icon",

				icon = "󰎲  ", hl = "MarkviewHeading4",
				---_
			},
			heading_5 = {
				---+ ${conf, Heading 5}
				style = "icon",

				icon = "󰼓  ", hl = "MarkviewHeading5",
				---_
			},
			heading_6 = {
				---+ ${conf, Heading 6}
				style = "icon",

				icon = "󰎴  ", hl = "MarkviewHeading6",
				---_
			},

			setext_1 = {
				---+ ${conf, Setext heading 1}
				style = "decorated",

				sign = "󰌕 ", sign_hl = "MarkviewHeading1Sign",
				icon = "  ", hl = "MarkviewHeading1",
				border = "▂"
				---_
			},
			setext_2 = {
				---+ ${conf, Setext heading 2}
				style = "decorated",

				sign = "󰌖 ", sign_hl = "MarkviewHeading2Sign",
				icon = "  ", hl = "MarkviewHeading2",
				border = "▁"
				---_
			}

			---_
		},

		horizontal_rules = {
			---+ ${class, Horizontal rules}
			enable = true,

			parts = {
				{
					---+ ${conf, Left portion}

					type = "repeating",
					direction = "left",

					repeat_amount = function (buffer)
						local utils = require("markview.utils");
						local window = utils.buf_getwin(buffer)

						local width = vim.api.nvim_win_get_width(window)
						local textoff = vim.fn.getwininfo(window)[1].textoff;

						return math.floor((width - textoff - 3) / 2);
					end,

					text = "─",

					hl = {
						"MarkviewGradient1", "MarkviewGradient1",
						"MarkviewGradient2", "MarkviewGradient2",
						"MarkviewGradient3", "MarkviewGradient3",
						"MarkviewGradient4", "MarkviewGradient4",
						"MarkviewGradient5", "MarkviewGradient5",
						"MarkviewGradient6", "MarkviewGradient6",
						"MarkviewGradient7", "MarkviewGradient7",
						"MarkviewGradient8", "MarkviewGradient8",
						"MarkviewGradient9", "MarkviewGradient9"
					}
					---_
				},
				{
					type = "text",

					text = "  ",
					hl = "MarkviewIcon3Fg"
				},
				{
					---+ ${conf, Right portion}
					type = "repeating",
					direction = "right",

					repeat_amount = function (buffer) --[[@as function]]
						local utils = require("markview.utils");
						local window = utils.buf_getwin(buffer)

						local width = vim.api.nvim_win_get_width(window)
						local textoff = vim.fn.getwininfo(window)[1].textoff;

						return math.ceil((width - textoff - 3) / 2);
					end,

					text = "─",
					hl = {
						"MarkviewGradient1", "MarkviewGradient1",
						"MarkviewGradient2", "MarkviewGradient2",
						"MarkviewGradient3", "MarkviewGradient3",
						"MarkviewGradient4", "MarkviewGradient4",
						"MarkviewGradient5", "MarkviewGradient5",
						"MarkviewGradient6", "MarkviewGradient6",
						"MarkviewGradient7", "MarkviewGradient7",
						"MarkviewGradient8", "MarkviewGradient8",
						"MarkviewGradient9", "MarkviewGradient9"
					}
					---_
				}
			}
			---_
		},

		list_items = {
			---+${conf, List items}
			enable = true,
			wrap = true,

			indent_size = 2,
			shift_width = 4,

			marker_minus = {
				add_padding = true,
				conceal_on_checkboxes = true,

				text = "",
				hl = "MarkviewListItemMinus"
			},

			marker_plus = {
				add_padding = true,
				conceal_on_checkboxes = true,

				text = "",
				hl = "MarkviewListItemPlus"
			},

			marker_star = {
				add_padding = true,
				conceal_on_checkboxes = true,

				text = "",
				hl = "MarkviewListItemStar"
			},

			marker_dot = {
				add_padding = true,
				conceal_on_checkboxes = true
			},

			marker_parenthesis = {
				add_padding = true,
				conceal_on_checkboxes = true
			}
			---_
		},

		metadata_minus = {
			---+${lua}

			enable = true,

			hl = "MarkviewCode",
			border_hl = "MarkviewCodeFg",

			border_top = "▄",
			border_bottom = "▀"

			---_
		},

		metadata_plus = {
			---+${lua}

			enable = true,

			hl = "MarkviewCode",
			border_hl = "MarkviewCodeFg",

			border_top = "▄",
			border_bottom = "▀"

			---_
		},

		reference_definitions = {
			---+${lua}

			enable = true,

			default = {
				icon = " ",
				hl = "MarkviewPalette4Fg"
			},

			---+${lua, Github sites}

			["github%.com/[%a%d%-%_%.]+%/?$"] = {
				--- github.com/<user>

				icon = " ",
				hl = "MarkviewPalette0Fg"
			},
			["github%.com/[%a%d%-%_%.]+/[%a%d%-%_%.]+%/?$"] = {
				--- github.com/<user>/<repo>

				icon = "󰳐 ",
				hl = "MarkviewPalette0Fg"
			},
			["github%.com/[%a%d%-%_%.]+/[%a%d%-%_%.]+/tree/[%a%d%-%_%.]+%/?$"] = {
				--- github.com/<user>/<repo>/tree/<branch>

				icon = " ",
				hl = "MarkviewPalette0Fg"
			},
			["github%.com/[%a%d%-%_%.]+/[%a%d%-%_%.]+/commits/[%a%d%-%_%.]+%/?$"] = {
				--- github.com/<user>/<repo>/commits/<branch>

				icon = " ",
				hl = "MarkviewPalette0Fg"
			},

			["github%.com/[%a%d%-%_%.]+/[%a%d%-%_%.]+%/releases$"] = {
				--- github.com/<user>/<repo>/releases

				icon = " ",
				hl = "MarkviewPalette0Fg"
			},
			["github%.com/[%a%d%-%_%.]+/[%a%d%-%_%.]+%/tags$"] = {
				--- github.com/<user>/<repo>/tags

				icon = " ",
				hl = "MarkviewPalette0Fg"
			},
			["github%.com/[%a%d%-%_%.]+/[%a%d%-%_%.]+%/issues$"] = {
				--- github.com/<user>/<repo>/issues

				icon = " ",
				hl = "MarkviewPalette0Fg"
			},
			["github%.com/[%a%d%-%_%.]+/[%a%d%-%_%.]+%/pulls$"] = {
				--- github.com/<user>/<repo>/pulls

				icon = " ",
				hl = "MarkviewPalette0Fg"
			},

			["github%.com/[%a%d%-%_%.]+/[%a%d%-%_%.]+%/wiki$"] = {
				--- github.com/<user>/<repo>/wiki

				icon = " ",
				hl = "MarkviewPalette0Fg"
			},

			---_
			---+${lua, Commonly used sites by programmers}

			["developer%.mozilla%.org"] = {
				priority = 9999,

				icon = "󰖟 ",
				hl = "MarkviewPalette5Fg"
			},

			["w3schools%.com"] = {
				priority = 9999,

				icon = " ",
				hl = "MarkviewPalette4Fg"
			},

			["stackoverflow%.com"] = {
				priority = 9999,

				icon = "󰓌 ",
				hl = "MarkviewPalette2Fg"
			},

			["reddit%.com"] = {
				priority = 9999,

				icon = " ",
				hl = "MarkviewPalette2Fg"
			},

			["github%.com"] = {
				priority = 9999,

				icon = " ",
				hl = "MarkviewPalette6Fg"
			},

			["gitlab%.com"] = {
				priority = 9999,

				icon = " ",
				hl = "MarkviewPalette2Fg"
			},

			["dev%.to"] = {
				priority = 9999,

				icon = "󱁴 ",
				hl = "MarkviewPalette0Fg"
			},

			["codepen%.io"] = {
				priority = 9999,

				icon = " ",
				hl = "MarkviewPalette6Fg"
			},

			["replit%.com"] = {
				priority = 9999,

				icon = " ",
				hl = "MarkviewPalette2Fg"
			},

			["jsfiddle%.net"] = {
				priority = 9999,

				icon = " ",
				hl = "MarkviewPalette5Fg"
			},

			["npmjs%.com"] = {
				priority = 9999,

				icon = " ",
				hl = "MarkviewPalette0Fg"
			},

			["pypi%.org"] = {
				priority = 9999,

				icon = "󰆦 ",
				hl = "MarkviewPalette0Fg"
			},

			["mvnrepository%.com"] = {
				priority = 9999,

				icon = " ",
				hl = "MarkviewPalette1Fg"
			},

			["medium%.com"] = {
				priority = 9999,

				icon = " ",
				hl = "MarkviewPalette6Fg"
			},

			["linkedin%.com"] = {
				priority = 9999,

				icon = "󰌻 ",
				hl = "MarkviewPalette5Fg"
			},

			["news%.ycombinator%.com"] = {
				priority = 9999,

				icon = " ",
				hl = "MarkviewPalette2Fg"
			},

			---_

			---_
		},

		tables = {
			---+ ${class, Tables}

			enable = true,

			col_min_width = 10,
			block_decorator = true,
			use_virt_lines = false,

			parts = {
				top = { "╭", "─", "╮", "┬" },
				header = { "│", "│", "│" },
				separator = { "├", "─", "┤", "┼" },
				row = { "│", "│", "│" },
				bottom = { "╰", "─", "╯", "┴" },

				overlap = { "┝", "━", "┥", "┿" },

				align_left = "╼",
				align_right = "╾",
				align_center = { "╴", "╶" }
			},

			hl = {
				top = { "TableHeader", "TableHeader", "TableHeader", "TableHeader" },
				header = { "TableHeader", "TableHeader", "TableHeader" },
				separator = { "TableHeader", "TableHeader", "TableHeader", "TableHeader" },
				row = { "TableBorder", "TableBorder", "TableBorder" },
				bottom = { "TableBorder", "TableBorder", "TableBorder", "TableBorder" },

				overlap = { "TableBorder", "TableBorder", "TableBorder", "TableBorder" },

				align_left = "TableAlignLeft",
				align_right = "TableAlignRight",
				align_center = { "TableAlignCenter", "TableAlignCenter" }
			}

			---_
		},

		---_
	},
	markdown_inline = {
		---+${lua}

		enable = true,

		block_references = {
			---+${lua}

			enable = true,

			default = {
				icon = "󰿨 ",

				hl = "MarkviewPalette6Fg",
				file_hl = "MarkviewPalette0Fg",
			},

			---_
		},

		checkboxes = {
			---+ ${conf, Minimal style checkboxes}
			enable = true,

			checked = { text = "󰗠", hl = "MarkviewCheckboxChecked", scope_hl = "MarkviewCheckboxChecked" },
			unchecked = { text = "󰄰", hl = "MarkviewCheckboxUnchecked", scope_hl = "MarkviewCheckboxUnchecked" },

			["/"] = { text = "󱎖", hl = "MarkviewCheckboxPending" },
			[">"] = { text = "", hl = "MarkviewCheckboxCancelled" },
			["<"] = { text = "󰃖", hl = "MarkviewCheckboxCancelled" },
			["-"] = { text = "󰍶", hl = "MarkviewCheckboxCancelled", scope_hl = "MarkviewCheckboxStriked" },

			["?"] = { text = "󰋗", hl = "MarkviewCheckboxPending" },
			["!"] = { text = "󰀦", hl = "MarkviewCheckboxUnchecked" },
			["*"] = { text = "󰓎", hl = "MarkviewCheckboxPending" },
			['"'] = { text = "󰸥", hl = "MarkviewCheckboxCancelled" },
			["l"] = { text = "󰆋", hl = "MarkviewCheckboxProgress" },
			["b"] = { text = "󰃀", hl = "MarkviewCheckboxProgress" },
			["i"] = { text = "󰰄", hl = "MarkviewCheckboxChecked" },
			["S"] = { text = "", hl = "MarkviewCheckboxChecked" },
			["I"] = { text = "󰛨", hl = "MarkviewCheckboxPending" },
			["p"] = { text = "", hl = "MarkviewCheckboxChecked" },
			["c"] = { text = "", hl = "MarkviewCheckboxUnchecked" },
			["f"] = { text = "󱠇", hl = "MarkviewCheckboxUnchecked" },
			["k"] = { text = "", hl = "MarkviewCheckboxPending" },
			["w"] = { text = "", hl = "MarkviewCheckboxProgress" },
			["u"] = { text = "󰔵", hl = "MarkviewCheckboxChecked" },
			["d"] = { text = "󰔳", hl = "MarkviewCheckboxUnchecked" },
			---_
		},

		emails = {
			---+${lua}

			enable = true,

			default = {
				icon = " ",
				hl = "MarkviewEmail"
			},

			---+${lua, Commonly used email service providers}

			["%@gmail%.com$"] = {
				--- user@gmail.com

				icon = "󰊫 ",
				hl = "MarkviewPalette0Fg"
			},

			["%@outlook%.com$"] = {
				--- user@outlook.com

				icon = "󰴢 ",
				hl = "MarkviewPalette5Fg"
			},

			["%@yahoo%.com$"] = {
				--- user@yahoo.com

				icon = " ",
				hl = "MarkviewPalette6Fg"
			},

			["%@icloud%.com$"] = {
				--- user@icloud.com

				icon = "󰀸 ",
				hl = "MarkviewPalette6Fg"
			}

			---_

			---_
		},

		embed_files = {
			---+${lua}

			enable = true,

			default = {
				icon = "󰠮 ",
				hl = "MarkviewPalette7Fg"
			}

			---_
		},

		entities = {
			---+${lua}

			enable = true,
			hl = "Special"

			---_
		},

		escapes = {
			enable = true
		},

		footnotes = {
			---+${lua}

			enable = true,

			default = {
				icon = "󰯓 ",
				hl = "MarkviewHyperlink"
			},

			["^%d+$"] = {
				--- Numbered footnotes.

				icon = "󰯓 ",
				hl = "MarkviewPalette4Fg"
			}

			---_
		},

		highlights = {
			---+${lua}

			enable = true,

			default = {
				padding_left = " ",
				padding_right = " ",

				hl = "MarkviewPalette3"
			}

			---_
		},

		hyperlinks = {
			---+${lua}

			enable = true,

			default = {
				icon = "󰌷 ",
				hl = "MarkviewHyperlink",
			},

			---+${lua, Github sites}

			["github%.com/[%a%d%-%_%.]+%/?$"] = {
				--- github.com/<user>

				icon = " ",
				hl = "MarkviewPalette0Fg"
			},
			["github%.com/[%a%d%-%_%.]+/[%a%d%-%_%.]+%/?$"] = {
				--- github.com/<user>/<repo>

				icon = "󰳐 ",
				hl = "MarkviewPalette0Fg"
			},
			["github%.com/[%a%d%-%_%.]+/[%a%d%-%_%.]+/tree/[%a%d%-%_%.]+%/?$"] = {
				--- github.com/<user>/<repo>/tree/<branch>

				icon = " ",
				hl = "MarkviewPalette0Fg"
			},
			["github%.com/[%a%d%-%_%.]+/[%a%d%-%_%.]+/commits/[%a%d%-%_%.]+%/?$"] = {
				--- github.com/<user>/<repo>/commits/<branch>

				icon = " ",
				hl = "MarkviewPalette0Fg"
			},

			["github%.com/[%a%d%-%_%.]+/[%a%d%-%_%.]+%/releases$"] = {
				--- github.com/<user>/<repo>/releases

				icon = " ",
				hl = "MarkviewPalette0Fg"
			},
			["github%.com/[%a%d%-%_%.]+/[%a%d%-%_%.]+%/tags$"] = {
				--- github.com/<user>/<repo>/tags

				icon = " ",
				hl = "MarkviewPalette0Fg"
			},
			["github%.com/[%a%d%-%_%.]+/[%a%d%-%_%.]+%/issues$"] = {
				--- github.com/<user>/<repo>/issues

				icon = " ",
				hl = "MarkviewPalette0Fg"
			},
			["github%.com/[%a%d%-%_%.]+/[%a%d%-%_%.]+%/pulls$"] = {
				--- github.com/<user>/<repo>/pulls

				icon = " ",
				hl = "MarkviewPalette0Fg"
			},

			["github%.com/[%a%d%-%_%.]+/[%a%d%-%_%.]+%/wiki$"] = {
				--- github.com/<user>/<repo>/wiki

				icon = " ",
				hl = "MarkviewPalette0Fg"
			},

			---_
			---+${lua, Commonly used sites by programmers}

			["developer%.mozilla%.org"] = {
				priority = 9999,

				icon = "󰖟 ",
				hl = "MarkviewPalette5Fg"
			},

			["w3schools%.com"] = {
				priority = 9999,

				icon = " ",
				hl = "MarkviewPalette4Fg"
			},

			["stackoverflow%.com"] = {
				priority = 9999,

				icon = "󰓌 ",
				hl = "MarkviewPalette2Fg"
			},

			["reddit%.com"] = {
				priority = 9999,

				icon = " ",
				hl = "MarkviewPalette2Fg"
			},

			["github%.com"] = {
				priority = 9999,

				icon = " ",
				hl = "MarkviewPalette6Fg"
			},

			["gitlab%.com"] = {
				priority = 9999,

				icon = " ",
				hl = "MarkviewPalette2Fg"
			},

			["dev%.to"] = {
				priority = 9999,

				icon = "󱁴 ",
				hl = "MarkviewPalette0Fg"
			},

			["codepen%.io"] = {
				priority = 9999,

				icon = " ",
				hl = "MarkviewPalette6Fg"
			},

			["replit%.com"] = {
				priority = 9999,

				icon = " ",
				hl = "MarkviewPalette2Fg"
			},

			["jsfiddle%.net"] = {
				priority = 9999,

				icon = " ",
				hl = "MarkviewPalette5Fg"
			},

			["npmjs%.com"] = {
				priority = 9999,

				icon = " ",
				hl = "MarkviewPalette0Fg"
			},

			["pypi%.org"] = {
				priority = 9999,

				icon = "󰆦 ",
				hl = "MarkviewPalette0Fg"
			},

			["mvnrepository%.com"] = {
				priority = 9999,

				icon = " ",
				hl = "MarkviewPalette1Fg"
			},

			["medium%.com"] = {
				priority = 9999,

				icon = " ",
				hl = "MarkviewPalette6Fg"
			},

			["linkedin%.com"] = {
				priority = 9999,

				icon = "󰌻 ",
				hl = "MarkviewPalette5Fg"
			},

			["news%.ycombinator%.com"] = {
				priority = 9999,

				icon = " ",
				hl = "MarkviewPalette2Fg"
			},

			---_

			---_
		},

		images = {
			---+${lua}

			enable = true,

			default = {
				icon = "󰥶 ",
				hl = "MarkviewImage",
			},

			["%.svg$"] = { icon = "󰜡 " },
			["%.png$"] = { icon = "󰸭 " },
			["%.jpg$"] = { icon = "󰈥 " },
			["%.gif$"] = { icon = "󰵸 " },
			["%.pdf$"] = { icon = " " }

			---_
		},

		inline_codes = {
			---+${lua}

			enable = true,
			hl = "MarkviewInlineCode",

			padding_left = " ",
			padding_right = " "

			---_
		},

		internal_links = {
			---+${lua}

			enable = true,

			default = {
				icon = " ",
				hl = "MarkviewPalette7Fg",
			},

			---_
		},

		uri_autolinks = {
			---+${lua}

			enable = true,

			default = {
				icon = " ",
				hl = "MarkviewEmail"
			},

			---+${lua, Github sites}

			["github%.com/[%a%d%-%_%.]+%/?$"] = {
				--- github.com/<user>

				icon = " ",
				hl = "MarkviewPalette0Fg"
			},
			["github%.com/[%a%d%-%_%.]+/[%a%d%-%_%.]+%/?$"] = {
				--- github.com/<user>/<repo>

				icon = "󰳐 ",
				hl = "MarkviewPalette0Fg"
			},
			["github%.com/[%a%d%-%_%.]+/[%a%d%-%_%.]+/tree/[%a%d%-%_%.]+%/?$"] = {
				--- github.com/<user>/<repo>/tree/<branch>

				icon = " ",
				hl = "MarkviewPalette0Fg"
			},
			["github%.com/[%a%d%-%_%.]+/[%a%d%-%_%.]+/commits/[%a%d%-%_%.]+%/?$"] = {
				--- github.com/<user>/<repo>/commits/<branch>

				icon = " ",
				hl = "MarkviewPalette0Fg"
			},

			["github%.com/[%a%d%-%_%.]+/[%a%d%-%_%.]+%/releases$"] = {
				--- github.com/<user>/<repo>/releases

				icon = " ",
				hl = "MarkviewPalette0Fg"
			},
			["github%.com/[%a%d%-%_%.]+/[%a%d%-%_%.]+%/tags$"] = {
				--- github.com/<user>/<repo>/tags

				icon = " ",
				hl = "MarkviewPalette0Fg"
			},
			["github%.com/[%a%d%-%_%.]+/[%a%d%-%_%.]+%/issues$"] = {
				--- github.com/<user>/<repo>/issues

				icon = " ",
				hl = "MarkviewPalette0Fg"
			},
			["github%.com/[%a%d%-%_%.]+/[%a%d%-%_%.]+%/pulls$"] = {
				--- github.com/<user>/<repo>/pulls

				icon = " ",
				hl = "MarkviewPalette0Fg"
			},

			["github%.com/[%a%d%-%_%.]+/[%a%d%-%_%.]+%/wiki$"] = {
				--- github.com/<user>/<repo>/wiki

				icon = " ",
				hl = "MarkviewPalette0Fg"
			},

			---_
			---+${lua, Commonly used sites by programmers}

			["developer%.mozilla%.org"] = {
				priority = 9999,

				icon = "󰖟 ",
				hl = "MarkviewPalette5Fg"
			},

			["w3schools%.com"] = {
				priority = 9999,

				icon = " ",
				hl = "MarkviewPalette4Fg"
			},

			["stackoverflow%.com"] = {
				priority = 9999,

				icon = "󰓌 ",
				hl = "MarkviewPalette2Fg"
			},

			["reddit%.com"] = {
				priority = 9999,

				icon = " ",
				hl = "MarkviewPalette2Fg"
			},

			["github%.com"] = {
				priority = 9999,

				icon = " ",
				hl = "MarkviewPalette6Fg"
			},

			["gitlab%.com"] = {
				priority = 9999,

				icon = " ",
				hl = "MarkviewPalette2Fg"
			},

			["dev%.to"] = {
				priority = 9999,

				icon = "󱁴 ",
				hl = "MarkviewPalette0Fg"
			},

			["codepen%.io"] = {
				priority = 9999,

				icon = " ",
				hl = "MarkviewPalette6Fg"
			},

			["replit%.com"] = {
				priority = 9999,

				icon = " ",
				hl = "MarkviewPalette2Fg"
			},

			["jsfiddle%.net"] = {
				priority = 9999,

				icon = " ",
				hl = "MarkviewPalette5Fg"
			},

			["npmjs%.com"] = {
				priority = 9999,

				icon = " ",
				hl = "MarkviewPalette0Fg"
			},

			["pypi%.org"] = {
				priority = 9999,

				icon = "󰆦 ",
				hl = "MarkviewPalette0Fg"
			},

			["mvnrepository%.com"] = {
				priority = 9999,

				icon = " ",
				hl = "MarkviewPalette1Fg"
			},

			["medium%.com"] = {
				priority = 9999,

				icon = " ",
				hl = "MarkviewPalette6Fg"
			},

			["linkedin%.com"] = {
				priority = 9999,

				icon = "󰌻 ",
				hl = "MarkviewPalette5Fg"
			},

			["news%.ycombinator%.com"] = {
				priority = 9999,

				icon = " ",
				hl = "MarkviewPalette2Fg"
			},

			---_

			---_
		},

		---_
	},
	html = {
		---+${lua}

		container_elements = {
			---+${lua}

			enable = true,

			---+${lua, Various inline elements used in markdown}

			["^b$"] = {
				on_opening_tag = { conceal = "" },
				on_node = { hl_group = "Bold" },
				on_closing_tag = { conceal = "" },
			},
			["^code$"] = {
				on_opening_tag = { conceal = "", hl_mode = "combine", virt_text_pos = "inline", virt_text = { { " ", "MarkviewInlineCode" } } },
				on_node = { hl_group = "MarkviewInlineCode" },
				on_closing_tag = { conceal = "", hl_mode = "combine", virt_text_pos = "inline", virt_text = { { " ", "MarkviewInlineCode" } } },
			},
			["^em$"] = {
				on_opening_tag = { conceal = "" },
				on_node = { hl_group = "@text.emphasis" },
				on_closing_tag = { conceal = "" },
			},
			["^i$"] = {
				on_opening_tag = { conceal = "" },
				on_node = { hl_group = "Italic" },
				on_closing_tag = { conceal = "" },
			},
			["^mark$"] = {
				on_opening_tag = { conceal = "" },
				on_node = { hl_group = "MarkviewPalette1" },
				on_closing_tag = { conceal = "" },
			},
			["^strong$"] = {
				on_opening_tag = { conceal = "" },
				on_node = { hl_group = "@text.strong" },
				on_closing_tag = { conceal = "" },
			},
			["^sub$"] = {
				on_opening_tag = { conceal = "", hl_mode = "combine", virt_text_pos = "inline", virt_text = { { "↓[", "MarkviewSubscript" } } },
				on_node = { hl_group = "MarkviewSubscript" },
				on_closing_tag = { conceal = "", hl_mode = "combine", virt_text_pos = "inline", virt_text = { { "]", "MarkviewSubscript" } } },
			},
			["^sup$"] = {
				on_opening_tag = { conceal = "", hl_mode = "combine", virt_text_pos = "inline", virt_text = { { "↑[", "MarkviewSuperscript" } } },
				on_node = { hl_group = "MarkviewSuperscript" },
				on_closing_tag = { conceal = "", hl_mode = "combine", virt_text_pos = "inline", virt_text = { { "]", "MarkviewSuperscript" } } },
			},
			["^u$"] = {
				on_opening_tag = { conceal = "" },
				on_node = { hl_group = "Underlined" },
				on_closing_tag = { conceal = "" },
			},

			---_
			---_
		},

		headings = {
			---+${lua}

			enable = true,

			heading_1 = {
				hl_group = "MarkviewPalette1Bg"
			},
			heading_2 = {
				hl_group = "MarkviewPalette2Bg"
			},
			heading_3 = {
				hl_group = "MarkviewPalette3Bg"
			},
			heading_4 = {
				hl_group = "MarkviewPalette4Bg"
			},
			heading_5 = {
				hl_group = "MarkviewPalette5Bg"
			},
			heading_6 = {
				hl_group = "MarkviewPalette6Bg"
			},

			---_
		},

		void_elements = {
			---+${lua}

			enable = true,

			---+${lua, Various void elements used in markdown}

			["^hr$"] = {
				on_node = {
					conceal = "",

					virt_text_pos = "inline",
					virt_text = {
						{ "─", "MarkviewGradient2" },
						{ "─", "MarkviewGradient3" },
						{ "─", "MarkviewGradient4" },
						{ "─", "MarkviewGradient5" },
						{ " ◉ ", "MarkviewGradient9" },
						{ "─", "MarkviewGradient5" },
						{ "─", "MarkviewGradient4" },
						{ "─", "MarkviewGradient3" },
						{ "─", "MarkviewGradient2" },
					}
				}
			},
			["^br$"] = {
				on_node = {
					conceal = "",

					virt_text_pos = "inline",
					virt_text = {
						{ "󱞦", "Comment" },
					}
				}
			},

			---_

			---_
		}

		---_
	},
	latex = {
		---+${lua}

		enable = true,

		blocks = {
			---+${lua}

			enable = true,

			hl = "MarkviewCode",
			pad_char = " ",
			pad_amount = 3,

			text = "  LaTeX ",
			text_hl = "MarkviewCodeInfo"

			---_
		},

		commands = {
			---+${lua}

			enable = true,

			---+${lua, Various commonly used LaTeX math commands}

			["frac"] = {
				condition = function (item)
					return #item.args == 2;
				end,
				on_command = {
					conceal = ""
				},

				on_args = {
					{
						on_before = function (item)
							return {
								end_col = item.range[2] + 1,
								conceal = "",

								virt_text_pos = "inline",
								virt_text = {
									{ "(", "@punctuation.bracket" }
								},

								hl_mode = "combine"
							}
						end,

						after_offset = function (range)
							return { range[1], range[2], range[3], range[4] - 1 };
						end,
						on_after = function (item)
							return {
								end_col = item.range[4],
								conceal = "",

								virt_text_pos = "inline",
								virt_text = {
									{ ")", "@punctuation.bracket" },
									{ " ÷ ", "@keyword.function" }
								},

								hl_mode = "combine"
							}
						end
					},
					{
						on_before = function (item)
							return {
								end_col = item.range[2] + 1,
								conceal = "",

								virt_text_pos = "inline",
								virt_text = {
									{ "(", "@punctuation.bracket" }
								},

								hl_mode = "combine"
							}
						end,

						after_offset = function (range)
							return { range[1], range[2], range[3], range[4] - 1 };
						end,
						on_after = function (item)
							return {
								end_col = item.range[4],
								conceal = "",

								virt_text_pos = "inline",
								virt_text = {
									{ ")", "@punctuation.bracket" },
								},

								hl_mode = "combine"
							}
						end
					},
				}
			},

			["sin"] = operator("sin"),
			["cos"] = operator("cos"),
			["tan"] = operator("tan"),

			["sinh"] = operator("sinh"),
			["cosh"] = operator("cosh"),
			["tanh"] = operator("tanh"),

			["csc"] = operator("csc"),
			["sec"] = operator("sec"),
			["cot"] = operator("cot"),

			["csch"] = operator("csch"),
			["sech"] = operator("sech"),
			["coth"] = operator("coth"),

			["arcsin"] = operator("arcsin"),
			["arccos"] = operator("arccos"),
			["arctan"] = operator("arctan"),

			["arg"] = operator("arg"),
			["deg"] = operator("deg"),
			["det"] = operator("det"),
			["dim"] = operator("dim"),
			["exp"] = operator("exp"),
			["gcd"] = operator("gcd"),
			["hom"] = operator("hom"),
			["inf"] = operator("inf"),
			["ker"] = operator("ker"),
			["lg"] = operator("lg"),

			["lim"] = operator("lim"),
			["liminf"] = operator("lim inf", "inline", 7),
			["limsup"] = operator("lim sup", "inline", 7),

			["ln"] = operator("ln"),
			["log"] = operator("log"),
			["min"] = operator("min"),
			["max"] = operator("max"),
			["Pr"] = operator("Pr"),
			["sup"] = operator("sup"),
			["sqrt"] = operator(symbols.entries.sqrt, "inline", 5),
			["lvert"] = operator(symbols.entries.vert, "inline", 6),
			["lVert"] = operator(symbols.entries.Vert, "inline", 6),

			---_

			---_
		},

		escapes = {
			enable = true
		},

		fonts = {
			---+${lua}

			enable = true,

			default = {
				hl = "MarkviewSpecial", enable = true
			},
			-- ["^mathtt$"] = { hl = "MarkviewPalette1" }
			---_
		},

		inlines = {
			---+${lua}

			enable = true,

			padding_left = " ",
			padding_right = " ",

			hl = "MarkviewInlineCode"

			---_
		},

		parenthesis = {
			---+${lua}

			enable = true,

			left = "(",
			right = "(",
			hl = "@punctuation.bracket"

			---_
		},

		subscripts = {
			enable = true,

			hl = "MarkviewSubscript"
		},

		superscripts = {
			enable = true,

			hl = "MarkviewSuperscript"
		},

		symbols = {
			enable = true,

			hl = "MarkviewComment"
		},

		texts = {
			enable = true
		},

		---_
	},
	typst = {
		---+${lua}

		enable = true,

		code_blocks = {
			---+${lua}

			enable = true,

			style = "block",
			text_direction = "right",

			min_width = 60,
			pad_amount = 3,
			pad_char = " ",

			text = "󰣖 Code",

			hl = "MarkviewCode",
			text_hl = "MarkviewIcon5"

			---_
		},

		code_spans = {
			---+${lua}

			enable = true,

			padding_left = " ",
			padding_right = " ",

			hl = "MarkviewCode"

			---_
		},

		escapes = {
			enable = true
		},

		headings = {
			---+ ${class, Headings}
			enable = true,
			shift_width = 1,

			heading_1 = {
				---+ ${conf, Heading 1}
				style = "icon",
				sign = "󰌕 ", sign_hl = "MarkviewHeading1Sign",

				icon = "󰼏  ", hl = "MarkviewHeading1",
				---_
			},
			heading_2 = {
				---+ ${conf, Heading 2}
				style = "icon",
				sign = "󰌖 ", sign_hl = "MarkviewHeading2Sign",

				icon = "󰎨  ", hl = "MarkviewHeading2",
				---_
			},
			heading_3 = {
				---+ ${conf, Heading 3}
				style = "icon",

				icon = "󰼑  ", hl = "MarkviewHeading3",
				---_
			},
			heading_4 = {
				---+ ${conf, Heading 4}
				style = "icon",

				icon = "󰎲  ", hl = "MarkviewHeading4",
				---_
			},
			heading_5 = {
				---+ ${conf, Heading 5}
				style = "icon",

				icon = "󰼓  ", hl = "MarkviewHeading5",
				---_
			},
			heading_6 = {
				---+ ${conf, Heading 6}
				style = "icon",

				icon = "󰎴  ", hl = "MarkviewHeading6",
				---_
			}
			---_
		},

		labels = {
			---+${lua}

			enable = true,

			default = {
				hl = "MarkviewInlineCode",
				padding_left = " ",
				icon = " ",
				padding_right = " "
			}

			---_
		},

		list_items = {
			---+${conf, List items}

			enable = true,

			indent_size = 2,
			shift_width = 4,

			marker_minus = {
				add_padding = true,

				text = "",
				hl = "MarkviewListItemMinus"
			},

			marker_plus = {
				add_padding = true,

				text = "%d)",
				hl = "MarkviewListItemPlus"
			},

			marker_dot = {
				add_padding = true,
			}

			---_
		},

		math_blocks = {
			---+${lua}

			enable = true,

			text = " 󰪚 Math ",
			pad_amount = 3,
			pad_char = " ",

			hl = "MarkviewCode",
			text_hl = "MarkviewCodeInfo"

			---_
		},
		math_spans = {
			---+${lua}

			enable = true,

			padding_left = " ",
			padding_right = " ",

			hl = "MarkviewInlineCode"

			---_
		},

		raw_blocks = {
			---+${lua}

			enable = true,

			style = "block",
			icons = "internal",
			label_direction = "right",

			sign = true,

			min_width = 60,
			pad_amount = 3,
			pad_char = " ",

			hl = "MarkviewCode"

			---_
		},

		raw_spans = {
			---+${lua}

			enable = true,

			padding_left = " ",
			padding_right = " ",

			hl = "MarkviewInlineCode"

			---_
		},

		reference_links = {
			---+${lua}

			enable = true,

			default = {
				icon = " ",
				hl = "MarkviewHyperlink"
			},

			---_
		},

		subscripts = {
			enable = true,

			hl = "MarkviewSubscript"
		},

		superscripts = {
			enable = true,

			hl = "MarkviewSuperscript"
		},

		symbols = {
			enable = true,

			hl = "Special"
		},

		terms = {
			---+${lua}

			enable = true,

			default = {
				text = " ",
				hl = "MarkviewPalette6Fg"
			},

			---_
		},

		url_links = {
			---+${lua}

			enable = true,

			default = {
				icon = " ",
				hl = "MarkviewEmail"
			},

			---+${lua, Github sites}

			["github%.com/[%a%d%-%_%.]+%/?$"] = {
				--- github.com/<user>

				icon = " ",
				hl = "MarkviewPalette0Fg"
			},
			["github%.com/[%a%d%-%_%.]+/[%a%d%-%_%.]+%/?$"] = {
				--- github.com/<user>/<repo>

				icon = "󰳐 ",
				hl = "MarkviewPalette0Fg"
			},
			["github%.com/[%a%d%-%_%.]+/[%a%d%-%_%.]+/tree/[%a%d%-%_%.]+%/?$"] = {
				--- github.com/<user>/<repo>/tree/<branch>

				icon = " ",
				hl = "MarkviewPalette0Fg"
			},
			["github%.com/[%a%d%-%_%.]+/[%a%d%-%_%.]+/commits/[%a%d%-%_%.]+%/?$"] = {
				--- github.com/<user>/<repo>/commits/<branch>

				icon = " ",
				hl = "MarkviewPalette0Fg"
			},

			["github%.com/[%a%d%-%_%.]+/[%a%d%-%_%.]+%/releases$"] = {
				--- github.com/<user>/<repo>/releases

				icon = " ",
				hl = "MarkviewPalette0Fg"
			},
			["github%.com/[%a%d%-%_%.]+/[%a%d%-%_%.]+%/tags$"] = {
				--- github.com/<user>/<repo>/tags

				icon = " ",
				hl = "MarkviewPalette0Fg"
			},
			["github%.com/[%a%d%-%_%.]+/[%a%d%-%_%.]+%/issues$"] = {
				--- github.com/<user>/<repo>/issues

				icon = " ",
				hl = "MarkviewPalette0Fg"
			},
			["github%.com/[%a%d%-%_%.]+/[%a%d%-%_%.]+%/pulls$"] = {
				--- github.com/<user>/<repo>/pulls

				icon = " ",
				hl = "MarkviewPalette0Fg"
			},

			["github%.com/[%a%d%-%_%.]+/[%a%d%-%_%.]+%/wiki$"] = {
				--- github.com/<user>/<repo>/wiki

				icon = " ",
				hl = "MarkviewPalette0Fg"
			},

			---_
			---+${lua, Commonly used sites by programmers}

			["developer%.mozilla%.org"] = {
				priority = 9999,

				icon = "󰖟 ",
				hl = "MarkviewPalette5Fg"
			},

			["w3schools%.com"] = {
				priority = 9999,

				icon = " ",
				hl = "MarkviewPalette4Fg"
			},

			["stackoverflow%.com"] = {
				priority = 9999,

				icon = "󰓌 ",
				hl = "MarkviewPalette2Fg"
			},

			["reddit%.com"] = {
				priority = 9999,

				icon = " ",
				hl = "MarkviewPalette2Fg"
			},

			["github%.com"] = {
				priority = 9999,

				icon = " ",
				hl = "MarkviewPalette6Fg"
			},

			["gitlab%.com"] = {
				priority = 9999,

				icon = " ",
				hl = "MarkviewPalette2Fg"
			},

			["dev%.to"] = {
				priority = 9999,

				icon = "󱁴 ",
				hl = "MarkviewPalette0Fg"
			},

			["codepen%.io"] = {
				priority = 9999,

				icon = " ",
				hl = "MarkviewPalette6Fg"
			},

			["replit%.com"] = {
				priority = 9999,

				icon = " ",
				hl = "MarkviewPalette2Fg"
			},

			["jsfiddle%.net"] = {
				priority = 9999,

				icon = " ",
				hl = "MarkviewPalette5Fg"
			},

			["npmjs%.com"] = {
				priority = 9999,

				icon = " ",
				hl = "MarkviewPalette0Fg"
			},

			["pypi%.org"] = {
				priority = 9999,

				icon = "󰆦 ",
				hl = "MarkviewPalette0Fg"
			},

			["mvnrepository%.com"] = {
				priority = 9999,

				icon = " ",
				hl = "MarkviewPalette1Fg"
			},

			["medium%.com"] = {
				priority = 9999,

				icon = " ",
				hl = "MarkviewPalette6Fg"
			},

			["linkedin%.com"] = {
				priority = 9999,

				icon = "󰌻 ",
				hl = "MarkviewPalette5Fg"
			},

			["news%.ycombinator%.com"] = {
				priority = 9999,

				icon = " ",
				hl = "MarkviewPalette2Fg"
			},

			---_

			---_
		}

		---_
	},
	yaml = {
		---+${lua}

		enable = true,

		properties = {
			---+${lua}

			enable = true,

			data_types = {
				["text"] = {
					text = " 󰗊 ", hl = "MarkviewIcon4"
				},
				["list"] = {
					text = " 󰝖 ", hl = "MarkviewIcon5"
				},
				["number"] = {
					text = "  ", hl = "MarkviewIcon6"
				},
				["checkbox"] = {
					---@diagnostic disable
					text = function (_, item)
						return item.value == "true" and " 󰄲 " or " 󰄱 "
					end,
					---@diagnostic enable
					hl = "MarkviewIcon6"
				},
				["date"] = {
					text = " 󰃭 ", hl = "MarkviewIcon2"
				},
				["date_&_time"] = {
					text = " 󰥔 ", hl = "MarkviewIcon3"
				}
			},

			default = {
				use_types = true,

				border_top = " │ ",
				border_middle = " │ ",
				border_bottom = " ╰╸",

				border_hl = "MarkviewComment"
			},

			["^tags$"] = {
				match_string = "^tags$",
				use_types = false,

				text = " 󰓹 ",
				hl = nil
			},
			["^aliases$"] = {
				match_string = "^aliases$",
				use_types = false,

				text = " 󱞫 ",
				hl = nil
			},
			["^cssclasses$"] = {
				match_string = "^cssclasses$",
				use_types = false,

				text = "  ",
				hl = nil
			},


			["^publish$"] = {
				match_string = "^publish$",
				use_types = false,

				text = "  ",
				hl = nil
			},
			["^permalink$"] = {
				match_string = "^permalink$",
				use_types = false,

				text = "  ",
				hl = nil
			},
			["^description$"] = {
				match_string = "^description$",
				use_types = false,

				text = " 󰋼 ",
				hl = nil
			},
			["^image$"] = {
				match_string = "^image$",
				use_types = false,

				text = " 󰋫 ",
				hl = nil
			},
			["^cover$"] = {
				match_string = "^cover$",
				use_types = false,

				text = " 󰹉 ",
				hl = nil
			}

			---_
		}

		---_
	}
	---_
};

spec.config = spec.default;

---+${custom, Option maps}
spec.preview = {
	"modes", "hybrid_modes",
	"filetypes", "buf_ignore",
	"callbacks",
	"debounce",
	"ignore_nodes",
	"max_file_length", "render_distance",
	"split_conf"
};
spec.experimental = {};

spec.markdown = {
	"block_quotes",
	"code_blocks",
	"footnotes",
	"headings",
	"horizontal_rules",
	"list_items",
	"tables"
};
spec.markdown_inline = {
	"checkboxes",
	"inline_codes",
	"links"
};
spec.html = {};
spec.latex = {};
spec.typst = {};
---_


spec.__preview = function (config)
	---+${func}
	for opt, val in pairs(config) do
		if opt == "buf_ignore" then
			spec.notify({
				{ " buf_ignore ", "DiagnosticVirtualTextInfo" },
				{ " is deprecated! Use " },
				{ " preview.ignore_buftypes ", "DiagnosticVirtualTextHint" },
				{ " instead."},
			}, {
				class = "markview_opt_name_change",

				old = "preview.buf_ignore",
				new = "preview.ignore_buftypes"
			});

			config["ignore_buftypes"] = val;
			config["buf_ignore"] = nil;
		elseif opt == "debounce" then
			spec.notify({
				{ " debounce ", "DiagnosticVirtualTextInfo" },
				{ " is deprecated! Use " },
				{ " preview.debounce_delay ", "DiagnosticVirtualTextHint" },
				{ " instead."},
			}, {
				class = "markview_opt_name_change",

				old = "preview.debounce",
				new = "preview.debounce_delay"
			});

			config["debounce_delay"] = val;
			config["debounce"] = nil;
		elseif opt == "ignore_nodes" then
			spec.notify({
				{ " ignore_nodes ", "DiagnosticVirtualTextError" },
				{ " is deprecated! Use " },
				{ " preview.ignore_node_classes ", "DiagnosticVirtualTextHint" },
				{ " instead."},
			}, {
				class = "markview_opt_name_change",

				old = "preview.ignore_nodes",
				new = "preview.ignore_node_classes",

				level = vim.log.levels.ERROR,
			});

			config["ignore_nodes"] = nil;
		elseif opt == "initial_state" then
			spec.notify({
				{ " initial_state ", "DiagnosticVirtualTextInfo" },
				{ " is deprecated! Use " },
				{ " preview.enable ", "DiagnosticVirtualTextHint" },
				{ " instead."},
			}, {
				class = "markview_opt_name_change",

				old = "preview.initial_state",
				new = "preview.enable",

				level = vim.log.levels.ERROR,
			});

			config["enable"] = val;
			config["initial_state"] = nil;
		elseif opt == "split_conf" then
			spec.notify({
				{ " split_conf ", "DiagnosticVirtualTextInfo" },
				{ " is deprecated! Use " },
				{ " preview.splitview_winopts ", "DiagnosticVirtualTextHint" },
				{ " instead."},
			}, {
				class = "markview_opt_name_change",

				old = "preview.split_conf",
				new = "preview.splitview_winopts"
			});

			config["splitview_winopts"] = val;
			config["split_conf"] = nil;
		elseif opt == "max_file_length" then
			spec.notify({
				{ " max_file_length ", "DiagnosticVirtualTextInfo" },
				{ " is deprecated! Use " },
				{ " preview.max_buf_lines ", "DiagnosticVirtualTextHint" },
				{ " instead."},
			}, {
				class = "markview_opt_name_change",

				old = "max_file_length",
				new = "preview.max_buf_lines"
			});

			config["max_buf_lines"] = val;
			config["max_file_length"] = nil;
		elseif opt == "render_distance" then
			spec.notify({
				{ " render_distance ", "DiagnosticVirtualTextInfo" },
				{ " is deprecated! Use " },
				{ " preview.draw_range ", "DiagnosticVirtualTextHint" },
				{ " instead."},
			}, {
				class = "markview_opt_name_change",

				old = "render_distance",
				new = "preview.draw_range"
			});

			if type(val) == "number" then
				spec.notify({
					{ " preview.draw_range ", "DiagnosticVirtualTextInfo" },
					{ " should be a " },
					{ "[ integer, integer ]", "DiagnosticOk" },
					{ "! Got "},
					{ "number", "DiagnosticWarn" },
					{ ". "},
				}, {
					class = "markview_opt_invalid_type",
					name = "preview.draw_range",

					should_be = "table",
					is = "number"
				});

				config["draw_range"] = { val, val };
			else
				config["draw_range"] = val;
			end

			config["render_distance"] = nil;
		end
	end

	return config;
	---_
end

spec.__markdown = function (config)
	---+${func}
	for opt, val in pairs(config) do
		if opt == "block_quotes" and vim.islist(val.callouts) then
			spec.notify({
				{ " block_quotes.callouts ", "DiagnosticVirtualTextError" },
				{ " is deprecated!" },
			}, {
				class = "markview_opt_deprecated",
				level = vim.log.levels.ERROR,

				name = "block_quotes.callouts"
			});

			local _n = {};

			for _, item in ipairs(val.callouts) do
				_n[string.lower(item.match_string)] = {
					hl = item.hl,
					preview = item.preview,
					preview_hl = item.preview_hl,

					title = item.title,
					icon = item.icon,

					border = item.border,
					border_hl = item.border_hl
				}
			end

			config["block_quotes"] = vim.tbl_extend("keep", {
				enable = val.enable,
				default = val.default or {}
			}, _n);
		elseif opt == "code_blocks" and val.icon_provider then
			spec.notify({
				{ " code_blocks.icon_provider ", "DiagnosticVirtualTextError" },
				{ " is deprecated!" },
			}, {
				class = "markview_opt_deprecated",
				level = vim.log.levels.ERROR,

				name = "code_blocks.icon_provider"
			});

			val.icon_provider = nil;
			config["code_blocks"] = val;
		elseif opt == "tables" and ( vim.islist(val.text) or vim.islist(val.hl) ) then
			local _p, _h = val.text, val.hl;
			local np, nh = {
				top = {},
				header = {},
				separator = {},
				row = {},
				bottom = {},

				align_left = nil,
				align_right = nil,
				align_center = {}
			}, vim.islist(val.hl) == false and val.hl or {
				top = {},
				header = {},
				separator = {},
				row = {},
				bottom = {},

				align_left = nil,
				align_right = nil,
				align_center = {}
			};

			if vim.islist(_p) then
				spec.notify({
					{ " markdown.tables.parts ", "DiagnosticVirtualTextInfo" },
					{ " should be a " },
					{ "table", "DiagnosticOk" },
					{ "! Got "},
					{ "list", "DiagnosticWarn" },
					{ ". "},
				}, {
					class = "markview_opt_invalid_type",
					name = "markdown.tables.parts",

					should_be = "table",
					is = "list"
				});

				for p, part in ipairs(_p) do
					if vim.list_contains({ 1, 2, 3, 4 }, p) then
						np.top[p] = part;

						if p == 2 then
							np.separator[2] = part;
						end
					elseif p == 5 then
						np.separator[1] = part;
					elseif p == 6 then
						np.header[1] = part;
						np.header[2] = part;
						np.header[3] = part;

						np.row[1] = part;
						np.row[2] = part;
						np.row[3] = part;
					elseif p == 7 then
						np.separator[3] = part;
					elseif p == 8 then
						np.separator[4] = part;
					elseif vim.list_contains({ 9, 10, 11, 12 }, p) then
						np.bottom[p - 8] = part;
					elseif vim.list_contains({ 13, 14 }, p) then
						np.align_center[p - 12] = part;
					elseif p == 15 then
						np.align_left = part;
					else
						np.align_right = part;
					end
				end
			end

			if vim.islist(_h) then
				spec.notify({
					{ " markdown.tables.hls ", "DiagnosticVirtualTextInfo" },
					{ " is deprecated! Use " },
					{ " markdown.tables.hl ", "DiagnosticVirtualTextHint" },
					{ " instead."},
				}, {
					class = "markview_opt_name_change",
					level = vim.log.levels.ERROR,

					old = "markdown.tables.hls",
					new = "markdown.tables.hl"
				});

				spec.notify({
					{ " markdown.tables.hl ", "DiagnosticVirtualTextInfo" },
					{ " should be a " },
					{ "table", "DiagnosticOk" },
					{ "! Got "},
					{ "list", "DiagnosticWarn" },
					{ ". "},
				}, {
					class = "markview_opt_invalid_type",
					name = "markdown.tables.hl",

					should_be = "table",
					is = "list"
				});

				for p, part in ipairs(_h) do
					if vim.list_contains({ 1, 2, 3, 4 }, p) then
						nh.top[p] = part;

						if p == 2 then
							nh.separator[2] = part;
						end
					elseif p == 5 then
						nh.separator[1] = part;
					elseif p == 6 then
						nh.header[1] = part;
						nh.header[2] = part;
						nh.header[3] = part;

						nh.row[1] = part;
						nh.row[2] = part;
						nh.row[3] = part;
					elseif p == 7 then
						nh.separator[3] = part;
					elseif p == 8 then
						nh.separator[4] = part;
					elseif vim.list_contains({ 9, 10, 11, 12 }, p) then
						nh.bottom[p - 8] = part;
					elseif vim.list_contains({ 13, 14 }, p) then
						nh.align_center[p - 12] = part;
					elseif p == 15 then
						nh.align_left = part;
					else
						nh.align_right = part;
					end
				end
			end

			---@type markdown.tables
			config["tables"] = {
				enable = val.enable,
				hl = nh,
				parts = np,
				use_virt_lines = val.use_virt_lines,
				block_decorator = val.block_decorator
			};
		end
	end

	return config;
	---_
end

spec.__markdown_inline = function (config)
	---+${func}
	for opt, val in pairs(config) do
		if
			opt == "checkboxes" and
			vim.islist(val.custom)
		then
			spec.notify({
				{ " checkboxes.custom ", "DiagnosticVirtualTextError" },
				{ " is deprecated!" },
			}, {
				class = "markview_opt_deprecated",
				level = vim.log.levels.ERROR,

				name = "checkboxes.custom"
			});

			local _n = {};

			for _, item in ipairs(val.custom) do
				_n[string.lower(item.match_string)] = {
					hl = item.hl,
					scope_hl = item.scope_hl,
					text = item.text,
				}
			end

			config["checkboxes"] = vim.tbl_extend("keep", {
				enable = val.enable,
				checked = val.checked,
				unchecked = val.unchecked,
			}, _n);
		elseif opt == "links" then
			for k, v in pairs(val) do
				if vim.list_contains({ "emails", "hyperlinks", "images", "internal_links" }, k) == false then
					goto continue;
				end

				spec.notify({
					{ " links." .. k .. " ", "DiagnosticVirtualTextError" },
					{ " is deprecated! Use" },
					{ " markdown_inline." .. opt .. "." .. k .. " ", "DiagnosticVirtualTextHint" },
					{ "instead." },
				}, {
					class = "markview_opt_deprecated",
					name = "links." .. k,
					level = vim.log.levels.ERROR
				});

				config[k] = v;
				::continue::
			end

			config[opt] = nil;
			config = spec.__markdown_inline(config);
		elseif vim.list_contains({ "footnotes", "emails", "uri_autolinks", "images", "embed_files", "internal_links", "hyperlinks" }, opt) then
			if not val.default then val.default = {}; end

			for k, v in pairs(val) do
				if
					vim.list_contains({
						"corner_left", "corner_right",
						"padding_left", "padding_right",
						"icon", "icon_hl",
						"padding_left_hl", "padding_right_hl",
						"corner_left_hl", "corner_right_hl",
					}, k)
				then
					spec.notify({
						{ string.format(" markdown_inline.%s.%s ", opt, k), "DiagnosticVirtualTextError" },
						{ " is deprecated! Use" },
						{ string.format(" markdown_inline.%s.default.%s ", opt, k), "DiagnosticVirtualTextHint" },
						{ "instead." },
					}, {
						class = "markview_opt_deprecated",
						name = string.format("markdown_inline.%s.%s", opt, k),
						level = vim.log.levels.ERROR
					});

					val.default[k] = v;
				end
			end

			if val.custom then
				spec.notify({
					{ " markdown_inline." .. opt .. ".custom ", "DiagnosticVirtualTextError" },
					{ " is deprecated! Use" },
					{ " markdown_inline." .. opt .. ".[string] ", "DiagnosticVirtualTextHint" },
					{ "instead." },
				}, {
					class = "markview_opt_name_change",

					old = "markdown_inline." .. opt .. ".custom",
					new = "markdown_inline." .. opt .. ".[string]",
				});
			end

			config[opt] = {
				enable = val.enable,
				default = val.default or { text = val.text, hl = val.hl },
			};

			for _, item in ipairs(val.patterns or val.custom or {}) do
				if type(item.match_string) == "string" then
					config[item.match_string] = item;
				end
			end
		end
	end

	return config;
	---_
end

spec.fix_config = function (config)
	if type(config) ~= "table" then
		return {};
	end

	local _o = {
		renderers = config.renderers or {},
		highlight_groups = config.highlight_groups or {},

		splitview = config.splitview or {},
		preview = config.preview or {},
		experimental = config.experimental or {};

		markdown = config.markdown or {},
		markdown_inline = config.markdown_inline or {},
		html = config.html or {},
		latex = config.latex or {},
		typst = config.typst or {}
	};

	for key, value in pairs(config) do
		if vim.list_contains(spec.preview, key) then
			_o.preview[key] = value;
		elseif vim.list_contains(spec.experimental, key) then
			_o.experimental[key] = value;
		elseif vim.list_contains(spec.markdown, key) then
			_o.markdown[key] = value;
		elseif vim.list_contains(spec.markdown_inline, key) then
			_o.markdown_inline[key] = value;
		elseif vim.list_contains(spec.html, key) then
			_o.html[key] = value;
		elseif vim.list_contains(spec.latex, key) then
			_o.latex[key] = value
		elseif vim.list_contains(spec.typst, key) then
			_o.typst[key] = value;
		end
	end

	for k, v in pairs(_o) do
		if spec["__" .. k] then
			_o[k] = spec["__" .. k](v);
		end
	end

	return _o;
end

spec.setup = function (config)
	config = spec.fix_config(config);
	spec.config = vim.tbl_deep_extend("force", spec.default, config);
end

---@param keys ( string | integer )[]
---@param opts { fallback: any, eval_ignore: string[]?, ignore_enable: boolean?, source: table?, eval_args: any[]?, args: any[] | { __is_arg_list: boolean, [integer]: any } }
---@return any
spec.get = function (keys, opts)
	--- In case the values are correctly provided..
	keys = keys or {};
	opts = opts or {};

	--- Turns a dynamic value into
	--- a static value.
	---@param val any | fun(...): any
	---@param args any[]?
	---@return any
	local function to_static(val, args)
		---+${lua}

		args = args or {};

		---@diagnostic disable
		if pcall(val, unpack(args)) then
			return val(unpack(args));
		end
		---@diagnostic enable

		return val;
		---_
	end

	---@param index integer | string
	---@return any
	local function get_arg(index)
		---+${lua}
		if type(opts.args) ~= "table" then
			return {};
		elseif opts.args.__is_arg_list == true then
			return opts.args[index];
		else
			return opts.args;
		end
		---_
	end

	--- Temporarily store the value.
	---
	--- Use `deepcopy()` as we may need to
	--- modify this value.
	---@type any
	local val;

	if type(opts.source) == "table" or type(opts.source) == "function" then
		val = opts.source;
	elseif spec.config then
		val = spec.config;
	else
		val = {};
	end

	--- Turn the main value into a static value.
	--- [ In case a function was provided as the source. ]
	val = to_static(val, get_arg("init"));

	if type(val) ~= "table" then
		--- The source isn't a table.
		return opts.fallback;
	end

	for k, key in ipairs(keys) do
		val = to_static(val[key], val.args);

		if k ~= #keys then
			if type(val) ~= "table" then
				return opts.fallback;
			elseif opts.ignore_enable ~= true and val.enable == false then
				return opts.fallback;
			end
		end
	end

	if vim.islist(opts.eval_args) == true and type(val) == "table" then
		local _e = {};
		local ignore = opts.eval_ignore or {};

		for k, v in pairs(val) do
			if vim.list_contains(ignore, k) == false then
				_e[k] = to_static(v, opts.eval_args);
			else
				_e[k] = v;
			end
		end

		val = _e;
	elseif vim.islist(opts.eval_args) == true and type(val) == "function" then
		val = to_static(val, opts.eval_args);
	end

	if val == nil and opts.fallback then
		return opts.fallback;
	elseif type(val) == "table" and ( opts.ignore_enable ~= true and val.enable == false ) then
		return opts.fallback;
	else
		return val;
	end
end

return spec;
