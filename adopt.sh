#!/usr/bin/env bash
# dogfood-harness adopt — установка harness в EXISTING проект.
# Non-destructive: backup'ит существующие harness-файлы, не перезаписывает.
# Генерирует adopt-flavored PLAN.md: Phase 0 Audit → 1 Cleanup → 2 Stabilize → 3 Forward.

set -euo pipefail

HARNESS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEMPLATE_DIR="${HARNESS_DIR}/template"
ADOPT_DIR="${HARNESS_DIR}/template-adopt"

for d in "$TEMPLATE_DIR" "$ADOPT_DIR"; do
  if [ ! -d "$d" ]; then
    echo "ERROR: $d не найден" >&2
    exit 1
  fi
done

cat <<'BANNER'
==============================================
  dogfood-harness — adopt EXISTING project
==============================================
Установит harness в existing dogfood-проект:
  - CLAUDE.md, PLAN.md, RISKS.md, AGENT-MAP.md (new or backup-and-install)
  - .claude/settings.json + session-state hook
  - .gitignore append-only merge

Non-destructive. Existing файлы бэкапятся как *-legacy-YYYYMMDD.md.
Git — не коммитит сам, только создаёт файлы.
Ctrl-C в любой момент — safe abort.
==============================================

BANNER

read -r -p "Path to existing project: " TARGET_DIR
TARGET_DIR="${TARGET_DIR/#\~/$HOME}"
if [ ! -d "$TARGET_DIR" ]; then
  echo "ERROR: $TARGET_DIR не существует или не директория" >&2
  exit 1
fi
TARGET_DIR="$(cd "$TARGET_DIR" && pwd)"

DEFAULT_NAME="$(basename "$TARGET_DIR")"
read -r -p "Project name [${DEFAULT_NAME}]: " PROJECT_NAME
PROJECT_NAME="${PROJECT_NAME:-$DEFAULT_NAME}"
PROJECT_SLUG=$(printf '%s' "$PROJECT_NAME" | tr '[:upper:]' '[:lower:]' | tr -cs 'a-z0-9' '-' | sed 's/^-//;s/-$//')

read -r -p "One-line pitch (зачем этот проект сейчас): " ONE_LINE_PITCH
while [ -z "$ONE_LINE_PITCH" ]; do
  read -r -p "  (обязательное поле): " ONE_LINE_PITCH
done

read -r -p "First user (v1) [сам owner]: " FIRST_USER
FIRST_USER="${FIRST_USER:-сам owner}"

BOOTSTRAP_DATE=$(date +'%Y-%m-%d')
BACKUP_SUFFIX="legacy-${BOOTSTRAP_DATE//-/}"

# --- Detect stack ---
STACK="unknown"
STACK_REVIEWER="code-reviewer"
if [ -f "${TARGET_DIR}/package.json" ]; then
  if grep -q '"next"' "${TARGET_DIR}/package.json" 2>/dev/null; then
    STACK="Next.js + TypeScript"
  elif grep -q '"react-native"' "${TARGET_DIR}/package.json" 2>/dev/null; then
    STACK="React Native + TypeScript"
  elif grep -q '"react"' "${TARGET_DIR}/package.json" 2>/dev/null; then
    STACK="React + TypeScript"
  else
    STACK="TypeScript/JavaScript"
  fi
  STACK_REVIEWER="typescript-reviewer"
elif [ -f "${TARGET_DIR}/pubspec.yaml" ]; then
  STACK="Flutter/Dart"
  STACK_REVIEWER="flutter-reviewer"
elif [ -f "${TARGET_DIR}/Cargo.toml" ]; then
  STACK="Rust"
  STACK_REVIEWER="rust-reviewer"
elif [ -f "${TARGET_DIR}/go.mod" ]; then
  STACK="Go"
  STACK_REVIEWER="go-reviewer"
elif compgen -G "${TARGET_DIR}/*.xcodeproj" > /dev/null || [ -f "${TARGET_DIR}/Package.swift" ]; then
  STACK="Swift"
  STACK_REVIEWER="code-reviewer (skills: swiftui-patterns, swift-concurrency-6-2)"
elif [ -f "${TARGET_DIR}/build.gradle.kts" ] || [ -f "${TARGET_DIR}/build.gradle" ]; then
  STACK="Kotlin/Android"
  STACK_REVIEWER="kotlin-reviewer"
elif [ -f "${TARGET_DIR}/pom.xml" ]; then
  STACK="Java"
  STACK_REVIEWER="java-reviewer"
elif [ -f "${TARGET_DIR}/requirements.txt" ] || [ -f "${TARGET_DIR}/pyproject.toml" ]; then
  STACK="Python"
  STACK_REVIEWER="python-reviewer"
fi

# --- Scan existing harness-like artifacts ---
EXISTING_FILES=()
for f in CLAUDE.md docs/PLAN.md docs/RISKS.md docs/AGENT-MAP.md .claude/settings.json .claude/scripts/session-state.sh; do
  if [ -e "${TARGET_DIR}/${f}" ]; then
    EXISTING_FILES+=("$f")
  fi
done

cat <<EOF

--- Adopt plan ---
  Target:         ${TARGET_DIR}
  Project:        ${PROJECT_NAME}
  Slug:           ${PROJECT_SLUG}
  Pitch:          ${ONE_LINE_PITCH}
  First user:     ${FIRST_USER}
  Date:           ${BOOTSTRAP_DATE}
  Detected stack: ${STACK}
  Primary review: ${STACK_REVIEWER}

  Existing harness artifacts (будут бэкапнуты как *-${BACKUP_SUFFIX}.md):
EOF
if [ ${#EXISTING_FILES[@]} -eq 0 ]; then
  echo "    (нет — чистая установка)"
else
  for f in "${EXISTING_FILES[@]}"; do
    echo "    ⚠ ${f}"
  done
fi

cat <<EOF

  Files to create/update:
    docs/PLAN.md           (adopt-flavored: Phase 0 Audit → 1 Cleanup → 2 Stabilize → 3 Forward)
    docs/RISKS.md          (R1-R11 + R-G + R-Adopt-1..3)
    docs/AGENT-MAP.md      (pre-filled under ${STACK})
    CLAUDE.md              (adopt-aware)
    .claude/settings.json  (Stop hook)
    .claude/scripts/session-state.sh
    .gitignore             (append .claude/local/ + .DS_Store если отсутствуют)
    docs/audit/            (пустая — для Phase 0 артефактов)
    docs/decisions/        (пустая — для retroactive ADR)
    docs/research/README.md

  Git:
    - НЕ делает commit автоматически
    - НЕ делает branch автоматически
    - Только создаёт файлы; git status покажет их как новые

EOF

read -r -p "Proceed? [y/N]: " confirm
if [[ ! "$confirm" =~ ^[Yy] ]]; then
  echo "Aborted."
  exit 0
fi

echo
echo "[1/7] Backing up existing harness artifacts..."
if [ ${#EXISTING_FILES[@]} -eq 0 ]; then
  echo "  (нет файлов для backup)"
else
  for f in "${EXISTING_FILES[@]}"; do
    ext="${f##*.}"
    base="${f%.*}"
    backup="${base}-${BACKUP_SUFFIX}.${ext}"
    mv "${TARGET_DIR}/${f}" "${TARGET_DIR}/${backup}"
    echo "  ${f} → ${backup}"
  done
fi

# --- Sed helper ---
if sed --version >/dev/null 2>&1; then
  SED_INPLACE=(sed -i)
else
  SED_INPLACE=(sed -i '')
fi
escape_sed() { printf '%s' "$1" | sed -e 's/[\/&|]/\\&/g'; }
ESC_NAME=$(escape_sed "$PROJECT_NAME")
ESC_SLUG=$(escape_sed "$PROJECT_SLUG")
ESC_PITCH=$(escape_sed "$ONE_LINE_PITCH")
ESC_USER=$(escape_sed "$FIRST_USER")
ESC_DATE=$(escape_sed "$BOOTSTRAP_DATE")
ESC_STACK=$(escape_sed "$STACK")
ESC_REVIEWER=$(escape_sed "$STACK_REVIEWER")

substitute_file() {
  local file="$1"
  "${SED_INPLACE[@]}" \
    -e "s|{{PROJECT_NAME}}|${ESC_NAME}|g" \
    -e "s|{{PROJECT_SLUG}}|${ESC_SLUG}|g" \
    -e "s|{{ONE_LINE_PITCH}}|${ESC_PITCH}|g" \
    -e "s|{{FIRST_USER}}|${ESC_USER}|g" \
    -e "s|{{BOOTSTRAP_DATE}}|${ESC_DATE}|g" \
    -e "s|{{STACK}}|${ESC_STACK}|g" \
    -e "s|{{STACK_REVIEWER}}|${ESC_REVIEWER}|g" \
    "$file"
}

echo "[2/7] Creating directories..."
mkdir -p "${TARGET_DIR}/docs/audit" \
         "${TARGET_DIR}/docs/decisions" \
         "${TARGET_DIR}/docs/research" \
         "${TARGET_DIR}/.claude/scripts"

echo "[3/7] Installing base template files (CLAUDE.md, settings, session-state, research README)..."
cp "${TEMPLATE_DIR}/CLAUDE.md" "${TARGET_DIR}/CLAUDE.md"
cp "${TEMPLATE_DIR}/.claude/settings.json" "${TARGET_DIR}/.claude/settings.json"
cp "${TEMPLATE_DIR}/.claude/scripts/session-state.sh" "${TARGET_DIR}/.claude/scripts/session-state.sh"
cp "${TEMPLATE_DIR}/docs/research/README.md" "${TARGET_DIR}/docs/research/README.md"

for f in "${TARGET_DIR}/CLAUDE.md" "${TARGET_DIR}/.claude/scripts/session-state.sh" "${TARGET_DIR}/docs/research/README.md"; do
  substitute_file "$f"
done

# Inject adopt-context block into CLAUDE.md after "First user" line
python3 - "$TARGET_DIR/CLAUDE.md" "$BOOTSTRAP_DATE" "$STACK" "$STACK_REVIEWER" <<'PYEOF'
import sys, pathlib
target = pathlib.Path(sys.argv[1])
date = sys.argv[2]
stack = sys.argv[3]
reviewer = sys.argv[4]
text = target.read_text()
block = (
    f"\n\n> **⚠ Adopted existing project** (harness установлен {date}). "
    f"Код существовал до harness'а. Phase 0 — это **Audit** "
    f"(инвентаризация, retroactive ADR), не fresh scaffolding. См. `docs/PLAN.md`.\n"
    f"> **Detected stack:** {stack}. Primary code reviewer: `{reviewer}`."
)
marker = "> First user (v1):"
idx = text.find(marker)
if idx != -1:
    end = text.find("\n", idx)
    text = text[:end] + block + text[end:]
    target.write_text(text)
PYEOF

echo "[4/7] Writing adopt PLAN.md..."
cp "${ADOPT_DIR}/docs/PLAN.md" "${TARGET_DIR}/docs/PLAN.md"
substitute_file "${TARGET_DIR}/docs/PLAN.md"

echo "[5/7] Writing RISKS.md (+ R-Adopt-1..3 injection)..."
cp "${TEMPLATE_DIR}/docs/RISKS.md" "${TARGET_DIR}/docs/RISKS.md"
substitute_file "${TARGET_DIR}/docs/RISKS.md"

# Replace "Project-Specific Risks (R-X)" placeholder section with R-Adopt-1..3
python3 - "$TARGET_DIR/docs/RISKS.md" <<'PYEOF'
import sys, pathlib, re
target = pathlib.Path(sys.argv[1])
text = target.read_text()

adopt_block = """# Project-Specific Risks

## R-Adopt-1. «Bulk delete без tests» (Unsafe Cleanup)

**Trigger:** User в Phase 1 (Cleanup) предлагает удалить модуль/файл/компонент, который НЕ покрыт тестами, без smoke-test'а (build + ручная проверка критичных user flows) перед удалением.

**Warning:**
> ⚠️ Dead-code без тестов — это **предполагаемо** dead. Реальность: часто вызывается через reflection, lazy imports, или feature flag, которые не детектятся статическим анализом.
>
> Правило Phase 1: **no delete without proof of deadness**. Proof = (a) test covers surrounding module and passes after delete, или (b) smoke-test критичных flows (build + manual click-through на ключевых страницах/экранах).
>
> Рекомендуется:
> 1. Измерить coverage baseline до удаления
> 2. Удалить на feature branch
> 3. Прогнать smoke-test
> 4. Если coverage не упал и flows работают → PR
> 5. Если что-то сломалось → revert, добавить в `docs/audit/dead-code.md` как «предполагалось dead, оказалось live: [context]»

---

## R-Adopt-2. «Retroactive ADR skip» (No memory of why)

**Trigger:** User в Phase 0 пропустил написание retroactive ADR'ов (≥3 крупных решения должны быть задокументированы) и хочет перейти в Phase 1.

**Warning:**
> ⚠️ Phase 1 Cleanup без retroactive ADR'ов опасен: без understanding «почему так сделано», легко удалить что-то, что было намеренным workaround'ом конкретной проблемы.
>
> Типичный сценарий: удалил якобы dead jQuery-import → через неделю production ломается, потому что jQuery был workaround для конкретного browser-bug, не зафиксированного нигде.
>
> Рекомендуется: написать минимум retroactive ADR на stack choice, auth, storage/DB перед Phase 1.

---

## R-Adopt-3. «Markdown-кладбище silent cleanup» (Lost context deletion)

**Trigger:** User предлагает удалить markdown-файлы в корне проекта (например, `QUICK_FIX.md`, `RUNTIME_FIX_SUMMARY.md`) как «мусор», без чтения содержимого.

**Warning:**
> ⚠️ Markdown'ы с именами типа `*_FIX*.md`, `*_GUIDE.md`, `*_CHECKLIST.md` в корне — это обычно **замороженный контекст** фикса, который не попал в ADR. Удалить без чтения = потерять единственный источник «почему ломалось».
>
> Рекомендуется:
> 1. Прочитать каждый, извлечь key-insight
> 2. Insight → retroactive ADR в `docs/decisions/`
> 3. Оригинал → `docs/history/` (не удаляем, просто убираем из корня)
> 4. После этого — архивация root'а от дебаг-заметок
>
> Решение по каждому MD фиксируется в `docs/audit/md-cleanup.md` до физического перемещения.

---

> *Добавь сюда дополнительные проект-специфичные риски по мере того, как они всплывают в real usage.*
"""

# Find and replace the TEMPLATE-TODO R-X block
pattern = r'# Project-Specific Risks \(R-X\).*?<!-- Delete this TEMPLATE-TODO block after filling in project-specific risks\. -->'
new_text = re.sub(pattern, adopt_block, text, flags=re.DOTALL)
target.write_text(new_text)
PYEOF

echo "[6/7] Writing AGENT-MAP.md..."
cp "${TEMPLATE_DIR}/docs/AGENT-MAP.md" "${TARGET_DIR}/docs/AGENT-MAP.md"
substitute_file "${TARGET_DIR}/docs/AGENT-MAP.md"

# Inject stack note
python3 - "$TARGET_DIR/docs/AGENT-MAP.md" "$STACK" "$STACK_REVIEWER" <<'PYEOF'
import sys, pathlib
target = pathlib.Path(sys.argv[1])
stack = sys.argv[2]
reviewer = sys.argv[3]
text = target.read_text()
note = (
    f"\n> **Detected stack:** {stack}. Primary code reviewer: `{reviewer}`. "
    f"Phase-mapping адаптирован под **adopted existing project** "
    f"(Phase 0 Audit, не Setup).\n"
)
marker = "\n---\n\n## By Phase"
if marker in text:
    text = text.replace(marker, note + "\n---\n\n## By Phase (adopt)", 1)
    target.write_text(text)
PYEOF

echo "[7/7] Merging .gitignore (append-only)..."
GITIGNORE="${TARGET_DIR}/.gitignore"
touch "$GITIGNORE"
if ! grep -q 'harness additions' "$GITIGNORE" 2>/dev/null; then
  {
    echo ""
    echo "# harness additions ($(date +%Y-%m-%d))"
  } >> "$GITIGNORE"
  for entry in ".claude/local/" ".DS_Store"; do
    if ! grep -qxF "$entry" "$GITIGNORE" 2>/dev/null; then
      echo "$entry" >> "$GITIGNORE"
    fi
  done
fi

chmod +x "${TARGET_DIR}/.claude/scripts/session-state.sh"

echo
cat <<EOF
==============================================
  ${PROJECT_NAME} adopted at ${TARGET_DIR}
==============================================

Создано:
  ✓ CLAUDE.md                         (adopt-aware)
  ✓ docs/PLAN.md                      (Phase 0 Audit → 1 Cleanup → 2 Stabilize → 3 Forward)
  ✓ docs/RISKS.md                     (R1-R11 + R-G + R-Adopt-1..3)
  ✓ docs/AGENT-MAP.md                 (pre-filled под ${STACK})
  ✓ docs/audit/                       (пустая — для Phase 0)
  ✓ docs/decisions/                   (пустая — для retroactive ADR)
  ✓ docs/research/README.md
  ✓ .claude/settings.json
  ✓ .claude/scripts/session-state.sh
  ✓ .gitignore                        (append-only merge)
EOF

if [ ${#EXISTING_FILES[@]} -gt 0 ]; then
  echo
  echo "Бэкапы существующих файлов:"
  for f in "${EXISTING_FILES[@]}"; do
    ext="${f##*.}"
    base="${f%.*}"
    echo "  ${base}-${BACKUP_SUFFIX}.${ext}"
  done
  echo
  echo "⚠ Просмотри бэкапы и смержи полезный контент в новые harness-файлы вручную."
fi

cat <<EOF

Next steps:
  1. cd ${TARGET_DIR}
  2. git status                       # посмотреть новые файлы
  3. git checkout -b harness-adopt    # feature branch для первого коммита
  4. git add -A && git commit -m "chore: adopt dogfood-harness"
  5. claude                           # старт первой harness-сессии

Phase 0 Audit priorities (первой сессии):
  - docs/audit/inventory.md — карта репо
  - Secrets audit: git log --all -p | grep -iE 'secret|password|token'
  - Retroactive ADR на stack choice (${STACK})
  - Retroactive ADR на auth / storage / deployment
  - docs/audit/md-cleanup.md — решение по markdown'ам в корне

==============================================
EOF
