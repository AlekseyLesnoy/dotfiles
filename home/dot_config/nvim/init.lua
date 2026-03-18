-- ~/.config/nvim/init.lua — managed by chezmoi
-- Bootstrap lazy.nvim

local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not (vim.uv or vim.loop).fs_stat(lazypath) then
    local lazyrepo = "https://github.com/folke/lazy.nvim.git"
    local out = vim.fn.system({
        "git", "clone", "--filter=blob:none", "--branch=stable",
        lazyrepo, lazypath,
    })
    if vim.v.shell_error ~= 0 then
        vim.api.nvim_echo({
            { "Failed to clone lazy.nvim:\n", "ErrorMsg" },
            { out,                             "WarningMsg" },
            { "\nPress any key to continue...", "" },
        }, true, {})
        vim.fn.getchar()
        os.exit(1)
    end
end
vim.opt.rtp:prepend(lazypath)

-- ─── Core options ──────────────────────────────────────────────────────────
vim.g.mapleader      = " "
vim.g.maplocalleader = "\\"

vim.opt.number         = true
vim.opt.relativenumber = true
vim.opt.tabstop        = 4
vim.opt.shiftwidth     = 4
vim.opt.expandtab      = true
vim.opt.smartindent    = true
vim.opt.wrap           = false
vim.opt.swapfile       = false
vim.opt.backup         = false
vim.opt.undofile       = true
vim.opt.hlsearch       = false
vim.opt.incsearch      = true
vim.opt.termguicolors  = true
vim.opt.scrolloff      = 8
vim.opt.signcolumn     = "yes"
vim.opt.updatetime     = 50
vim.opt.splitright     = true
vim.opt.splitbelow     = true
vim.opt.clipboard      = "unnamedplus"

-- ─── Plugins ──────────────────────────────────────────────────────────────
require("lazy").setup({
    -- Colorscheme
    {
        "catppuccin/nvim",
        name     = "catppuccin",
        priority = 1000,
        config   = function()
            require("catppuccin").setup({ flavour = "mocha" })
            vim.cmd.colorscheme("catppuccin")
        end,
    },

    -- File tree
    {
        "nvim-neo-tree/neo-tree.nvim",
        branch = "v3.x",
        dependencies = {
            "nvim-lua/plenary.nvim",
            "nvim-tree/nvim-web-devicons",
            "MunifTanjim/nui.nvim",
        },
        keys = {
            { "<leader>e", "<cmd>Neotree toggle<cr>", desc = "Toggle NeoTree" },
        },
    },

    -- Fuzzy finder
    {
        "nvim-telescope/telescope.nvim",
        branch = "0.1.x",
        dependencies = {
            "nvim-lua/plenary.nvim",
            { "nvim-telescope/telescope-fzf-native.nvim", build = "make" },
        },
        config = function()
            local t = require("telescope")
            t.setup({})
            t.load_extension("fzf")
        end,
        keys = {
            { "<leader>ff", "<cmd>Telescope find_files<cr>",  desc = "Find files" },
            { "<leader>fg", "<cmd>Telescope live_grep<cr>",   desc = "Live grep" },
            { "<leader>fb", "<cmd>Telescope buffers<cr>",     desc = "Buffers" },
            { "<leader>fh", "<cmd>Telescope help_tags<cr>",   desc = "Help tags" },
        },
    },

    -- Treesitter
    {
        "nvim-treesitter/nvim-treesitter",
        build = ":TSUpdate",
        config = function()
            require("nvim-treesitter.configs").setup({
                ensure_installed = { "lua", "vim", "vimdoc", "bash", "python",
                                     "javascript", "typescript", "go", "rust", "toml", "yaml", "json" },
                highlight = { enable = true },
                indent    = { enable = true },
            })
        end,
    },

    -- LSP
    {
        "neovim/nvim-lspconfig",
        dependencies = {
            "williamboman/mason.nvim",
            "williamboman/mason-lspconfig.nvim",
        },
        config = function()
            require("mason").setup()
            require("mason-lspconfig").setup({
                ensure_installed = { "lua_ls", "pyright", "ts_ls", "gopls", "rust_analyzer" },
                automatic_installation = true,
            })
            local lsp = require("lspconfig")
            local capabilities = require("cmp_nvim_lsp").default_capabilities()
            local servers = { "lua_ls", "pyright", "ts_ls", "gopls", "rust_analyzer" }
            for _, srv in ipairs(servers) do
                lsp[srv].setup({ capabilities = capabilities })
            end
        end,
    },

    -- Autocompletion
    {
        "hrsh7th/nvim-cmp",
        dependencies = {
            "hrsh7th/cmp-nvim-lsp",
            "hrsh7th/cmp-buffer",
            "hrsh7th/cmp-path",
            "L3MON4D3/LuaSnip",
            "saadparwaiz1/cmp_luasnip",
        },
        config = function()
            local cmp     = require("cmp")
            local luasnip = require("luasnip")
            cmp.setup({
                snippet = { expand = function(args) luasnip.lsp_expand(args.body) end },
                mapping = cmp.mapping.preset.insert({
                    ["<C-b>"]     = cmp.mapping.scroll_docs(-4),
                    ["<C-f>"]     = cmp.mapping.scroll_docs(4),
                    ["<C-Space>"] = cmp.mapping.complete(),
                    ["<C-e>"]     = cmp.mapping.abort(),
                    ["<CR>"]      = cmp.mapping.confirm({ select = true }),
                    ["<Tab>"]     = cmp.mapping(function(fallback)
                        if cmp.visible() then cmp.select_next_item()
                        elseif luasnip.expand_or_jumpable() then luasnip.expand_or_jump()
                        else fallback() end
                    end, { "i", "s" }),
                }),
                sources = cmp.config.sources({
                    { name = "nvim_lsp" },
                    { name = "luasnip" },
                    { name = "buffer" },
                    { name = "path" },
                }),
            })
        end,
    },

    -- Status line
    {
        "nvim-lualine/lualine.nvim",
        dependencies = { "nvim-tree/nvim-web-devicons" },
        config = function()
            require("lualine").setup({ options = { theme = "catppuccin" } })
        end,
    },

    -- Git signs
    {
        "lewis6991/gitsigns.nvim",
        config = function() require("gitsigns").setup() end,
    },

    -- Auto-pairs
    {
        "windwp/nvim-autopairs",
        event  = "InsertEnter",
        config = function() require("nvim-autopairs").setup() end,
    },

    -- Comment toggle
    {
        "numToStr/Comment.nvim",
        config = function() require("Comment").setup() end,
    },

    -- Which-key
    {
        "folke/which-key.nvim",
        event  = "VeryLazy",
        config = function() require("which-key").setup() end,
    },
}, {
    ui = {
        icons = vim.g.have_nerd_font and {} or {
            cmd = "⌘", config = "🛠", event = "📅", ft = "📂",
            init = "⚙", keys = "🗝", plugin = "🔌", runtime = "💻",
            require = "🌙", source = "📄", start = "🚀", task = "📌",
            lazy = "💤",
        },
    },
})

-- ─── Keymaps ──────────────────────────────────────────────────────────────
local map = vim.keymap.set
map("n", "<C-h>", "<C-w><C-h>", { desc = "Move to left window" })
map("n", "<C-l>", "<C-w><C-l>", { desc = "Move to right window" })
map("n", "<C-j>", "<C-w><C-j>", { desc = "Move to lower window" })
map("n", "<C-k>", "<C-w><C-k>", { desc = "Move to upper window" })
map("n", "<leader>q", "<cmd>q<cr>",  { desc = "Quit" })
map("n", "<leader>w", "<cmd>w<cr>",  { desc = "Write" })
map("n", "<leader>bd", "<cmd>bd<cr>", { desc = "Delete buffer" })
map("v", "<", "<gv", { desc = "Indent left" })
map("v", ">", ">gv", { desc = "Indent right" })
