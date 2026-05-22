{ config, pkgs, lib, ... }:

{
  # Hyprland 設定ファイル
  home.file.".config/hypr/hyprland.conf" = {
    source = ../hypr/hyprland.conf;
    force = true;
  };

  # wofi テーマ
  home.file.".config/wofi/style.css".source = ../wofi/style.css;
  home.file.".config/wofi/config".source    = ../wofi/config;

  # 電源メニュースクリプト
  home.file.".config/hypr/scripts/powermenu.sh" = {
    executable = true;
    text = ''
      #!/usr/bin/env bash
      options="󰐥  Shutdown\n󰒲  Sleep\n󰜉  Reboot\n󰌾  Lock\n󰗽  Logout"
      chosen=$(echo -e "$options" | wofi \
        --show dmenu \
        --prompt "" \
        --width 220 \
        --height 235 \
        --no-actions \
        --insensitive)
      case "$chosen" in
        "󰐥  Shutdown") systemctl poweroff ;;
        "󰒲  Sleep")    systemctl suspend ;;
        "󰜉  Reboot")   systemctl reboot ;;
        "󰌾  Lock")     hyprlock ;;
        "󰗽  Logout")   hyprctl dispatch exit ;;
      esac
    '';
  };

  # エコシステムツール
  home.packages = with pkgs; [
    wofi              # アプリランチャー
    swww              # 壁紙デーモン
    hyprlock          # スクリーンロック
    hypridle          # アイドル管理
    grimblast         # スクリーンショット
    wl-clipboard      # クリップボード
    cliphist          # クリップボード履歴
    brightnessctl     # 輝度調整
    playerctl         # メディアキー制御
    networkmanagerapplet  # WiFi トレイ
    polkit_gnome      # 認証ダイアログ
    adw-gtk3          # GTK3 ダークテーマ
    papirus-icon-theme  # アイコンテーマ
    swaynotificationcenter  # 通知センター
  ];

  # swaync 設定
  home.file.".config/swaync/config.json".source = ../swaync/config.json;
  home.file.".config/swaync/style.css".source   = ../swaync/style.css;

  # GTK ダークテーマ
  gtk = {
    enable = true;
    theme = {
      name = "adw-gtk3-dark";
      package = pkgs.adw-gtk3;
    };
    iconTheme = {
      name = "Papirus-Dark";
      package = pkgs.papirus-icon-theme;
    };
    cursorTheme = {
      name = "Adwaita";
      size = 24;
    };
    gtk3.extraConfig.gtk-application-prefer-dark-theme = 1;
    gtk4.extraConfig.gtk-application-prefer-dark-theme = 1;
  };

  # Qt テーマ（GTK に従わせる）
  qt = {
    enable = true;
    platformTheme.name = "gtk";
  };

  # システムカラースキーム（GTK4/libadwaita アプリ向け）
  dconf.settings = {
    "org/gnome/desktop/interface" = {
      color-scheme = "prefer-dark";
      gtk-theme = "adw-gtk3-dark";
      icon-theme = "Papirus-Dark";
      cursor-theme = "Adwaita";
      cursor-size = 24;
    };
  };

  # ステータスバー
  programs.waybar = {
    enable = true;
    settings = {
      mainBar = {
        layer = "top";
        position = "top";
        height = 46;
        spacing = 4;
        modules-left = [ "hyprland/workspaces" ];
        modules-center = [ "clock" ];
        modules-right = [
          "pulseaudio"
          "network"
          "battery"
          "tray"
          "custom/notification"
          "custom/power"
        ];

        "hyprland/workspaces" = {
          format = "{id}";
          on-click = "activate";
        };

        clock = {
          format = "{:%H:%M}";
          format-alt = "{:%Y-%m-%d (%a) %H:%M}";
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

        "custom/notification" = {
          format = "{icon}";
          format-icons = {
            notification = "󰂚";
            none = "󰂜";
            dnd-notification = "󰂛";
            dnd-none = "󰂛";
          };
          return-type = "json";
          exec-if = "which swaync-client";
          exec = "swaync-client -swb";
          on-click = "swaync-client -t -sw";
          on-click-right = "swaync-client -d -sw";
          escape = true;
          tooltip = false;
        };

        "custom/power" = {
          format = "󰐥";
          on-click = "$HOME/.config/hypr/scripts/powermenu.sh";
          tooltip = false;
        };
      };
    };
    style = ''
      * {
        font-family: "HackGenNerd Console", "HackGenNerd", monospace;
        font-size: 13px;
        min-height: 0;
        border: none;
        border-radius: 0;
      }

      window#waybar {
        background-color: transparent;
        color: #cdd6f4;
      }

      /* 左・中央・右グループをそれぞれ角丸ピルに */
      .modules-left,
      .modules-center,
      .modules-right {
        background-color: rgba(30, 30, 46, 0.88);
        border-radius: 12px;
        margin: 5px 4px;
        padding: 0 6px;
      }

      #workspaces {
        background: transparent;
        padding: 0 2px;
      }

      #workspaces button {
        padding: 0 8px;
        color: #6c7086;
        background: transparent;
        border-radius: 8px;
        margin: 3px 2px;
        min-height: 24px;
      }

      #workspaces button.active {
        color: #89b4fa;
        background: rgba(137, 180, 250, 0.2);
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

      #custom-notification {
        padding: 0 12px;
        color: #cdd6f4;
        font-size: 15px;
      }

      #custom-notification.notification {
        color: #fab387;
      }

      #custom-notification:hover {
        background: rgba(250, 179, 135, 0.15);
        border-radius: 4px;
      }

      #custom-power {
        padding: 0 14px;
        color: #f38ba8;
        font-size: 15px;
        border-radius: 0 12px 12px 0;
      }

      #custom-power:hover {
        background: rgba(243, 139, 168, 0.15);
      }
    '';
  };

}
