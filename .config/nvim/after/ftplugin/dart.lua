local nmap = require'common'.nmap

vim.diagnostic.config({ update_in_insert = true })
nmap('tb', function()
  require'harpoon.term'.sendCommand(1, 'dart run build_runner watch\n')
end)

nmap('<F1>', ':FlutterQuit<CR>:sleep 1<CR>:FlutterRun<CR>')
nmap('<F2>', ':FlutterRestart<CR>')

-- Go to test file for the current source file.
-- The path for the test file is the same as the source file one relative to `lib`,
-- but instead in the `test` directory. For example, `lib/src/foo.dart` and `test/src/foo_test.dart`.
local function goto_test()
  -- Check if buffer ends is _test.dart
  local path = vim.fn.expand('%:p:r') .. '_test.dart'
  local test_path = path:gsub('/lib/', '/test/', 1)
  if vim.fn.filereadable(test_path) == 1 then
    vim.cmd('edit ' .. test_path)
  else
    vim.notify('No test file')
  end
end

local function outline()
  vim.cmd('FlutterOutlineOpen')
  local wins = vim.api.nvim_tabpage_list_wins(0)
  for _, win in ipairs(wins) do
    local buf = vim.api.nvim_win_get_buf(win)
    if vim.api.nvim_buf_get_name(buf):find('Flutter Outline') then
      vim.api.nvim_set_current_win(win)
    end
  end
end

nmap('git', goto_test)
nmap('<Leader>s', outline)
