local api = vim.api

local lsp_status = require'lsp-status'
lsp_status.register_progress()

local M = {}

function M.map(mode, lhs, rhs, opts) vim.keymap.set(mode, lhs, rhs, opts) end

function M.nmap(...) M.map('n', ...) end

function M.vmap(...) M.map('v', ...) end

function M.imap(...) M.map('i', ...) end

function M.ncmap(lhs, rhs, ...) M.nmap(lhs, '<Cmd>' .. rhs .. '<CR>', ...) end

function M.vcmap(lhs, rhs, ...) M.vmap(lhs, '<Cmd>' .. rhs .. '<CR>', ...) end

function M.hover()
  if vim.diagnostic.open_float() == nil then vim.lsp.buf.hover() end
end

local auhigh = vim.api.nvim_create_augroup('LspHighlighting', {})

---@param client vim.lsp.Client
---@param bufnr number
function M.on_attach(client, bufnr)
  local nmap = M.nmap

  -- LSP Status
  lsp_status.on_attach(client)

  -- Disable inlay hints
  vim.lsp.inlay_hint.enable(false, { bufnr = bufnr })

  api.nvim_set_option_value('omnifunc', 'v:lua.vim.lsp.omnifunc', { buf = bufnr })

  -- Mappings
  local opts = { noremap = true, silent = true, buffer = bufnr }
  nmap('gd', function() vim.lsp.buf.definition() end, opts)
  nmap('K', function() vim.lsp.buf.hover() end, opts)
  nmap('<Leader>R', function() vim.lsp.buf.rename() end, opts)
  nmap('gd', function() vim.lsp.buf.definition() end, opts)
  nmap('K', function() vim.lsp.buf.hover() end, opts)
  nmap('<Leader>R', function() vim.lsp.buf.rename() end, opts)
  nmap('<Leader>ks', function() vim.lsp.buf.signature_help() end, opts)
  nmap('<Leader>kp', function() vim.diagnostic.jump({ count = -1, float = true }) end, opts)
  nmap('<Leader>kn', function() vim.diagnostic.jump({ count = 1, float = true }) end, opts)
  nmap('<Leader>kk', function() vim.diagnostic.open_float() end, opts)
  vim.keymap.set({ 'v', 'n' }, '<Leader>a', require('actions-preview').code_actions)

  -- Capability specific commands
  if client:supports_method('documentHighlightProvider', bufnr) then
    api.nvim_clear_autocmds({ group = auhigh, buffer = bufnr })
    -- Highlight symbol in document on hover. Delay is controlled by |updatetime|
    api.nvim_create_autocmd('CursorHold', {
      group = auhigh,
      buffer = bufnr,
      callback = function()
        vim.lsp.buf.document_highlight()
      end,
    })
    api.nvim_create_autocmd('CursorMoved', {
      group = auhigh,
      buffer = bufnr,
      callback = function()
        vim.lsp.buf.clear_references()
      end,
    })
  end

  if client:supports_method('codeLensProvider', bufnr) then
    nmap('<Leader>lc', function()
      vim.lsp.codelens.run()
    end)
  end
end

function M.capabilities()
  local capabilities = require'cmp_nvim_lsp'.default_capabilities()
  capabilities = vim.tbl_extend('keep', capabilities,
    require'lsp-status'.capabilities)
  return capabilities
end

function M.print_table(o)
  if type(o) == 'table' then
    local s = '{ '
    for k, v in pairs(o) do
      if type(k) ~= 'number' then k = '"' .. k .. '"' end
      s = s .. '[' .. k .. '] = ' .. M.print_table(v) .. ','
    end
    return s .. '} '
  else
    return tostring(o)
  end
end

return M
