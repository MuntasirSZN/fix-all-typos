--- Definition files for `markview.nvim`
---
--- **Author**  : MD. Mouinul Hossain Shawon (OXY2DEV)
---
---@meta
local M = {};

--- Table containing various plugin states.
---@class mkv.state
---
---@field enable boolean Is the plugin enabled?
---@field hybrid_mode boolean Is hybrid mode enabled?
---@field attached_buffers integer[] List of attached buffers.
---
---@field buffer_states { [integer]: { enable: boolean, hybrid_mode: boolean?, events: boolean } } Buffer local states.
---
---@field splitview_source? integer Source buffer for hybrid mode.
---@field splitview_buffer? integer Preview buffer for hybrid mode.
---@field splitview_window? integer Preview window for hybrid mode.
---@field splitview_cstate? { enable: boolean, hybrid_mode: boolean?, events: boolean } Cached state for the source buffer.
M.states = {
	enable = true,
	hybrid_mode = true,
	buffer_states = {
		[10] = {
			events = false,
			enable = true,
			hybrid_mode = true
		}
	},
	attached_buffers = { 10 },

	splitview_buffer = 50,
	splitview_source = nil,
	splitview_cstate = { enable = true },
	splitview_window = nil
};

 ------------------------------------------------------------------------------------------

--- Table containing completion candidates for `:Markview`.
---@class mkv.cmd_completion
---
---@field default fun(str: string): string[] | nil Default completion.
---@field [string] fun(args: any[], cmd: string): string[] | nil Completion for the {string} sub-command.
M.cmd_completion = {
	default = function (str)
		vim.print(str);
		return { "enable", "disable" };
	end,

	enable = function (args, cmd)
		vim.print(cmd);
		return #args >= 2 and { "1", "2" } or nil;
	end
};

 ------------------------------------------------------------------------------------------

--- Configuration table for `markview.nvim`.
--- >[!NOTE]
--- > All options should be **dynamic**.
---@class mkv.config
---
---@field experimental config.experimental | fun(): config.experimental
---@field highlight_groups { [string]: config.hl } | fun(): { [string]: config.hl }
---@field html config.html | fun(): config.html
---@field latex config.latex | fun(): config.latex
---@field markdown config.markdown | fun(): config.markdown
---@field markdown_inline config.markdown_inline | fun(): config.markdown_inline
---@field preview config.preview | fun(): config.preview
---@field renderers config.renderer[] | fun(): config.renderer[]
---@field typst config.typst | fun(): config.typst
---@field yaml config.yaml | fun(): config.yaml
M.config = {
	typst = {},
	renderers = {},
	preview = {},
	markdown_inline = {},
	markdown = {},
	latex = {},
	highlight_groups = {},
	experimental = {},
	yaml = {},
	html = {}
};

 ------------------------------------------------------------------------------------------

--- Experimental options.
---@class config.experimental
---
---@field file_open_command string Command used to open links inside Neovim.
---@field link_open_alerts boolean When `true`, alert when opening links.
---@field list_empty_line_tolerance integer Number of empty lines between text in a list item.
---@field read_chunk_size integer Number of bytes to check to see if a file is a text file.
---@field text_filetypes string[] Filetypes to open inside `Neovim`.
M.experimental = {
	list_empty_line_tolerance = 3,
	text_filetypes = { "markdown" },
	link_open_alerts = false,
	file_open_command = "tabnew",
	read_chunk_size = 1000
};

 ------------------------------------------------------------------------------------------

--- Highlight group for Neovim.
---@class config.hl
---
---@field fg? string | integer
---@field bg? string | integer
---@field sp? string | integer
---@field blend? integer
---@field bold? boolean
---@field standout? boolean
---@field underline? boolean
---@field undercurl? boolean
---@field underdouble? boolean
---@field underdotted? boolean
---@field underdashed? boolean
---@field strikethrough? boolean
---@field italic? boolean
---@field reverse? boolean
---@field nocombine? boolean
---@field link? string
---@field default? boolean
---@field ctermfg? string | integer
---@field ctermbg? string | integer
---@field cterm? table
---@field force? boolean
M.hl = {
	fg = "#1e1e2e",
	bg = "#cdd6f4"
};

---@class config.extmark
---
---@field id? integer
---@field end_row? integer
---@field end_col? integer
---@field hl_group? string
---@field hl_eol? boolean
---@field virt_text? [ string, string? ][]
---@field virt_text_pos? "inline" | "right_align" | "overlay" | "eol"
---@field virt_text_win_col? integer
---@field virt_text_hide? boolean
---@field virt_text_repeat_linebreak? boolean
---@field hl_mode? "replace" | "combine" | "blend"
---@field virt_lines? [ string, string? ][][]
---@field virt_lines_above? boolean
---@field ephemeral? boolean
---@field right_gravity? boolean
---@field end_right_gravity? boolean
---@field undo_restore? boolean
---@field invalidate? boolean
---@field priority? integer
---@field strict? boolean
---@field sign_text? string
---@field sign_hl_group? string
---@field number_hl_group? string
---@field line_hl_group? string
---@field cursorline_hl_group? string
---@field conceal? string
---@field spell? boolean
---@field ui_watched? boolean
---@field url? string
---@field scoped? boolean
M.extmark = {
	spell = false,
	end_col = 10,
	virt_text = {
		{ "Hi", "Special" }
	}
};

---@class config.inline_generic
---
---@field corner_left? string Left corner.
---@field corner_left_hl? string Highlight group for left corner.
---@field corner_right? string Right corner.
---@field corner_right_hl? string Highlight group for right corner.
---@field hl? string Base Highlight group.
---@field icon? string Icon.
---@field icon_hl? string Highlight group for icon.
---@field padding_left? string Left padding.
---@field padding_left_hl? string Highlight group for left padding.
---@field padding_right? string Right padding.
---@field padding_right_hl? string Highlight group for right padding.
---
---@field file_hl? string Highlight group for block reference file name.
---@field block_hl? string Highlight group for block reference block ID.
---
---@field match_string? string Pattern used to determine when to use this(when supported).
M.inline_generic = {
	corner_left = "<",
	padding_left = " ",
	icon = "π ",
	padding_right = " ",
	corner_right = ">",

	hl = "MarkviewCode"
};

---@class node.range
---
---@field row_start integer
---@field row_end integer
---@field col_start integer
---@field col_end integer
---
---@field font? integer[]
M.range = {
	col_end = 1,
	row_end = 1,
	col_start = 0,
	row_start = 0
};

---@class tag.properties
---
---@field text string
---@field range integer[]
M.tag_properties = {
	text = "<p>hi</p>",
	range = { 0, 0, 0, 9 }
};

---@class inline_link.range
---
---@field row_start integer
---@field row_end integer
---@field col_start integer
---@field col_end integer
---
---@field label? integer[]
---@field description? integer[]
---
---@field alias? integer[]
---@field file? integer[]
---@field block? integer[]
M.inline_link_range = {
	col_end = 1,
	row_end = 1,
	col_start = 0,
	row_start = 0
};

 ------------------------------------------------------------------------------------------

--- Configuration table for HTML preview.
---@class config.html
---
---@field container_elements html.container_elements
---@field headings html.headings
---@field void_elements html.void_elements
M.html = {
	headings = {},
	void_elements = {},
	container_elements = {}
}

--- HTML <container></container> element config.
---@class html.container_elements
---
---@field enable boolean Enables container element rendering.
---@field [string] container_elements.opts Configuration for <string></string>.
M.html_container_elements = {
	enable = true,
	bold = {
		closing_tag_offset = function (range)
			return range;
		end,
		on_closing_tag = function ()
			return { fg = "#1e1e2e", bg = "#cdd6f4" }
		end
	}
};

--- Configuration table for a specific container element.
---@class container_elements.opts
---
---@field closing_tag_offset? fun(range: integer[]): integer[] Modifies the closing </tag>'s range.
---@field node_offset? fun(range: integer[]): table Modifies the element's range.
---@field on_closing_tag? fun(tag: table): config.extmark Extmark configuration to use on the closing </tag>.
---@field on_node? fun(tag: table): config.extmark Extmark configuration to use on the element.
---@field on_opening_tag? fun(tag: table): config.extmark Extmark configuration to use on the opening <tag>.
---@field opening_tag_offset? fun(range: integer[]): integer[] Modifies the opening <tag>'s range.
M.html_container_elements_opts = {
	opening_tag_offset = function (range)
		range[2] = range[2] + 1;
		range[3] = range[3] - 1;

		return range;
	end,
	on_opening_tag = function ()
		return { hl_mode = "combine", hl_group = "Special" }
	end
};


--- HTML heading config.
---@class html.headings
---
---@field enable boolean Enables heading rendering.
---@field [string] heading_elements.opts Configuration for <string></string>.
M.html_headings = {
	enable = true,
	heading_1 = { fg = "#1e1e2e" }
};

--- Configuration table for heading elements.
---@alias heading_elements.opts config.extmark

--- HTML <void> element config.
---@class html.void_elements
---
---@field enable boolean Enables void element rendering.
---@field [string] void_elements.opts Configuration for <string>.
M.html_void_elements = {
	enable = true,
	bold = {
		node_offset = function (range)
			return range;
		end,
		on_node = function ()
			return { fg = "#1e1e2e", bg = "#cdd6f4" }
		end
	}
};

--- Configuration table for a specific void element.
---@class void_elements.opts
---
---@field node_offset fun(range: integer[]): table Modifies the element's range.
---@field on_node fun(tag: table): config.extmark Extmark configuration to use on the element.
M.html_void_elements_opts = {
	node_offset = function (range)
		return range;
	end,
	on_node = function ()
		return { fg = "#1e1e2e", bg = "#cdd6f4" }
	end
};

 ------------------------------------------------------------------------------------------

---@class config.latex
---
---@field blocks latex.blocks | fun(): latex.blocks
---@field commands latex.commands | fun(): latex.commands
---@field escapes latex.escapes | fun(): latex.escapes
---@field fonts latex.fonts | fun(): latex.fonts
---@field inlines latex.inlines | fun(): latex.inlines
---@field parenthesis latex.parenthesis | fun(): latex.parenthesis
---@field subscripts latex.subscripts | fun(): latex.subscripts
---@field superscripts latex.superscripts | fun(): latex.superscripts
---@field symbols latex.symbols | fun(): latex.symbols
---@field texts latex.texts | fun(): latex.texts
M.latex = {
	commands = {},
	texts = {},
	symbols = {},
	subscripts = {},
	superscripts = {},
	parenthesis = {},
	escapes = {},
	inlines = {},
	blocks = {},
	fonts = {}
};

--- Configuration table for latex math blocks.
---@class latex.blocks
---
---@field enable boolean Enables latex block preview.
---@field hl? string Highlight group for the block.
---@field pad_amount integer Number of {pad_char} to add before & after the text.
---@field pad_char string Text used for padding.
---@field text string Text to show on the top-right of the block.
---@field text_hl? string Highlight group for the {text}.
M.latex_blocks = {
	enable = true,
	pad_char = " ",
	pad_amount = 3,
	text = "Math",
	hl = "MarkviewCode"
};

---@class latex.commands
---
---@field enable boolean Enables latex command preview.
---@field [string] commands.opts Configuration table for {string}.
M.latex_commands = {
	enable = true,
	sin = {
		condition = function (item)
			return #item.args == 2;
		end,
		on_command = function ()
			return { conceal = "" };
		end
	}
};

---@class commands.opts
---
---@field command_offset? fun(range: integer[]): table Modifies the command's range.
---@field on_command? fun(tag: table): config.extmark Extmark configuration to use on the command.
---@field on_args? commands.arg_opts[]? Configuration table for each argument.
M.latex_commands_opts = {
	on_command = function ()
		return { conceal = "" };
	end,
	command_offset = nil,
	on_args = {}
};

---@class commands.arg_opts
---
---@field after_offset? fun(range: integer[]): integer[] Modifies the range of the argument(only for `on_after`).
---@field before_offset? fun(range: integer[]): integer[] Modifies the range of the argument(only for `on_before`).
---@field condition? fun(item: table): boolean Can be used to change when the command preview is shown.
---@field content_offset? fun(range: integer[]): table Modifies the argument's range(only for `on_content`).
---@field on_after? fun(tag: table): config.extmark Extmark configuration to use at the end of the argument.
---@field on_before? fun(tag: table): config.extmark Extmark configuration to use at the start of the argument.
---@field on_content? fun(tag: table): config.extmark Extmark configuration to use on the argument.
M.latex_commands_arg_opts = {
	on_after = function ()
		return { virt_text = { ")", "Comment" } };
	end,
	on_before = function ()
		return { virt_text = { "(", "Comment" } };
	end
};

--- Configuration table for latex escaped characters.
---@class latex.escapes
---
---@field enable boolean Enables escaped character preview.
---@field hl? string Highlight group for the escaped character.
M.latex_escapes = {
	enable = true,
	hl = "Operator"
};

--- Configuration table for latex math fonts.
---@alias latex.fonts { enable: boolean }

--- Configuration table for inline latex math.
---@class latex.inlines
---
---@field enable boolean Enables preview of inline latex maths.
---@field corner_left? string Left corner.
---@field corner_left_hl? string Highlight group for left corner.
---@field corner_right? string Right corner.
---@field corner_right_hl? string Highlight group for right corner.
---@field hl? string Base Highlight group.
---@field padding_left? string Left padding.
---@field padding_left_hl? string Highlight group for left padding.
---@field padding_right? string Right padding.
---@field padding_right_hl? string Highlight group for right padding.
M.latex_inlines = {
	enable = true,
	corner_left = " ",
	corner_right = " ",
	hl = "MarkviewInlineCode"
};

--- Configuration table for {}.
---@alias latex.parenthesis { enable: boolean }

---@class latex.subscripts
---
---@field enable boolean Enables preview of subscript text.
---@field hl? string Highlight group for the subscript text.
M.latex_subscripts = {
	enable = true,
	hl = "MarkviewSubscript"
};

---@class latex.superscripts
---
---@field enable boolean Enables preview of superscript text.
---@field hl? string Highlight group for the superscript text.
M.latex_subscripts = {
	enable = true,
	hl = "MarkviewSuperscript"
};

--- Configuration table for latex math symbols.
---@class latex.symbols
---
---@field enable boolean Enables preview of latex math symbols.
---@field hl? string Highlight group for the symbols.
M.latex_symbols = {
	enable = true,
	hl = "MarkviewSuperscript"
};

--- Configuration table for text.
---@alias latex.texts { enable: boolean }

 ------------------------------------------------------------------------------------------


---@class config.markdown
---
---@field block_quotes markdown.block_quotes | fun(): markdown.block_quotes
---@field code_blocks markdown.code_blocks | fun(): markdown.code_blocks
---@field headings markdown.headings | fun(): markdown.headings
---@field horizontal_rules markdown.horizontal_rules | fun(): markdown.horizontal_rules
---@field list_items markdown.list_items | fun(): markdown.list_items
---@field metadata_minus markdown.metadata_minus | fun(): markdown.metadata_minus
---@field metadata_plus markdown.metadata_plus | fun(): markdown.metadata_plus
---@field tables markdown.tables | fun(): markdown.tables
M.markdown = {
	metadata_minus = {},
	horizontal_rules = {},
	headings = {},
	code_blocks = {},
	block_quotes = {},
	list_items = {},
	metadata_plus = {},
	tables = {}
};


---@class markdown.block_quotes
---
---@field enable boolean Enables preview of block quotes.
---@field default block_quotes.opts Default block quote configuration.
---@field [string] block_quotes.opts Configuration for >[!{string}] callout.
M.markdown_block_quotes = {
	enable = true,
	default = { border = "", hl = "MarkviewBlockQuoteDefault" },

	["EXAMPLE"] = { border = { "|", "^", "•" } }
};

---@class block_quotes.opts
---
---@field border string | string[] Text for the border.
---@field border_hl? (string | string[])? Highlight group for the border.
---@field hl? string Base highlight group for the block quote.
---@field icon? string Icon to show before the block quote title.
---@field icon_hl? string Highlight group for the icon.
---@field preview? string Callout/Alert preview string(shown where >[!{string}] was).
---@field preview_hl? string Highlight group for the preview.
---@field title? boolean Whether the block quote can have a title or not.
M.block_quotes_opts = {
	border = "|",
	hl = "MarkviewBlockQuoteDefault",
	icon = "π",
	preview = "π Some text"
};

---@class markdown.code_blocks
---
---@field hl? string Base highlight group for code blocks.
---@field info_hl? string Highlight group for the info string.
---@field label_direction? "left" | "right" Changes where the label is shown.
---@field label_hl? string Highlight group for the label
---@field min_width? integer Minimum width of the code block.
---@field pad_amount? integer Left & right padding size.
---@field pad_char? string Character to use for the padding.
---@field sign? boolean Whether to show signs for the code blocks.
---@field sign_hl? string Highlight group for the signs.
---@field style "simple" | "block" Preview style for code blocks.
M.markdown_code_blocks = {
	style = "simple",
	hl = "MarkviewCode"
} or {
	style = "block",
	label_direction = "right",
	min_width = 60,
	pad_amount = 3,
	pad_char = " "
};

---@class markdown.headings
---
---@field enable boolean Enables preview of headings.
---@field heading_1 headings.atx | fun(): headings.atx
---@field heading_2 headings.atx | fun(): headings.atx
---@field heading_3 headings.atx | fun(): headings.atx
---@field heading_4 headings.atx | fun(): headings.atx
---@field heading_5 headings.atx | fun(): headings.atx
---@field heading_6 headings.atx | fun(): headings.atx
---
---@field shift_width integer Amount of spaces to add before the heading(per level).
M.markdown_headings = {
	enable = true,
	shift_width = 1,

	heading_1 = {},
	heading_2 = {},
	heading_3 = {},
	heading_4 = {},
	heading_5 = {},
	heading_6 = {}
};

---@class headings.atx
---
---@field align "left" | "center" | "right" Label alignment.
---@field corner_left? string Left corner.
---@field corner_left_hl? string Highlight group for left corner.
---@field corner_right? string Right corner.
---@field corner_right_hl? string Highlight group for right corner.
---@field hl? string Base Highlight group.
---@field icon? string Icon.
---@field icon_hl? string Highlight group for icon.
---@field padding_left? string Left padding.
---@field padding_left_hl? string Highlight group for left padding.
---@field padding_right? string Right padding.
---@field padding_right_hl? string Highlight group for right padding.
---@field sign? string Text to show on the sign column.
---@field sign_hl? string Highlight group for the sign.
---@field style "simple" | "label" | "icon" Preview style.
M.headings_atx = {
	style = "simple",
	hl = "MarkviewHeading1"
} or {
	style = "label",
	align = "center",

	padding_left = " ",
	padding_right = " ",

	hl = "MarkviewHeading1"
} or {
	style = "icon",

	icon = "~",
	hl = "MarkviewHeading1"
};

---@class headings.setext
---
---@field border string Text to use for the preview border.
---@field border_hl? string Highlight group for the border.
---@field hl? string Base highlight group.
---@field icon? string Text to use for the icon.
---@field icon_hl? string Highlight group for the icon.
---@field sign? string Text to show in the sign column.
---@field sign_hl? string Highlight group for the sign.
---@field style "simple" | "decorated" Preview style.
M.headings_setext = {
	style = "simple",
	hl = "MarkviewHeading1"
} or {
	style = "decorated",
	border = "—",
	hl = "MarkviewHeading1"
};

---@class markdown.horizontal_rules
---
---@field enable boolean Enables preview of horizontal rules.
---@field parts ( horizontal_rules.text | horizontal_rules.repeating )[] Parts for the horizontal rules.
M.markdown_horizontal_rules = {
	enable = true,
	parts = {};
};

---@class horizontal_rules.text
---
---@field class "text" Part name.
---@field hl? string Highlight group for this part.
---@field text string Text to show.
M.hr_text = {
	class = "text",
	hl = "MarkviewPalette9",
	text = " π "
};

---@class horizontal_rules.repeating
---
---@field type "repeating" Part name.
---@field direction "left" | "right" Direction from which the highlight groups are applied from.
---@field repeat_amount integer How many times to repeat the text.
---@field repeat_hl? boolean Whether to repeat the highlight groups.
---@field repeat_text? boolean Whether to repeat the text.
---@field text string | string[] Text to repeat.
---@field hl? string | string[] Highlight group for the text.
M.hr_repeating = {
	class = "repeating",
	repeat_amount = math.floor(vim.o.columns / 2),
	text = "-",
	hl = { "MarkviewPalette0", "MarkviewPalette1", "MarkviewPalette2", "MarkviewPalette3" },
	repeat_hl = false,
	repeat_text = true
};

--- Configuration for list items.
---@class markdown.list_items
---
---@field enable boolean
---@field marker_dot list_items.ordered
---@field indent_size integer
---@field marker_minus list_items.unordered
---@field marker_parenthesis list_items.ordered
---@field marker_plus list_items.unordered
---@field marker_star list_items.unordered
---@field shift_width integer
M.markdown_list_items = {
	enable = true,
	marker_plus = {},
	marker_star = {},
	marker_minus = {},
	marker_dot = {},
	marker_parenthesis = {}
};

---@class list_items.unordered
---
---@field add_padding boolean
---@field conceal_on_checkbox boolean
---@field enable boolean
---@field hl? string
---@field text string
M.list_items_unordered = {
	enable = true,
	hl = "MarkviewListItemPlus",
	text = "•",
	add_padding = true,
	conceal_on_checkbox = true
};

---@class list_items.ordered
---
---@field add_padding boolean
---@field conceal_on_checkbox boolean
---@field enable boolean
M.list_items_ordered = {
	enable = true,
	add_padding = true,
	conceal_on_checkbox = true
};

--- Configuration for YAML metadata.
---@class markdown.metadata_minus
---
---@field enable boolean
---@field border_bottom? string
---@field border_bottom_hl? string
---@field border_hl? string
---@field border_top? string
---@field border_top_hl? string
---@field hl? string
M.markdown_metadata_minus = {
	enable = true,
	hl = "MarkviewCode"
};

--- Configuration for TOML metadata.
---@class markdown.metadata_plus
---
---@field enable boolean
---@field border_bottom? string
---@field border_bottom_hl? string
---@field border_hl? string
---@field border_top? string
---@field border_top_hl? string
---@field hl? string
M.markdown_metadata_plus = {
	enable = true,
	hl = "MarkviewCode"
};

--- Configuration for tables.
---@class markdown.tables
---
---@field block_decorator boolean
---@field enable boolean
---@field hl tables.parts
---@field parts tables.parts
---@field use_virt_lines boolean
M.markdown_tables = {
	parts = {},
	enable = true,
	hl = {},
	block_decorator = true,
	use_virt_lines = true
};

---@class tables.parts
---
---@field align_center [ string, string ]
---@field align_left string
---@field align_right string
---@field top string[]
---@field header string[]
---@field separator string[]
---@field row string[]
---@field bottom string[]
---@field overlap string[]
M.tables_parts = {
	align_center = { "" },
	row = { "", "", "" },
	top = { "", "", "", "" },
	bottom = { "", "", "", "" },
	header = { "", "", "" },
	overlap = { "", "", "", "" },
	separator = { "", "", "" },
	align_left = "",
	align_right = ""
};

---@class markdown.reference_definitions
---
---@field enable boolean
---@field default config.inline_generic
---@field patterns? config.inline_generic[]
M.markdown_ref_def = {
	enable = true,
	default = { hl = "Title" },
	patterns = {
		{
			match_string = "^mkv",
			hl = "Special"
		}
	}
};

 ------------------------------------------------------------------------------------------

---@class config.markdown_inline
---
---@field checkboxes inline.checkboxes
---@field block_references inline.block_references
---@field inline_codes inline.inline_codes
---@field emails inline.emails
---@field embed_files inline.embed_files
---@field entities inline.entities
---@field escapes inline.escapes
---@field footnotes inline.footnotes
---@field highlights inline.highlights
---@field hyperlinks inline.hyperlinks
---@field images inline.images
---@field internal_links inline.internal_links
---@field uri_autolinks inline.uri_autolinks
M.markdown_inline = {
	footnotes = {},
	checkboxes = {},
	inline_codes = {},
	uri_autolinks = {},
	internal_links = {},
	hyperlinks = {},
	embed_files = {},
	entities = {},
	emails = {},
	block_references = {},
	escapes = {},
	images = {},
	highlights = {}
};

--- Configuration for checkboxes.
---@class inline.checkboxes
---
---@field enable boolean
---@field checked checkboxes.opts
---@field unchecked checkboxes.opts
---@field [string] checkboxes.opts
M.inline_checkboxes = {
	enable = true,
	checked = {},
	unchecked = {},
	["-"] = {}
}

---@class checkboxes.opts
---
---@field text string
---@field hl? string
M.checkboxes_opts = {
	text = "∆",
	hl = "MarkviewCheckboxChecked"
};

--- Configuration for block reference links.
---@class inline.block_references
---
---@field enable boolean
---@field default config.inline_generic
---@field patterns config.inline_generic[]
M.inline_block_ref = {
	enable = true,
	default = {},
	patterns = {
		{
			match_string = "^obs",
			hl = "Special"
		}
	}
};

--- Configuration for inline codes.
---@alias inline.inline_codes config.inline_generic

--- Configuration for emails.
---@class inline.emails
---
---@field enable boolean
---@field default config.inline_generic
---@field patterns config.inline_generic[]
M.inline_emails = {
	enable = true,
	default = {},
	patterns = {
		{
			match_string = "teams",
			hl = "Special"
		}
	}
};

--- Configuration for obsidian's embed files.
---@class inline.embed_files
---
---@field enable boolean
---@field default config.inline_generic
---@field patterns config.inline_generic[]
M.inline_embed_files = {
	enable = true,
	default = {},
	patterns = {
		{
			match_string = "img$",
			hl = "Special"
		}
	}
};

--- Configuration for HTML entities.
---@class inline.entities
---
---@field enable boolean
---@field hl? string
M.inline_entities = {
	enable = true,
	hl = "Comment"
};

--- Configuration for escaped characters.
---@alias inline.escapes { enable: boolean }

--- Configuration for footnotes.
---@class inline.footnotes
---
---@field enable boolean
---@field default config.inline_generic
---@field patterns config.inline_generic[]
M.inline_footnotes = {
	enable = true,
	default = {},
	patterns = {
		{
			match_string = "^from",
			hl = "Special"
		}
	}
};

--- Configuration for highlighted texts.
---@class inline.highlights
---
---@field enable boolean
---@field default config.inline_generic
---@field patterns config.inline_generic[]
M.inline_highlights = {
	enable = true,
	default = {},
	patterns = {
		{
			match_string = "^!",
			hl = "Special"
		}
	}
};

--- Configuration for hyperlinks.
---@class inline.hyperlinks
---
---@field enable boolean
---@field default config.inline_generic
---@field patterns config.inline_generic[]
M.inline_hyperlinks = {
	enable = true,
	default = {},
	patterns = {
		{
			match_string = "neovim%.org",
			hl = "Special"
		}
	}
};

--- Configuration for image links.
---@class inline.images
---
---@field enable boolean
---@field default config.inline_generic
---@field patterns config.inline_generic[]
M.inline_images = {
	enable = true,
	default = {},
	patterns = {
		{
			match_string = "svg$",
			hl = "Special"
		}
	}
};

--- Configuration for obsidian's internal links.
---@class inline.internal_links
---
---@field enable boolean
---@field default config.inline_generic
---@field patterns config.inline_generic[]
M.inline_internal_links = {
	enable = true,
	default = {},
	patterns = {
		{
			match_string = "^vault",
			hl = "Special"
		}
	}
};

--- Configuration for uri autolinks.
---@class inline.uri_autolinks
---
---@field enable boolean
---@field default config.inline_generic
---@field patterns config.inline_generic[]
M.inline_uri_autolinks = {
	enable = true,
	default = {},
	patterns = {
		{
			match_string = "^https",
			hl = "Special"
		}
	}
};

 ------------------------------------------------------------------------------------------

---@class config.preview
---
---@field callbacks preview.callbacks
---@field enable boolean
---@field hybrid_modes string[]
---@field ignore_previews preview.ignore
---@field modes string[]
---@field debounce integer
---@field edit_range [ integer, integer ]
---@field draw_range [ integer, integer ]
---@field filetypes string[]
---@field ignore_buftypes string[]
---@field splitview_winopts table
M.preview = {
	enable = true,
	callbacks = {},
	modes = { "n" },
	debounce = 50,
	filetypes = { "md" },
	draw_range = { 10, 10 },
	ignore_buftypes = {},
	splitview_winopts = {},
	edit_range = { 1, 1 },
	hybrid_modes = {},
	ignore_previews = {}
};

---@class preview.callbacks
---
---@field on_attach? fun(buf: integer, wins: integer[]): nil
---@field on_enable? fun(buf: integer, wins: integer[]): nil
---@field on_disable? fun(buf: integer, wins: integer[]): nil
---@field on_detach? fun(buf: integer, wins: integer[]): nil
---@field on_mode_change? fun(buf: integer, wins: integer[], mode: string): nil
---@field on_splitview_open? fun(source: integer, buf: integer, win: integer, mode: string): nil
---@field on_splitview_close? fun(source: integer, buf: integer, win: integer, mode: string): nil
M.preview_callbacks = {
	on_attach = function (buf, wins)
		vim.print(wins);
	end
};

---@class preview.ignore
---
---@field html string[]
---@field latex string[]
---@field markdown string[]
---@field markdown_inline string[]
---@field typst string[]
---@field yaml string[]
M.preview_ignore = {
	markdown = { "!block_quotes", "!code_blocks" }
};

---@class config.renderer

 ------------------------------------------------------------------------------------------

---@class config.typst
---
---@field enable boolean
---@field codes typst.codes
---@field escapes typst.escapes
---@field headings typst.headings
---@field raw_blocks typst.raw_blocks
---@field raw_spans typst.raw_spans
---@field labels typst.labels
---@field list_items typst.list_items
---@field math_blocks typst.math_blocks
---@field math_spans typst.math_spans
---@field url_links typst.url_links
---@field reference_links typst.reference_links
---@field subscripts typst.subscripts
---@field superscript typst.subscripts
---@field symbols typst.symbols
---@field terms typst.terms
M.typst = {
	enable = true,

	terms = {},
	superscript = {},
	math_spans = {},
	math_blocks = {},
	raw_spans = {},
	raw_blocks = {},
	headings = {},
	symbols = {},
	list_items = {},
	escapes = {},
	codes = {},
	labels = {},
	url_links = {},
	subscripts = {},
	reference_links = {}
};

---@class typst.code_block
---
---@field enable boolean
---@field hl? string
---@field min_width integer
---@field pad_amount integer
---@field pad_char? string
---@field sign? string
---@field sign_hl? string
---@field style "simple" | "block"
---@field text string
---@field text_direction "left" | "right"
---@field text_hl? string
M.typst_codes_block = {
	style = "block",
	text_direction = "right",
	pad_amount = 3,
	pad_char = " ",
	min_width = 60,
	hl = "MarkviewCode"
} or {
	style = "simple",
	hl = "MarkviewCode"
};

---@class typst.code_inline
---
---@field enable boolean
---@field corner_left? string Left corner.
---@field corner_left_hl? string Highlight group for left corner.
---@field corner_right? string Right corner.
---@field corner_right_hl? string Highlight group for right corner.
---@field hl? string Base Highlight group.
---@field padding_left? string Left padding.
---@field padding_left_hl? string Highlight group for left padding.
---@field padding_right? string Right padding.
---@field padding_right_hl? string Highlight group for right padding.
M.typst_codes_inline = {
	enable = true,

	padding_left = " ",
	corner_left = " ",
	hl = "MarkviewCode"
};

---@alias typst.escapes { enable: boolean }

---@class typst.headings
---
---@field enable boolean
---@field shift_width integer
---@field [string] headings.typst
M.typst_headings = {
	enable = true,
	shift_width = 1,

	heading_1 = { style = "simple", hl = "MarkviewPalette1" }
};

---@class headings.typst
---
---@field style "simple" | "icon"
---@field hl? string
---@field icon? string
---@field icon_hl? string
---@field sign? string
---@field sign_hl? string
M.headings_typst = {
	style = "simple",
	hl = "MarkviewHeading1"
} or {
	style = "icon",

	icon = "~",
	hl = "MarkviewHeading1"
};

---@class typst.labels
---
---@field enable boolean
---@field default config.inline_generic
---@field patterns config.inline_generic[]
M.typst_labels = {
	enable = true,
	default = { hl = "MarkviewInlineCode" },
	patterns = {
		{
			match_string = "^nv",
			hl = "MarkviewPalette1"
		}
	}
};

---@class typst.reference_links
---
---@field enable boolean
---@field default config.inline_generic
---@field patterns config.inline_generic[]
M.typst_link_ref = {
	enable = true,
	default = { hl = "MarkviewHyperlink" },
	patterns = {
		{
			match_string = "neovim.org",
			hl = "MarkviewPalette1"
		}
	}
};

---@class typst.url_links
---
---@field enable boolean
---@field default config.inline_generic
---@field patterns config.inline_generic[]
M.typst_link_ref = {
	enable = true,
	default = { hl = "MarkviewHyperlink" },
	patterns = {
		{
			match_string = "neovim.org",
			hl = "MarkviewPalette1"
		}
	}
};

---@class typst.list_items
---
---@field enable boolean
---@field marker_dot list_items.ordered
---@field indent_size integer
---@field marker_minus list_items.unordered
---@field marker_plus list_items.unordered
---@field shift_width integer
M.typst_list_items = {
	enable = true,
	marker_plus = {},
	marker_minus = {},
	marker_dot = {},
};

---@alias typst.math_spans config.inline_generic
M.typst_math_spans = {
	enable = true,
	hl = "MarkviewInlineCode"
};

---@class typst.math_blocks
---
---@field enable boolean
---@field hl? string
---@field pad_amount integer
---@field pad_char string
---@field text string
---@field text_hl? string
M.typst_math_blocks = {
	enable = true,
	hl = "MarkviewInlineCode"
};

---@alias typst.raw_spans config.inline_generic
M.typst_raw_spans = {
	enable = true,
	hl = "MarkviewInlineCode"
};

---@class typst.raw_blocks
---
---@field hl? string Base highlight group for code blocks.
---@field label_direction? "left" | "right" Changes where the label is shown.
---@field label_hl? string Highlight group for the label
---@field min_width? integer Minimum width of the code block.
---@field pad_amount? integer Left & right padding size.
---@field pad_char? string Character to use for the padding.
---@field sign? boolean Whether to show signs for the code blocks.
---@field sign_hl? string Highlight group for the signs.
---@field style "simple" | "block" Preview style for code blocks.
M.typst_raw_blocks = {
	enable = true,
	hl = "MarkviewInlineCode"
};

---@class typst.subscripts
---
---@field enable boolean
---@field hl? string | string[]
---@field marker_left? string
---@field marker_right? string
M.typst_subscripts = {
	enable = true,
	hl = "MarkviewSubscript"
};

---@class typst.superscripts
---
---@field enable boolean
---@field hl? string | string[]
---@field marker_left? string
---@field marker_right? string
M.typst_superscripts = {
	enable = true,
	hl = "MarkviewSuperscript"
};

---@class typst.symbols
---
---@field enable boolean
---@field hl? string
M.typst_symbols = {
	enable = true,
	hl = "Special"
};

---@class typst.fonts
---
---@field enable boolean
---@field hl? string
M.typst_fonts = {
	enable = true,
	hl = "Special"
};

---@class typst.terms
---
---@field enable boolean
---@field default term.opts
---@field patterns term.opts[]
M.typst_term = {
	enable = true,
	default = {},
	patterns = {}
};

---@class term.opts
---
---@field text string
---@field hl? string
M.term_opts = {
	text = "π",
	hl = "Comment"
};

 ------------------------------------------------------------------------------------------

---@class config.yaml
---
---@field enable boolean
---@field properties yaml.properties
M.yaml = {
	enable = true,
	properties = {};
};

---@class yaml.properties
---
---@field enable boolean
---@field data_types { [string]: properties.opts }
---@field default properties.opts
---@field patterns properties.opts
M.yaml_properties = {
	enable = true,
	default = {},
	data_types = {},
	patterns = {}
};

---@class properties.opts
---
---@field match_string? string
---@field border_bottom? string
---@field border_bottom_hl? string
---@field border_hl? string
---@field border_middle? string
---@field border_middle_hl? string
---@field border_top? string
---@field border_top_hl? string
---@field hl? string
---@field text string
---@field use_types? boolean
M.properties_opts = {
	use_types = true,
	match_string = "^hi",
	text = "π",
	hl = "Title"
};


 ------------------------------------------------------------------------------------------
 ------------------------------------------------------------------------------------------
 ------------------------------------------------------------------------------------------


---@class __html.headings
---
---@field class "html_heading"
---@field level integer
---@field range node.range
---@field text string[]
M.__html_headings = {
	class = "html_heading",
	level = 1,
	text = {
		"<h1>",
		"heading text",
		"</h1>"
	},
	range = {
		row_start = 0,
		col_start = 0,
		row_end = 2,
		col_end = 5
	}
};

---@class __html.container_elements
---
---@field class "html_container_element"
---@field opening_tag tag.properties
---@field closing_tag tag.properties
---@field name string
---@field text string[]
---@field range node.range
M.__html_container_elements = {
	class = "html_container_element",
	name = "p",
	text = {
		"<p>",
		"text</p>"
	},

	opening_tag = {
		text = "<p>",
		range = { 0, 0, 0, 3 }
	},
	closing_tag = {
		text = "</p>",
		range = { 1, 5, 1, 8 }
	},
	range = {
		row_start = 0,
		row_end = 1,
		col_start = 0,
		col_end = 8
	}
};

---@class __html.void_elements
---
---@field class "html_container_element"
---@field name string
---@field text string[]
---@field range node.range
M.__html_void_elements = {
	class = "html_container_element",
	name = "img",
	text = {
		"<img src = './markview.jpg'>"
	},
	range = {
		row_start = 0,
		row_end = 0,
		col_start = 0,
		col_end = 27
	}
};

 ------------------------------------------------------------------------------------------

--- LaTeX blocks(typically made with `$$...$$`)
---@class __latex.blocks
---
---@field class "latex_block"
---@field inline boolean Is this block within text?
---@field closed boolean Is there a closing `$$`?
---@field text string[]
---@field range node.range
M.__latex_blocks = {
	class = "latex_block",
	inline = true,
	closed = true,
	text = { "$$1 + 2 = 3$$" },
	range = {
		row_start = 0,
		row_end = 0,
		col_start = 0,
		col_end = 13
	}
};

--- LaTeX commands(must have at least 1 argument).
---@class __latex.commands
---
---@field class "latex_command"
---@field command { name: string, range: integer[] } Command name(without `\`) and it's range.
---@field args { text: string, range: integer[] }[] List of arguments(inside `{...}`) with their text & range.
---@field text string[]
---@field range node.range
M.__latex_commands = {
	class = "latex_command",
	command = {
		name = "frac",
		range = { 0, 0, 0, 5 }
	},
	args = {
		{
			text = "{1}",
			range = { 0, 5, 0, 8 }
		},
		{
			text = "{2}",
			range = { 0, 8, 0, 11 }
		}
	},
	text = { "\\frac{1}{2}" },
	range = {
		row_start = 0,
		row_end = 0,

		col_start = 0,
		col_end = 11
	}
};

--- Escaped characters.
---@class __latex.escapes
---
---@field class "latex_escaped"
---@field text string[]
---@field range node.range
M.__latex_escapes = {
	class = "latex_escaped",
	text = { "\\|" },
	range = {
		row_start = 0,
		row_end = 0,

		col_start = 0,
		col_end = 2
	}
};

--- Math fonts
---@class __latex.fonts
---
---@field class "latex_font"
---@field name string Font name.
---@field text string[]
---@field range node.range
M.__latex_fonts = {
	class = "latex_font",
	name = "mathtt",
	text = { "\\mathtt{abcd}" },
	range = {
		font = { 0, 0, 0, 7 },
		row_start = 0,
		row_end = 0,
		col_start = 0,
		col_end = 13
	}
};

--- Inline LaTeX(typically made using `$...$`).
---@class __latex.inlines
---
---@field class "latex_inlines"
---@field closed boolean Is there a closing `$`?
---@field text string[]
---@field range node.range
M.__latex_inlines = {
	class = "latex_inlines",
	closed = true,

	text = { "$1 + 1 = 2$" },
	range = {
		row_start = 0,
		col_start = 0,

		row_end = 0,
		col_end = 11
	}
};

--- {} in LaTeX.
---@class __latex.parenthesis
---
---@field class "latex_parenthesis"
---@field text string[]
---@field range node.range
M.__latex_parenthesis = {
	class = "latex_parenthesis",
	text = { "{1+2}" },
	range = {
		row_start = 0,
		row_end = 0,

		col_start = 0,
		col_end = 5
	}
};

--- Subscript text(e.g. _h, _{hi}, _{+} etc.).
---@class __latex.subscripts
---
---@field class "latex_subscript"
---@field parenthesis boolean Is the text within `{...}`?
---@field level integer Level of the subscript text. Used for handling nested subscript text.
---@field preview boolean Can the text be previewed?
---@field text string[]
---@field range node.range
M.__latex_subscripts = {
	class = "latex_subscript",
	parenthesis = true,
	preview = true,
	level = 1,

	text = { "_{hi}" },
	range = {
		row_start = 0,
		row_end = 0,

		col_start = 0,
		col_end = 5
	}
};

--- Superscript text(e.g. ^h, ^{hi}, ^{+} etc.).
---@class __latex.superscripts
---
---@field class "latex_superscript"
---@field parenthesis boolean Is the text within `{...}`?
---@field level integer Level of the superscript text. Used for handling nested superscript text.
---@field preview boolean Can the text be previewed?
---@field text string[]
---@field range node.range
M.__latex_superscripts = {
	class = "latex_superscript",
	parenthesis = true,
	preview = true,
	level = 1,

	text = { "^{hi}" },
	range = {
		row_start = 0,
		row_end = 0,

		col_start = 0,
		col_end = 5
	}
};

--- Math symbols in LaTeX(e.g. \Alpha).
---@class __latex.symbols
---
---@field class "latex_symbols"
---@field name string Symbol name(without the `\`).
---@field style "superscripts" | "subscripts" | nil Text styles to apply(if possible).
---@field text string[]
---@field range node.range
M.__latex_symbols = {
	class = "latex_symbols",
	name = "pi",
	style = nil,

	text = { "\\pi" },
	range = {
		row_start = 0,
		row_end = 0,

		col_start = 0,
		col_end = 3
	}
};

--- `\text{}` nodes.
---@class __latex.text
---
---@field class "latex_text"
---@field text string[]
---@field range node.range
M.__latex_word = {
	class = "latex_text",
	text = { "word" },
	range = {
		row_start = 0,
		row_end = 0,

		col_start = 5,
		col_end = 9
	}
};

--- Groups of characters(without any spaces between them).
--- Used for applying fonts & text styles.
---@class __latex.word
---
---@field class "latex_word"
---@field text string[]
---@field range node.range
M.__latex_word = {
	class = "latex_word",
	text = { "word" },
	range = {
		row_start = 0,
		row_end = 0,

		col_start = 5,
		col_end = 9
	}
};

 ------------------------------------------------------------------------------------------

--- Cached data. Used for applying text styles & fonts.
--- Also used for filtering nodes.
---@class __latex.cache
---
---@field font_regions { name: string, row_start: integer, row_end: integer, col_start: integer, col_end: integer }
---@field style_regions { superscripts: node.range[], subscripts: node.range[] }
M.__latex_cache = {
	font_regions = {
		{
			name = "mathtt",
			row_start = 0,
			row_end = 0,

			col_start = 0,
			col_end = 5
		}
	},
	style_regions = {
		subscripts = {
			{
				row_start = 1,
				row_end = 1,

				col_start = 0,
				col_end = 6
			}
		},
		superscripts = {}
	}
};

 ------------------------------------------------------------------------------------------

---@class __markdown.atx
---
---@field class "markdown_atx_heading"
---@field marker "#" | "##" | "###" | "####" | "#####" | "######" Heading marker.
---@field text string[]
---@field range node.range
M.__markdown_atx = {
	class = "markdown_atx_heading",
	marker = "#",

	text = { "# Heading 1" },
	range = {
		row_start = 0,
		row_end = 0,

		col_start = 0,
		col_end = 11
	}
};


---@class __markdown.setext
---
---@field class "markdown_setext_heading"
---@field marker "---" | "===" Heading marker.
---@field text string[]
---@field range node.range
M.__markdown_setext = {
	class = "markdown_setext_heading",
	marker = "---",
	text = {
		"Heading",
		"---"
	},
	range = {
		row_start = 0,
		row_end = 2,

		col_start = 0,
		col_end = 3
	}
};

---@class __markdown.block_quotes
---
---@field class "markdown_block_quote"
---@field callout string? Callout text(text inside `[!...]`).
---@field title string? Title of the callout.
---@field text string[]
---@field range __block_quotes.range
M.__markdown_block_quotes = {
	class = "markdown_block_quote",
	callout = "TIP",
	title = "Title",

	text = {
		">[!TIP] Title",
		"> Something."
	},
	range = {
		row_start = 0,
		row_end = 2,

		col_start = 0,
		col_end = 0,

		callout_start = 3,
		callout_end = 6,

		title_start = 8,
		title_end = 13
	}
};

---@class __block_quotes.range
---
---@field row_start integer
---@field row_end integer
---@field col_start integer
---@field col_end integer
---
---@field callout_start? integer Start column of callout text(after `[!`).
---@field callout_end? integer End column of callout text(before `]`).
---@field title_start? integer Start column of the title.
---@field title_end? integer End column of the title.
M.__block_quotes_range = {
	row_start = 0,
	row_end = 2,

	col_start = 0,
	col_end = 0,

	callout_start = 3,
	callout_end = 6,

	title_start = 8,
	title_end = 13
};

---@class __markdown.code_blocks
---
---@field class "markdown_code_block"
---@field language string? Language string(typically after ```).
---@field info_string string? Extra information regarding the code block.
---@field text string[]
---@field range __code_blocks.range
M.__markdown_code_blocks = {
	class = "markdown_code_block",

	language = "lua",
	info_string = "Info string",

	text = {
		"```lua Info string",
		'vim.print("Hello, Neovim!");',
		"```"
	},

	range = {
		row_start = 0,
		row_end = 2,

		col_start = 0,
		col_end = 3,

		lang_start = 3,
		lang_end = 6,

		info_start = 7,
		info_end = 18
	}
};

---@class __code_blocks.range
---
---@field row_start integer
---@field row_end integer
---@field col_start integer
---@field col_end integer
---
---@field lang_start? integer Start column of the language string.
---@field lang_end? integer End column of the language string.
---
---@field info_start? integer Start column of the info string.
---@field info_end? integer End column of the info string.
M.__code_blocks_range = {
	row_start = 0,
	row_end = 2,

	col_start = 0,
	col_end = 3,

	lang_start = 3,
	lang_end = 6,

	info_start = 7,
	info_end = 18
};

---@class __markdown.checkboxes
---
---@field class "markdown_checkbox"
---@field state string State of the checkbox(text inside `[]`).
---@field text string[],
---@field range node.range
M.__markdown_checkboxes = {
	class = "markdown_checkbox",
	state = " ",
	text = { "[ ]" },
	range = {
		row_start = 0,
		row_end = 0,

		col_start = 2,
		col_end = 5
	}
};

---@class __markdown.horizontal_rules
---
---@field class "markdown_hr"
---@field text string[]
---@field range node.range
M.__markdown_hr = {
	class = "markdown_hr",
	text = { "---" },
	range = {
		row_start = 0,
		row_end = 1,

		col_start = 0,
		col_end = 0
	}
};

---@class __markdown.reference_definitions
---
---@field class "markdown_link_ref_definition"
---@field label? string Visible part of the reference link definition.
---@field description? string Description of the reference link.
---@field text string[]
---@field range __reference_definitions.range
M.__markdown_reference_definitions = {
	class = "markdown_link_ref_definition",
	label = "nvim",
	description = "https://www.neovim.org",

	text = {
		"[nvim]:",
		"https://www.neovim.org"
	},
	range = {
		row_start = 0,
		row_end = 1,

		col_start = 0,
		col_end = 21,

		label = { 0, 0, 0, 7 },
		description = { 1, 0, 1, 21 }
	}
};

---@class __reference_definitions.range
---
---@field row_start integer
---@field row_end integer
---@field col_start integer
---@field col_end integer
---
---@field label integer[] Range of the label node(result of `TSNode:range()`).
---@field description? integer[] Range of the description node. Same as `label`.
M.__reference_definitions_range = {
	row_start = 0,
	row_end = 1,

	col_start = 0,
	col_end = 21,

	label = { 0, 0, 0, 7 },
	description = { 1, 0, 1, 21 }
};

---@class __markdown.list_items
---
---@field class "markdown_list_item"
---@field candidates integer[] List of line numbers(0-indexed) from `range.row_start` that should be indented.
---@field marker "-" | "+" | "*" | string List marker text.
---@field checkbox? string Checkbox state(if there is a checkbox).
---@field indent integer Spaces before the list marker.
---@field text string[]
---@field range node.range
M.__markdown_list_items = {
	class = "markdown_list_item",
	marker = "-",
	checkbox = nil,
	candidates = { 0 },

	text = { "- List item" },
	range = {
		row_start = 0,
		row_end = 0,

		col_start = 0,
		col_end = 11
	}
};

---@class __markdown.metadata_minus
---
---@field class "markdown_metadata_minus"
---@field text string[]
---@field range node.range
M.__markdown_metadata_minus = {
	class = "markdown_metadata_minus",

	text = {
		"---",
		"author: OXY2DEV",
		"---"
	},
	range = {
		row_start = 0,
		row_end = 2,

		col_start = 0,
		col_end = 3
	}
};

---@class __markdown.metadata_plus
---
---@field class "markdown_metadata_plus"
---@field text string[]
---@field range node.range
M.__markdown_metadata_plus = {
	class = "markdown_metadata_plus",

	text = {
		"---",
		"author: OXY2DEV",
		"---"
	},
	range = {
		row_start = 0,
		row_end = 2,

		col_start = 0,
		col_end = 3
	}
};

---@class __markdown.tables
---
---@field class "markdown_table"
---@field top_border boolean Can we draw the top border?
---@field bottom_border boolean Can we draw the bottom border?
---@field border_overlap boolean Is the table's borders overlapping another table?
---@field alignments ( "left" | "center" | "right" | "default" )[] Text alignments.
---@field header __tables.cell[]
---@field separator __tables.cell[]
---@field rows __tables.cell[][]
---@field text string[]
---@field range node.range
M.__markdown_tables = {
	class = "markdown_table",

	top_border = true,
	bottom_border = true,
	border_overlap = false,

	alignments = { "default", "default", "default" },
	header = {
		{
			class = "separator",
			text = "|",
			col_start = 0,
			col_end = 1
		},
		{
			class = "column",
			text = " Col 1 ",
			col_start = 2,
			col_end = 9
		},
		{
			class = "separator",
			text = "|",
			col_start = 10,
			col_end = 11
		},
		{
			class = "column",
			text = " Col 2 ",
			col_start = 12,
			col_end = 19
		},
		{
			class = "separator",
			text = "|",
			col_start = 20,
			col_end = 21
		}
	},
	separator = {
		{
			class = "separator",
			text = "|",
			col_start = 0,
			col_end = 1
		},
		{
			class = "column",
			text = " ----- ",
			col_start = 2,
			col_end = 9
		},
		{
			class = "separator",
			text = "|",
			col_start = 10,
			col_end = 11
		},
		{
			class = "column",
			text = " ----- ",
			col_start = 12,
			col_end = 19
		},
		{
			class = "separator",
			text = "|",
			col_start = 20,
			col_end = 21
		}
	},
	rows = {
		{
			{
				class = "separator",
				text = "|",
				col_start = 0,
				col_end = 1
			},
			{
				class = "column",
				text = " Cell 1 ",
				col_start = 2,
				col_end = 10
			},
			{
				class = "separator",
				text = "|",
				col_start = 11,
				col_end = 12
			},
			{
				class = "column",
				text = " Cell 2 ",
				col_start = 13,
				col_end = 21
			},
			{
				class = "separator",
				text = "|",
				col_start = 22,
				col_end = 23
			}
		}
	},

	text = {
		"| Col 1 | Col 2 |",
		"| ----- | ----- |",
		"| Cell 1 | Cell 2 |"
	}
};

---@class __tables.cell
---
---@field class "separator" | "column" | "missing_separator"
---@field text string
---@field col_start integer
---@field col_end integer
M.__tables_cell = {
	class = "separator",
	text = "|",
	col_start = 0,
	col_end = 1
};

 ------------------------------------------------------------------------------------------

---@class __inline.block_references
---
---@field class "inline_link_block_ref"
---@field file? string File name.
---@field block string Block ID.
---@field label string
---@field text string[]
---@field range inline_link.range
M.__inline_block_references = {
	class = "inline_link_block_ref",

	file = "Some_file.md",
	block = "Block",
	label = "Some_file.md#^Block",

	text = { "![[Some_file.md#^Block]]" },
	range = {
		row_start = 0,
		row_end = 0,

		col_start = 0,
		col_end = 25,

		label = { 0, 3, 0, 23 },
		file = { 0, 3, 0, 12 },
		block = { 0, 14, 0, 23 }
	}
};

---@class __inline.checkboxes
---
---@field class "inline_checkbox"
---@field state string Checkbox state(text inside `[]`).
---@field text string[]
---@field range node.range
M.__inline_checkboxes = {
	class = "inline_checkbox",
	state = "-",

	text = { "[-]" },
	range = {
		row_start = 0,
		row_end = 0,

		col_start = 2,
		col_end = 5
	}
};

---@class __inline.inline_codes
---
---@field class "inline_code_span"
---@field text string[]
---@field range node.range
M.__inline_inline_codes = {
	class = "inline_code_span",
	text = { "`inline code`" },
	range = {
		row_start = 0,
		row_end = 0,

		col_start = 0,
		col_end = 13
	}
};

---@class __inline.embed_files
---
---@field class "inline_link_embed_file"
---@field label string Text inside `[[...]]`.
---@field text string[]
---@field range node.range
M.__inline_link_embed_files = {
	class = "inline_link_embed_file",
	label = "v25",

	text = { "![[v25]]" },
	range = {
		row_start = 0,
		row_end = 0,

		col_start = 0,
		col_end = 8
	}
};

---@class __inline.emails
---
---@field class "inline_link_email"
---@field label string
---@field text string[]
---@field range inline_link.range
M.__inline_link_emails = {
	class = "inline_link_email",
	label = "example@mail.com",

	text = { "<example@mail.com>" },
	range = {
		row_start = 0,
		row_end = 0,

		col_start = 0,
		col_end = 17,

		label = { 0, 1, 0, 16 }
	}
};

---@class __inline.entities
---
---@field class "inline_entity"
---@field name string Entity name(text after "\")
---@field text string[]
---@field range node.range
M.__inline_entities = {
	class = "inline_entity",
	name = "Int",
	text = { "&Int;" },
	range = {
		row_start = 0,
		row_end = 0,

		col_start = 0,
		col_end = 5
	}
};

---@class __inline.escaped
---
---@field class "inline_escaped"
---@field text string[]
---@field range node.range
M.__inline_escaped = {
	class = "inline_escaped",
	text = { "\\'" },
	range = {
		row_start = 0,
		row_end = 0,

		col_start = 0,
		col_end = 2
	}
};

---@class __inline.footnotes
---
---@field class "inline_footnotes"
---@field label string
---@field text string[]
---@field range node.range
M.__inline_footnotes = {
	class = "inline_footnotes",
	label = "^1",

	text = { "[^1]" },
	range = {
		row_start = 0,
		row_end = 0,

		col_start = 0,
		col_end = 4
	}
};

---@class __inline.highlights
---
---@field class "inline_highlight"
---@field text string[]
---@field range node.range
M.__inline_highlights = {
	class = "inline_highlight",

	text = { "==Highlight==" },
	range = {
		row_start = 0,
		row_end = 0,

		col_start = 0,
		col_end = 13
	}
};

---@class __inline.images
---
---@field class "inline_link_image"
---@field label? string
---@field description? string
---@field text string[]
---@field range inline_link.range
M.__inline_images = {
	class = "inline_link_image",
	label = "image",
	description = "test.svg",

	text = { "![image](test.svg)" },
	range = {
		row_start = 0,
		row_end = 0,

		col_start = 0,
		col_end = 18,

		label = { 0, 2, 0, 7 },
		description = { 0, 9, 0, 17 }
	}
};

---@class __inline.internal_links
---
---@field class "inline_link_internal"
---@field alias? string
---@field label string
---@field text string[]
---@field range inline_link.range

---@class __inline.hyperlinks
---
---@field class "inline_link_hyperlink"
---@field label? string
---@field description? string
---@field text string[]
---@field range inline_link.range
M.__inline_images = {
	class = "inline_link_hyperlink",
	label = "link",
	description = "test.svg",

	text = { "[link](example.md)" },
	range = {
		row_start = 0,
		row_end = 0,

		col_start = 0,
		col_end = 18,

		label = { 0, 1, 0, 5 },
		description = { 0, 7, 0, 16 }
	}
};

---@class __inline.uri_autolinks
---
---@field class "inline_link_uri_autolinks"
---@field label string
---@field text string[]
---@field range inline_link.range
M.__inline_uri_autolinks = {
	class = "inline_link_uri_autolinks",
	label = "https://example.com",

	text = { "<https://example.com>" },
	range = {
		row_start = 0,
		row_end = 0,

		col_start = 0,
		col_end = 21,

		label = { 0, 1, 0, 20 }
	}
};

 ------------------------------------------------------------------------------------------

---@class __typst.code_block
---@field class "typst_code_block"
---@field text string[]
---@field range node.range
M.__typst_codes = {
	class = "typst_code_block",

	text = {
		"#{",
		"    let a = [from]",
		"}"
	},
	range = {
		row_start = 0,
		row_end = 2,

		col_start = 0,
		col_end = 1
	}
};

---@class __typst.code_inline
---@field class "typst_code_inline"
---@field text string[]
---@field range node.range
M.__typst_codes = {
	class = "typst_code_inline",

	text = { "#{ let a = 1 }" },
	range = {
		row_start = 0,
		row_end = 0,

		col_start = 0,
		col_end = 13
	}
};

---@class __typst.emphasis
---
---@field class "typst_emphasis"
---@field text string[]
---@field range node.range
M.__typst_emphasis = {
	class = "typst_emphasis",
	text = { "_emphasis_" },
	range = {
		row_start = 0,
		row_end = 0,

		col_start = 0,
		col_end = 9
	}
};

---@class __typst.escapes
---
---@field class "typst_escaped"
---@field text string[]
---@field range node.range
M.__typst_escapes = {
	class = "typst_escaped",

	text = { "\\|" },
	range = {
		row_start = 0,
		row_end = 0,

		col_start = 0,
		col_end = 2
	}
};

---@class __typst.headings
---
---@field class "typst_heading"
---@field level integer Heading level.
---@field text string[]
---@field range node.range
M.__typst_headings = {
	class = "typst_heading",
	level = 1,

	text = { "= Heading 1" },
	range = {
		row_start = 0,
		row_end = 0,

		col_start = 0,
		col_end = 10
	}
};

---@class __typst.labels
---
---@field class "typst_labels"
---@field text string[]
---@field range node.range
M.__typst_labels = {
	class = "typst_labels",

	text = { "<label>" },
	range = {
		row_start = 0,
		row_end = 0,

		col_start = 0,
		col_end = 7
	}
};

---@class __typst.list_items
---
---@field class "typst_list_item"
---@field indent integer
---@field marker "+" | "-" | string
---@field number? integer Number to show on the list item when previewing.
---@field text string[]
---@field range node.range
M.__typst_list_items = {
	class = "typst_list_item",
	indent = 0,
	marker = "-",

	text = { "- List item" },
	range = {
		row_start = 0,
		row_end = 0,

		col_start = 0,
		col_end = 11
	}
};

---@class __typst.maths
---
---@field class "typst_math"
---@field inline boolean Should we render it inline?
---@field closed boolean Is the node closed(ends with `$$`)?
---@field text string[]
---@field range node.range
M.__typst_maths = {
	class = "typst_math",
	inline = true,
	closed = true,

	text = { "$ 1 + 2 $" },
	range = {
		row_start = 0,
		row_end = 0,

		col_start = 0,
		col_end = 9
	}
};

---@class __typst.url_links
---
---@field class "typst_link_url"
---@field label string
---@field text string[]
---@field range inline_link.range
M.__typst_url_links = {
	class = "typst_link_url",
	label = "https://example.com",

	text = { "https://example.com" },
	range = {
		row_start = 0,
		row_end = 0,

		col_start = 0,
		col_end = 19,

		label = { 0, 0, 0, 19 }
	}
};

---@class __typst.reference_links
---
---@field class "typst_link_ref"
---@field label string
---@field text string[]
---@field range inline_link.range
M.__typst_link_ref = {
	class = "typst_link_ref",
	label = "label",

	text = { "@label" },
	range = {
		row_start = 0,
		row_end = 0,

		col_start = 0,
		col_end = 6,

		label = { 0, 1, 0, 6 }
	}
};

---@class __typst.raw_blocks
---
---@field class "typst_raw_block"
---@field language? string
---@field text string[]
---@field range node.range
M.__typst_raw_blocks = {
	class = "typst_raw_block",
	language = "lua",

	text = {
		"```lua",
		'vim.print("Hello, Neovim")',
		"```"
	},
	range = {
		row_start = 0,
		row_end = 2,

		col_start = 0,
		col_end = 3
	}
};

---@class __typst.raw_spans
---
---@field class "typst_raw_span"
---@field text string[]
---@field range node.range
M.__typst_raw_blocks = {
	class = "typst_raw_span",

	text = { "`hi`" },
	range = {
		row_start = 0,
		row_end = 0,

		col_start = 0,
		col_end = 4
	}
};

---@class __typst.strong
---
---@field class "typst_strong"
---@field text string[]
---@field range node.range
M.__typst_strong = {
	class = "typst_strong",

	text = { "*strong*" },
	range = {
		row_start = 0,
		row_end = 0,

		col_start = 0,
		col_end = 7
	}
};

---@class __typst.subscripts
---
---@field class "typst_subscript"
---@field parenthesis boolean Whether the text is surrounded by parenthesis.
---@field level integer Subscript level.
---@field text string[]
---@field range node.range
M.__typst_subscripts = {
	class = "typst_subscript",
	parenthesis = true,
	preview = true,
	level = 1,

	text = { "_{12}" },
	range = {
		row_start = 0,
		row_end = 0,

		col_start = 0,
		col_end = 5
	}
};

---@class __typst.superscripts
---
---@field class "typst_superscript"
---@field parenthesis boolean Whether the text is surrounded by parenthesis.
---@field level integer Superscript level.
---@field text string[]
---@field range node.range
M.__typst_subscripts = {
	class = "typst_superscript",
	parenthesis = true,
	preview = true,
	level = 1,

	text = { "^{12}" },
	range = {
		row_start = 0,
		row_end = 0,

		col_start = 0,
		col_end = 5
	}
};

---@class __typst.symbols
---
---@field class "typst_symbol"
---@field name string
---@field text string[]
---@field range node.range
M.__typst_symbols = {
	class = "typst_symbol",
	name = "alpha",

	text = { "alpha" },
	range = {
		row_start = 0,
		row_end = 0,

		col_start = 0,
		col_end = 5
	}
};

---@class __typst.text
---
---@field class "typst_text"
---@field text string[]
---@field range node.range
M.__typst_text = {
	class = "typst_text",

	text = { "1" },
	range = {
		row_start = 0,
		row_end = 0,

		col_start = 0,
		col_end = 1
	}
};

---@class __typst.terms
---
---@field class "typst_term"
---@field label string
---@field text string[]
---@field range inline_link.range
M.__typst_terms = {
	class = "typst_term",
	label = "Term",

	text = { "/ Term" },
	range = {
		row_start = 0,
		row_end = 0,

		col_start = 0,
		col_end = 6,

		label = { 0, 2, 0, 6 }
	}
}

 return M;
