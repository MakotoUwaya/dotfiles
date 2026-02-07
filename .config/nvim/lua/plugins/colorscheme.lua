return {
  {
    'xiyaowong/transparent.nvim',
    event = 'VeryLazy',
    config = function()
      vim.cmd('TransparentEnable')
    end
  },
}
