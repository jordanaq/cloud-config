# Declarative `tailscale serve` — tailnet-only HTTPS front doors for services
# that stay on loopback. nixpkgs has no option for this: serve mappings live in
# tailscaled's own state (set via CLI, not a config file), so each entry becomes
# a small oneshot that re-asserts itself on boot and after every tailscaled
# restart. `tailscale serve` upserts, so re-running it is harmless.
#
# Usage (from whichever module owns the service):
#   services.tailscaleServe."8443" = "http://127.0.0.1:3001";
# → https://tsiru-cloud.<tailnet>.ts.net:8443  (ts.net cert, tailnet-only)
#
# ⚠️ Never use port 443: tailscaled then binds <tailnet-ip>:443, colliding with
# Caddy's wildcard :443 and taking every public vhost down.
{ config, lib, pkgs, ... }:

let
  cfg = config.services.tailscaleServe;
in
{
  options.services.tailscaleServe = lib.mkOption {
    type = lib.types.attrsOf lib.types.str;
    default = { };
    example = {
      "8443" = "http://127.0.0.1:3001";
      "10000" = "http://127.0.0.1:8222";
    };
    description = ''
      Attrset of HTTPS port → local target URL. Each entry runs
      `tailscale serve --bg --https=<port> <url>` as a systemd oneshot, so the
      mapping survives reboots and tailscaled restarts. Tailnet-only; nothing
      is exposed publicly and no firewall hole is needed (tailscaled proxies
      from its own listener to the loopback target).
    '';
  };

  config = lib.mkIf (cfg != { }) {
    systemd.services = lib.mapAttrs' (
      port: url:
      lib.nameValuePair "tailscale-serve-${port}" {
        description = "tailscale serve :${port} -> ${url}";

        wantedBy = [ "multi-user.target" ];
        # The CLI talks to tailscaled's socket, so it must be up first.
        # partOf: a tailscaled restart restarts this unit, re-asserting the map.
        wants = [ "tailscaled.service" ];
        after = [ "tailscaled.service" ];
        partOf = [ "tailscaled.service" ];

        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
          ExecStart = "${lib.getExe' pkgs.tailscale "tailscale"} serve --bg --https=${port} ${url}";
          Restart = "on-failure";
          RestartSec = "10s";
        };
      }
    ) cfg;
  };
}
