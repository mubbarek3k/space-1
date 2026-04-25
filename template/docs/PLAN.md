# Master Plan — {{PROJECT_NAME}}

> {{ONE_LINE_PITCH}}
> Owner: @qartelio (solo)
> First user (v1): {{FIRST_USER}}

## Current Phase

🟡 **Phase 0: Setup** — IN PROGRESS

---

## Как читать этот файл

- Claude и owner читают его каждую сессию
- Чекбокс → `[x]` после выполнения, коммитим
- **Нельзя скипать фазы.** Exit criteria должны быть закрыты
- Если хочешь скипнуть — сначала `docs/decisions/NNN-*.md` с объяснением WHY

---

## Phase 0: Setup

**Goal:** Репо, дисциплина, документация готовы до любой реальной работы.

- [x] Папка создана
- [x] `CLAUDE.md` установлен из `dogfood-harness` template
- [x] `PLAN.md`, `AGENT-MAP.md`, `RISKS.md` созданы
- [x] `.claude/settings.json` + session-state hook
- [x] `git init` + первый коммит
- [x] GitHub repo создан (**private**)
- [x] Первый push на GitHub
- [ ] `docs/idea.md` — первая гипотеза продукта (one page)
- [ ] `docs/research/` — минимум 1 research-файл по критическим неизвестным (стэк, рынок, платформа, compliance)
- [ ] ADR `001-<topic>.md` — первое нетривиальное решение зафиксировано
- [ ] CLAUDE.md адаптирован под project specifics (удалён TEMPLATE-TODO блок)
- [ ] PLAN.md Phase 1–3 переписаны под конкретный проект (заменить placeholder-контент)
- [ ] RISKS.md project-specific секция заполнена (R-X риски этого проекта)

**Exit criteria:**
- Все чекбоксы ✅
- Repo доступен на GitHub (private)
- Project-specific phases в PLAN.md перестали быть placeholder'ами

**Allowed agents:** `Explore`, `docs-lookup`, `planner`, `architect` (для ADR 001)
**Blocked agents:** code agents (`tdd-guide`, code reviewers, build-resolvers) — **кода ещё нет**

---

## Phase 1: Validation (PLACEHOLDER — переписать под проект)

> **TEMPLATE-TODO:** это заглушка. Вопросы для заполнения:
> - Что значит «валидировать» для **этого** проекта?
> - Какой paper-prototype / user-interview / market-test реально проверяет главную гипотезу?
> - Какое поведение должно возникнуть **без кода**, прежде чем писать код?
> - Сколько дней/интервью/экспериментов = достаточно?
>
> Примеры из существующих dogfood'ов:
> - `newflow` (SoloYolo dogfood #1): manual-workflow пока harness устанавливается
> - `dailyquest` (SoloYolo dogfood #2): paper-prototype с ребёнком ≥7 дней
> - `SoloYolo`: 5 discovery calls с ≥2 конверг-сигналами

**Entry criteria:**
- [ ] Phase 0 exit criteria ✅
- [ ] PR флипающий 🟡 marker Phase 0 → Phase 1 смёржен

**Goal:** <переписать>

**Deliverables:**

- [ ] `docs/validation/<name>.md` — <что фиксируем>
- [ ] `docs/validation/session-log.md` — ежедневные/еженедельные заметки

**Exit criteria:**
- <переписать под проект>

**Allowed agents:** `Explore`, `docs-lookup`, `planner`, `product-manager`
**Blocked agents:** code agents (кода всё ещё нет)

---

## Phase 2: Build (PLACEHOLDER — переписать под проект)

> **TEMPLATE-TODO:** это заглушка. Заполни:
> - Что за стэк? (ADR)
> - Что в MVP, что НЕ в MVP?
> - Кто первый реальный пользователь?
> - Сколько дней реального использования = signal?

**Entry criteria:**
- [ ] Phase 1 exit criteria ✅
- [ ] PR флипающий 🟡 marker смёржен
- [ ] Стэк выбран и зафиксирован ADR
- [ ] `docs/validation/mvp-scope.md` — минимальный scope v1

**Goal:** <переписать>

**Deliverables:**

- [ ] Repo инициализирован в выбранном стэке
- [ ] <core фичи по ADR>
- [ ] Тесты: ≥80% coverage (rules/common/testing.md)
- [ ] `docs/validation/field-log.md` — реальное использование ≥14 дней

**Правила:**
- TDD mandatory по rules/common/testing.md
- Никаких third-party SDK без ADR
- Privacy by design

**Exit criteria:**
- <переписать>

**Allowed agents:** all по AGENT-MAP
**Blocked agents:** смотри AGENT-MAP

---

## Phase 3+: <PLACEHOLDER — определить по проекту>

> **TEMPLATE-TODO:** это может быть:
> - External validation (вторая семья / вторая команда / second-customer)
> - Platform compliance (если это mobile / regulated)
> - Public launch
> - Monetization / scale

---

## How to update this plan

При закрытии фазы:
1. Отметить все `[x]`
2. Обновить **Current Phase** наверху (перенести 🟡)
3. Коммит: `chore(plan): complete Phase N`
4. В следующей сессии: «мы перешли в Phase X»

При изменении самого плана:
1. Issue с `[DECISION]` label (или ADR draft)
2. Обдумать 24 часа (solo-дисциплина)
3. Обновить через PR (даже solo — audit trail)
