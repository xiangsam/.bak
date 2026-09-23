#!/usr/bin/env bash
# ============================================================================
#  setup-shell.sh —— macOS 终端一键配置
#
#  内容：zsh 插件（补全/行内建议/语法高亮）+ starship preset + 历史强化
#
#  用法:
#     ./setup-shell.sh                  # 自动识别当前 preset 并沿用（识别不出则用 pastel-powerline）
#     ./setup-shell.sh tokyo-night      # 显式指定 preset
#     ./setup-shell.sh --list           # 列出全部可用 preset
#     DRY_RUN=1 ./setup-shell.sh        # 演练：只打印将做什么，不落盘
#
#  幂等：可反复运行。每次覆盖前自动备份到 ~/.dotfiles-backup/<时间戳>/
#  注意：本脚本不触碰 Ghostty/WezTerm 等终端模拟器的配置。
# ============================================================================
set -euo pipefail

# 中文字符串 + UTF-8 locale。
# 在 C/POSIX locale 下，bash 会把多字节字符的首字节当成合法的变量名字符，
# 于是 $VAR 紧跟前导中文（如 $PRESET（ ）时变量名会被读成 "PRESET\ufffd"，
# 报 "PRESET\ufffd: unbound variable"。这里固定 locale，
# 同时下文所有变量引用均用 ${VAR} 显式界定边界，不依赖 locale 行为。
export LC_ALL=en_US.UTF-8

readonly PRESET_DEFAULT="pastel-powerline"   # 仅在无法识别当前 preset 时兜底
readonly FORMULAE=(zsh-autosuggestions zsh-syntax-highlighting zsh-completions)
readonly STAMP="$(date +%Y%m%d-%H%M%S)"
readonly BACKUP_DIR="$HOME/.dotfiles-backup/$STAMP"

# ---------------------------------------------------------------------------
# 输出
# ---------------------------------------------------------------------------
info() { printf '\033[38;2;118;159;240m▸\033[0m %s\n' "$*"; }
ok()   { printf '\033[38;2;152;195;121m✓\033[0m %s\n' "$*"; }
warn() { printf '\033[38;2;209;154;102m!\033[0m %s\n' "$*"; }
die()  { printf '\033[38;2;224;108;117m✗ %s\033[0m\n' "$*" >&2; exit 1; }

run() {
  if [[ "${DRY_RUN:-0}" == "1" ]]; then
    printf '   \033[2m[dry-run]\033[0m %s\n' "$*"
  else
    "$@"
  fi
}

# ---------------------------------------------------------------------------
# 参数
# ---------------------------------------------------------------------------
PRESET=""   # 空 = 用户未指定，稍后自动识别
case "${1:-}" in
  "")
    ;;
  -h|--help)
    sed -n '3,15p' "$0"; exit 0
    ;;
  --list|-l)
    command -v starship >/dev/null || die "未安装 starship，先执行: brew install starship"
    exec starship preset --list
    ;;
  -*) die "未知参数: $1（用 --help 查看用法）" ;;
  *)  PRESET="$1" ;;
esac

[[ "${DRY_RUN:-0}" == "1" ]] && warn "DRY_RUN 模式：不会真正修改任何文件"

# ---------------------------------------------------------------------------
# 0. 环境检查
# ---------------------------------------------------------------------------
info "环境检查"
[[ "$(uname -s)" == "Darwin" ]] || die "本脚本只支持 macOS（当前: $(uname -s)）"
command -v brew >/dev/null || die "未找到 Homebrew，先安装: https://brew.sh"

BREW_PREFIX="$(brew --prefix)"
[[ -d "$BREW_PREFIX/share" ]] || die "Homebrew prefix 异常: $BREW_PREFIX"
ok "Homebrew prefix = $BREW_PREFIX"

# ---------------------------------------------------------------------------
# 1. 安装缺失的依赖
# ---------------------------------------------------------------------------
info "检查依赖"
missing=()
for f in starship "${FORMULAE[@]}"; do
  if brew list --formula "$f" >/dev/null 2>&1; then
    ok "已安装 $f"
  else
    warn "缺失 $f"
    missing+=("$f")
  fi
done

if (( ${#missing[@]} > 0 )); then
  info "安装: ${missing[*]}"
  run brew install "${missing[@]}"
else
  ok "依赖齐全"
fi

# ---------------------------------------------------------------------------
# 2. 确定 preset
#    未显式指定时，把当前 ~/.config/starship.toml 与内置 preset 逐个比对，
#    命中则沿用，实现「不改动你现有观感」的一键重配。
# ---------------------------------------------------------------------------
detect_preset() {
  local f="$HOME/.config/starship.toml" list p
  [[ -f "$f" ]] || return 1
  list="$(starship preset --list 2>/dev/null)" || return 1
  for p in $list; do
    if diff -q <(starship preset "$p" 2>/dev/null) "$f" >/dev/null 2>&1; then
      printf '%s\n' "$p"
      return 0
    fi
  done
  return 1
}

info "确定 preset"
if [[ -z "$PRESET" ]]; then
  if [[ "${DRY_RUN:-0}" == "1" ]]; then
    PRESET="$PRESET_DEFAULT"
    warn "dry-run：跳过自动识别，假定 $PRESET"
  elif detected="$(detect_preset)"; then
    PRESET="$detected"
    ok "自动识别到当前 preset = ${PRESET}（将是 no-op，观感不变）"
  else
    PRESET="$PRESET_DEFAULT"
    warn "无法识别当前 starship.toml 对应的 preset，回退到 $PRESET"
  fi
else
  ok "用户指定 preset = $PRESET"
fi

# 校验 preset 名称合法
if [[ "${DRY_RUN:-0}" != "1" ]]; then
  starship preset --list | grep -qx "$PRESET" \
    || die "未知 preset: $PRESET
可用值: $(starship preset --list | tr '\n' ' ')"
fi

# ---------------------------------------------------------------------------
# 3. 备份现有配置
# ---------------------------------------------------------------------------
info "备份现有配置 → $BACKUP_DIR"
STARSHIP_TOML="$HOME/.config/starship.toml"
ZSHRC="$HOME/.zshrc"

run mkdir -p "$BACKUP_DIR"
for f in "$STARSHIP_TOML" "$ZSHRC"; do
  if [[ -f "$f" ]]; then
    run cp "$f" "$BACKUP_DIR/"
    ok "备份 $(basename "$f")"
  else
    warn "$f 不存在，跳过备份"
  fi
done
# 顺手记下本脚本自身的版本，便于日后对账
run cp "$0" "$BACKUP_DIR/setup-shell.sh"

# ---------------------------------------------------------------------------
# 4. 写入 starship 配置
# ---------------------------------------------------------------------------
info "写入 $STARSHIP_TOML"
run mkdir -p "$(dirname "$STARSHIP_TOML")"
run starship preset "$PRESET" -f -o "$STARSHIP_TOML"

# ---------------------------------------------------------------------------
# 5. 写入 .zshrc
#    @BREW_PREFIX@ 在写入前替换为真实路径，避免运行时调用 brew（拖慢启动）
# ---------------------------------------------------------------------------
info "写入 $ZSHRC"
TMP_ZSHRC="$(mktemp)"
trap 'rm -f "$TMP_ZSHRC" "$TMP_ZSHRC.replaced"' EXIT

cat > "$TMP_ZSHRC" <<'ZSHRC_EOF'
# ============================================================================
#  ~/.zshrc  —— 由 setup-shell.sh 生成
#  手动修改后请勿重复运行脚本，或在运行前先备份。
# ============================================================================

# ---------------------------------------------------------------------------
# 环境变量
# ---------------------------------------------------------------------------
export PATH="$HOME/.local/bin:$PATH"

# ---------------------------------------------------------------------------
# 历史记录强化
# ---------------------------------------------------------------------------
HISTFILE="$HOME/.zsh_history"
HISTSIZE=100000                # 内存中保留的历史条数
SAVEHIST=100000                # 写入磁盘的条数

setopt EXTENDED_HISTORY        # 记录每条命令的时间戳与耗时
setopt INC_APPEND_HISTORY      # 命令执行后立即落盘（多窗口实时共享）
setopt SHARE_HISTORY           # 所有 shell 共享同一份历史
setopt HIST_IGNORE_DUPS        # 连续重复的命令只记一条
setopt HIST_IGNORE_ALL_DUPS    # 整份历史内重复命令只保留最新一条
setopt HIST_IGNORE_SPACE       # 以空格开头的命令不留痕（跑敏感命令时用）
setopt HIST_VERIFY             # !! / !$ 展开后先回显，再按回车才执行
setopt HIST_REDUCE_BLANKS      # 写入前压缩多余空白
setopt HIST_EXPIRE_DUPS_FIRST  # 超出 HISTSIZE 时优先淘汰重复项

# ---------------------------------------------------------------------------
# 补全系统（zsh-completions 提供额外补全定义）
#   fpath 必须在 compinit 之前扩展
# ---------------------------------------------------------------------------
[[ -d @BREW_PREFIX@/share/zsh-completions ]] && fpath=(@BREW_PREFIX@/share/zsh-completions $fpath)

mkdir -p "$HOME/.cache/zsh"

autoload -Uz compinit
# .zcompdump 超过 24 小时才重建；否则用 -C 跳过安全检查，加快启动
if [[ -n ${ZDOTDIR:-$HOME}/.zcompdump(#qN.mh+24) ]]; then
  compinit
else
  compinit -C
fi

setopt AUTO_MENU            # 第二次 Tab 进入菜单，用方向键上下选
setopt AUTO_LIST            # 有歧义时自动列出候选
setopt COMPLETE_IN_WORD     # 光标停在词中间也能补全
setopt ALWAYS_TO_END        # 补全后光标自动跳到词尾

zstyle ':completion:*' menu select                                  # 菜单式补全
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}'           # 大小写不敏感
zstyle ':completion:*' group-name ''                                # 候选按类别分组
zstyle ':completion:*:descriptions' format '%F{yellow}-- %d --%f'   # 组标题
zstyle ':completion:*' use-cache on
zstyle ':completion:*' cache-path "$HOME/.cache/zsh/compcache"

# ---------------------------------------------------------------------------
# 上/下方向键：按前缀搜索历史
#   例：打完 "git " 再按 ↑，只在以 "git " 开头的历史里翻
#   纯 zsh 内建 widget，不需要额外插件
# ---------------------------------------------------------------------------
autoload -Uz up-line-or-beginning-search down-line-or-beginning-search
zle -N up-line-or-beginning-search
zle -N down-line-or-beginning-search
[[ -n ${terminfo[kcuu1]} ]] && bindkey "${terminfo[kcuu1]}" up-line-or-beginning-search
[[ -n ${terminfo[kcud1]} ]] && bindkey "${terminfo[kcud1]}" down-line-or-beginning-search

# ---------------------------------------------------------------------------
# nvm
# ---------------------------------------------------------------------------
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"

# ---------------------------------------------------------------------------
# zsh-autosuggestions —— 灰色行内建议（按 → / Ctrl+Space 接受）
#   所有 ZSH_AUTOSUGGEST_* 变量必须在 source 之前设置
# ---------------------------------------------------------------------------
ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE='fg=#6c7086'   # 建议文字颜色：暗灰
ZSH_AUTOSUGGEST_STRATEGY=(history)             # 只查历史，零延迟
ZSH_AUTOSUGGEST_BUFFER_MAX_SIZE=20             # 输入超 20 字符不再建议，防卡顿
# 不要设 ZSH_AUTOSUGGEST_USE_ASYNC：插件源码在 zsh >= 5.0.8 上会强制清空它
# （老版本 async 下 ^C 失灵，见 zsh-autosuggestions issue #364），写了也是被静默抹掉。

if [[ -f @BREW_PREFIX@/share/zsh-autosuggestions/zsh-autosuggestions.zsh ]]; then
  source @BREW_PREFIX@/share/zsh-autosuggestions/zsh-autosuggestions.zsh
  bindkey '^ '    autosuggest-accept           # Ctrl+Space 接受建议
  bindkey '^[[Z'  autosuggest-accept           # Shift+Tab 接受建议（默认未占用）
fi

# ---------------------------------------------------------------------------
# starship 提示符（配置见 ~/.config/starship.toml）
# ---------------------------------------------------------------------------
command -v starship >/dev/null && eval "$(starship init zsh)"

# ---------------------------------------------------------------------------
# zsh-syntax-highlighting —— 命令着色（合法=绿，非法=红）
#   必须放在最后 source，否则会覆盖上面插件的 zle 绑定
# ---------------------------------------------------------------------------
ZSH_HIGHLIGHT_HIGHLIGHTERS=(main brackets pattern cursor root line)
if [[ -f @BREW_PREFIX@/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh ]]; then
  source @BREW_PREFIX@/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

  # 配色贴近 pastel-powerline 的冷色调
  typeset -A ZSH_HIGHLIGHT_STYLES
  ZSH_HIGHLIGHT_STYLES[command]='fg=#98c379,bold'                     # 有效命令：绿
  ZSH_HIGHLIGHT_STYLES[unknown-token]='fg=#e06c75'                    # 未知命令：红
  ZSH_HIGHLIGHT_STYLES[builtin]='fg=#61afef'                          # 内建命令：蓝
  ZSH_HIGHLIGHT_STYLES[alias]='fg=#56b6c2'                            # 别名：青
  ZSH_HIGHLIGHT_STYLES[path]='fg=#a3aed2,underline'                   # 存在路径：淡紫下划线
  ZSH_HIGHLIGHT_STYLES[path_pathseparator]='fg=#a3aed2'
  ZSH_HIGHLIGHT_STYLES[globbing]='fg=#c678dd'
  ZSH_HIGHLIGHT_STYLES[reserved-word]='fg=#c678dd,bold'
  ZSH_HIGHLIGHT_STYLES[single-quoted-argument]='fg=#d19a66'
  ZSH_HIGHLIGHT_STYLES[double-quoted-argument]='fg=#d19a66'
  ZSH_HIGHLIGHT_STYLES[comment]='fg=#5c6370,italic'
  ZSH_HIGHLIGHT_STYLES[bracket-level-1]='fg=#a3aed2,bold'
  ZSH_HIGHLIGHT_STYLES[bracket-level-2]='fg=#769ff0,bold'
  ZSH_HIGHLIGHT_STYLES[root]='bg=#e06c75'
fi
ZSHRC_EOF

# 占位符替换：故意不用 sed。
# macOS 的 BSD sed 在 C locale 下对含多字节 UTF-8 的内容做替换会报
#   sed: RE error: illegal byte sequence
# 并直接退出（本脚本模板带大量中文注释，必然命中）。而 sed 的 -i 参数
# 在 BSD/GNU 上又不兼容，写一行要兼顾两个平台太脆。
# bash 的 ${var//pat/repl} 是字面替换：无 locale 依赖、无平台差异。
while IFS= read -r _line || [[ -n "$_line" ]]; do
  printf '%s\n' "${_line//@BREW_PREFIX@/$BREW_PREFIX}"
 done < "$TMP_ZSHRC" > "$TMP_ZSHRC.replaced"

if [[ "${DRY_RUN:-0}" != "1" ]]; then
  if grep -q '@BREW_PREFIX@' "$TMP_ZSHRC.replaced"; then
    die "占位符替换失败，$TMP_ZSHRC.replaced 中仍残留 @BREW_PREFIX@"
  fi
fi

run mv "$TMP_ZSHRC.replaced" "$TMP_ZSHRC"
run cp "$TMP_ZSHRC" "$ZSHRC"

# ---------------------------------------------------------------------------
# 6. 修掉让 compinit 卡死提问的权限问题
#    /opt/homebrew/share 若是 group-writable，compinit 会交互询问
#    "Ignore insecure directories and continue [y] or abort compinit [n]?"
#    这个提问会阻塞新开的终端。Homebrew 官方做法就是收掉 group 写权限。
# ---------------------------------------------------------------------------
info "检查 compinit 目录权限"
# compinit 判定「不安全」的条件是该目录对 group/other 可写。
# 注意 stat -f '%p' 返回含文件类型位（755 → 40755），必须用 %Lp 或直接查权限字符串。
SHARE_PERM="$(stat -f '%Sp' "$BREW_PREFIX/share" 2>/dev/null)"
if [[ "${SHARE_PERM:5:1}" == "w" || "${SHARE_PERM:8:1}" == "w" ]]; then
  warn "$BREW_PREFIX/share 为 ${SHARE_PERM}（group/other 可写），compinit 会报 insecure 并弹提问阻塞终端"
  run chmod go-w "$BREW_PREFIX/share"
  ok "已执行 chmod go-w $BREW_PREFIX/share"
else
  ok "权限正常（${SHARE_PERM}）"
fi

# ---------------------------------------------------------------------------
# 7. 验证
# ---------------------------------------------------------------------------
info "验证"
[[ "${DRY_RUN:-0}" == "1" ]] && { warn "DRY_RUN：跳过验证"; exit 0; }

fail=0
zsh -n "$ZSHRC" && ok ".zshrc 语法正确" || { warn ".zshrc 语法有误"; fail=1; }

for f in "$STARSHIP_TOML" "$ZSHRC"; do
  if [[ -s "$f" ]]; then
    ok "已生成 ${f}（$(wc -c < "$f" | tr -d ' ') 字节）"
  else
    warn "缺失或为空: $f"
    fail=1
  fi
done

# 确认写入的 preset 确实生效
if diff -q <(starship preset "$PRESET") "$STARSHIP_TOML" >/dev/null 2>&1; then
  ok "starship.toml 与 preset '$PRESET' 一致"
else
  warn "starship.toml 与 preset '$PRESET' 不一致"
  fail=1
fi

autoload_ok() {  # $1=路径片段
  grep -q "$1" "$ZSHRC" && ok "已启用 ${1##*/}" || { warn "未启用 $1"; fail=1; }
}
autoload_ok "zsh-autosuggestions/zsh-autosuggestions.zsh"
autoload_ok "zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"
autoload_ok "zsh-completions"

if zsh -c 'autoload -Uz compaudit; [[ -d '"$BREW_PREFIX"'/share/zsh-completions ]] && fpath=('"$BREW_PREFIX"'/share/zsh-completions $fpath); compaudit' 2>&1 | grep -q .; then
  warn "compaudit 仍报告不安全目录，见上方输出"
  fail=1
else
  ok "compaudit 无告警"
fi

echo
if (( fail == 0 )); then
  ok "配置完成。开一个新终端窗口即可生效（当前窗口执行: source ~/.zshrc）"
else
  warn "配置完成但有告警，请检查上方 ✗/! 项"
fi
info "备份位于 $BACKUP_DIR"
info "回滚: cp $BACKUP_DIR/.zshrc ~/ && cp $BACKUP_DIR/starship.toml ~/.config/"
