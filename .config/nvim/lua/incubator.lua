-- Desc: A place to put new code that is not yet ready for prime time.

local M = {}

-- Copy the file contents and name to system clipboard.
-- Useful for generating context for an LLM.
function M.copy_file_to_clipboard()
  local file = vim.fn.expand('%:.')
  local lines = vim.fn.readfile(file)
  local contents = table.concat(lines, '\n')
  local text = string.format(
    'Contents of %s:\n\n```\n%s\n```',
    file,
    contents
  )
  vim.fn.setreg('+', text)
  vim.notify(string.format('Copied file context to clipboard (%d lines)', #lines))
end

-- Look for the `User ID: [token]` string in the output of a flutter run command
-- and copy it to the clipboard.
function M.flutter_copy_user_id()
  local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
  local content = table.concat(lines)

  -- Use a pattern to find the User ID
  local user_id = content:match('User ID: ([^%s]+%.)')

  if user_id then
    vim.fn.setreg('+', user_id)
    vim.notify('User ID copied to clipboard')
  else
    vim.notify('User ID not found in the current buffer')
  end
end

return M
