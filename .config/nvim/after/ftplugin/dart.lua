local nmap = require'common'.nmap

vim.diagnostic.config({ update_in_insert = true })
nmap('tf', function()
  require'harpoon.term'.sendCommand(1, 'flutter test\n')
end)

nmap('<F5>', ':FlutterQuit<CR>:sleep 1<CR>:FlutterRun<CR>')
nmap('<F4>', ':FlutterRestart<CR>')
