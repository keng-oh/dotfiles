{ config, pkgs, lib, ... }:

{
  # Hyprland 設定ファイル
  home.file.".config/hypr/hyprland.conf" = {
    source = ../hypr/hyprland.conf;
    force = true;
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
    adwaita-qt        # Qt ダークテーマ
  ];

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

  # Qt ダークテーマ
  qt = {
    enable = true;
    platformTheme.name = "gtk";
    style = {
      name = "adwaita-dark";
      package = pkgs.adwaita-qt;
    };
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
        font-family: "HackGenNerd Console", "HackGenNerd", monospace;
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
    font = "HackGenNerd Console 11";
  };
}
