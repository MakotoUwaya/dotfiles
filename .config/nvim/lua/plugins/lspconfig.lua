return {
  'neovim/nvim-lspconfig',
  event = { 'BufReadPre', 'BufNewFile' },
  dependencies = {
    {
      'mason-org/mason.nvim',
      cmd = { 'Mason', 'MasonInstall', 'MasonUninstall', 'MasonLog' },
      opts = {
        registries = {
          'github:mason-org/mason-registry',
          'github:Crashdummyy/mason-registry',
        },
      },
    },
    'mason-org/mason-lspconfig.nvim',
    'hrsh7th/cmp-nvim-lsp',
    { 'folke/lazydev.nvim', ft = 'lua', opts = {} },
  },
  config = function()
    vim.api.nvim_create_autocmd('LspAttach', {
      callback = function(args)
        local bufnr = args.buf
        local client = vim.lsp.get_client_by_id(args.data.client_id)
        local keymap = function(mode, lhs, rhs, desc)
          vim.keymap.set(mode, lhs, rhs, { buffer = bufnr, desc = desc })
        end

        keymap('n', '[d', function() vim.diagnostic.jump({ count = -1 }) end, 'Go to previous diagnostic')
        keymap('n', ']d', function() vim.diagnostic.jump({ count = 1 }) end, 'Go to next diagnostic')
        keymap('n', 'gl', vim.diagnostic.open_float, 'Show diagnostic error')

        keymap('n', 'gd', vim.lsp.buf.definition, 'Go to definition')
        keymap('n', 'K', vim.lsp.buf.hover, 'Show hover documentation')
        keymap('n', '<leader>rn', vim.lsp.buf.rename, 'Rename symbol')
        keymap('n', '<leader>ca', vim.lsp.buf.code_action, 'Code action')

        if client and client.name == 'eslint' then
          vim.api.nvim_create_autocmd('BufWritePre', {
            buffer = bufnr,
            callback = function()
              pcall(function()
                vim.cmd('EslintFixAll')
              end)
            end,
          })
        end
      end,
    })

    local capabilities = require('cmp_nvim_lsp').default_capabilities()
    vim.lsp.config('*', { capabilities = capabilities })

    local util = require('lspconfig.util')
    local js_root = util.root_pattern('package.json', '.eslintrc.js', '.eslintrc.json', '.git')
    local js_root_servers = {
      'eslint', 'lua_ls', 'ts_ls', 'html', 'cssls', 'lemminx',
      'yamlls', 'dockerls', 'docker_compose_language_service',
    }
    for _, name in ipairs(js_root_servers) do
      vim.lsp.config(name, { root_dir = js_root })
    end

    vim.lsp.config('eslint', {
      settings = { workingDirectories = { mode = 'auto' } },
    })
    vim.lsp.config('lemminx', {
      filetypes = { 'xml', 'xsd', 'xsl', 'xslt', 'svg', 'xaml' },
    })

    require('mason-lspconfig').setup({
      ensure_installed = {
        'eslint', 'lua_ls', 'ts_ls', 'html', 'cssls', 'lemminx',
        'yamlls', 'dockerls', 'docker_compose_language_service',
        'gopls', 'rust_analyzer', 'bashls', 'sqlls', 'basedpyright', 'ruff',
      },
      automatic_enable = true,
    })
  end,
}
