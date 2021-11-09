local dap = require 'dap'

dap.adapters.lldb = {
    type = 'executable',
    command = '/usr/bin/lldb-vscode',
    name = 'lldb'
}

dap.configurations.cpp = {
    {
        name = 'Launch',
        type = 'lldb',
        request = 'launch',
        program = function()
            return vim.fn.input('Path to executable: ', vim.fn.getcwd() .. '/',
                                'file')
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
        runInTerminal = false
    }
}

dap.configurations.rust = {
    {
        name = 'default',
        type = 'lldb',
        request = 'launch',
        program = '${workspaceFolder}/target/debug/${workspaceFolderBasename}',
        cwd = '${workspaceFolder}',
        stopOnEntry = false,
        args = {},
        runInTerminal = false
    },
    {
        name = 'rustc stage1 debug',
        type = 'lldb',
        request = 'launch',
        program = '/home/jeanluc/Code/rust/build/x86_64-unknown-linux-gnu/stage1/bin/rustc',
        cwd = '${workspaceFolder}',
        stopOnEntry = false,

        args = function()
            local path = vim.fn.input('Target rust project: ',
                                      '/home/jeanluc/Code/', 'file')
            local target = path:match('.+/(.+)/$') -- extract dir name
            return {
                '--crate-name',
                target,
                '--edition=2018',
                path .. '/src/main.rs',
                '--error-format=json',
                '--json=diagnostic-rendered-ansi',
                '--crate-type',
                'bin',
                '--emit=dep-info,link',
                '-C',
                'embed-bitcode=no',
                '-C',
                'debuginfo=2',
                -- These hashcodes are for mangling, and I copied this one from a cargo project
                '-C',
                'metadata=3a8a540162ab7ee9',
                '-C',
                'extra-filename=-3a8a540162ab7ee9',
                '--out-dir',
                path .. 'target/debug/deps',
                '-C',
                'incremental=' .. path .. 'target/debug/incremental',
                '-L',
                'dependency=' .. path .. 'target/debug/deps'
            }
        end,
        runInTerminal = false
    }
}

vim.fn.sign_define('DapBreakpoint',
                   {text = '🛑', texthl = '', linehl = '', numhl = ''})
