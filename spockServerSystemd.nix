{ pkgs, ... }:
let
  spockPackage = import ./default.nix;
in
{
  systemd.services.pogspock = {
    description = "Spock server for PogBot";
    serviceConfig = {
      ExecStart = "${spockPackage}/bin/spock";
      Restart = "always";
      RestartSec = 1;
    };
    wantedBy = [ "multi-user.target" ];
    after = [ "network.target" ];
    path = [ pkgs.ffmpeg ];
  };

  systemd.services.pogspock.enable = true;
  networking = {
    firewall = {
      enable = true;
      allowedTCPPorts = [ 8080 ];
    };
  };
}
