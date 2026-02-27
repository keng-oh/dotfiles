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

  # デフォルトシェルをzshに変更（/etc/shellsへの追加にsudoが必要）
  home.activation.setDefaultShell = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    ZSH_PATH="${pkgs.zsh}/bin/zsh"
    if ! grep -qF "$ZSH_PATH" /etc/shells 2>/dev/null; then
      echo "==> /etc/shellsにzshを追加中（sudo必要）..."
      echo "$ZSH_PATH" | sudo tee -a /etc/shells
    fi
    if [ "$SHELL" != "$ZSH_PATH" ]; then
      echo "==> デフォルトシェルをzshに変更中..."
      $DRY_RUN_CMD chsh -s "$ZSH_PATH"
    fi
  '';
}
