{ config, pkgs, ... }:

{
  programs.ssh = {
    enable = true;
    matchBlocks = {
      "pve01" = {
        hostname = "192.168.0.200";
        user = "root";
        port = 22;
        identitiesOnly = true;
        identityFile = "~/.ssh/proxmox.pub";
      };
      "pve01-develop" = {
        hostname = "192.168.2.101";
        user = "dev";
        port = 22;
        identitiesOnly = true;
        identityFile = "~/.ssh/proxmox_dev.pub";
      };
      "llm-server" = {
        hostname = "192.168.0.7";
        user = "keng";
        port = 2222;
        identitiesOnly = true;
        identityFile = "~/.ssh/llm-server.pub";
      };
      "*" = {
        extraOptions = {
          IdentityAgent = "~/.1password/agent.sock";
        };
      };
    };
  };
}
