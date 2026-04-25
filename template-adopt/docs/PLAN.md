# Master Plan — {{PROJECT_NAME}} (adopted)

> {{ONE_LINE_PITCH}}
> Owner: @qartelio (solo)
> Harness installed: {{BOOTSTRAP_DATE}} через `dogfood-adopt`
> **Adopted existing project** — Phase 0 это Audit, не fresh scaffolding.
> Detected stack: {{STACK}}

## Current Phase

🟡 **Phase 0: Audit** — IN PROGRESS

---

## Как читать этот файл

- Claude и owner читают его каждую сессию
- Чекбокс → `[x]` после выполнения, коммитим
- **Нельзя скипать фазы.** Exit criteria должны быть закрыты
- Если хочешь скипнуть — сначала `docs/decisions/NNN-*.md` с объяснением WHY

---

## Phase 0: Audit

**Goal:** Инвентаризация бардака. Harness установлен — теперь понять, ЧТО в этом коде, ЗАЧЕМ каждое крупное решение было принято, и ЧТО чистить первым.

**Deliverables:**

- [ ] `docs/audit/inventory.md` — карта репо: модули, размеры, зависимости (особо — deprecated), entry points, тесты (если есть), coverage baseline
- [ ] `docs/audit/dead-code.md` — результаты `knip` / `ts-prune` / `depcheck` прогонов (для JS/TS) или equivalent для {{STACK}}; явно помеченные false-positives
- [ ] `docs/audit/duplicates.md` — дубликаты паттернов, параллельные реализации (например, если jQuery + React вместе — это duplicate DOM-подхода)
- [ ] `docs/audit/md-cleanup.md` — решение по markdown-кладбищу в корне (какие документы сохранить, какие в `docs/history/`, какие удалить), с ADR'ом
- [ ] `docs/audit/priorities.md` — очередь: что чистим первым, что вторым, что оставляем
- [ ] Retroactive ADR'ы в `docs/decisions/` на **≥3 крупных принятых решения**. Примеры для TS-проекта: выбор stack, выбор auth, выбор storage/DB, выбор deployment target, выбор UI library
- [ ] `.gitignore` audit: что случайно tracked (`.DS_Store`, random JPG в корне, и т.д.)
- [ ] Secrets audit: `git log --all -p | grep -iE 'secret|password|token|api[_-]key'` — проверить, не утёк ли секрет в history

**Правила Phase 0:**
- **НЕ удаляем ничего в коде.** Audit только описывает, не действует.
- **НЕ переписываем архитектуру.** Phase 0 — только observation + retroactive ADR.
- Любое решение «что удалить» фиксируется в `priorities.md` + ADR, реальное удаление — Phase 1.

**Exit criteria:**
- Все deliverables ✅
- Retroactive ADR'ы покрывают минимум 3 «почему так сделано» для будущих сессий
- Priorities отсортированы и согласованы с owner
- Coverage baseline зафиксирован (даже если 0%)

**Allowed agents:** `Explore`, `docs-lookup`, `planner`, `architect` (для ADR retrospective), `refactor-cleaner` **только для анализа**, не для удалений
**Blocked agents:** `tdd-guide` на новый код (нет новых фич в Phase 0), build-resolvers (кроме read-only проверки, что сейчас собирается)

---

## Phase 1: Cleanup

**Entry criteria:**
- [ ] Phase 0 exit criteria ✅
- [ ] PR флипающий 🟡 marker Phase 0 → Phase 1 смёржен
- [ ] Coverage baseline зафиксирован в `docs/audit/inventory.md`

**Goal:** Удалить dead code и дубликаты по приоритетам из `docs/audit/priorities.md`. Безопасно — coverage не падает, продакшен не ломается.

**Правила Phase 1 (CRITICAL — см. R-Adopt-1 в RISKS.md):**
- **Никакого bulk-delete без тестов.** Если нет tests на модуль, который удаляем — сначала smoke-test (минимум: прогон `npm run build` + ручная проверка критичных user flows).
- Один concern = один PR. Не mix «удалил dead code + рефакторил auth + fix bug».
- Каждый PR в описании: какой priority из `priorities.md` закрывает.
- Coverage после PR ≥ baseline. Если упала — значит удалили что-то используемое.
- Если обнаружил, что «dead code» на самом деле live → remove from priorities, update `dead-code.md` с объяснением.

**Deliverables:**

- [ ] Priorities-очередь в `docs/audit/priorities.md` сократилась до ≤20% от начальной
- [ ] Каждый закрытый priority → PR merged, ссылка в priorities.md
- [ ] `docs/audit/cleanup-log.md` — что удалено, что оставлено и почему (обновляется после каждого PR)
- [ ] Coverage report после Phase 1 ≥ baseline

**Exit criteria:**
- ≥80% priorities из Phase 0 закрыто
- Не было регрессий в critical user flows (owner подтверждает через manual smoke-test)
- `cleanup-log.md` финализирован

**Allowed agents:** all из AGENT-MAP (Phase 1+ row), особенно `refactor-cleaner`, `{{STACK_REVIEWER}}`, `code-reviewer`, `security-reviewer` (при touching auth/storage)

---

## Phase 2: Stabilize

**Entry criteria:**
- [ ] Phase 1 exit criteria ✅
- [ ] PR флипающий 🟡 marker смёржен

**Goal:** Привести проект к known-good state: тесты, CI, commit-дисциплина. После Phase 2 можно добавлять новые фичи уверенно.

**Deliverables:**

- [ ] Tests: ≥60% coverage на критичных модулях (auth, payment/booking если есть, data persistence)
- [ ] CI-pipeline (GitHub Actions): lint + type-check + test на каждый PR
- [ ] Conventional-commits hook (`commitlint` или pre-commit)
- [ ] Все retroactive ADR'ы финализированы (не stub'ы)
- [ ] `docs/audit/*` promoted в `docs/history/` (они больше не актуальны — просто historical record)
- [ ] README.md обновлён: как запустить, как тестить, как деплоить

**Exit criteria:**
- CI зелёный на main ≥2 недели подряд
- Ни одного merge без passing tests
- Все ADR'ы — полноценные (context / options / chosen / why), не заглушки

**Allowed agents:** all
**Blocked agents:** none

---

## Phase 3+: Forward

**Entry criteria:**
- [ ] Phase 2 exit criteria ✅

**Goal:** Normal dogfood-работа: новые фичи идут через стандартный flow (planner → tdd-guide → implement → reviewer → PR). Harness теперь просто часть проекта.

В этой фазе PLAN.md переосмысляется: что дальше делать с проектом? Новые фичи? Migration off deprecated dependencies? Monetization? Открытие API?

Каждое направление — отдельный ADR и phase.

---

## How to update this plan

При закрытии фазы:
1. Отметить все `[x]`
2. Обновить **Current Phase** наверху (перенести 🟡)
3. Коммит: `chore(plan): complete Phase N`
4. В следующей сессии: «мы перешли в Phase X»
