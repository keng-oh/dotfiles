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
	@echo "==> パッケージ(pacman/AUR)を更新中..."
	@paru -Syu
	@echo "✓ 更新完了"

doctor: ## chezmoiの状態を診断
	@chezmoi doctor

git-push: ## Gitにコミット＆プッシュ
	@cd $(CONFIG_DIR) && \
		git add . && \
		git commit -m "Update: $$(date +%Y-%m-%d)" && \
		git push
	@echo "✓ GitHubにプッシュしました"
