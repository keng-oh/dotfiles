{ config, pkgs, ... }:

{
  # macOS固有の設定
  home.packages = with pkgs; [
    # macOS専用ツール（必要に応じて追加）
  ];

  # macOS固有の環境変数
  home.sessionVariables = {
    # 必要に応じて追加
  };
}
