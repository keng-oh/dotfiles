.PHONY: help install update switch check clean info backup git-push

# シェルをBashに指定
SHELL := /bin/bash

# デフォルトターゲット
.DEFAULT_GOAL := help

# OSの検出
UNAME := $(shell uname -s)
ifeq ($(UNAME),Linux)
    SYSTEM := linux
else ifeq ($(UNAME),Darwin)
    SYSTEM := mac
else
    $(error Unsupported OS: $(UNAME))
endif

# 設定ディレクトリ
CONFIG_DIR := $(HOME)/repos/dotfiles
FLAKE_PATH := $(CONFIG_DIR)\#$(SYSTEM)

help: ## ヘルプを表示
	@echo "利用可能なコマンド:"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | \
		awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-15s\033[0m %s\n", $$1, $$2}'

install: ## 初回セットアップ（Nix + Home Manager）
	@echo "==> Nixのインストール状態を確認..."
	@if ! command -v nix >/dev/null 2>&1; then \
		echo "==> Nixをインストール中..."; \
		sh <(curl -L https://nixos.org/nix/install) --daemon; \
		echo "==> シェルを再起動してください: exec $$SHELL"; \
		exit 0; \
	fi
	@echo "==> Nix設定を確認..."
	@mkdir -p $(HOME)/.config/nix
	@if ! grep -q "experimental-features" $(HOME)/.config/nix/nix.conf 2>/dev/null; then \
		echo "experimental-features = nix-command flakes" >> $(HOME)/.config/nix/nix.conf; \
		echo "==> Flakes機能を有効化しました"; \
	fi
	@echo "==> flake.lockを生成中..."
	@cd $(CONFIG_DIR) && nix flake update
	@echo "==> Home Managerを適用中..."
	@cd $(CONFIG_DIR) && nix run home-manager/master -- switch --flake $(FLAKE_PATH)
	@echo ""
	@echo "✓ セットアップ完了！"
	@echo "  シェルを再起動してください: exec zsh"

switch: ## 設定を適用
	@echo "==> Home Manager設定を適用中..."
	@home-manager switch --flake $(FLAKE_PATH)
	@echo "✓ 設定を適用しました"

update: ## flakeを更新して設定を適用
	@echo "==> flakeを更新中..."
	@cd $(CONFIG_DIR) && nix flake update
	@echo "==> 設定を適用中..."
	@home-manager switch --flake $(FLAKE_PATH)
	@echo "✓ 更新完了"

check: ## 設定をチェック（適用せず）
	@echo "==> 設定をチェック中..."
	@cd $(CONFIG_DIR) && nix flake check
	@echo "✓ 設定に問題ありません"

clean: ## 古い世代を削除
	@echo "==> 古い世代を削除中..."
	@home-manager expire-generations "-7 days"
	@nix-collect-garbage -d
	@echo "✓ クリーンアップ完了"

info: ## システム情報を表示
	@echo "System: $(SYSTEM)"
	@echo "Config: $(FLAKE_PATH)"
	@echo "Nix version: $$(nix --version)"
	@if command -v home-manager >/dev/null 2>&1; then \
		echo "Home Manager: installed"; \
	else \
		echo "Home Manager: not installed"; \
	fi

backup: ## 現在の設定をバックアップ
	@echo "==> バックアップ作成中..."
	@tar -czf $(HOME)/home-manager-backup-$$(date +%Y%m%d-%H%M%S).tar.gz -C $(HOME)/.config home-manager
	@echo "✓ バックアップ完了: ~/home-manager-backup-*.tar.gz"

git-push: ## Gitにコミット＆プッシュ
	@cd $(CONFIG_DIR) && \
		git add . && \
		git commit -m "Update: $$(date +%Y-%m-%d)" && \
		git push
	@echo "✓ GitHubにプッシュしました"
