{ config, pkgs, lib, ... }:

{
  # Hyprland 設定ファイル
  home.file.".config/hypr/hyprland.conf" = {
    source = ../hypr/hyprland.conf;
    force = true;
  };

  # エコシステムツール
  home.packages = with pkgs; [
    wofi          # アプリランチャー
    swww          # 壁紙デーモン
    hyprlock      # スクリーンロック
    grimblast     # スクリーンショット
    wl-clipboard  # クリップボード
    brightnessctl # 輝度調整
  ];

  # ステータスバー
  programs.waybar = {
    enable = true;
    settings = {
      mainBar = {
        layer = "top";
        position = "top";
        height = 36;
        spacing = 4;
        modules-left = [ "hyprland/workspaces" "hyprland/window" ];
        modules-center = [ "clock" ];
        modules-right = [
          "pulseaudio"
          "network"
          "battery"
          "tray"
        ];

        "hyprland/workspaces" = {
          format = "{id}";
          on-click = "activate";
        };

        "hyprland/window" = {
          max-length = 50;
        };

        clock = {
          format = "{:%H:%M}";
          format-alt = "{:%Y-%m-%d %H:%M}";
          tooltip-format = "<big>{:%Y %B}</big>\n<tt><small>{calendar}</small></tt>";
        };

        battery = {
          states = {
            warning = 30;
            critical = 15;
          };
          format = "{capacity}% {icon}";
          format-charging = "{capacity}% 󰂄";
          format-icons = [ "󰁺" "󰁼" "󰁾" "󰂀" "󰂂" "󰁹" ];
        };

        network = {
          format-wifi = "{essid} 󰤨";
          format-ethernet = "󰈀";
          format-disconnected = "󰤭";
          tooltip-format-wifi = "{signalStrength}%";
        };

        pulseaudio = {
          format = "{volume}% {icon}";
          format-muted = "󰸈";
          format-icons = {
            default = [ "󰕿" "󰖀" "󰕾" ];
          };
          on-click = "pavucontrol";
        };

        tray = {
          spacing = 8;
        };
      };
    };
    style = ''
      * {
        font-family: "HackGen Console NF", monospace;
        font-size: 13px;
      }

      window#waybar {
        background-color: rgba(30, 30, 46, 0.9);
        color: #cdd6f4;
        border-bottom: 2px solid rgba(137, 180, 250, 0.3);
      }

      #workspaces button {
        padding: 0 8px;
        color: #6c7086;
        background: transparent;
        border: none;
        border-radius: 4px;
      }

      #workspaces button.active {
        color: #89b4fa;
        background: rgba(137, 180, 250, 0.15);
      }

      #workspaces button:hover {
        background: rgba(137, 180, 250, 0.1);
        color: #cdd6f4;
      }

      #clock,
      #battery,
      #network,
      #pulseaudio,
      #tray {
        padding: 0 12px;
        color: #cdd6f4;
      }

      #battery.warning {
        color: #fab387;
      }

      #battery.critical {
        color: #f38ba8;
      }
    '';
  };

  # 通知デーモン
  services.mako = {
    enable = true;
    backgroundColor = "#1e1e2e";
    borderColor = "#89b4fa";
    borderRadius = 8;
    borderSize = 2;
    textColor = "#cdd6f4";
    defaultTimeout = 5000;
    font = "HackGen Console NF 11";
  };
}
