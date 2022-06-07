local api = vim.api

local lsp_status = require 'lsp-status'
lsp_status.register_progress()

local M = {}

function M.map(mode, lhs, rhs, opts)
    local options = {noremap = true}
    if opts then options = vim.tbl_extend('force', options, opts) end
    api.nvim_set_keymap(mode, lhs, rhs, options)
end
function M.nmap(...) M.map('n', ...) end
function M.ncmap(lhs, rhs, ...) M.nmap(lhs, '<Cmd>' .. rhs .. '<CR>', ...) end
function M.imap(...) M.map('i', ...) end

function M.hover()
    if vim.diagnostic.open_float() == nil then vim.lsp.buf.hover() end
end

function M.on_attach(client, bufnr)
    -- Sets up LSP keybindings when LSP attaches to the buffer
    local function bnmap(lhs, rhs, ...)
        api.nvim_buf_set_keymap(bufnr, "n", lhs, "<Cmd>lua " .. rhs .. "<CR>",
                                ...)
    end

    -- LSP Status
    lsp_status.on_attach(client)

    api.nvim_buf_set_option(bufnr, "omnifunc", "v:lua.vim.lsp.omnifunc")

    -- Mappings
    local opts = {noremap = true, silent = true}
    bnmap("gd", "vim.lsp.buf.definition()", opts)
    bnmap("K", "vim.lsp.buf.hover()", opts)
    bnmap("<Leader>r", "vim.lsp.buf.rename()", opts)
    bnmap("<Leader>ks", "vim.lsp.buf.signature_help()", opts)
    bnmap("<Leader>kp", "vim.diagnostic.goto_prev()", opts)
    bnmap("<Leader>kn", "vim.diagnostic.goto_next()", opts)
    bnmap("<Leader>kk", "vim.diagnostic.open_float()", opts)
    bnmap("<Leader>wl",
          "require'common'.print_table(vim.lsp.buf.list_workspace_folders())",
          opts)
    bnmap("<Leader>a", "vim.lsp.buf.code_action({apply=true})", opts)

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
        bnmap("<Leader>f", "vim.lsp.buf.formatting()", opts)
    end
    if client.server_capabilities.codeLensProvider then
        -- CodeLens provides extra actions like "Run Test"
        -- under lang specific unit tests
        bnmap("<F11>", "vim.lsp.codelens.run()", opts)
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
