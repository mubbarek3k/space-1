# dogfood-harness

Bootstrap для dogfood-проектов @qartelio + друзей. Устанавливает harness из SoloYolo-методики (phase discipline + RISKS catalog + AGENT-MAP + session-state hook) в новый проект.

Два пути:
- **Owner (Эрик):** `dogfood-new` / `dogfood-adopt` — interactive bash CLI, создаёт новую папку с harness'ом или адаптирует existing проект.
- **Друзья:** «Use this template» на GitHub → clone → в Claude Code запустить `/onboard`. Работает прямо в склонированном repo.

Client-ready `templates/base/` живёт в SoloYolo и появится в Phase 4+ (после 2+ успешных клиентских engagement'ов). До тех пор — этот репо.

---

## Для друзей: clone + `/onboard`

Если тебе скинули ссылку на этот repo и сказали «начинай оттуда»:

1. На странице repo жми **«Use this template» → Create a new repository** (создаст твою копию). Если кнопки нет — `git clone https://github.com/qartelio/dogfood-harness.git my-project && rm -rf my-project/.git && cd my-project && git init` (после fallback'а у тебя не будет remote origin — `/onboard` спросит project name вручную, либо заранее `git remote add origin <url-твоего-repo>`).
2. Открой проект в VSCode / Cursor / любом IDE с Claude Code.
3. В Claude Code набери `/onboard`.
4. Ответь на 6 вопросов (~3 минуты). Harness настроится под тип / стек / цель.
5. Дальше — пиши «хочу сделать X» и поехали.

Что произойдёт за `/onboard`:
- Спросит тип проекта (dev / content / vibe), стек, цель, нужны ли фазы, severity-предпочтение, рабочий язык.
- Скопирует подходящий template (`template/` или `template-contentmanager/`) в корень repo.
- Подставит project name, pitch, дату.
- Удалит installer-файлы (`bootstrap.sh`, `adopt.sh`, `template*/`, `/onboard` команда — больше не нужны).
- Запишет `.harness/state.json` с твоими ответами (это memory для Claude между сессиями).
- Опционально закоммитит.

После онбординга `dogfood-harness` исчезает — у тебя остаётся **твой** проект с CLAUDE.md, docs/PLAN.md, docs/RISKS.md, docs/AGENT-MAP.md, `.claude/` и `.harness/state.json`.

---

## Install (для owner)

```bash
# Клонировать репо в ~/.claude/dogfood-harness (canonical location)
gh repo clone qartelio/dogfood-harness ~/.claude/dogfood-harness

# (опционально) aliases для удобства
cat >> ~/.zshrc <<'EOF'

# dogfood-harness
alias dogfood-new='bash ~/.claude/dogfood-harness/bootstrap.sh'
alias dogfood-adopt='bash ~/.claude/dogfood-harness/adopt.sh'
EOF
source ~/.zshrc
```

## Usage

### `dogfood-new` — new empty project

```bash
dogfood-new                              # default template (dev project)
dogfood-new --template contentmanager    # non-dev content workflow
dogfood-new --help                       # list templates
```

Для нового пустого dogfood-проекта. Interactive CLI, набор вопросов зависит от template.

Результат (общий для всех templates):
- `/Users/user/<name>/` с harness'ом
- `git init` + initial commit
- Private GitHub repo `qartelio/<name>` (если `gh` установлен)
- Первый push

#### Template: `(default)` — dev project

Prompts:
- Project name, One-line pitch, First user

Phase-skeleton: **Phase 0 Setup → 1 Validation → 2 Build → 3+ custom**.

Agents enabled: `Explore`, `planner`, `architect`, `tdd-guide`, code-reviewers by stack.

#### Template: `contentmanager` — non-dev content workflow

Для контент-менеджеров (Instagram / социальные сети / СМИ-outreach). Non-dev workflow, code-agents отключены.

Prompts:
- Project name (slug)
- Brand name, Owner first name, Organization, Region
- Sprint length (default: 3 недели)
- Brand character (1 строка про tone)

Phase-skeleton: **Phase 0 Corpus Collection → 1 Agent Setup MVP → 2 Full Agent Farm → 3 Sprint Rhythm**.

Включает: 7 content-agents (MediaScout, ContentPlanner, ImageStudio, ReelScripter, MetricsReality, EventRecap, NetworkScout), R-IG-1..6 (Instagram TOS, pods, disclosure KZ+FTC, content theft, over-posting, AI-slop), R-Org-1..4 (corporate IP, approval chain, brand voice, government-adjacent sensitivity).

IP-boundary: `docs/corpus/` автоматически в `.gitignore` — бренд-материалы не попадают в git.

### `dogfood-adopt` — existing messy project

```bash
dogfood-adopt
```

Для **existing** dogfood-проекта с уже существующим кодом и git history. Non-destructive: бэкапит существующие harness-файлы, не перезаписывает.

Interactive CLI спросит:
- Path to existing project
- Project name (default — имя папки)
- One-line pitch
- First user (default — сам owner)

Автоматически:
- Детектит стэк из `package.json` / `pubspec.yaml` / `Cargo.toml` / etc.
- Pre-fill'ит AGENT-MAP под detected stack (Next.js → typescript-reviewer, Flutter → flutter-reviewer, и т.д.)
- Бэкапит существующие CLAUDE.md/PLAN.md/etc. как `*-legacy-YYYYMMDD.md`
- `.gitignore` append-only merge (не overwrite)
- **НЕ делает commit автоматически** — owner коммитит сам на feature branch

Phase-skeleton **другой**: **Phase 0 Audit → 1 Cleanup → 2 Stabilize → 3+ Forward**.

Дополнительные risks в adopt-режиме:
- **R-Adopt-1** Bulk delete без tests (unsafe cleanup)
- **R-Adopt-2** Retroactive ADR skip
- **R-Adopt-3** Markdown-кладбище silent cleanup

Session-state hook в adopt-mode пропускает «future-phase artifacts» проверку (код существовал до harness'а).

## Что внутри harness

| File | Purpose |
|---|---|
| `CLAUDE.md` | Behavioral guidelines: think-before-coding, phase discipline, language policy |
| `docs/PLAN.md` | Phase skeleton (0 Setup → 1 Validation → 2 Build → 3+ project-specific) |
| `docs/RISKS.md` | Universal R1–R11 + R-G (dogfood feedback loop) + placeholder для project-specific R-X |
| `docs/AGENT-MAP.md` | Который ECC-агент на какой фазе/задаче/типе файла |
| `.claude/settings.json` | Stop hook → session-state.sh |
| `.claude/scripts/session-state.sh` | Phase/git/PLAN.md status dump перед закрытием сессии |
| `.gitignore` | Generic: `.claude/local/`, `*.env`, OS, IDE |

## После bootstrap

1. `cd /Users/user/<name> && claude`
2. Ищи `TEMPLATE-TODO` и `PLACEHOLDER` маркеры — адаптируй под project specifics:
   - CLAUDE.md: добавь project-specific sections (например, compliance, client confidentiality, child-data discipline)
   - PLAN.md: перепиши Phase 1–3 заглушки под реальные фазы проекта
   - RISKS.md: заполни project-specific R-X секцию (минимум 2-3 риска)
   - AGENT-MAP.md: убери лишние стэки, добавь project-specific pipelines
3. `docs/idea.md` — первая гипотеза продукта
4. ADR `001-<topic>.md` — первое нетривиальное решение
5. Когда Phase 0 готов — флипни 🟡 marker на Phase 1

## Обновление harness

Если нашёл паттерн, который стоит промотировать во все будущие dogfood'ы:

1. Edit `template/*` в этом репо
2. Commit + push
3. Существующие dogfood'ы **не синхронизируются автоматически** (by design — каждый проект эволюционирует независимо)
4. Если хочешь синхронизировать конкретный проект вручную — cherry-pick изменения

## Relationship to SoloYolo

- Методика **приходит из** SoloYolo `docs/methodology/`
- Harness **извлекается сюда** после каждого witness'а паттерна в ≥2 dogfood-проектах
- Когда SoloYolo дойдёт до Phase 4 (≥2 успешных клиентских engagement'ов), **client-ready** `templates/base/` создастся в SoloYolo на основе того, что здесь к тому моменту survived
- До Phase 4 — этот репо остаётся **personal-only**, без public release

См. также:
- `/Users/user/SoloYolo/docs/PLAN.md` — Phase 4 deliverables
- `/Users/user/SoloYolo/docs/RISKS.md` R-C — rule of two domains
- `/Users/user/SoloYolo/docs/methodology/` — источник методики
