-- init.lua — minimal neovim (no plugin manager; uses built-ins only)
-- Modern defaults (Nix 24.05+ ships neovim with lua goodies).

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
vim.opt.hlsearch = false          -- no highlight after search
vim.opt.incsearch = true
vim.opt.swapfile = false
vim.opt.termguicolors = true
vim.opt.signcolumn = "yes"
vim.opt.updatetime = 250
vim.opt.scrolloff = 4
vim.opt.splitright = true
vim.opt.splitbelow = true
vim.opt.clipboard = "unnamedplus" -- use system clipboard (niri/wl-clipboard)

-- Appearance (tinted dark; adjusted by wallpaper palette if you set it)
vim.cmd("set background=dark")

-- Keymaps (leader = space)
local map = vim.keymap.set
local opts = { noremap = true, silent = true }
map("n", "<leader>e", vim.cmd.Ex, opts)                 -- netrw file manager
map("n", "<leader>w", "<cmd>w<CR>", opts)
map("n", "<leader>q", "<cmd>q<CR>", opts)
map("n", "<leader>h", "<cmd>noh<CR>", opts)             -- clear search highlight
map("v", "K", ":m '<-2<CR>gv=gv", opts)                 -- move line up
map("v", "J", ":m '>+1<CR>gv=gv", opts)                 -- move line down
map("n", "J", "mzJ`z", opts)                            -- join without jump

-- Better buffers
vim.keymap.set("n", "<C-p>", "<cmd>buffer #<CR>", opts) -- jump to last buffer

-- Neovim set-format
vim.filetype.add({ extension = { nix = "nix", razor = "cshtml" } })

-- LSP + Treesitter: enable only if the plugins are present (nixpkgs option).
pcall(function()
  require("lspconfig")
  require("nvim-treesitter.configs").setup({
    highlight = { enable = true },
  })
end)