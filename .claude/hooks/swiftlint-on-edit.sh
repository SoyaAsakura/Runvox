#!/bin/bash
#
# Claude Code PostToolUse hook: 編集された .swift ファイルだけ SwiftLint をかける。
# 警告のみ（自動修正はしない）。違反があれば exit 2 で stderr を Claude に返す。
#
# 安全側の挙動:
#   - .swift 以外 / 存在しないファイル / swiftlint 未インストール → 何もせず exit 0
#   - 違反ゼロ → exit 0
#   - 違反あり → 内容を stderr に出して exit 2 (Claude にフィードバック)
#
# stdin: Claude Code から渡される PostToolUse の JSON
#   { "tool_name": "Edit", "tool_input": { "file_path": "...", ... }, ... }

input=$(cat)

file_path=$(printf '%s' "$input" | jq -r '.tool_input.file_path // empty' 2>/dev/null)

# 対象外は静かに通過
[ -z "$file_path" ] && exit 0
case "$file_path" in
  *.swift) ;;
  *) exit 0 ;;
esac
[ -f "$file_path" ] || exit 0
command -v swiftlint >/dev/null 2>&1 || exit 0

# .swiftlint.yml がある最も近い祖先ディレクトリを設定ルートにする
root=$(cd "$(dirname "$file_path")" 2>/dev/null && pwd)
[ -z "$root" ] && exit 0
while [ "$root" != "/" ] && [ ! -f "$root/.swiftlint.yml" ]; do
  root=$(dirname "$root")
done

# そのファイル単体を lint（設定ルートで実行して .swiftlint.yml を効かせる）
result=$(cd "$root" && swiftlint lint --quiet "$file_path" 2>/dev/null)

if [ -n "$result" ]; then
  {
    echo "SwiftLint violations in $(basename "$file_path") (consider fixing before commit):"
    echo "$result"
  } >&2
  exit 2
fi

exit 0
