set -l OS (uname)

set -x PATH $PATH $HOME/.local/bin $HOME/.node_modules/bin $HOME/Code/bin $HOME/.cargo/bin

set CODE $HOME/Code

if [ $OS = "Linux" ]

  set -g BIN /usr/bin

  set -x CC $BIN/clang
  set -x CXX $BIN/clang++
  set -x ANDROID_HOME $CODE/android-sdk

else if [ $OS = "Darwin" ]

  set -x CC /usr/local/opt/llvm/bin/clang
  set -x CXX /usr/local/opt/llvm/bin/clang++
  set -x ANDROID_HOME /Users/$USER/Library/Android/sdk

end

if [ "$KITTY_THEME" = "solarized-light" -o "$ITERM_PROFILE" = "Default" ]
  set -x BAT_THEME "Solarized (light)"
else
  set -x BAT_THEME "Solarized (dark)"
end



# XDG
set -x XDG_CONFIG_HOME $HOME/.config 
set -x XDG_CACHE_HOME $HOME/.cache 
set -x XDG_DATA_HOME $HOME/.local/share 
set -x XDG_DOWNLOAD_DIR $HOME/Downloads 

set -x npm_config_prefix $HOME/.node_modules 
set -x EDITOR $BIN/nvim
set -x LC_ALL en_US.UTF-8

set CONFIG $XDG_CONFIG_HOME
set CONF $CONFIG
set GITHUB "https://www.github.com/jeanlucthumm"
