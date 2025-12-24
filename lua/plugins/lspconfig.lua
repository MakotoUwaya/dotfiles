return {
  "neovim/nvim-lspconfig",
  event = { "BufReadPre", "BufNewFile" },
  dependencies = {
    "williamboman/mason.nvim",
    "williamboman/mason-lspconfig.nvim",
    "hrsh7th/cmp-nvim-lsp",
    { "folke/lazydev.nvim", ft = "lua", opts = {} },
  },
  opts = {
    servers = {
      lua_ls = {},
      omnisharp = {},
      ts_ls = {},
      html = {},
      lemminx = {
        filetypes = { "xml", "xsd", "xsl", "xslt", "svg", "xaml" },
      },
    },
  },
  config = function(_, opts)
    require("mason").setup()
    local mlsp = require("mason-lspconfig")
    local capabilities = require("cmp_nvim_lsp").default_capabilities()

    mlsp.setup({
      ensure_installed = vim.tbl_keys(opts.servers),
      handlers = {
        function(server_name)
          local server_opts = opts.servers[server_name] or {}
          server_opts.capabilities = capabilities
          require("lspconfig")[server_name].setup(server_opts)
        end,
      },
    })
  end,
}

