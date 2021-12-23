set -x OS (uname)
if [ -f "/etc/arch-release" ]
  set -x DISTRO "Arch"
end

set -x PATH $PATH $HOME/.local/bin $HOME/.node_modules/bin $HOME/Code/bin $HOME/.cargo/bin
set CODE $HOME/Code

if [ $OS = "Linux" ]

  set -g BIN /usr/bin

  set -x CC $BIN/clang
  set -x CXX $BIN/clang++
  set -x ANDROID_HOME $CODE/android-sdk

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

set CONFIG $XDG_CONFIG_HOME
set CONF $CONFIG
set GITHUB "https://www.github.com/jeanlucthumm"
