local api = vim.api

local lsp_status = require'lsp-status'
lsp_status.register_progress()

local M = {}

function M.hover()
    if vim.diagnostic.open_float() == nil then
        vim.lsp.buf.hover()
    end
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
    local opts = {
        noremap = true,
        silent = true
    }
    bnmap("gd", "vim.lsp.buf.definition()", opts)
    bnmap("K", "vim.lsp.buf.hover()", opts)
    bnmap("<Leader>r", "vim.lsp.buf.rename()", opts)
    bnmap("<Leader>ks", "vim.lsp.buf.signature_help()", opts)
    bnmap("<Leader>kp", "vim.lsp.diagnostic.goto_prev()", opts)
    bnmap("<Leader>kn", "vim.lsp.diagnostic.goto_next()", opts)
    bnmap("<Leader>kk", "vim.diagnostic.open_float()", opts)
    bnmap("<Leader>wl", "PrintTable(vim.lsp.buf.list_workspace_folders())", opts)

    -- Capability specific commands
    if client.resolved_capabilities.document_highlight then
        -- Highlight symbol in document on hover. Delay is controlled by |updatetime|
        api.nvim_exec([[
      augroup lsp_document_highlight
      autocmd! * <buffer>
      autocmd CursorHold <buffer> lua vim.lsp.buf.document_highlight()
      autocmd CursorMoved <buffer> lua vim.lsp.buf.clear_references()
      augroup END
      ]], false)
    end
    if client.resolved_capabilities.document_formatting then
        bnmap("<Leader>f", "vim.lsp.buf.formatting()", opts)
    end
    if client.resolved_capabilities.code_lens then
        -- CodeLens provides extra actions like "Run Test"
        -- under lang specific unit tests
        bnmap("<F11>", "vim.lsp.codelens.run()", opts)
    end
end

return M
