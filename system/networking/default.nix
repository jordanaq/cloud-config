# networking — private mesh access (additive; nothing here depends on it).
{ ... }:

{
  imports = [
    ./tailscale.nix
    ./tailscale-serve.nix
  ];
}
