return {
  {
    'zbirenbaum/copilot.lua',
    cmd = 'Copilot',
    event = { 'BufReadPost', 'BufNewFile' },
    config = function()
      local node_cmd = vim.fn.exepath('node')

      -- Windows では mise bin-paths から node.exe を明示取得
      if vim.fn.has('win32') == 1 then
        local mise_path = vim.fn.exepath('mise')
        if mise_path ~= '' then
          local bin_paths = vim.fn.system('"' .. mise_path .. '" bin-paths')
          if vim.v.shell_error == 0 then
            for path in bin_paths:gmatch('[^\r\n]+') do
              local cmd = path .. '\\node.exe'
              if vim.fn.executable(cmd) == 1 then
                node_cmd = cmd
                break
              end
            end
          end
        end
      end

      require('copilot').setup({
        copilot_node_command = node_cmd,
        suggestion = { enabled = false },
        panel = { enabled = false },
      })
    end,
  },
  {
    'zbirenbaum/copilot-cmp',
    dependencies = { 'zbirenbaum/copilot.lua' },
    event = { 'BufReadPost', 'BufNewFile' },
    config = function()
      require('copilot_cmp').setup()
    end,
  },
}
