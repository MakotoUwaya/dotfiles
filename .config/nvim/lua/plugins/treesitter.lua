return {
  'nvim-treesitter/nvim-treesitter',
  branch = 'master',
  event = { 'BufReadPost', 'BufNewFile' },
  build = ':TSUpdate',
  config = function(_, opts)
    -- Windows 環境では zig を C コンパイラとして使用する
    if vim.fn.has('win32') == 1 then
      require('nvim-treesitter.install').compilers = { 'zig' }
    end
    require('nvim-treesitter.configs').setup(opts)
  end,
  opts = {
    ensure_installed = {
      'bash',
      'c_sharp',
      'css',
      'dockerfile',
      'go',
      'html',
      'json',
      'lua',
      'markdown',
      'markdown_inline',
      'mermaid',
      'python',
      'regex',
      'rust',
      'sql',
      'tsx',
      'typescript',
      'vim',
      'xml',
      'yaml',
    },
  },
}
