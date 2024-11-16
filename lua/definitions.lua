---@meta

---•------------
--- Internals
---•------------

---@class markview.cached_state Cached autocmds for buffers
---
---@field [integer] { redraw: integer, delete: integer, splitview: integer }


---@class markview.states Various plugin states.
---
--- Stores autocmd IDs.
---@field autocmds { [string]: table }
---
--- Determines whether the plugin is enabled or not.
---@field enable boolean
---
--- Determines whether "hybrid mode" is enabled or not.
--- When `false`, hybrid mode is temporarily disabled.
---@field hybrid_mode boolean
---
--- Plugin states in different buffers.
--- Can be used to disable preview in specific buffers.
---@field buffer_states { [integer]: boolean }
---
--- Hybrid mode states in different buffers.
--- Can be used to disable hybrid mode in specific buffers.
---@field hybrid_states { [integer]: boolean }
---
---
--- When not `nil` represents the source buffer for "split view".
--- Should become `nil` when disabling "split view".
---@field splitview_source integer?
---
--- Buffer where the preview is shown.
--- It's text updates on every redraw cycle of the plugin.
---@field splitview_buffer integer?
---
--- Window where the preview is shown.
--- By default it's value is `nil`.
---@field splitview_window integer?

---•----------------
--- Configuration
---•----------------

---@class markview.configuration Configuration table for `markview.nvim`.
---
---@field highlight_groups table
---@field renderers table
---
---@field experimental markview.o.experimental
---@field preview markview.o.preview
---
---@field html markview.o.html
---@field latex table
---@field markdown markview.o.markdown
---@field markdown_inline markview.o.markdown_inline
---@field typst table
---@field yaml table

---@class markview.o.experimental
---
---@field file_byte_read integer
---@field list_empty_line_tolerance integer
---@field text_filetypes string[]?

---@class markview.o.preview
---
---@field enable_preview_on_attach boolean
---@field callbacks { [string]: function }
---@field debounce integer
---@field edit_distance [integer, integer]
---@field hybrid_modes string[]
---@field ignore_buftypes string[]
---@field ignore_node_classes table
---@field max_file_length integer
---@field render_distance integer
---@field splitview_winopts table


 ------------------------------------------------------------------------------------------


---@class TSNode.range
---
---@field row_start integer
---@field col_start integer
---
---@field row_end integer
---@field col_end integer

---•----------------
--- HTML
---•----------------

---@class markview.o.html HTML config table
---
---@field container_elements html.container_elements
---@field headings { enable: boolean, [string]: table }
---@field void_elements html.void_elements


---@class html.container_elements
---
---@field enable boolean
---@field [string] html.container_opts


---@class html.container_opts
---
---@field on_closing_tag? fun(item: { text: string, range: integer[] }):table|table
---@field closing_tag_offset? fun(range: integer[]):integer[]
---
---@field on_node? fun(item: __html.container_item):table|table
---@field node_offset? fun(range: integer[]):integer[]
---
---@field on_opening_tag? fun(item: { name: string, range: integer[] }):table|table
---@field opening_tag_offset? fun(range: integer[]): integer[]


---@class html.void_elements
---
---@field enable boolean
---@field [string] html.container_opts


---@class html.void_opts
---
---@field on_node? fun(item: __html.container_item):table|table
---@field node_offset? fun(range: integer[]):integer[]


 ------------------------------------------------------------------------------------------


---@class __html.container_item
---
---@field class "markview_container_element"
---@field closing_tag { text: string, range: integer[] }
---@field name string
---@field opening_tag { text: string, range: integer[] }
---@field text string[]
---@field range TSNode.range


---@class __html.heading_item
---
---@field class "html_heading"
---@field level integer
---@field text string[]
---@field range TSNode.range


---@class __html.void_item
---
---@field class "markview_void_element"
---@field name string
---@field text string[]
---@field range TSNode.range


---•----------------
--- LaTeX
---•----------------


---@class markview.o.latex
---
---@field blocks latex.blocks
---@field commands latex.commands
---@field escapes latex.escapes
---@field fonts latex.fonts
---@field inlines latex.inlines
---@field parenthesis latex.parenthesis
---@field subscripts latex.styles
---@field superscripts latex.styles
---@field symbols latex.symbols
---@field texts latex.texts


---@class latex.blocks
---
---@field hl? string
---@field pad_amount integer
---@field pad_char string
---@field text? string
---
---@field text_hl? string


---@class latex.commands
---
---@field enable boolean
---@field [string] command.opts


---@class command.opts
---
---@field command_offset? fun(range: integer[]): integer[]
---@field condition? fun(content: table): boolean
---@field on_args? command.arg_opts[]
---@field on_command? table | fun(content: table): table


---@class command.arg_opts
---
---@field after? table | fun(content: table): table
---@field after_offset? fun(range: integer[]): integer[]
---@field before? table | fun(content: table): table
---@field before_offset? fun(range: integer[]): integer[]
---@field content? table | fun(content: table): table
---@field content_offset? fun(range: integer[]): integer[]


---@class latex.escapes
---
---@field enable boolean
---@field hl? string


---@class latex.inlines
---
---@field corner_left? string
---@field corner_left_hl? string
---@field corner_right? string
---@field corner_right_hl? string
---@field hl? string
---@field padding_left? string
---@field padding_left_hl? string
---@field padding_right? string
---@field padding_right_hl? string


---@class latex.fonts
---
---@field enable boolean
---@field hl? string


---@class latex.parenthesis
---
---@field enable boolean


---@class latex.symbols
---
---@field enable boolean
---@field hl? string


---@class latex.styles
---
---@field enable boolean
---@field hl? string


---@class latex.texts
---
---@field enable boolean
---@field hl? string


 ------------------------------------------------------------------------------------------


---@class __latex.block
---
---@field class "latex_block"
---@field closed boolean
---@field inline boolean
---@field range TSNode.range
---@field text string[]


---@class __latex.command
---
---@field args command.segment[]
---@field class "latex_command"
---@field command command.segment
---@field range TSNode.range
---@field text string[]

---@class command.segment
---
---@field name string
---@field range integer[]


---@class __latex.escaped
---
---@field class "latex_escaped"
---@field range TSNode.range
---@field text string[]


---@class __latex.font
---
---@field class "latex_font"
---@field name string
---@field range font.range
---@field text string[]


---@class font.range
---
---@field font_start integer
---@field font_end integer
---
---@field row_start integer
---@field col_start integer
---
---@field row_end integer
---@field col_end integer


---@class __latex.inline
---
---@field class "latex_inline"
---@field closed boolean
---@field range TSNode.range
---@field text string[]


---@class __latex.parenthesis
---
---@field class "latex_parenthesis"
---@field range TSNode.range
---@field text string[]


---@class __latex.style
---
---@field class "latex_subscript" | "latex_superscript"
---@field level integer
---@field parenthesis boolean
---@field preview boolean
---@field range TSNode.range
---@field text string[]

---@class __latex.symbol
---
---@field class "latex_symbol"
---@field name string
---@field style string?
---@field range TSNode.range
---@field text string[]


---@class __latex.text
---
---@field class "latex_text"
---@field range TSNode.range
---@field text string[]

---@class __latex.word
---
---@field class "latex_word"
---@field range TSNode.range
---@field text string[]


---•----------------
--- Markdown
---•----------------


---@class markview.o.markdown
---
---@field block_quotes markdown.block_quotes
---@field code_blocks markdown.code_blocks
---@field headings markdown.headings
---@field horizontal_rules markdown.horizontal_rules
---@field list_items markdown.list_items
---@field metadata_minus markdown.metadata
---@field metadata_plus markdown.metadata
---@field tables markdown.tables


---@class markdown.block_quotes
---
---@field enable boolean
---@field default block_quotes.opts
---@field [string] block_quotes.opts


---@class block_quotes.opts
---
---@field border? string | string[]
---@field border_hl? string | string[]
---
---@field hl? string
---
---@field icon? string
---@field icon_hl? string
---
---@field preview? string
---@field preview_hl? string
---
---@field title? boolean


---@class markdown.code_blocks
---
---@field hl? string
---@field icons "devicons" | "mini" | "internal" | nil
---@field info_hl? string
---@field language_direction "left" | "right"
---@field language_hl? string
---@field language_names? { [string]: string }
---@field min_width integer
---@field pad_amount integer
---@field pad_char string
---@field sign? boolean
---@field sign_hl? string
---@field style "simple" | "block"


---@class markdown.headings
---
---@field enable boolean
---
---@field heading_1 headings.atx
---@field heading_2 headings.atx
---@field heading_3 headings.atx
---@field heading_4 headings.atx
---@field heading_5 headings.atx
---@field heading_6 headings.atx
---
---@field setext_1 headings.setext
---@field setext_2 headings.setext


---@class headings.atx
---
---@field align? "left" | "center" | "right"
---@field corner_left? string
---@field corner_left_hl? string
---@field corner_right? string
---@field corner_right_hl? string
---@field hl? string
---@field icon? string
---@field icon_hl? string
---@field padding_left? string
---@field padding_left_hl? string
---@field padding_right? string
---@field padding_right_hl? string
---@field sign? string
---@field sign_hl? string
---@field style "simple" | "label" | "icon"


---@class headings.setext
---
---@field border? string
---@field border_hl? string
---@field hl? string
---@field icon? string
---@field icon_hl? string
---@field style "simple" | "decorated"


---@class markdown.horizontal_rules
---
---@field enable boolean
---@field parts (horizontal_rules.text | horizontal_rules.repeating)[]


---@class horizontal_rules.repeating
---
---@field direction "left" | "right"
---@field hl? string[]
---@field repeat_amount integer | fun(buffer: integer): integer
---@field text string
---@field type "repeating"


---@class horizontal_rules.text
---
---@field hl? string
---@field text string
---@field type "text"


---@class markdown.list_items
---
---@field enable boolean
---@field indent_size integer
---
---@field marker_dot? table
---@field marker_minus? table
---@field marker_parenthesis? table
---@field marker_plus? table
---@field marker_star? table
---
---@field shift_width integer


---@class list_items.unordered
---
---@field add_padding? boolean
---@field conceal_on_checkboxes? boolean
---@field hl? string
---@field text string


---@class list_items.ordered
---
---@field add_padding? boolean
---@field conceal_on_checkboxes? boolean


---@class markdown.metadata
---
---@field border_bottom? string
---@field border_bottom_hl? string
---@field border_hl? string
---@field border_top? string
---@field border_top_hl? string
---@field hl? string
---
---@field enable boolean


---@class markdown.tables
---
---@field block_decorator boolean
---@field enable boolean
---@field hl table
---@field parts table
---@field use_virt_lines boolean


---@class tables.parts
---
---@field top string[]
---@field header string[]
---@field separator string[]
---@field row string[]
---@field bottom string[]
---
---@field overlap string[]
---
---@field align_left string
---@field align_right string
---@field align_center [ string, string ]


 ------------------------------------------------------------------------------------------


---@class __markdown.block_quote
---
---@field class "markdown_block_quote"
---@field callout? string
---@field text string[]
---@field title? string
---@field range block_quote.range


---@class block_quote.range
---
---@field callout_start? integer
---@field callout_end? integer
---
---@field row_start integer
---@field col_start integer
---
---@field row_end integer
---@field col_end integer
---
---@field title_start? integer
---@field title_end? integer


---@class __markdown.code_block
---
---@field class "markdown_code_block"
---@field info_string? string
---@field language string
---@field text string[]
---@field range code_block.range


---@class code_block.range
---
---@field info_start? integer
---@field info_end? integer
---
---@field lang_start? integer
---@field lang_end? integer
---
---@field row_start integer
---@field col_start integer
---
---@field row_end integer
---@field col_end integer


---@class __markdown.heading_atx
---
---@field class "markdown_atx_heading"
---@field marker string
---@field text string[]
---@field range TSNode.range


---@class __markdown.heading_setext
---
---@field class "markdown_setext_heading"
---@field marker string
---@field text string[]
---@field range TSNode.range


---@class __markdown.horizontal_rule
---
---@field class "markdown_hr"
---@field text string[]
---@field range TSNode.range


---@class __markdown.list_item
---
---@field candidates integer[]
---@field checkbox? string
---@field class "markdown_list_item"
---@field indent integer
---@field marker string
---@field text string[]
---@field range TSNode.range


---@class __markdown.metadata_minus
---
---@field class "markdown_metadata_minus"
---@field text string[]
---@field range TSNode.range


---@class __markdown.metadata_plus
---
---@field class "markdown_metadata_plus"
---@field text string[]
---@field range TSNode.range


---@class __markdown.table
---
---@field alignments string[]
---@field border_overlap boolean
---@field bottom_border boolean
---@field class "markdown_table"
---@field header table.column[]
---@field rows table.column[]
---@field separator table.column[]
---@field top_border boolean
---@field text string[]
---@field range TSNode.range


---@class table.column
---
---@field class "column" | "separator" | "missing_seperator"
---@field col_start integer
---@field col_end integer
---@field text string


---•----------------
--- Markdown Inline
---•----------------


---@class markview.o.markdown_inline
---
---@field block_references inline.item
---@field checkboxes inline.checkboxes
---@field emails inline.item
---@field embed_files inline.item
---@field entities table
---@field escapes { enable: boolean }
---@field footnotes inline.item
---@field highlights inline.item
---@field hyperlinks inline.item
---@field images inline.item
---@field inline_codes table
---@field internal_links inline.item
---@field uri_autolinks inline.item


---@class inline.checkboxes
---
---@field enable boolean
---@field checked { text: string, hl: string?, scope_hl: string? }
---@field unchecked { text: string, hl: string?, scope_hl: string? }
---@field [string] { text: string, hl: string?, scope_hl: string? }


---@class inline.item
---
---@field enable boolean
---@field default inline.item_config
---@field patterns? { [string]: inline.item_patterns }


---@class inline.item_patterns
---
---@field match_string string
---
---@field corner_left? string
---@field corner_left_hl? string
---@field corner_right? string
---@field corner_right_hl? string
---@field hl? string
---@field icon? string
---@field icon_hl? string
---@field padding_left? string
---@field padding_left_hl? string
---@field padding_right? string
---@field padding_right_hl? string


---@class inline.item_config
---
---@field corner_left? string
---@field corner_left_hl? string
---@field corner_right? string
---@field corner_right_hl? string
---@field hl? string
---@field icon? string
---@field icon_hl? string
---@field padding_left? string
---@field padding_left_hl? string
---@field padding_right? string
---@field padding_right_hl? string


 ------------------------------------------------------------------------------------------


---@class __inline.inline_code
---
---@field class "inline_code_span"
---
---@field text string
---@field range TSNode.range


---@class __inline.checkbox
---
---@field class "inline_checkbox"
---
---@field text string
---@field range TSNode.range


---@class __inline.link
---
---@field class string
---@field has_file? boolean
---
---@field description? string
---@field label? string
---
---@field range __inline.link_range
---@field text string


---@class __inline.link_range
---
---@field alias_start? integer
---@field alias_end? integer
---
---@field desc_start? integer
---@field desc_end? integer
---
---@field label_start integer
---@field label_end integer
---
---@field row_start integer
---@field col_start integer
---
---@field row_end integer
---@field col_end integer

--[[

--]]




