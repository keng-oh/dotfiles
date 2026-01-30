{ config, pkgs, ... }:

{
  # Linux固有の設定
  home.packages = with pkgs; [
    # Linux専用ツール（必要に応じて追加）
  ];

  # Linux固有の環境変数
  home.sessionVariables = {
    # 必要に応じて追加
  };
}
