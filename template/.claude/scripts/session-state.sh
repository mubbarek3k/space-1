#!/usr/bin/env bash
# {{PROJECT_NAME}} — Phase discipline state dump.
# Выход: stdout (человеко-читаемый). Не блокирует. Только показывает.
# Вызывается хуком перед вопросом «готов закрыть сессию?».

set -euo pipefail

# Move to project repo root based on script location (.claude/scripts/<file>)
script_dir="$(cd "$(dirname "$0")" && pwd)"
cd "${script_dir}/../.." || {
  echo "ERROR: не смог перейти в {{PROJECT_NAME}} repo root"
  exit 1
}

if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  gitroot="$(git rev-parse --show-toplevel 2>/dev/null)"
  if [ -f "${gitroot}/CLAUDE.md" ] && grep -q '{{PROJECT_NAME}}' "${gitroot}/CLAUDE.md" 2>/dev/null; then
    cd "$gitroot"
  fi
fi

if [ ! -f docs/PLAN.md ]; then
  echo "ERROR: docs/PLAN.md не найден"
  exit 1
fi

echo "=============================================="
echo "  {{PROJECT_NAME}} — PHASE DISCIPLINE — SESSION STATE"
echo "=============================================="
echo
echo "When:    $(date +'%Y-%m-%d %H:%M %Z')"
if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  echo "Branch:  $(git branch --show-current 2>/dev/null || echo '(detached)')"
else
  echo "Branch:  (no git yet)"
fi
echo

# --- Current phase ---
current_line=$(grep -m1 '🟡' docs/PLAN.md 2>/dev/null | sed 's/^[[:space:]]*//' || echo "")
if [ -z "$current_line" ]; then
  current_line="(🟡 маркер не найден в PLAN.md)"
fi
echo "Current phase:"
echo "  $current_line"
echo

phase_num=$(printf '%s\n' "$current_line" | grep -oE 'Phase [0-9]+' | head -1 | grep -oE '[0-9]+' || echo "")

# --- Git state ---
if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  echo "--- Git state ---"
  uncommitted=$(git status --short 2>/dev/null || echo "")
  if [ -z "$uncommitted" ]; then
    echo "  Uncommitted: (clean)"
  else
    echo "  Uncommitted changes:"
    printf '%s\n' "$uncommitted" | sed 's/^/    /'
  fi
  unpushed=$(git log --oneline '@{u}..HEAD' 2>/dev/null || echo "")
  if [ -z "$unpushed" ]; then
    echo "  Unpushed: (в синхроне с upstream или upstream не настроен)"
  else
    echo "  Unpushed commits:"
    printf '%s\n' "$unpushed" | sed 's/^/    /'
  fi
  echo
fi

# --- TEMPLATE-TODO check (harness не адаптирован) ---
template_todos=$(grep -lE 'TEMPLATE-TODO|PLACEHOLDER' CLAUDE.md docs/PLAN.md docs/RISKS.md docs/AGENT-MAP.md 2>/dev/null || echo "")
if [ -n "$template_todos" ]; then
  echo "--- TEMPLATE-TODO остатки (harness не адаптирован до конца) ---"
  printf '%s\n' "$template_todos" | sed 's/^/  /'
  echo "  → Phase 0 exit criteria не закрыт, пока есть TEMPLATE-TODO"
  echo
fi

# --- Future-phase artifacts ---
# Skip in adopt-mode (existing project — код уже есть до harness'а).
is_adopted=false
if head -5 docs/PLAN.md 2>/dev/null | grep -q '(adopted)'; then
  is_adopted=true
fi

if [ "$is_adopted" = true ]; then
  echo "--- Future-phase artifacts ---"
  echo "  (adopt-mode: проверка пропущена — код существовал до harness'а)"
  echo
else
  echo "--- Future-phase artifacts (не должны существовать в текущей фазе) ---"
  violations=""
  check_paths() {
    local tag="$1"; shift
    for p in "$@"; do
      if [ -e "$p" ]; then
        violations="${violations}
    [${tag}] ${p}"
      fi
    done
  }
  case "${phase_num:-0}" in
    0)
      check_paths "Phase 1+" docs/validation
      check_paths "Phase 2+" src lib app pubspec.yaml package.json Package.swift build.gradle build.gradle.kts Cargo.toml go.mod
      ;;
    1)
      check_paths "Phase 2+" src lib app pubspec.yaml package.json Package.swift build.gradle build.gradle.kts Cargo.toml go.mod
      ;;
  esac
  if [ -z "$violations" ]; then
    echo "  Нет нарушений."
  else
    echo "  ⚠ Найдены артефакты из будущих фаз:${violations}"
  fi
  echo
fi

# --- Phase 0 blockers ---
if [ "${phase_num:-x}" = "0" ]; then
  echo "--- Phase 0: Setup blockers ---"
  missing=0
  [ ! -f CLAUDE.md ] && echo "  ❌ CLAUDE.md отсутствует" && missing=$((missing+1))
  [ ! -f docs/PLAN.md ] && echo "  ❌ docs/PLAN.md отсутствует" && missing=$((missing+1))
  [ ! -f docs/RISKS.md ] && echo "  ❌ docs/RISKS.md отсутствует" && missing=$((missing+1))
  [ ! -f docs/AGENT-MAP.md ] && echo "  ❌ docs/AGENT-MAP.md отсутствует" && missing=$((missing+1))
  [ ! -f .claude/settings.json ] && echo "  ❌ .claude/settings.json отсутствует" && missing=$((missing+1))
  ! git rev-parse --is-inside-work-tree >/dev/null 2>&1 && echo "  ❌ git не инициализирован" && missing=$((missing+1))
  [ ! -f docs/idea.md ] && echo "  ❌ docs/idea.md не создан" && missing=$((missing+1))
  if [ "$missing" -eq 0 ] && [ -z "$template_todos" ]; then
    echo "  Все Phase 0 артефакты на месте — можно флипать в Phase 1"
  fi
  echo
fi

# --- SoloYolo dogfood-feedback check (R-G) ---
if [ -d "../SoloYolo" ]; then
  echo "--- SoloYolo dogfood-feedback (R-G) ---"
  recent_retro=$(find ../SoloYolo/docs/decisions -name '*.md' -mtime -30 2>/dev/null | xargs grep -lE '{{PROJECT_NAME}}|{{PROJECT_SLUG}}' 2>/dev/null || echo "")
  if [ -z "$recent_retro" ]; then
    if [ "${phase_num:-0}" -ge 2 ] 2>/dev/null; then
      echo "  ⚠ R-G: нет dogfood-retro упоминающего {{PROJECT_NAME}} в SoloYolo/docs/decisions за 30 дней"
      echo "     Рекомендуется: docs/decisions/NNN-dogfood-retro-MM.md в SoloYolo"
    else
      echo "  (Phase ${phase_num:-0}: R-G ещё не активен — код не начат)"
    fi
  else
    echo "  Свежий dogfood-retro найден:"
    printf '%s\n' "$recent_retro" | sed 's/^/    /'
  fi
  echo
fi

# --- PLAN.md freshness vs commits ---
if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  echo "--- PLAN.md freshness ---"
  plan_last_commit=$(git log -1 --format='%H %ci' -- docs/PLAN.md 2>/dev/null || echo "")
  if [ -z "$plan_last_commit" ]; then
    echo "  ⚠ docs/PLAN.md не зафиксирован в git истории (ok до первого коммита)"
  else
    plan_sha=$(printf '%s' "$plan_last_commit" | awk '{print $1}')
    plan_date=$(printf '%s' "$plan_last_commit" | cut -d' ' -f2-)
    echo "  Last PLAN.md update: ${plan_date} (${plan_sha:0:7})"
    commits_since=$(git log --oneline "${plan_sha}..HEAD" 2>/dev/null || echo "")
    if [ -z "$commits_since" ]; then
      echo "  Commits since: (нет — PLAN синхронизирован с HEAD)"
    else
      commit_count=$(printf '%s\n' "$commits_since" | wc -l | tr -d ' ')
      echo "  ⚠ ${commit_count} коммит(ов) после последнего PLAN.md update:"
      printf '%s\n' "$commits_since" | head -10 | sed 's/^/    /'
      echo "  → Проверь: нужно ли тикнуть чекбокс в PLAN.md?"
    fi
  fi
  echo
fi

# --- Entry criteria for next phase ---
if [[ "${phase_num:-}" =~ ^[0-9]+$ ]]; then
  next_phase=$((phase_num + 1))
  echo "--- Entry criteria для Phase ${next_phase} ---"
  output=$(awk -v n="## Phase ${next_phase}:" '
    started && /^## Phase / && index($0, n) != 1 {exit}
    index($0, n) == 1 {started=1}
    started && /^\*\*Entry criteria/ {in_entry=1}
    started && /^\*\*Goal:/ {in_entry=0}
    started && in_entry {print}
  ' docs/PLAN.md || echo "")
  if [ -z "$output" ]; then
    echo "  (не найдены — возможно Phase ${next_phase} не существует)"
  else
    printf '%s\n' "$output" | sed 's/^/  /'
  fi
  echo
fi

# --- Closing reminders ---
echo "--- Напоминания перед закрытием ---"
echo "  - PLAN.md изменён? → ADR/Issue открыт ДО этого?"
echo "  - Нетривиальное решение? → docs/decisions/NNN-<slug>.md черновик есть?"
echo "  - Контекст сессии плотный? → /save-session перед закрытием"
echo
echo "=============================================="
