function is_ssh_session -d "Check if current session is an SSH session"
  if set -q SSH_CLIENT; or set -q SSH_TTY
    return 0
  end
  return 1
end
