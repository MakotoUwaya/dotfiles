return {
  'github/copilot.vim',
  event = { 'BufReadPost', 'BufNewFile' },
  config = function()
    -- Tab キーを copilot に奪われないようにする（nvim-cmp との競合回避）
    vim.g.copilot_no_tab_map = true

    -- Windows では mise bin-paths から node コマンドを取得して明示設定
    if vim.fn.has('win32') == 1 then
      local mise_path = vim.fn.exepath('mise')
      if mise_path ~= '' then
        local bin_paths = vim.fn.system('"' .. mise_path .. '" bin-paths')
        if vim.v.shell_error == 0 then
          for path in bin_paths:gmatch('[^\r\n]+') do
            local node_cmd = path .. '\\node.exe'
            if vim.fn.executable(node_cmd) == 1 then
              vim.g.copilot_node_command = node_cmd
              break
            end
          end
        end
      end
    end

    -- サジェスト確定: <M-l>（Alt+L）
    vim.keymap.set('i', '<M-l>', 'copilot#Accept("\\<Tab>")', {
      expr = true,
      replace_keycodes = false,
      desc = 'Copilot: サジェストを確定',
    })

    -- サジェスト候補ナビゲーション
    vim.keymap.set('i', '<M-]>', '<Plug>(copilot-next)', { desc = 'Copilot: 次の候補' })
    vim.keymap.set('i', '<M-[>', '<Plug>(copilot-previous)', { desc = 'Copilot: 前の候補' })
    vim.keymap.set('i', '<M-Backspace>', '<Plug>(copilot-dismiss)', { desc = 'Copilot: サジェストを却下' })
  end,
}
