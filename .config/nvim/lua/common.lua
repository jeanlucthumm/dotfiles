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

local auformat = vim.api.nvim_create_augroup('LspFormatting', {})
local auhigh = vim.api.nvim_create_augroup('LspHighlighting', {})


---@param clients table<number, vim.lsp.Client>
---@param capability string
---@return boolean
local function any_client_has_capability(clients, capability)
  for _, client in ipairs(clients) do
    if client.server_capabilities[capability] then
      return true
    end
  end
  return false
end

---@param client vim.lsp.Client
---@param bufnr number
function M.on_attach(client, bufnr)
  local nmap = M.nmap
  local ncmap = M.ncmap

  -- LSP Status
  lsp_status.on_attach(client)

  -- Disable inlay hints
  vim.lsp.inlay_hint.enable(false, { bufnr = bufnr })

  api.nvim_set_option_value('omnifunc', 'v:lua.vim.lsp.omnifunc', { buf = bufnr })

  -- Mappings
  local opts = { noremap = true, silent = true, buffer = bufnr }
  ncmap('gd', 'lua vim.lsp.buf.definition()', opts)
  ncmap('K', 'lua vim.lsp.buf.hover()', opts)
  ncmap('<Leader>R', 'lua vim.lsp.buf.rename()', opts)
  ncmap('<Leader>ks', 'lua vim.lsp.buf.signature_help()', opts)
  ncmap('<Leader>kp', 'lua vim.diagnostic.goto_prev()', opts)
  ncmap('<Leader>kn', 'lua vim.diagnostic.goto_next()', opts)
  ncmap('<Leader>kk', 'lua vim.diagnostic.open_float()', opts)
  vim.keymap.set({ 'v', 'n' }, '<Leader>a', require('actions-preview').code_actions)

  -- Capability specific commands
  local clients = vim.lsp.get_clients { bufnr = bufnr }
  if any_client_has_capability(clients, 'documentHighlightProvider') then
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

  if any_client_has_capability(clients, 'codeLensProvider') then
    -- CodeLens provides extra actions like "Run Test"
    -- under lang specific unit tests
    ncmap('<F11>', 'lua vim.lsp.codelens.run()', opts)
  end

  -- Format on save is now handled by conform.nvim's format_on_save option
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
