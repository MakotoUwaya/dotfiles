return {
  'nvim-treesitter/nvim-treesitter',
  branch = 'master',
  event = { 'BufReadPost', 'BufNewFile' },
  build = ':TSUpdate',
  opts = {
    ensure_installed = {
      'bash',
      'go',
      'json',
      'lua',
      'markdown',
      'markdown_inline',
      'python',
      'regex',
      'rust',
      'sql',
      'tsx',
      'typescript',
      'vim',
      'yaml',
    },
  },
}
