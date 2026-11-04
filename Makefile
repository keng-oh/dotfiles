.PHONY: help install switch diff update doctor git-push

# デフォルトターゲット
.DEFAULT_GOAL := help

CONFIG_DIR := $(HOME)/repos/dotfiles

help: ## ヘルプを表示
	@echo "利用可能なコマンド:"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | \
		awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-15s\033[0m %s\n", $$1, $$2}'

install: ## 初回セットアップ
	@bash $(CONFIG_DIR)/init.sh

switch: ## 設定を適用
	@chezmoi apply -k
	@echo "✓ 設定を適用しました"

diff: ## 適用される差分を表示（適用せず）
	@chezmoi diff

update: ## リポジトリとパッケージを更新して設定を適用
	@echo "==> dotfilesを更新中..."
	@chezmoi update -k
	@# 配布先はCachyOS(paru)とDebian/Ubuntu系(apt + mise)の2系統。
	@# OSではなくコマンドの有無で判定し、どちらも無ければ失敗させる
	@if command -v paru >/dev/null 2>&1; then \
		echo "==> パッケージ(pacman/AUR)を更新中..."; \
		paru -Syu; \
	elif command -v apt-get >/dev/null 2>&1; then \
		echo "==> パッケージ(apt)を更新中..."; \
		sudo apt-get update && sudo apt-get upgrade; \
		if [ -x "$(HOME)/.local/bin/mise" ]; then \
			echo "==> mise管理ツールを更新中..."; \
			"$(HOME)/.local/bin/mise" upgrade --yes; \
		fi; \
	else \
		echo "!! 未対応のパッケージマネージャです(paru / apt-get が見つかりません)" >&2; \
		exit 1; \
	fi
	@echo "✓ 更新完了"

doctor: ## chezmoiの状態を診断
	@chezmoi doctor

git-push: ## Gitにコミット＆プッシュ
	@cd $(CONFIG_DIR) && \
		git add . && \
		git commit -m "Update: $$(date +%Y-%m-%d)" && \
		git push
	@echo "✓ GitHubにプッシュしました"
