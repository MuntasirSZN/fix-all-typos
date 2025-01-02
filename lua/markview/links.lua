--- A simple link opener for `markview.nvim`.
---
--- This is a `tree-sitter` based wrapper
--- for `vim.ui.input()`.
---
--- Features:
---     • Flexible enough to work on any
---       of the supported nodes.
---     • Opens text files/selected filetypes
---       inside **Neovim**.
---     • Multiple file open methods.
local links = {};
local spec = require("markview.spec");

--- Opens an address via `vim.ui.open()`.
---@param address string
links.__open_in_app = function (address)
	---+${lua}

	local cmd, err = vim.ui.open(address);

	if err then
		spec.notify({
			{ "Failed to open " },
			{ " " .. link.address .. " ", "DiagnosticVirtualTextInfo" }
		})

		return;
	end

	if cmd then
		cmd:wait();
		return;
	end
	---_
end

--- Opens a file inside **Neovim**.
---@param address string
links.__open_in_nvim = function (address)
	---+${lua}

	local cmd = spec.get({ "experimental", "file_open_command" }, { fallback = "tab" });
	local _, err = pcall(function ()
		vim.cmd(cmd .. " " .. address);
	end);

	if err then
		spec.notify({
			{ "Failed to open " },
			{ " " .. address .. " ", "DiagnosticVirtualTextInfo" }
		})

		return;
	end
	---_
end

--- Internal function that handles
--- opening links.
---@param address string?
links.__open = function (address)
	--++${lua}

	if not address then
		return;
	end

	if spec.get({ "experimental", "link_open_alerts" }, { fallback = false }) then
		spec.notify({
			{ "Opening " },
			{ " " .. address .. " ", "DiagnosticVirtualTextInfo" }
		}, {
			level = vim.log.levels.INFO
		})
	end

	local extension = vim.fn.fnamemodify(address, ":e");

	if spec.get({ "experimental", "text_filetypes" }, { fallback = nil }) then
		---+${default, Configuration for filetypes to open in nvim exists}
		local in_nvim = spec.get({ "experimental", "text_filetypes" }, { fallback = nil });

		if
			not address:match("^http") and
			not address:match("^www%.") and

			vim.list_contains(in_nvim, extension)
		then
			links.__open_in_nvim(address);
		else
			links.__open_in_app(address);
		end
		---_
		return;
	end

	local file = io.open(address, "rb");

	if not file then
		links.__open_in_app(address);
		return;
	end

	local read_bytes = spec.get({ "experimental", "read_chunk_size" }, { fallback = 1024 });
	local bytes = file:read(read_bytes);
	file:close();

	for b = 1, #bytes do
		local byte = bytes:byte(b);

		if
			byte < 32 and
			not vim.list_contains({ 9, 10, 13 }, byte)
		then
			links.__open_in_app(address);
			return;
		end
	end

	links.__open_in_nvim(address);
	---_
end

--- Opens an inline link.
--- Example: `[text](https://www.neovim.org)`
---@param node table
---@param buffer integer
links.inline_link = function (node, buffer)
	local to = node:child(4);
	if not to then return; end

	links.__open(vim.treesitter.get_node_text(to, buffer))
end;

--- Opens an image link.
--- Example: `![text](https://www.neovim.org)`
---@param node table
---@param buffer integer
links.image = function (node, buffer)
	local to = node:child(5);
	if not to then return; end

	links.__open(vim.treesitter.get_node_text(to, buffer))
end;

--- Opens an shortcut link.
--- Example: `[https://www.neovim.org]`
---@param node table
---@param buffer integer
links.shortcut_link = function (node, buffer)
	local to = node:child(1);
	if not to then return; end

	local address = vim.treesitter.get_node_text(to, buffer);
	if address:match("|") then
		address = address:match("^([^%|]+)%|");
	elseif address:match("%#%^") then
		address = address:match("^(.+)%#%^");
	end

	links.__open(address)
end

--- Opens an uri_autolink.
--- Example: `<https://www.neovim.org>`
---@param node table
---@param buffer integer
links.uri_autolink = function (node, buffer)
	local to = node;
	if not to then return; end

	links.__open(
		vim.treesitter.get_node_text(to, buffer):gsub("^%<", ""):gsub("%>$", "")
	);
end;

--- Opens the link under the cursor.
---
--- Initially uses tree-sitter to find
--- a valid link.
---
--- Fallback to the `<cfile>` if no node
--- was found.
links.open = function ()
	---+${lua}

	local utils = require("markview.utils");
	local buffer = vim.api.nvim_get_current_buf();
	local node;

	if
		vim.treesitter.language.get_lang(vim.bo[buffer].ft) == nil or
		utils.parser_installed(vim.treesitter.language.get_lang(vim.bo[buffer].ft)) == false
	then
		goto language_not_found;
	end

	node = vim.treesitter.get_node({
		ignore_injections = false
	});

	while node do
		if links[node:type()] then
			links[node:type()](node, buffer);
			return;
		end

		node = node:parent();
	end

	::language_not_found::

	if not vim.fn.expand("<cfile>") then return; end

	if spec.get({ "experimental", "link_open_alerts" }, { fallback = false }) then
		spec.notify({
			{ "Opening " },
			{ " " .. vim.fn.expand("<cfile>") .. " ", "DiagnosticVirtualTextInfo" }
		}, {
			level = vim.log.levels.INFO
		})
	end

	links.__open_in_app(vim.fn.expand("<cfile>"));
	---_
end

return links;
