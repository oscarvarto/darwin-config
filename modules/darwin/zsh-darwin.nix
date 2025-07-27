{ config, pkgs, lib, ... }:

{
  programs.zsh = {
    # Darwin-specific zsh configuration
    shellInit = ''
      # macOS-specific PATH configurations
      PATH="$PATH:/opt/homebrew/bin"
      PATH="/opt/homebrew/opt/llvm/bin:$PATH"
      export LDFLAGS="-L/opt/homebrew/opt/llvm/lib"
      export CPPFLAGS="-I/opt/homebrew/opt/llvm/include"

      export DOTNET_ROOT=/usr/local/share/dotnet
      PATH="$DOTNET_ROOT:$HOME/.dotnet/tools:$PATH"

      PATH="/opt/homebrew/opt/mysql@8.4/bin:$PATH"
      PATH="/opt/homebrew/opt/gnu-tar/libexec/gnubin:$PATH"
      PATH="/run/current-system/sw/bin:$PATH"

      export PATH
    '';
  };
}
