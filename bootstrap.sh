#!/usr/bin/env bash
# dogfood-harness bootstrap — interactive installer.
# Создаёт новый dogfood-проект из template/ с подстановкой placeholder'ов,
# git init, commit, gh repo create --private, push.
#
# Usage:
#   bash ~/.claude/dogfood-harness/bootstrap.sh
#   bash ~/.claude/dogfood-harness/bootstrap.sh --template contentmanager
#
# Available templates:
#   (default)       — dev project (code + tests + phased build)
#   contentmanager  — non-dev content workflow (Instagram/social media)
#
# Or add alias: alias dogfood-new='bash ~/.claude/dogfood-harness/bootstrap.sh'

set -euo pipefail

# --- Parse args ---
TEMPLATE_NAME="template"  # default: base dev template

while [[ $# -gt 0 ]]; do
  case "$1" in
    --template)
      case "${2:-}" in
        ""|default|base)
          TEMPLATE_NAME="template"
          ;;
        *)
          TEMPLATE_NAME="template-$2"
          ;;
      esac
      shift 2
      ;;
    --template=*)
      _val="${1#*=}"
      case "$_val" in
        default|base|"")
          TEMPLATE_NAME="template"
          ;;
        *)
          TEMPLATE_NAME="template-${_val}"
          ;;
      esac
      shift
      ;;
    -h|--help)
      cat <<'HELP'
Usage: bootstrap.sh [--template <name>]

Templates:
  (default)         — standard dev project (CLAUDE, PLAN, RISKS, AGENT-MAP)
  contentmanager    — non-dev content workflow (Instagram/social media/СМИ)

Examples:
  dogfood-new
  dogfood-new --template contentmanager

HELP
      exit 0
      ;;
    *)
      echo "Unknown arg: $1" >&2
      echo "Run with --help for usage" >&2
      exit 1
      ;;
  esac
done

# --- Resolve paths ---
HARNESS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEMPLATE_DIR="${HARNESS_DIR}/${TEMPLATE_NAME}"

if [ ! -d "$TEMPLATE_DIR" ]; then
  echo "ERROR: ${TEMPLATE_NAME}/ не найден в ${HARNESS_DIR}" >&2
  echo "Available templates:" >&2
  find "$HARNESS_DIR" -maxdepth 1 -type d -name 'template*' -exec basename {} \; | sed 's/^/  /' >&2
  exit 1
fi

# --- Banner ---
cat <<BANNER
==============================================
  dogfood-harness — new project bootstrap
  template: ${TEMPLATE_NAME}
==============================================
Создаст новый проект с harness'ом из SoloYolo методики:
  - CLAUDE.md, PLAN.md, RISKS.md, AGENT-MAP.md
  - git init, private GitHub repo, initial push

Ctrl-C в любой момент — safe abort (ничего не сохраняется).
==============================================

BANNER

# --- Interactive prompts ---
prompt_required() {
  local var_name="$1"
  local prompt_text="$2"
  local example="$3"
  local value=""
  while [ -z "$value" ]; do
    if [ -n "$example" ]; then
      read -r -p "${prompt_text} (e.g. \"${example}\"): " value
    else
      read -r -p "${prompt_text}: " value
    fi
    if [ -z "$value" ]; then
      echo "  (обязательное поле)" >&2
    fi
  done
  printf -v "$var_name" '%s' "$value"
}

# Defaults — overwritten by template-specific prompts below
BRAND_NAME=""
OWNER_FIRST_NAME=""
ORG_NAME=""
BRAND_REGION=""
SPRINT_LENGTH=""
BRAND_CHARACTER=""

case "$TEMPLATE_NAME" in
  template-contentmanager)
    # Content-manager non-dev workflow
    prompt_required PROJECT_NAME "Project name (slug, используется для folder/repo)" "aqmolahub-content"
    PROJECT_SLUG=$(printf '%s' "$PROJECT_NAME" | tr '[:upper:]' '[:lower:]' | tr -cs 'a-z0-9' '-' | sed 's/^-//;s/-$//')
    if [ "$PROJECT_SLUG" != "$PROJECT_NAME" ]; then
      echo "  → slug: ${PROJECT_SLUG}"
    fi

    prompt_required BRAND_NAME "Brand name (displayed)" "AQMOLA HUB"
    prompt_required OWNER_FIRST_NAME "Твоё имя (owner)" "Айгуль"
    prompt_required ORG_NAME "Organization / employer" "AQMOLA HUB (Astana Hub regional)"
    prompt_required BRAND_REGION "Region served" "Акмолинская область, Кокшетау"

    read -r -p "Sprint length [3 недели]: " SPRINT_LENGTH
    SPRINT_LENGTH="${SPRINT_LENGTH:-3 недели}"

    read -r -p "Brand character (1 строка) [government-adjacent IT ecosystem — профессиональный, community-oriented]: " BRAND_CHARACTER
    BRAND_CHARACTER="${BRAND_CHARACTER:-government-adjacent IT ecosystem — профессиональный, community-oriented}"

    # Pitch/first_user aren't used in content template but we keep them filled
    # for any potential future cross-template placeholder
    ONE_LINE_PITCH="Контент-workflow ${BRAND_NAME}: 7 AI-агентов для Instagram и СМИ"
    FIRST_USER="${OWNER_FIRST_NAME} (solo content-manager)"
    ;;

  *)
    # Default: dev project template
    prompt_required PROJECT_NAME "Project name" "dailyquest"
    PROJECT_SLUG=$(printf '%s' "$PROJECT_NAME" | tr '[:upper:]' '[:lower:]' | tr -cs 'a-z0-9' '-' | sed 's/^-//;s/-$//')
    if [ "$PROJECT_SLUG" != "$PROJECT_NAME" ]; then
      echo "  → slug (для git/folder): ${PROJECT_SLUG}"
    fi

    prompt_required ONE_LINE_PITCH "One-line pitch" "RPG-квест для задач ребёнка"
    prompt_required FIRST_USER "First user (who uses v1)" "сын owner'а, 8 лет"
    ;;
esac

# Parent directory
DEFAULT_PARENT="/Users/user"
read -r -p "Parent directory [${DEFAULT_PARENT}]: " PARENT_DIR
PARENT_DIR="${PARENT_DIR:-$DEFAULT_PARENT}"

TARGET_DIR="${PARENT_DIR}/${PROJECT_SLUG}"

if [ -e "$TARGET_DIR" ]; then
  echo "ERROR: ${TARGET_DIR} уже существует — прерываем, чтобы не затереть" >&2
  exit 1
fi

# GitHub repo
DEFAULT_GH_USER="qartelio"
read -r -p "GitHub owner [${DEFAULT_GH_USER}]: " GH_USER
GH_USER="${GH_USER:-$DEFAULT_GH_USER}"

read -r -p "Создать private GitHub repo ${GH_USER}/${PROJECT_SLUG}? [Y/n]: " create_repo
create_repo="${create_repo:-Y}"

# --- Confirm ---
BOOTSTRAP_DATE=$(date +'%Y-%m-%d')

if [[ "$TEMPLATE_NAME" == "template-contentmanager" ]]; then
  cat <<EOF

--- Bootstrap plan ---
  Template:       ${TEMPLATE_NAME}
  Target:         ${TARGET_DIR}
  Project slug:   ${PROJECT_SLUG}
  Brand:          ${BRAND_NAME}
  Owner:          ${OWNER_FIRST_NAME}
  Org:            ${ORG_NAME}
  Region:         ${BRAND_REGION}
  Sprint:         ${SPRINT_LENGTH}
  Character:      ${BRAND_CHARACTER}
  Date:           ${BOOTSTRAP_DATE}
  GitHub repo:    $(if [[ "${create_repo}" =~ ^[Yy] ]]; then echo "${GH_USER}/${PROJECT_SLUG} (private)"; else echo "(skipped)"; fi)

EOF
else
  cat <<EOF

--- Bootstrap plan ---
  Template:     ${TEMPLATE_NAME}
  Target:       ${TARGET_DIR}
  Project:      ${PROJECT_NAME}
  Slug:         ${PROJECT_SLUG}
  Pitch:        ${ONE_LINE_PITCH}
  First user:   ${FIRST_USER}
  Date:         ${BOOTSTRAP_DATE}
  GitHub repo:  $(if [[ "${create_repo}" =~ ^[Yy] ]]; then echo "${GH_USER}/${PROJECT_SLUG} (private)"; else echo "(skipped)"; fi)

EOF
fi

read -r -p "Proceed? [Y/n]: " confirm
confirm="${confirm:-Y}"
if [[ ! "$confirm" =~ ^[Yy] ]]; then
  echo "Aborted."
  exit 0
fi

# --- Copy template ---
echo
echo "[1/6] Copying template to ${TARGET_DIR}..."
mkdir -p "$PARENT_DIR"
# Use cp -R, then remove any stale git metadata (template must not carry its own .git)
cp -R "$TEMPLATE_DIR" "$TARGET_DIR"
rm -rf "${TARGET_DIR}/.git" 2>/dev/null || true

# --- Substitute placeholders ---
echo "[2/6] Substituting placeholders..."
# Use a portable sed approach (BSD sed on macOS, GNU sed on Linux)
if sed --version >/dev/null 2>&1; then
  SED_INPLACE=(sed -i)
else
  SED_INPLACE=(sed -i '')
fi

escape_sed() {
  printf '%s' "$1" | sed -e 's/[\/&|]/\\&/g'
}

ESC_NAME=$(escape_sed "$PROJECT_NAME")
ESC_SLUG=$(escape_sed "$PROJECT_SLUG")
ESC_PITCH=$(escape_sed "$ONE_LINE_PITCH")
ESC_USER=$(escape_sed "$FIRST_USER")
ESC_DATE=$(escape_sed "$BOOTSTRAP_DATE")
ESC_BRAND=$(escape_sed "$BRAND_NAME")
ESC_OWNER_FIRST=$(escape_sed "$OWNER_FIRST_NAME")
ESC_ORG=$(escape_sed "$ORG_NAME")
ESC_REGION=$(escape_sed "$BRAND_REGION")
ESC_SPRINT=$(escape_sed "$SPRINT_LENGTH")
ESC_CHAR=$(escape_sed "$BRAND_CHARACTER")

# Find files to substitute (text files only, skip binary / node_modules / etc)
# Note: unused placeholders in target files are no-ops (sed leaves them intact)
while IFS= read -r -d '' file; do
  "${SED_INPLACE[@]}" \
    -e "s|{{PROJECT_NAME}}|${ESC_NAME}|g" \
    -e "s|{{PROJECT_SLUG}}|${ESC_SLUG}|g" \
    -e "s|{{ONE_LINE_PITCH}}|${ESC_PITCH}|g" \
    -e "s|{{FIRST_USER}}|${ESC_USER}|g" \
    -e "s|{{BOOTSTRAP_DATE}}|${ESC_DATE}|g" \
    -e "s|{{BRAND_NAME}}|${ESC_BRAND}|g" \
    -e "s|{{OWNER_FIRST_NAME}}|${ESC_OWNER_FIRST}|g" \
    -e "s|{{ORG_NAME}}|${ESC_ORG}|g" \
    -e "s|{{BRAND_REGION}}|${ESC_REGION}|g" \
    -e "s|{{SPRINT_LENGTH}}|${ESC_SPRINT}|g" \
    -e "s|{{BRAND_CHARACTER}}|${ESC_CHAR}|g" \
    "$file"
done < <(find "$TARGET_DIR" -type f \( -name '*.md' -o -name '*.json' -o -name '*.sh' -o -name '.gitignore' \) -print0)

# --- Permissions ---
echo "[3/6] Setting script permissions..."
if [ -d "$TARGET_DIR/.claude/scripts" ]; then
  find "$TARGET_DIR/.claude/scripts" -type f -name '*.sh' -exec chmod +x {} \;
else
  echo "  (no .claude/scripts/ in this template — skipping)"
fi

# --- Git init ---
echo "[4/6] git init + initial commit..."
cd "$TARGET_DIR"
git init -q -b main
git add -A
git commit -q -m "chore: bootstrap from dogfood-harness

- ${ONE_LINE_PITCH}
- Harness: CLAUDE.md, PLAN.md, RISKS.md, AGENT-MAP.md, .claude/
- Source: qartelio/dogfood-harness
- Bootstrap date: ${BOOTSTRAP_DATE}"

# --- GitHub repo create ---
if [[ "$create_repo" =~ ^[Yy] ]]; then
  echo "[5/6] Creating private GitHub repo ${GH_USER}/${PROJECT_SLUG}..."
  if command -v gh >/dev/null 2>&1; then
    if gh repo create "${GH_USER}/${PROJECT_SLUG}" --private --source=. --remote=origin --description "${ONE_LINE_PITCH}" --push 2>&1; then
      echo "  ✓ Repo created and pushed"
    else
      echo "  ⚠ gh repo create failed — create manually later:"
      echo "    gh repo create ${GH_USER}/${PROJECT_SLUG} --private --source=. --push"
    fi
  else
    echo "  ⚠ gh CLI не установлен — пропускаю remote create."
    echo "    Install: https://cli.github.com/ — then run:"
    echo "    cd ${TARGET_DIR} && gh repo create ${GH_USER}/${PROJECT_SLUG} --private --source=. --push"
  fi
else
  echo "[5/6] Skipped GitHub repo creation."
fi

# --- Summary ---
echo "[6/6] Done."
echo

if [[ "$TEMPLATE_NAME" == "template-contentmanager" ]]; then
  cat <<EOF
==============================================
  ${BRAND_NAME} контент-workflow — готов!
  Repo: ${TARGET_DIR}
==============================================

Next steps (Phase 0 — Corpus Collection):
  1. cd ${TARGET_DIR} && claude
  2. Ищи TEMPLATE-TODO маркеры в CLAUDE.md / AGENT-MAP.md — адаптируй под специфику
  3. Заполни docs/corpus/:
       - brand-book (PDF/md) — цвета, шрифты, tone-of-voice
       - top-posts/ (5-7 успешных)
       - flop-posts/ (3-5 неудачных — важны!)
       - voice-guide.md (как пишем / как не пишем)
       - forbidden-topics.md (что не трогаем)
  4. Заполни docs/metrics/baseline.md — стартовые цифры
  5. Заполни docs/metrics/kpi-targets.md — цели спринта
  6. Когда Phase 0 готов — флипни 🟡 marker в PLAN.md на Phase 1 (Agent Setup MVP)

⚠ Corporate IP: docs/corpus/ в .gitignore. Не коммить брендовые материалы.
⚠ Setup-session: owner на связи @qartelio, пиши если что-то непонятно.
==============================================
EOF
else
  cat <<EOF
==============================================
  ${PROJECT_NAME} bootstrapped at ${TARGET_DIR}
==============================================

Next steps:
  1. cd ${TARGET_DIR} && claude
  2. Адаптируй CLAUDE.md, PLAN.md, RISKS.md, AGENT-MAP.md под project specifics
     — ищи TEMPLATE-TODO и PLACEHOLDER маркеры
  3. Создай docs/idea.md с первой гипотезой
  4. Первый research в docs/research/
  5. ADR 001 для первого нетривиального решения
  6. Когда Phase 0 готов — флипни 🟡 marker в PLAN.md на Phase 1

Session-state hook запустится автоматически в конце каждой сессии.
==============================================
EOF
fi
