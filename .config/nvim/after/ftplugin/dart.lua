local nmap = require'common'.nmap

vim.diagnostic.config({ update_in_insert = true })
nmap('tf', function()
  require'harpoon.term'.sendCommand(1, 'flutter test\n')
end)
