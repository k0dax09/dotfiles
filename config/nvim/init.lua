-- init.lua — minimal neovim (no plugin manager; uses built-ins only)

vim.g.mapleader = " "
vim.g.maplocalleader = " "

-- Options
vim.opt.number = true
vim.opt.relativenumber = true
vim.opt.tabstop = 4
vim.opt.shiftwidth = 4
vim.opt.expandtab = true
vim.opt.autoindent = true
vim.opt.smartindent = true
vim.opt.wrap = false
vim.opt.ignorecase = true
vim.opt.smartcase = true
vim.opt.hlsearch = false
vim.opt.incsearch = true
vim.opt.swapfile = false
vim.opt.termguicolors = true
vim.opt.signcolumn = "yes"
vim.opt.updatetime = 250
vim.opt.scrolloff = 4
vim.opt.splitright = true
vim.opt.splitbelow = true
vim.opt.clipboard = "unnamedplus"

vim.cmd("set background=dark")

-- ── Мини-палитра tokyonight-storm (без плагинов) ──────────
local p = {
  bg      = "#1a1b26",
  bg_alt  = "#24283b",
  surface = "#292e42",
  fg      = "#c0caf5",
  muted   = "#565f89",
  accent  = "#7aa2f7",
  red     = "#f7768e",
  green   = "#9ece6a",
  yellow  = "#e0af68",
  cyan    = "#7dcfff",
  magenta = "#bb9af7",
}

local hl = function(group, opts) vim.api.nvim_set_hl(0, group, opts) end

hl("Normal",        { fg = p.fg,      bg = p.bg })
hl("NormalFloat",   { fg = p.fg,      bg = p.surface })
hl("CursorLine",    { bg = p.bg_alt })
hl("CursorLineNr",  { fg = p.accent,  bold = true })
hl("LineNr",        { fg = p.muted })
hl("SignColumn",    { bg = p.bg })
hl("Visual",        { bg = p.surface })
hl("Search",        { bg = p.yellow, fg = p.bg })
hl("IncSearch",     { bg = p.accent, fg = p.bg })
hl("MatchParen",    { fg = p.magenta, bold = true, underline = true })
hl("Pmenu",         { fg = p.fg, bg = p.surface })
hl("PmenuSel",      { fg = p.bg, bg = p.accent })
hl("Comment",       { fg = p.muted, italic = true })
hl("Keyword",       { fg = p.magenta })
hl("Function",      { fg = p.accent })
hl("String",        { fg = p.green })
hl("Number",        { fg = p.yellow })
hl("Type",          { fg = p.cyan })
hl("Constant",      { fg = p.yellow })
hl("Statement",     { fg = p.magenta })
hl("Identifier",    { fg = p.fg })
hl("PreProc",       { fg = p.cyan })
hl("Todo",          { fg = p.bg, bg = p.yellow, bold = true })
hl("Error",         { fg = p.red })
hl("WarningMsg",    { fg = p.yellow })
hl("StatusLine",    { fg = p.fg, bg = p.bg_alt })
hl("StatusLineNC",  { fg = p.muted, bg = p.bg_alt })
hl("VertSplit",     { fg = p.surface, bg = p.bg })
hl("TabLine",       { fg = p.muted, bg = p.bg_alt })
hl("TabLineSel",    { fg = p.bg, bg = p.accent, bold = true })
hl("WinSeparator",  { fg = p.surface })

-- Keymaps
local map = vim.keymap.set
local opts = { noremap = true, silent = true }
map("n", "<leader>e", vim.cmd.Ex, opts)
map("n", "<leader>w", "<cmd>w<CR>", opts)
map("n", "<leader>q", "<cmd>q<CR>", opts)
map("n", "<leader>h", "<cmd>noh<CR>", opts)
map("v", "K", ":m '<-2<CR>gv=gv", opts)
map("v", "J", ":m '>+1<CR>gv=gv", opts)
map("n", "J", "mzJ`z", opts)
vim.keymap.set("n", "<C-p>", "<cmd>buffer #<CR>", opts)

vim.filetype.add({ extension = { nix = "nix" } })

pcall(function()
  require("lspconfig")
  require("nvim-treesitter.configs").setup({
    highlight = { enable = true },
  })
end)
