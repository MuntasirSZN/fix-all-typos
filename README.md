!<h1 align="center">☄️ Markview.nvim</h1>

<p align="center">
    A powerful Markdown, HTML, LaTeX, Typst & YAML previewer for Neovim.
</p>


<!-- Image here -->


## 📖 Features

Markview provides a large set of features,

### 🌐 HTML

- HTML heading(e.g. `<h1>`) support.
- User defined block-element & void-element decorations.

### 🧮 LaTeX

- 7 Basic math font support.
- 2056 LaTeX math symbols.
- LaTeX command support(e.g. `\frac{}{}`).
- Unicode-based *subscript* & *superscript* support with limited math symbol support.
- `\text{}` block support.

### 📝 Markdown

- Atx & Setext heading support.
- Block quote, callout & alert support.
- Code block & inline code support.
- Checkbox support with ability to add custom states.
- Custom horizontal rule.
- Entity reference(853 entity no. & 786 entity names).
- Footnote support.
- Ordered & Unordered list item support.
- Email, Hyperlink, Image & URI autolink support.
- Block reference, Embed file & Internal link support. Also supports aliases.
- Minus & Plus metadata support.
- Table support with *auto-resizing* preview columns.

### 🌟 Typst

- 932 Typst symbols & 39 shorthands support.
- Typst code support.
- Typst heading support.
- Label support.
- Typst List item support.
- Math section support.
- Reference support.
- URL link support.
- Terminology support.

### 🧩 YAML

- Property name based icon preview.

### 💻 Previewing

- **Hybrid mode** to allow editing & previewing together.
- **Splitview** to preview in a separate window.
- Conditional previewing based on VIM-mode.
- Ability to selectively conceal specific nodes.
- Partial rendering on large files.

### 🔋 Extras

- `checkbox.lua`, allows changing & toggling checkboxes.
- `editor.lua`, create & edit code blocks without losing LSP features.
- `headings.lua`, change *multiple* heading levels with a single helper function.

## 📐 Requirements

- Neovim version, `0.10.1` or higher.
- Tree-sitter parsers,
  - markdown
  - markdown_inline
  - html, *optional*.
  - latex, *optional*.
  - typst, *optional*.
  - yaml, *optional*.
- Nerd font, *optional*.
- Tree-sitter supported colorscheme, *optional*.

## 📦 Installation

### 💤 Lazy.nvim 

```lua
{
    "OXY2DEV/markview.nvim",
    lazy = false,

    dependencies = {
        --- In case you installed the parsers via
        --- `nvim-treesitter` and are lazy loading.
        "nvim-treesitter/nvim-treesitter",

        --- Icon provider(for code blocks)
        --- "nvim-tree/nvim-web-devicons"
        --- "echasnovski/mini.icons"
    }
}
```

### 🦠 Mini.deps

```lua
local MiniDeps = require("mini.deps");

MiniDeps.add({
    source = "OXY2DEV/markview.nvim",

    depends = {
        "nvim-treesitter/nvim-treesitter",

        --- Icon provider(for code blocks)
        --- "nvim-tree/nvim-web-devicons"
        --- "echasnovski/mini.icons"
    }
});
```

### 🌒 Rocks.nvim

```vim
:Rocks install markview.nvim
```

### 📦 Vim plug

```vim
Plug "nvim-treesitter/nvim-treesitter"
Plug "OXY2DEV/markview.nvim"
```

## 🪷 Commands

Markview provides a single command `:Markview`. It supports the following sub commands,

| Sub-command | Accepts argument? | Default argument | Description |
|:------------|:-:|:-:|:----------|
| `attach` | true | 0 | Attaches the plugin to a buffer. |
| `detach` | true | 0 | Detaches from an attached buffer. |
| | | | •--•--•--•--•--•--•--•--• |
| `toggle` | true | 0 | Toggles *preview* on the specified buffer. |
| `enable` | true | 0 | Enables *preview* on the specified buffer. |
| `disable` | true | 0 | Disables *preview* on the specified buffer. |
| | | | •--•--•--•--•--•--•--•--• |
| `Toggle` | false | nil | Toggles plugin state. |
| `Enable` | false | nil | Enables the plugin. |
| `Disable` | false | nil | Disables the plugin. |
| | | | •--•--•--•--•--•--•--•--• |
| `splitToggle` | true | 0 | Toggles *splitview*. |
| `splitEnable` | true | 0 | Opens *splitview* for the current buffer. |
| `splitDisable` | false | nil | Closes *splitview* window. |
| `splitRedraw` | false | nil | Redraws the *splitview* window. |
| | | | •--•--•--•--•--•--•--•--• |
| `toggleAll` | false | nil | **Deprecated!** Same as `Toggle`. |
| `enableAll` | false | nil | **Deprecated!** Same as `Enable`. |
| `disableAll` | false | nil | **Deprecated!** Same as `Disable`. |

Sub-commands that support an *argument* can take a buffer ID as the argument for it.

>[!TIP]
> Completion for buffer IDs are provided by this plugin too!

>[!NOTE]
> When `:Markview` is called without any argument(s), it runs `:Markview Toggle`.

## 💮 Configuration

Check [the wiki]() to see the entire configuration table.

<details>
    <summary>Simplified configuration table.</summary><!--+ -->

```lua
{
    --- Test feature(s) options.
    experimental = {
        --- Number of bytes to check to
        --- see if a file is a text file
        --- or not.
        --- Used by the internal link
        --- opener.
        ---
        --- Warning: Disabled if
        --- `text_filetypes` is not nil.
        file_byte_read = 1000,
        --- List of filetypes to open
        --- inside Neovim.
        --- Used by the internal link
        --- opener to only open specific
        --- type of files inside Neovim.
        ---
        --- Warning: This disables the use
        --- of `file_byte_read`.
        text_filetypes = nil,
        --- Amount of empty lines that can
        --- be inside a list item.
        list_empty_line_tolerance = 3
    },

    --- List of highlight groups.
    highlight_groups = {},

    --- Previewing related options.
    preview = {
        --- Callback functions for various
        --- events. See docs.
        callbacks = {},

        --- Debounce delay for rendering.
        debounce = 50,

        --- Lines above, below the cursor
        --- that are considered being "edited".
        ---
        --- Nodes inside `edit_distance` won't
        --- rendered.
        edit_distance = { 1, 0 },

        --- When `true`, previews are enabled
        --- on newly attached buffers.
        enable_preview_on_attach = true,

        --- List of filetypes where the plugin
        --- will be enabled.
        filetypes = { "markdown", "typst" },

        --- List of VIM modes where hybrid mode
        --- is used.
        hybrid_modes = {},

        --- Buffer types to ignore.
        ignore_buftypes = { "nofile" },

        --- Node classes that will show their
        --- previews even inside `edit_distance`.
        ---
        --- See the wiki for more jnfo.
        ignore_node_classes = {
            -- markdown = { "code_blocks" }
        },

        --- Maximum line count of a file for the
        --- plugin to render the entire buffer
        --- instead of only rendering part of it.
        max_file_length = 1000,

        --- List of VIM-modes where the rendering
        --- is enabled.
        modes = { "n", "no", "c" },

        --- Amount of lines surrounding the cursor
        --- to render on files where the line count
        --- exceeds `max_file_length`.
        render_distance = vim.o.lines,

        --- Window options for the splitview window.
        splitview_winopts = {
            split = "right"
        }
    },

    --- Custom renderers.
    renderers = {},

    --- Options for various language previews.
    --- See the wiki.
    html = {},
    latex = {},
    markdown = {},
    markdown_inline = {},
    typst = {},
    yaml = {},
}
```

<!--_-->
</details>


