{ config, pkgs, lib, ... }:

{
  # サーバー用設定（GUIアプリなし）
  home.packages = with pkgs; [
    # サーバー固有のパッケージがあれば追加
  ];

  # サーバー固有の環境変数
  home.sessionVariables = {
    # 必要に応じて追加
  };

}
