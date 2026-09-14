# OpenTypeless を Hyprland (CachyOS) で使えるか 調査メモ (2026-09)

**保留 (2026-09-14 時点)** — ソースを読む限り「回避策を2か所入れれば動く」見込みだが、
実機で一度も起動していない。fcitx5 との相性と Linux 版の実績の薄さが未解消のため、
導入せず記録だけ残す。

## 1. 対象

音声入力ツール **OpenTypeless**。ホットキーを押して喋ると
録音 → STT(文字起こし)→ LLM で整形 → 前面アプリに直接タイプ、という流れ。

| 項目 | 値 |
|---|---|
| 上流 | https://github.com/tover0314-w/opentypeless (528 stars) |
| 公式サイト | https://www.opentypeless.com |
| ライセンス | MIT |
| 実装 | Tauri v2 (Rust + React/TypeScript) |
| 調査時のバージョン | v1.1.59 (2026-09-09) |

Wispr Flow / Superwhisper のオープンソース代替という位置づけ。
似た名前の [Open-Less/openless](https://github.com/Open-Less/openless) (AGPL, 3.5k stars) は
別プロジェクトで **macOS / Windows のみ**。Linux で使えるのはこちら。

## 2. 最大の障害 — Wayland を「信用できない環境」として扱う

`src-tauri/src/platform.rs` の `capabilities_for()` が、Linux + Wayland のとき

- `global_hotkey_reliable`
- `keyboard_output_reliable`
- `clipboard_auto_paste_reliable`

を**すべて `false`** にする。素直に入れると「ホットキーが効かない・
出力がクリップボード止まりで自動ペーストもされない」になる。

## 3. 回避策(ソースを読んで確認済み・未実機検証)

| 問題 | 回避策 | 根拠 |
|---|---|---|
| 出力が前面アプリに届かない | Wayland かつ非 KDE なら **`wtype`** で直接タイプする実装が既にある(KDE は `kwtype`、X11 は `xdotool`)。設定で出力モードを Keyboard にすれば通る | `src-tauri/src/output/keyboard.rs` |
| グローバルホットキーが効かない | `parse_cli_action()` が引数 `toggle` / `ask` を解釈し、`tauri-plugin-single-instance` で**起動中のインスタンスへ転送**する。→ アプリ内ホットキーは使わず、Hyprland 側で `bind = $mod, D, exec, <AppImage> toggle` にすればよい | `src-tauri/src/lib.rs` |

アプリ内グローバルホットキー(Linux 既定 `Ctrl+/` / `Ctrl+.`)が効かないのは、
`tauri-plugin-global-shortcut` が Linux で X11 の `XGrabKey` を使うため。
XWayland ウィンドウにフォーカスがあるときしか発火しない。

`wtype` は**既にこのマシンに入っており**、`home/dot_config/packages/pacman.txt:69` にも
登録済み。`home/dot_config/hypr/hyprland.conf:212` のクリップボード履歴バインドで既に実用している。

## 4. このマシンで既に揃っているもの

| 項目 | 状況 |
|---|---|
| 音声入力 | cpal → ALSA → pipewire-alsa。マイク複数認識済み(AT2040USB / Sound Blaster X5 / BRIO) |
| APIキー保管 | `keyring` crate が Secret Service を使う。`gnome-keyring` は `hyprland.conf:52` の `exec-once` で起動済み、`org.freedesktop.secrets` が D-Bus に出ている |
| トレイ常駐 | `libayatana-appindicator` 導入済み、waybar に `tray` モジュールあり(`waybar/config:119`) |
| GPU | Intel Arc B390 (Panther Lake)。NVIDIA 向けの `WEBKIT_DISABLE_DMABUF_RENDERER` 回避は不要(`lib.rs` の `linux_workaround_plan()` が NVIDIA+Wayland のときだけ自動適用する) |
| キーバインドの空き | `$mod+D` / `$mod SHIFT+D` はどちらも未使用 |

## 5. 足りないもの・詰まる点

- **AUR にパッケージが無い。** AUR の `typeless` は商用版 typeless.com の非公式ビルドで**別物**。
  公式配布は AppImage / deb / rpm のみ → AppImage 一択
- **AppImage の実行に `libfuse.so.2` が要るが未導入**(`fuse3` しかない)。
  `fuse2` は `extra` にある。または `--appimage-extract-and-run` で回避できる
- `Fn` / 右Alt の押しっぱなし方式は **macOS/Windows 専用**
  (`native_hotkey.rs` が `#[cfg(any(target_os = "macos", target_os = "windows"))]`)。
  Linux はトグル方式のみ
- 出力モードは **Keyboard を選ぶこと**。Clipboard だと Wayland では自動ペーストされない
  (`output/clipboard.rs` の `should_auto_paste_after_clipboard()` が Wayland で `false`)
- アプリ内の自動アップデータ(`tauri-plugin-updater`)が AppImage を自己書き換えするため、
  chezmoi でバージョン固定するなら設定で切る必要がある

## 6. 保留の理由(未検証)

- **fcitx5 との相性。** `wtype` は virtual-keyboard プロトコルで打鍵を注入するため、
  日本語入力モードが ON だと fcitx5 に食われて化ける可能性がある。
  `hyprland.conf:212` で wofi に `GTK_IM_MODULE=gtk-im-context-simple` を付けているのと
  同種の問題が出るかもしれない
- **Linux 版の実績が薄い。** v1.1.59 の AppImage ダウンロード数 142 に対し
  Windows 251 / macOS 118。Linux は後発で、そもそも起動しない可能性もある
- **`$mod+D` の反応速度が読めない。** バインドのたびに AppImage を二重起動して引数を
  転送する構造なので、FUSE マウント + 起動のコストが毎回乗る。実測しないと実用性が分からない。
  遅ければ D-Bus (`com.opentypeless.app`) を直叩きするラッパーに置き換える手がある

## 7. 入れると決めたときの構成(未実施)

### プロバイダ

BYOK / OpenAI キーで使う想定。音声は OpenTypeless のサーバーを経由せず
`api.openai.com` に直行する(README「BYOK vs Cloud」)。Cloud プランは不要。

- STT プロバイダ `openai-whisper` は**モデルが `whisper-1` 固定**(`src-tauri/src/stt/config.rs:34`)
- `gpt-4o-transcribe` を使いたい場合は `custom-whisper` に
  base URL `https://api.openai.com/v1` を入れる手があるが、
  `stt_provider_requires_api_key()` が `custom-whisper` を「キー不要」扱いするため
  Authorization ヘッダが載らない懸念がある。要検証
- 言語ヒント `language` は送信される(`stt/whisper_compat.rs:148`)ので日本語を指定できる
- **APIキーはアプリが gnome-keyring に保管する。リポジトリにもファイルにも置かない**

### リポジトリに入れるもの

| 対象 | 内容 |
|---|---|
| `home/dot_config/packages/pacman.txt` | `fuse2` を追加(`wtype` は登録済み) |
| `home/.chezmoiscripts/run_onchange_after_80-opentypeless.sh` | バージョンを変数で固定し、AppImage と `SHA256SUMS-linux-x86_64.txt` を取得して `sha256sum -c` で検証してから `~/.local/opt/opentypeless/` に設置。変数を書き換えるとアップデートになる |
| `home/dot_local/share/applications/opentypeless.desktop.tmpl` | `.desktop` の `Exec=` は `~` を展開しないので `{{ .chezmoi.homeDir }}` で絶対パスを埋める |
| `home/.chezmoiignore` | 非 cachyos ブロックに `.local/opt/**`・`.chezmoiscripts/80-opentypeless.sh` 等を追加 |
| `home/dot_config/hypr/hyprland.conf` | `exec-once` で常駐(転送先が必要なため必須)+ `$mod+D` = `toggle` / `$mod SHIFT+D` = `ask`。カプセル窓の `windowrule` は `hyprctl clients` で class を見てから決める(identifier は `com.opentypeless.app`、ウィンドウラベルは `main` / `capsule` / `ask`) |

## 8. 再開するときの最初の一手

1. AppImage を手で落とす
   (`https://github.com/tover0314-w/opentypeless/releases/latest`)
2. `fuse2` を入れるか `--appimage-extract-and-run` を付けて起動し、
   **まず「窓が出るか」だけ**を確認する。出なければ `WEBKIT_DISABLE_DMABUF_RENDERER=1` を試す
3. 窓が出たら OpenAI キーを入れ、出力モードを Keyboard にする
4. **fcitx5 の直接入力モード**でテキストエディタに向けて録音 → タイプされるか
5. 次に**日本語入力モード**で同じことを試す。ここが化けるかどうかが実用性の分かれ目
6. 通ったら `$mod+D` バインドの反応速度を測り、許容できれば chezmoi 化に進む

## 参考

- https://github.com/tover0314-w/opentypeless — 上流。Linux 節に
  「Wayland は compositor ごとに helper が要る(KDE は `kwtype`、他は `wtype`)」
  「helper が無い/失敗したらクリップボードに残す」と明記されている
- `docs/2026-08-08-reliability-punctuation-wayland-release-spec.md`(リポジトリ内)
  — Wayland 直接入力を入れたときの設計。「`wtype` はバンドルしない」方針が書かれている
- https://github.com/tover0314-w/opentypeless/issues/87 — Wayland direct text input
