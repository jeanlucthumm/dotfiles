local api = vim.api

local lsp_status = require 'lsp-status'
lsp_status.register_progress()

local M = {}

function M.map(mode, lhs, rhs, opts)
  vim.keymap.set(mode, lhs, rhs, opts)
end

function M.nmap(...) M.map('n', ...) end

function M.vmap(...) M.map('v', ...) end

function M.imap(...) M.map('i', ...) end

function M.ncmap(lhs, rhs, ...) M.nmap(lhs, '<Cmd>' .. rhs .. '<CR>', ...) end

function M.vcmap(lhs, rhs, ...) M.vmap(lhs, '<Cmd>' .. rhs .. '<CR>', ...) end

function M.hover()
  if vim.diagnostic.open_float() == nil then vim.lsp.buf.hover() end
end

function M.on_attach(client, bufnr)
  local map = M.map
  local nmap = M.nmap
  local ncmap = M.ncmap

  -- LSP Status
  lsp_status.on_attach(client)

  api.nvim_buf_set_option(bufnr, "omnifunc", "v:lua.vim.lsp.omnifunc")

  -- Mappings
  local opts = { noremap = true, silent = true, buffer = bufnr }
  nmap("gd", "vim.lsp.buf.definition()", opts)
  ncmap("K", "Lspsaga hover_doc", opts)
  nmap("<Leader>r", "vim.lsp.buf.rename()", opts)
  nmap("<Leader>ks", "vim.lsp.buf.signature_help()", opts)
  nmap("<Leader>kp", "vim.diagnostic.goto_prev()", opts)
  nmap("<Leader>kn", "vim.diagnostic.goto_next()", opts)
  nmap("<Leader>kk", "vim.diagnostic.open_float()", opts)
  nmap("<Leader>wl",
    "require'common'.print_table(vim.lsp.buf.list_workspace_folders())",
    opts)

  -- Capability specific commands
  if client.server_capabilities.documentHighlightProvider then
    -- Highlight symbol in document on hover. Delay is controlled by |updatetime|
    api.nvim_exec([[
      augroup lsp_document_highlight
      autocmd! * <buffer>
      autocmd CursorHold <buffer> lua vim.lsp.buf.document_highlight()
      autocmd CursorMoved <buffer> lua vim.lsp.buf.clear_references()
      augroup END
      ]], false)
  end
  if client.server_capabilities.documentFormattingProvider then
    map('<Leader>f', function()
      vim.lsp.buf.format({ timeout_ms = '5000' })
    end)
  end
  if client.server_capabilities.codeLensProvider then
    -- CodeLens provides extra actions like "Run Test"
    -- under lang specific unit tests
    nmap("<F11>", "vim.lsp.codelens.run()", opts)
  end
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
