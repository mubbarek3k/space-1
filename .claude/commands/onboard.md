---
description: Интервью + настройка harness под текущий проект (one-shot)
---

# /onboard

Интерактивный онбординг: 6 вопросов → выбор template'а → копирование файлов в корень repo → подстановка placeholder'ов → cleanup installer-файлов → запись `.harness/state.json`.

Запускается **один раз** в свежеклонированном dogfood-harness. Idempotent: если уже онбоарден — спросит про re-onboard.

---

## Step 0 — Pre-check

Прочитай `.harness/state.json`:

- Если файл существует и `onboarded: true`:
  > «Re-onboard? Это перезапишет CLAUDE.md, docs/PLAN.md, RISKS.md, AGENT-MAP.md. [y/N]»

  Если `N` или нет ответа — выйти.
  Если `y` — сделать `git status`, если есть uncommitted changes — предупредить и спросить ещё раз.

- Если файл не существует или `onboarded: false` — продолжай.

Также проверь, что мы внутри git repo (`git rev-parse --git-dir`). Если нет — сказать «нужен git repo, сначала `git init` или клонируй repo» и выйти.

---

## Step 1 — Interview

**Правила:**
- Задавать вопросы **по одному**, дождаться ответ до следующего.
- Не подсказывать ответ. Не предлагать defaults для смыслосодержащих вопросов.
- Сохранять ответы в локальный объект (in-context, ещё не пишем в файл).
- Если ответ нечитаем / off-topic — переспросить один раз, потом сделать best-effort guess и идти дальше.

### Q1 — Тип проекта

> «Какого типа проект?
> 1. **dev** — приложение / сервис / библиотека (код + тесты + структурированные фазы)
> 2. **content** — контент-workflow (Instagram / соц.сети / СМИ)
> 3. **vibe** — экспериментальный, минимум структуры, поехали»

Сохрани → `project_type` (одно из: `dev` / `content` / `vibe`).

### Q2 — Стек *(только если Q1 = dev или vibe)*

> «Основной стек? (TS / Python / Go / Rust / Swift / Kotlin / Flutter / multi / none)»

Сохрани → `stack`. Если Q1 = `content` — пропустить, `stack = "n/a"`.

### Q3 — Цель

> «Цель проекта в одной строке. Примеры: "production SaaS для X", "научиться Rust на реальной задаче", "MVP чтобы validate idea", "вайб-эксперимент с LLM tooling".»

Сохрани → `goal`.

### Q4 — Фазы

> «Нужны ли формальные фазы (PLAN.md с Phase 0/1/2/...)?
> - **yes** — структура помогает (production / long-term проект)
> - **no** — слишком формально (vibe / прототип / экспериментальная задача)»

Сохрани → `phases` (boolean).

### Q5 — Severity

> «Как Claude должен реагировать на риски (auth / secrets / destructive ops / refactor)?
> - **strict** — warn агрессивно, спрашивать перед каждым нетривиальным действием
> - **chill** — warn только на критичном (rm -rf, secrets exposure, force-push), не блокировать поток»

Сохрани → `severity` (`strict` / `chill`).

### Q6 — Язык

> «Рабочий язык: **ru** / **en** / **mix** (ru в чате + en в коде/комментах)»

Сохрани → `language`.

---

## Step 2 — Дополнительные данные для placeholder'ов

После 6 вопросов задай ещё 1–6 коротких вопросов в зависимости от template'а (см. mapping ниже):

**Для всех:**
- `project_name` — попытайся выдернуть из git remote (`git config --get remote.origin.url` → последний path-сегмент без `.git`). Если есть — подтверди: «Project name: `<X>` — ок? [Y/n/другое]». Если нет remote — спроси.
- `first_user` — «Кто первый пользователь / для кого делаешь?»

**Только для `project_type = content`:**
- `brand_name` — «Бренд (то, что видит публика)»
- `owner_first_name` — «Твоё имя»
- `org_name` — «Organization / employer»
- `brand_region` — «Region served»
- `sprint_length` — «Sprint length [3 недели]:» (default: «3 недели»)
- `brand_character` — «Brand character (1 строка про tone)»

---

## Step 3 — Summary + Confirm

Покажи аккуратный summary в fenced block:

```
type:       dev
stack:      TypeScript
goal:       MVP сервиса для X
phases:     yes
severity:   strict
language:   ru
project:    my-cool-app
first_user: я сам
```

Спроси: **«Применить? [Y/n]»**. Если `n` — выйти, ничего не менять.

---

## Step 4 — Apply

### 4.1 Выбор source template

```
project_type = content → SOURCE = template-contentmanager/
project_type = dev     → SOURCE = template/
project_type = vibe    → SOURCE = template/  (с упрощениями на step 4.4)
```

### 4.2 Copy template → repo root

Скопируй из `<SOURCE>/` в корень repo:
- `CLAUDE.md` — overwrite корневой (bootstrap-версию)
- `docs/` — **skip-existing merge:** если файл/папка уже есть в корневом `docs/` — пропустить, только копировать missing. **Не делать line-level merge** (это даст некорректный markdown).
- `.claude/scripts/` — если в template есть, скопировать в корневой `.claude/scripts/`
- `.claude/settings.json` — если в template есть и нет в корне, скопировать
- `.gitignore` — append-only merge: прочитать оба, добавить из template только строки, которых нет в существующем

Используй `cp -R` (для нового) и `cp -n` (для skip-existing), проверяй существование source перед копированием.

### 4.3 Substitute placeholders

Используй portable sed (детект BSD vs GNU как в `bootstrap.sh`):

```bash
if sed --version >/dev/null 2>&1; then
  SED_INPLACE=(sed -i)
else
  SED_INPLACE=(sed -i '')
fi
```

Заменяемые placeholder'ы (применять через find в скопированных файлах `*.md`, `*.json`, `*.sh`, `.gitignore`):

| Placeholder | Source |
|---|---|
| `{{PROJECT_NAME}}` | `project_name` |
| `{{PROJECT_SLUG}}` | slug from `project_name` (lowercase, non-alnum → `-`) |
| `{{ONE_LINE_PITCH}}` | `goal` |
| `{{FIRST_USER}}` | `first_user` |
| `{{BOOTSTRAP_DATE}}` | `date +'%Y-%m-%d'` |
| `{{BRAND_NAME}}` | `brand_name` (только content) |
| `{{OWNER_FIRST_NAME}}` | `owner_first_name` (только content) |
| `{{ORG_NAME}}` | `org_name` (только content) |
| `{{BRAND_REGION}}` | `brand_region` (только content) |
| `{{SPRINT_LENGTH}}` | `sprint_length` (только content) |
| `{{BRAND_CHARACTER}}` | `brand_character` (только content) |

**Escape sed-special chars** в значениях. `bootstrap.sh::escape_sed` escape'ит только `/`, `&`, `|` — этого **недостаточно**. Используй полный escape:

```bash
escape_sed() {
  printf '%s' "$1" | sed -e 's/[\/&|.*^$[]/\\&/g'
}
```

Это покрывает все sed regex-метасимволы, которые могут встретиться в project_name (`my.app`), goal (`v1.0` / `2.5x`), brand_character (`*MEH*`), etc. Если значение пустое — пропустить замену (избежать `s|{{X}}||g` который создаёт визуальный мусор).

### 4.4 Adjustments по ответам

**Если `phases = false`:**
- Заменить содержимое `docs/PLAN.md` на упрощённый одностраничный план:
  ```md
  # PLAN — <project_name>

  > Vibe-режим: фаз нет, есть «то, над чем сейчас работаю».

  ## Сейчас
  <goal>

  ## Дальше
  - <пусто, заполняется по ходу>

  ## Done
  - <пусто>
  ```
- В корневом `CLAUDE.md` найти секцию `# CRITICAL: Phase Discipline` и заменить её на короткую заметку: «Phase discipline отключена (vibe-mode). Ориентируйся на `docs/PLAN.md` "Сейчас".»

**Если `severity = chill`:**
- В корневом `CLAUDE.md` добавить в самом верху (после первого `>` блока) строку:
  > **Severity: chill.** Warn только на critical (rm -rf, secrets exposure, force-push, prod-touching ops). Остальное — proceed без блокировки.

**Если `language = en`:**
- Не переводить тело автоматически. Добавить в `CLAUDE.md` в Language Policy замечание: «Working language: English — переведи остальные docs/ файлы вручную если нужно.»

**Если `language = mix`:**
- Не трогать (default).

**Stack-specific cleanup в `docs/AGENT-MAP.md`:**
- Найди в файле строки про code-reviewer'ов разных стэков. Оставь только релевантного:
  - `TS` → `typescript-reviewer`
  - `Python` → `python-reviewer`
  - `Go` → `go-reviewer`
  - `Rust` → `rust-reviewer`
  - `Swift` → (пометить TODO — нет swift-reviewer'а в каталоге)
  - `Kotlin` → `kotlin-reviewer`
  - `Flutter` → `flutter-reviewer`
  - `multi` / `none` / `n/a` — не трогать, оставь все
- Если уверенности нет — НЕ удалять, добавить TEMPLATE-TODO комментарий рядом.

### 4.5 Permissions

```bash
chmod +x .claude/scripts/*.sh 2>/dev/null || true
```

### 4.6 Write `.harness/state.json`

```bash
mkdir -p .harness
```

Содержимое:

```json
{
  "onboarded": true,
  "onboarded_at": "<ISO 8601 date>",
  "project_type": "...",
  "stack": "...",
  "goal": "...",
  "phases": true,
  "severity": "...",
  "language": "...",
  "project_name": "...",
  "first_user": "..."
}
```

Для `project_type = content` — добавить `brand_name`, `owner_first_name`, `org_name`, `brand_region`, `sprint_length`, `brand_character`.

### 4.7 Cleanup installer-файлов

Удалить (это installer-mess от dogfood-harness, не нужно в проекте Муббарека):

```bash
rm -rf template/ template-contentmanager/ template-adopt/
rm -f bootstrap.sh adopt.sh
rm -f .claude/commands/onboard.md
rmdir .claude/commands 2>/dev/null || true
```

`README.md` — спросить: «Переписать README.md под твой проект? [y/N]». Если `y` — сгенерировать минимальный stub:
```md
# <project_name>

<goal>

Built with [dogfood-harness](https://github.com/qartelio/dogfood-harness).
```
Если `N` — оставить existing (он будет про harness, может ввести в заблуждение — предупреди один раз).

`.harness/state.json` оставить — это его memory.

### 4.8 (опционально) Initial commit

Спроси: «Закоммитить? [Y/n]».

Если `Y` — staging **только то, что трогал onboard** (не `git add -A`, чтобы не подхватить случайные файлы пользователя):

```bash
git add CLAUDE.md docs/ .claude/ .harness/ .gitignore
# плюс удаления:
git add -u template/ template-contentmanager/ template-adopt/ bootstrap.sh adopt.sh
git commit -m "chore(harness): onboarded <project_type>/<stack> via /onboard"
```

Не пушить автоматически — пусть пользователь сам.

---

## Step 5 — Финал

Сообщить:

> Готово. Harness настроен под `<project_type>` / `<stack>` / цель `«<goal>»`.
>
> - `CLAUDE.md` — твои guidelines
> - `docs/PLAN.md` — `<phases ? "фазы" : "одностраничный текущий план">`
> - `docs/RISKS.md` — universal risks (адаптируй под свои риски)
> - `docs/AGENT-MAP.md` — какие агенты на чём
> - `.harness/state.json` — память онбординга
>
> Что хочешь сделать?

---

## Error handling

Если на шагах 4.2–4.7 что-то ломается:

1. **НЕ оставляй частично применённое.**
2. Если ещё не было `git commit` — `git restore` / `git clean` чтобы вернуть к pre-onboard состоянию.
3. Если уже коммит — `git reset --hard HEAD~1` (только если pre-onboard коммит был чистый dogfood-harness clone и мы уверены).
4. Сообщи человеку какой шаг упал и почему. **Не пытайся «починить» автоматически без подтверждения.**

---

## Что НЕ делать

- Не запускать `/onboard` повторно без явного re-onboard confirm.
- Не удалять `.git/`, `.harness/state.json`, `.gitignore` (те части которых не добавлял сам).
- Не пушить в remote.
- Не делать `gh repo create` — у Муббарека уже есть свой repo (он пришёл через GitHub Template).
- Не редактировать `dogfood-harness` upstream — это его клон, не мой workspace.
