set -x OS (uname)
if [ -f "/etc/arch-release" ]
  set -x DISTRO "Arch"
end

set -x PATH $PATH $HOME/.local/bin $HOME/.node_modules/bin $HOME/Code/bin $HOME/.cargo/bin $HOME/.pub-cache/bin
set CODE $HOME/Code

if [ $OS = "Linux" ]

  set -g BIN /usr/bin

  set -x CC $BIN/clang
  set -x CXX $BIN/clang++
  set -x ANDROID_SDK_ROOT $HOME/Android/Sdk
  set -x ANDROID_HOME $ANDROID_SDK_ROOT
  set -x CHROME_EXECUTABLE /usr/bin/chromium
  set -x GPG_TTY (tty)

  set -x PATH $PATH $ANDROID_SDK_ROOT/platforms $ANDROID_SDK_ROOT/tools/bin $ANDROID_SDK_ROOT/platform-tools /opt/flutter/bin
  set -x PATH $PATH $HOME/go/bin $HOME/.gem/ruby/3.0.0/bin

else if [ $OS = "Darwin" ]

  set -g BIN /usr/local/bin

  set -x CC /usr/local/opt/llvm/bin/clang
  set -x CXX /usr/local/opt/llvm/bin/clang++
  set -x ANDROID_HOME /Users/$USER/Library/Android/sdk

end

function get_theme
  if [ -n "$KITTY_THEME" ]
    echo $KITTY_THEME
  else if [ -n "$ALACRITTY_THEME" ]
    echo $ALACRITTY_THEME
  else if [ "$ITERM_PROFILE" = "Default Light" ]
    echo "solarized-light"
  else
    echo "solarized-light"
  end
end

switch (get_theme)
  case "solarized-light"
    set -x BAT_THEME "Solarized (light)"
  case "solarized-dark"
    set -x BAT_THEME "Solarized (dark)"
  case "gruvbox-light"
    set -x BAT_THEME "gruvbox-light"
    fish_config theme choose "fish default"
  case "gruvbox-dark"
    set -x BAT_THEME "gruvbox-dark"
end

# XDG
set -x XDG_CONFIG_HOME $HOME/.config 
set -x XDG_CACHE_HOME $HOME/.cache 
set -x XDG_DATA_HOME $HOME/.local/share 
set -x XDG_DOWNLOAD_DIR $HOME/Downloads 

set -x npm_config_prefix $HOME/.node_modules 
set -x EDITOR (which nvim)
set -x LC_ALL en_US.UTF-8
# Works in combination with the Man.sublime-syntax file in bat conf
set -x MANPAGER "sh -c 'sed -e s/.\\\\x08//g | bat -l man -p'"
# Fish prompts have automatic detection of venv
set -x VIRTUAL_ENV_DISABLE_PROMPT 1

set -x CONF $XDG_CONFIG_HOME
