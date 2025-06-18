local dap = require'dap'

dap.adapters.lldb = {
  type = 'executable',
  command = '/usr/bin/lldb-vscode',
  name = 'lldb',
}

-- For debugging dlv remote server
dap.adapters.delve_remote = {
  type = 'server',
  host = 'localhost',
  port = 40000,
}

dap.configurations.cpp = {
  {
    name = 'Launch',
    type = 'lldb',
    request = 'launch',
    program = function()
      return vim.fn
          .input('Path to executable: ', vim.fn.getcwd() .. '/', 'file')
    end,
    cwd = '${workspaceFolder}',
    stopOnEntry = false,
    args = {},

    -- if you change `runInTerminal` to true, you might need to change the yama/ptrace_scope setting:
    --
    --    echo 0 | sudo tee /proc/sys/kernel/yama/ptrace_scope
    --
    -- Otherwise you might get the following error:
    --
    --    Error on launch: Failed to attach to the target process
    --
    -- But you should be aware of the implications:
    -- https://www.kernel.org/doc/html/latest/admin-guide/LSM/Yama.html
    runInTerminal = false,
  },
}

-- TODO: This is project specific, should be moved to a project specific file
dap.configurations.go = {
  {
    type = 'delve_remote',
    name = 'Cora Docker',
    request = 'launch',
    mode = 'debug',
    substitutePath = {
      { from = '${workspaceFolder}', to = '/usr/src/app/server' },
    },
    program = 'cmd/server/main.go',
  },
}

vim.fn.sign_define('DapBreakpoint',
  { text = '🧘', texthl = '', linehl = '', numhl = '' })
