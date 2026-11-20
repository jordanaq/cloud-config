{ ... }:

{
  dotfiles.neovim.minimal = true;

  imports = [
    ./bat
    ./btop
    ./git
    ./misc
    ./neovim
    ./pandoc
    ./zip
    ./zoxide
  ];
}
