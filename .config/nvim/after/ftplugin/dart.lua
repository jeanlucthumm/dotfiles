local nmap = require'common'.nmap

vim.diagnostic.config({ update_in_insert = true })
nmap('tb', function()
  require'harpoon.term'.sendCommand(1, 'dart run build_runner watch\n')
end)

nmap('<F1>', ':FlutterQuit<CR>:sleep 1<CR>:FlutterRun<CR>')
nmap('<F2>', ':FlutterRestart<CR>')
