return {
  {
    'nvim-neo-tree/neo-tree.nvim',
    branch = 'v3.x',
    dependencies = {
      'nvim-lua/plenary.nvim',
      'MunifTanjim/nui.nvim',
      'nvim-tree/nvim-web-devicons', -- optional, but recommended
    },
    cmd = 'Neotree',
    ---@module 'neo-tree'
    ---@type neotree.Config
    opts = {
      -- options go here
      filesystem = {
        filtered_items = {
          visible = true,
          never_show = {
            '.git',
          },
        },
      },
    },
  }
}
