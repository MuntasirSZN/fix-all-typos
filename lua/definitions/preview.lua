---@meta

local M = {};

-- [ Markview | Preview options ] ---------------------------------------------------------

--- Preview configuration for `markview.nvim`.
---@class config.preview
---
--- Enables *preview* when attaching to new buffers.
---@field enable? boolean
--- Enables `hybrid mode` when attaching to new buffers.
---@field enable_hybrid_mode? boolean
---
--- Icon provider.
---@field icon_provider?
---| "internal" Internal icon provider.
---| "devicons" `nvim-web-devicons` as icon provider.
---| "mini" `mini.icons` as icon provider.
---
--- Callback functions.
---@field callbacks? preview.callbacks
--- VIM-modes where `hybrid mode` is enabled.
---@field hybrid_modes? string[]
--- Options that should/shouldn't be previewed in `hybrid_modes`.
---@field ignore_previews? preview.ignore
--- Clear lines around the cursor in `hybrid mode`, instead of nodes?
---@field linewise_hybrid_mode? boolean
--- VIM-modes where previews will be shown.
---@field modes? string[]
---
--- Debounce delay for updating previews.
---@field debounce? integer
--- Buffer filetypes where the plugin should attach.
---@field filetypes? string[]
--- Buftypes that should be ignored(e.g. nofile).
---@field ignore_buftypes? string[]
--- Maximum number of lines a buffer can have before switching to partial rendering.
---@field max_buf_lines? integer
---
--- Lines before & after the cursor that is considered being edited.
--- Edited content isn't rendered.
---@field edit_range? [ integer, integer ]
--- Lines before & after the cursor that is considered being previewed.
---@field draw_range? [ integer, integer ]
---
--- Window options for the `splitview` window.
--- See `:h nvim.open_win()`.
---@field splitview_winopts? table
M.preview = {
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

			for _, win in ipairs(wins) do
				--- Preferred conceal level should
				--- be 3.
				vim.wo[win].conceallevel = 3;
			end

			---_
		end,

		on_detach = function (_, wins)
			---+${lua}
			for _, win in ipairs(wins) do
				--- Only set `conceallevel`.
				--- `concealcursor` will be
				--- set via `on_hybrid_disable`.
				vim.wo[win].conceallevel = 0;
			end
			---_
		end,

		on_enable = function (_, wins)
			---+${lua}

			for _, win in ipairs(wins) do
				vim.wo[win].conceallevel = 3;
			end

			---_
		end,

		on_disable = function (_, wins)
			---+${lua}
			for _, win in ipairs(wins) do
				vim.wo[win].conceallevel = 0;
			end
			---_
		end,

		on_hybrid_enable = function (_, wins)
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
				vim.wo[win].concealcursor = concealcursor;
			end

			---_
		end,

		on_hybrid_disable = function (_, wins)
			---+${lua}

			---@type string[]
			local prev_modes = spec.get({ "preview", "modes" }, { fallback = {} });
			local concealcursor = "";

			for _, mode in ipairs(prev_modes) do
				if vim.list_contains({ "n", "v", "i", "c" }, mode) then
					concealcursor = concealcursor .. mode;
				end
			end

			for _, win in ipairs(wins) do
				vim.wo[win].concealcursor = concealcursor;
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
				if vim.list_contains(preview_modes, current_mode) then
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
};

-- [ Markview | Preview options > Callbacks ] ---------------------------------------------

--- Callback functions for specific events.
---@class preview.callbacks
---
--- Called when attaching to a buffer.
---@field on_attach? fun(buf: integer, wins: integer[]): nil
--- Called when detaching from a buffer.
---@field on_detach? fun(buf: integer, wins: integer[]): nil
---
--- Called when disabling preview of a buffer.
--- Also called when opening `splitview`.
---@field on_disable? fun(buf: integer, wins: integer[]): nil
--- Called when enabling preview of a buffer.
--- Also called when disabling `splitview`.
---@field on_enable? fun(buf: integer, wins: integer[]): nil
---
--- Called when disabling hybrid mode in a buffer.
--- > Called after `on_attach` when attaching to a buffer.
--- > Called after `on_disable`.
---@field on_hybrid_disable? fun(buf: integer, wins: integer[]): nil
--- Called when enabling hybrid mode in a buffer.
--- > Called after `on_attach`(if `hybrid_mod` is disabled).
--- > Called after `on_enable`.
---@field on_hybrid_enable? fun(buf: integer, wins: integer[]): nil
---
--- Called when changing VIM-modes(only on active buffers).
---@field on_mode_change? fun(buf: integer, wins: integer[], mode: string): nil
---
--- Called before closing splitview.
---@field on_splitview_close? fun(source: integer, preview_buf: integer, preview_win: integer): nil
--- Called when opening splitview.
---@field on_splitview_open? fun(source: integer, preview_buf: integer, preview_win: integer): nil
M.preview_callbacks = {
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

		for _, win in ipairs(wins) do
			--- Preferred conceal level should
			--- be 3.
			vim.wo[win].conceallevel = 3;
		end

		---_
	end,

	on_detach = function (_, wins)
		---+${lua}
		for _, win in ipairs(wins) do
			--- Only set `conceallevel`.
			--- `concealcursor` will be
			--- set via `on_hybrid_disable`.
			vim.wo[win].conceallevel = 0;
		end
		---_
	end,

	on_enable = function (_, wins)
		---+${lua}

		for _, win in ipairs(wins) do
			vim.wo[win].conceallevel = 3;
		end

		---_
	end,

	on_disable = function (_, wins)
		---+${lua}
		for _, win in ipairs(wins) do
			vim.wo[win].conceallevel = 0;
		end
		---_
	end,

	on_hybrid_enable = function (_, wins)
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
			vim.wo[win].concealcursor = concealcursor;
		end

		---_
	end,

	on_hybrid_disable = function (_, wins)
		---+${lua}

		---@type string[]
		local prev_modes = spec.get({ "preview", "modes" }, { fallback = {} });
		local concealcursor = "";

		for _, mode in ipairs(prev_modes) do
			if vim.list_contains({ "n", "v", "i", "c" }, mode) then
				concealcursor = concealcursor .. mode;
			end
		end

		for _, win in ipairs(wins) do
			vim.wo[win].concealcursor = concealcursor;
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
			if vim.list_contains(preview_modes, current_mode) then
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
};

-- [ Markview | Preview options > Ignore preview ] ----------------------------------------

--- Items to ignore when rendering.
---@class preview.ignore
---
---@field html? ignore_html[]
---@field latex? ignore_latex[]
---@field markdown? ignore_md[]
---@field markdown_inline? ignore_inline[]
---@field typst? ignore_typst[]
---@field yaml? ignore_yaml[]
M.preview_ignore = {
	markdown = { "!block_quotes", "!code_blocks" }
};

---+${lua}

---@alias ignore_html
---| "!container_elements"
---| "!headings"
---| "!void_elements"
---
---| "container_elements"
---| "headings"
---| "void_elements"

---@alias ignore_latex
---| "!blocks"
---| "!commands"
---| "!escapes"
---| "!fonts"
---| "!inlines"
---| "!parenthesis"
---| "!subscripts"
---| "!superscripts"
---| "!symbols"
---| "!texts"
---
---| "blocks"
---| "commands"
---| "escapes"
---| "fonts"
---| "inlines"
---| "parenthesis"
---| "subscripts"
---| "superscripts"
---| "symbols"
---| "texts"

---@alias ignore_md
---| "!block_quotes"
---| "!code_blocks"
---| "!headings"
---| "!horizontal_rules"
---| "!list_items"
---| "!metadata_minus"
---| "!metadata_plus"
---| "!reference_definitions"
---| "!tables"
---
---| "block_quotes"
---| "code_blocks"
---| "headings"
---| "horizontal_rules"
---| "list_items"
---| "metadata_minus"
---| "metadata_plus"
---| "reference_definitions"
---| "tables"
---
---| "checkboxes"

---@alias ignore_inline
---| "!block_references"
---| "!checkboxes"
---| "!emails"
---| "!embed_files"
---| "!entities"
---| "!escapes"
---| "!footnotes"
---| "!highlights"
---| "!hyperlinks"
---| "!images"
---| "!inline_codes"
---| "!internal_links"
---| "!uri_autolinks"
---
---| "block_references"
---| "checkboxes"
---| "emails"
---| "embed_files"
---| "entities"
---| "escapes"
---| "footnotes"
---| "highlights"
---| "hyperlinks"
---| "images"
---| "inline_codes"
---| "internal_links"
---| "uri_autolinks"

---@alias ignore_typst
---| "!code_blocks"
---| "!code_spans"
---| "!escapes"
---| "!headings"
---| "!labels"
---| "!list_items"
---| "!math_blocks"
---| "!math_spans"
---| "!raw_blocks"
---| "!raw_spans"
---| "!reference_links"
---| "!subscripts"
---| "!superscripts"
---| "!symbols"
---| "!terms"
---| "!url_links"
---
---| "code_blocks"
---| "code_spans"
---| "escapes"
---| "headings"
---| "labels"
---| "list_items"
---| "math_blocks"
---| "math_spans"
---| "raw_blocks"
---| "raw_spans"
---| "reference_links"
---| "subscripts"
---| "superscripts"
---| "symbols"
---| "terms"
---| "url_links"

---@alias ignore_yaml
---| "!properties"
---
---| "properties"

---_

return M;
