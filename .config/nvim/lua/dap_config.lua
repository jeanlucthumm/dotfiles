local dap = require'dap'

dap.adapters.lldb = {
  type = 'executable',
  command = '/usr/bin/lldb-vscode',
  name = 'lldb',
}

dap.adapters.delve_docker = {
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

-- Append a dap configuration for Go
-- TODO: this is not working yet
if not dap.configurations.go then
  dap.configurations.go = {}
end
table.insert(dap.configurations.go,
  {
    type = 'delve_docker',
    name = 'Delve Docker',
    request = 'launch',
    mode = 'debug',
    substitutePath = {
      { from = '${workspaceFolder}', to = '/usr/src/app/server' },
    },
    program = '${relativeFile}',
    connect = function()
      local host = vim.fn.input('Host [localhost]: ')
      host = host ~= '' and host or 'localhost'
      local port = vim.fn.input('Port [40000]: ')
      port = port ~= '' and port or '40000'
      return { host = host, port = port }
    end,
  })

vim.fn.sign_define('DapBreakpoint',
  { text = '🧘', texthl = '', linehl = '', numhl = '' })
