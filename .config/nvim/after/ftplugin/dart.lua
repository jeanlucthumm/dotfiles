local nmap = require'common'.nmap

nmap('tb', function()
  require'harpoon.term'.sendCommand(2, 'dart run build_runner watch\n')
end)

nmap('<F1>', function() require'harpoon.term'.sendCommand(1, 'flutter run\n') end)
nmap('<F2>', function() require'harpoon.term'.sendCommand(1, 'R') end)

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

local au = vim.api.nvim_create_augroup('DartAutocommands', { clear = true })
vim.api.nvim_create_autocmd('BufWritePost', {
  group = au,
  pattern = '*.dart',
  callback = function()
    require'harpoon.term'.sendCommand(1, 'r')
  end,
})

-- Look for the `User ID: [token]` string in the output of a flutter run command
-- and copy it to the clipboard.
local function flutter_copy_user_id()
  local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
  local content = table.concat(lines)

  -- Use a pattern to find the User ID
  local user_id = content:match('User ID: ([^%s]+%.)')

  if user_id then
    vim.fn.setreg('+', user_id)
    vim.notify('User ID copied to clipboard')
  else
    vim.notify('User ID not found in the current buffer')
  end
end

vim.api.nvim_create_user_command('FlutterCopyUserId', flutter_copy_user_id, {})
vim.o.cc = '100'
