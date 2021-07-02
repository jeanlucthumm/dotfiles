set -l OS (uname)

set -x PATH $PATH $HOME/.local/bin $HOME/.node_modules/bin $HOME/Code/bin $HOME/.cargo/bin

if [ $OS = "Linux" ]
  set -g BIN /usr/bin

  set -x CC $BIN/clang
  set -x CXX $BIN/clang++

  if [ "$KITTY_THEME" = "solarized-light" ]
    set -x BAT_THEME "Solarized (light)"
  else
    set -x BAT_THEME "Solarized (dark)"
  end
else if [ $OS = "Darwin" ]
  set -g BIN /usr/local/bin 

  set -x CC /usr/local/opt/llvm/bin/clang
  set -x CXX /usr/local/opt/llvm/bin/clang++

  if [ "$ITERM_PROFILE" = "Default" ]
    set -x BAT_THEME "Solarized (dark)"
  else
    set -x BAT_THEME "Solarized (light)"
  end
end


# XDG
set -x XDG_CONFIG_HOME $HOME/.config 
set -x XDG_CACHE_HOME $HOME/.cache 
set -x XDG_DATA_HOME $HOME/.local/share 
set -x XDG_DOWNLOAD_DIR $HOME/Downloads 

set -x TERMINAL kitty 
set -x npm_config_prefix $HOME/.node_modules 
set -x EDITOR $BIN/nvim
set -x LC_ALL en_US.UTF-8


# React Native
set -x ANDROID_HOME $HOME/Android/Sdk
set -x PATH $PATH $ANDROID_HOME/emulator
set -x PATH $PATH $ANDROID_HOME/tools 
set -x PATH $PATH $ANDROID_HOME/tools/bin
set -x PATH $PATH $ANDROID_HOME/platform-tools


set CONFIG $XDG_CONFIG_HOME
set CONF $CONFIG
set CODE $HOME/Code
set GITHUB "https://www.github.com/jeanlucthumm"
