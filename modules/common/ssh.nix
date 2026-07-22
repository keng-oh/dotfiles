{ config, pkgs, ... }:

{
  programs.ssh = {
    enable = true;
    enableDefaultConfig = false;
    settings = {
      "github.com" = {
        HostName = "github.com";
        User = "git";
        Port = 22;
        IdentitiesOnly = true;
        IdentityFile = "~/.ssh/github.pub";
      };
      "pve01" = {
        HostName = "192.168.0.200";
        User = "root";
        Port = 22;
        IdentitiesOnly = true;
        IdentityFile = "~/.ssh/proxmox.pub";
      };
      "pve01-develop" = {
        HostName = "192.168.2.101";
        User = "dev";
        Port = 22;
        IdentitiesOnly = true;
        IdentityFile = "~/.ssh/proxmox_dev.pub";
      };
      "*" = {
        IdentityAgent = "~/.1password/agent.sock";
        ForwardAgent = false;
        AddKeysToAgent = "no";
        Compression = false;
        ServerAliveInterval = 0;
        ServerAliveCountMax = 3;
        HashKnownHosts = false;
        UserKnownHostsFile = "~/.ssh/known_hosts";
        ControlMaster = "no";
        ControlPath = "~/.ssh/master-%r@%n:%p";
        ControlPersist = "no";
      };
    };
  };
}
