# Uptime Kuma — self-hosted status/heartbeat monitor; PRIVATE: loopback-only,
# NOT in Caddy. Reached over the tailnet via declarative `tailscale serve`
# (system/networking/tailscale-serve.nix):
#   -> https://tsiru-cloud.<tailnet>.ts.net:8443  (ts.net cert, tailnet-only)
# First run: create the admin account at that URL.
{ config, lib, ... }:

{
  services.uptime-kuma = {
    enable = true;
    # Loopback only — in via `tailscale serve` (below) or
    # `ssh -L 3001:127.0.0.1:3001 tsiru.pet`.
    settings.HOST = "127.0.0.1";
    settings.PORT = "3001";
  };

  # Tailnet-only front door. ⚠️ Port 8443, never 443 (see tailscale-serve.nix).
  services.tailscaleServe."8443" = "http://127.0.0.1:3001";

  # No Caddy vhost: public status.${domain} (basic-auth gated) removed 2026-09-12
  # in favour of tailnet-only. If a public status is ever wanted, expose a
  # separate read-only status page — not this admin dashboard.
}