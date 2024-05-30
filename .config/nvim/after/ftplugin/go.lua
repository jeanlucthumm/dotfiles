local ncmap = require'common'.ncmap

vim.opt_local.tabstop = 2
vim.opt_local.shiftwidth = 2
vim.opt_local.colorcolumn = '80'

ncmap('tf', 'GoTestFile')
ncmap('gfi', 'GoImport')
