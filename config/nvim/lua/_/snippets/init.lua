local M = {}

local filetypes = {
	'all',
	'javascript',
	'typescript',
	'javascriptreact',
	'typescriptreact',
	'markdown',
	'html',
	'css',
}

local filetype_extensions = {
	{ 'jinja', { 'html', 'twig' } },
	{ 'jinja2', { 'html', 'twig' } },
	{ 'html.twig', { 'html', 'twig' } },
	{ 'typescriptreact', { 'html' } },
	{ 'javascriptreact', { 'html' } },
}

function M.setup()
	local ls = require 'luasnip'

	for _, extension in ipairs(filetype_extensions) do
		ls.filetype_extend(extension[1], extension[2])
	end

	for _, filetype in ipairs(filetypes) do
		ls.add_snippets(filetype, require('_.snippets.' .. filetype))
	end
end

return M
