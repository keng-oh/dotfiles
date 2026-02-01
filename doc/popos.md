# Pop!OSメモ

```bash
sudo apt update && sudo apt upgrade -y

# XPS 13 9315固有の設定
#このモデルは特殊なハードウェアがあるため、以下を確認：
# ファームウェアアップデート
sudo fwupdmgr refresh
sudo fwupdmgr get-updates
sudo fwupdmgr update

# サウンドドライバ（重要）
sudo apt install firmware-sof-signed -y

sudo apt install -y \
  git curl wget \
  build-essential \
  ca-certificates

# fcitx5とMozcをインストール
sudo apt install -y \
  fcitx5 \
  fcitx5-mozc \
  fcitx5-config-qt \
  fcitx5-frontend-gtk3 \
  fcitx5-frontend-gtk4 \
  fcitx5-frontend-qt5 \
  fcitx5-frontend-qt6

# 入力メソッドをfcitx5に設定
im-config -n fcitx5

# 環境変数設定ファイルを作成
mkdir -p ~/.config/environment.d
cat > ~/.config/environment.d/fcitx.conf << 'EOF'
GTK_IM_MODULE=fcitx
QT_IM_MODULE=fcitx
XMODIFIERS=@im=fcitx
EOF

# 診断ツールで問題を確認
fcitx5-diagnose
```
