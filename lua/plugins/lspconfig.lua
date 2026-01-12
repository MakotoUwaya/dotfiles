return {
  'neovim/nvim-lspconfig',
  event = { 'BufReadPre', 'BufNewFile' },
  dependencies = {
    'williamboman/mason.nvim',
    'williamboman/mason-lspconfig.nvim',
    'hrsh7th/cmp-nvim-lsp',
    { 'folke/lazydev.nvim', ft = 'lua', opts = {} },
  },
  opts = {
    servers = {
      eslint = {
        settings = { workingDirectories = { mode = 'auto' } },
      },
      -- 警告回避のため、余計な設定を削除して空にします
      lua_ls = {},
      omnisharp = {},
      ts_ls = {},
      html = {},
      lemminx = {
        filetypes = { 'xml', 'xsd', 'xsl', 'xslt', 'svg', 'xaml' },
      },
    },
  },
  config = function(_, opts)
    local lspconfig = require('lspconfig')
    local util = require('lspconfig.util')

    vim.api.nvim_create_autocmd('LspAttach', {
      callback = function(args)
        local bufnr = args.buf
        local client = vim.lsp.get_client_by_id(args.data.client_id)
        local keymap = function(mode, lhs, rhs, desc)
          vim.keymap.set(mode, lhs, rhs, { buffer = bufnr, desc = desc })
        end

        -- 【最新の診断情報ジャンプ】
        -- 非推奨の goto_prev / goto_next を jump に変更
        keymap('n', '[d', function() vim.diagnostic.jump({ count = -1 }) end, 'Go to previous diagnostic')
        keymap('n', ']d', function() vim.diagnostic.jump({ count = 1 }) end, 'Go to next diagnostic')
        keymap('n', 'gl', vim.diagnostic.open_float, 'Show diagnostic error')

        -- 【LSP基本操作】
        keymap('n', 'gd', vim.lsp.buf.definition, 'Go to definition')
        keymap('n', 'K', vim.lsp.buf.hover, 'Show hover documentation')
        keymap('n', '<leader>rn', vim.lsp.buf.rename, 'Rename symbol')
        keymap('n', '<leader>ca', vim.lsp.buf.code_action, 'Code action')

        if client and client.name == 'eslint' then
          vim.api.nvim_create_autocmd('BufWritePre', {
            buffer = bufnr,
            callback = function()
              -- pcall を使うことで、エラーが発生しても無視して保存を続行します
              pcall(function()
                vim.cmd('EslintFixAll')
              end)
            end,
          })
        end
      end,
    })

    require('mason').setup()
    local capabilities = require('cmp_nvim_lsp').default_capabilities()

    require('mason-lspconfig').setup({
      ensure_installed = vim.tbl_keys(opts.servers),
      handlers = {
        function(server_name)
          local server_opts = opts.servers[server_name] or {}
          server_opts.capabilities = vim.deepcopy(capabilities)
          server_opts.root_dir = server_opts.root_dir or util.root_pattern(
            'package.json', '.eslintrc.js', '.eslintrc.json', '.git'
          )
          lspconfig[server_name].setup(server_opts)
        end,
      },
    })
  end,
}
