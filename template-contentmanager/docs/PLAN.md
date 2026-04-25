# Master Plan — {{BRAND_NAME}} контент-workflow

> ИИ-инструментарий для ведения Instagram и СМИ-outreach одному контент-менеджеру без команды.
> Owner: {{OWNER_FIRST_NAME}} (solo content-manager, {{BRAND_NAME}} @ {{ORG_NAME}})
> Sprint length: {{SPRINT_LENGTH}} (обычно 3 недели)

## Current Phase

🟡 **Phase 0: Corpus Collection** — IN PROGRESS

---

## Как читать этот файл

- Claude и owner читают его каждую сессию
- Чекбокс → `[x]` после выполнения, коммитим (git add + git commit — да, даже для контент-workflow, это твоя audit trail)
- **Нельзя скипать фазы.** Exit criteria должны быть закрыты
- Если хочешь скипнуть — сначала `docs/decisions/NNN-*.md` с объяснением WHY

---

## Почему 4 фазы, а не сразу «настроить AI и постить»

Большинство туториалов «AI для контент-менеджеров» начинают с шага 2. Это приводит к AI-slop: агент генерит «средний контент» без знания твоего бренда → посты звучат как у любого хаба → shadowban + brand voice drift.

Порядок — от собственного corpus к продвинутой автоматизации:
- **Phase 0 (Corpus):** AI обучается ТВОЕМУ голосу и брендбуку, не универсальному «хаб-говору»
- **Phase 1 (MVP):** 1 агент решает самую больную проблему (proof: $20/mo подписка окупается первым же win'ом)
- **Phase 2 (Full Farm):** 7 агентов работают в координации, а не изолированно
- **Phase 3 (Sprint Rhythm):** процесс автоматически повторяется каждые 3 недели, retro улучшает систему

---

## Phase 0: Corpus Collection

**Goal:** AI знает, как звучит {{BRAND_NAME}}, чтобы не генерить generic-контент.

**Длительность:** 1-2 дня активной работы (обычно часть setup session + доделка вечером)

**Deliverables в `docs/corpus/`:**

- [ ] `brand-book.pdf` или `brand-book.md` — брендбук {{BRAND_NAME}} (цвета, шрифты, логотип, tone-of-voice)
- [ ] `top-posts/` — 5-7 топ-постов с объяснением «почему это сработало» (в 2-3 предложениях)
- [ ] `flop-posts/` — 3-5 постов, которые **не** зашли (чтобы AI знал, чего избегать)
- [ ] `voice-guide.md` — собственный tone-of-voice guide: 3-5 примеров «мы пишем вот так», «не пишем вот так»
- [ ] `visual-assets/` — готовые афиши, аватарки, шаблоны (3-5 референсов)
- [ ] `forbidden-topics.md` — что **не** пишем (политика, sensitive регион. темы, не-approved гос.программы, конкуренты)
- [ ] `audience-personas.md` — 2-3 портрета твоей аудитории (кто она, зачем читает {{BRAND_NAME}}, что ожидает)

**Deliverables в `docs/metrics/`:**

- [ ] `baseline.md` — стартовые цифры на дату bootstrap: текущие подписчики, средний охват, engagement rate, СМИ-упоминаний за последние 3 спринта
- [ ] `kpi-targets.md` — цели: сколько подписчиков к [дата], сколько СМИ/спринт, сколько reels/спринт

**Entry criteria:**
- [x] Harness установлен через `dogfood-new`
- [x] CLAUDE.md / PLAN.md / RISKS.md / AGENT-MAP.md адаптированы

**Exit criteria:**
- Все чекбоксы выше ✅
- AI может ответить на вопрос «напиши пост в стиле {{BRAND_NAME}}» и ты распознаёшь «да, это наш голос» без редактирования структуры

**Allowed agents:** `Explore` (разбирать твой контент-архив), `planner` (структура corpus'а), `docs-lookup` (Instagram best practices), `product-manager` (audience research)
**Blocked agents:** все 7 content-agents (MediaScout, ContentPlanner, etc) — **им нечего читать** до Phase 0 exit

---

## Phase 1: Agent Setup MVP

**Goal:** 1 агент решает твою **самую больную** проблему (обычно MediaScout — СМИ outreach). Proof: $20/mo окупается.

**Длительность:** 1 неделя после Phase 0

**Entry criteria:**
- [ ] Phase 0 exit criteria ✅
- [ ] Определена «самая больная боль» — 1 из 3 (СМИ / контент-хаос / аналитика)
- [ ] PR флипающий 🟡 marker смёржен

**Deliverables:**

- [ ] `.claude/agents/<primary-agent>.md` — первый агент настроен и протестирован (MediaScout по дефолту, если боль #1 = СМИ)
- [ ] `docs/media/contacts.md` или аналог — список целевых журналистов/изданий (если MediaScout)
- [ ] `docs/content-calendar/sprint-N.md` — текущий спринт (если ContentPlanner)
- [ ] `docs/metrics/first-week.md` — результаты первой недели использования: сколько черновиков сгенерировано, сколько принято, сколько опубликовано
- [ ] ≥1 реальный win, который окупает $20/mo подписку (напр. принятый pitch, экономия 2 часов на reel-сценарий, и т.п.)

**Правила:**
- **Только 1 агент.** Остальные 6 — Phase 2.
- Каждый день — короткий лог в `docs/metrics/daily-log.md`: что агент сгенерил, принято/не принято, что пошло не так
- Если после 7 дней агент не приносит value → **переориентируй на другого primary агента** (ADR), не добавляй ещё 6 сверху

**Exit criteria:**
- Primary agent работает, ты используешь его ≥3 раза в неделю без сопротивления
- ≥1 measurable win (принятый pitch, опубликованный reel, data-driven решение по метрике)
- Retro зафиксирован в `docs/metrics/phase-1-retro.md`

**Allowed agents:** primary content-agent (1 из 7), `Explore`, `docs-lookup`, `planner`
**Blocked agents:** остальные 6 content-agents

---

## Phase 2: Full Agent Farm

**Goal:** Все 7 агентов работают в координации. Каждый знает, когда передать задачу другому.

**Длительность:** 2-3 недели после Phase 1

**Entry criteria:**
- [ ] Phase 1 exit criteria ✅
- [ ] Primary agent стабильно работает 7+ дней без manual restart'ов
- [ ] PR флипающий 🟡 marker смёржен

**Deliverables — 6 оставшихся агентов (очерёдность настройки):**

Порядок основан на том, что первый win даёт MediaScout (СМИ), затем нужна разгрузка контент-хаоса, затем визуал, затем аналитика:

- [ ] `.claude/agents/ContentPlanner.md` — календарь спринта, баланс обязательные/HQ push/свой/entertainment
- [ ] `.claude/agents/EventRecap.md` — шаблон отчётных reels (разгружает регулярную нагрузку)
- [ ] `.claude/agents/ImageStudio.md` — замена Figma через AI (брендбук встроен)
- [ ] `.claude/agents/ReelScripter.md` — сценарии 15-60сек + b-roll prompts для fal.ai
- [ ] `.claude/agents/MetricsReality.md` — real vs shown аналитика
- [ ] `.claude/agents/NetworkScout.md` — локальные блогеры/вузы/бизнесы + outreach drafts

**Инфраструктура:**

- [ ] `docs/media/pitches/sprint-N/` — pitches, отправленные в этом спринте (статус: draft/sent/replied/accepted/rejected)
- [ ] `docs/network/contacts.md` — CRM блогеров, вузов, бизнес-сообществ
- [ ] `docs/content-calendar/sprint-N.md` — текущий спринт с балансом по категориям
- [ ] `docs/metrics/sprint-N.md` — итоги спринта по KPI

**API / Tools (с ADR):**

- [ ] fal.ai API key настроен (для картинок/видео) — `.env.local`, **не в git**
- [ ] Instagram Insights доступ (через Meta Business) — метод подтверждён
- [ ] `docs/decisions/NNN-tool-choice.md` — ADR по выбору внешних сервисов

**Правила:**
- **Не все 6 сразу.** По одному агенту в неделю. Иначе хаос.
- Каждый новый агент — короткий ADR «почему сейчас, что ожидаем»
- Обязательный weekly review: какие агенты используются, какие простаивают, что блокирует

**Exit criteria:**
- 7 агентов настроены
- ≥4 агентов используются регулярно (остальные могут быть situational)
- Хотя бы один полный спринт прошёл end-to-end через harness
- Retro в `docs/metrics/phase-2-retro.md`

**Allowed agents:** все content-agents + `Explore`, `docs-lookup`, `planner`, `product-manager`, `tech-scout` (для твоих публичных постов про процесс — если интересно)
**Blocked agents:** все code agents (dev-инструменты не нужны)

---

## Phase 3: Sprint Rhythm

**Goal:** Процесс стабильно повторяется каждые 3 недели. AI-agents не требуют настройки, только input + review. Retro улучшает систему.

**Entry criteria:**
- [ ] Phase 2 exit criteria ✅
- [ ] ≥1 полный спринт прошёл в Phase 2
- [ ] PR флипающий 🟡 marker смёржен

**Rhythm (per 3-week sprint):**

- **Week 1:**
  - Day 1: ContentPlanner составляет календарь спринта (на базе ретро прошлого)
  - Day 1-3: MediaScout генерит 5-6 pitches под текущие темы, ты отправляешь
  - Day 4-7: Ежедневные posts по календарю; ImageStudio + ReelScripter по запросу

- **Week 2:**
  - Day 8-14: continued execution, EventRecap обрабатывает события недели
  - Mid-sprint check: MetricsReality — промежуточные цифры, корректируем Week 3

- **Week 3:**
  - Day 15-19: финальная неделя публикаций, NetworkScout активирует блогерские коллаборации
  - Day 20: MetricsReality — итоги спринта
  - Day 21: Retro в `docs/metrics/sprint-N.md` + update `docs/decisions/` если нашлись новые паттерны

**Правила:**
- **Retro обязательно каждый спринт.** Без него агенты не учатся.
- Если KPI не достигнуты 2 спринта подряд → STOP, разбор в отдельной сессии с owner'ом
- Подписка на $20/mo продолжается, пока value > cost; если нет — kill-switch без обид

**Exit criteria (не конец фазы — continuous):**
- 3 спринта прошли стабильно, KPI либо достигнуты, либо понятно почему не достигнуты
- Retro-файлы показывают прогресс (не «то же самое каждый спринт»)
- **Month-4 check-in с @qartelio:** стоит ли продолжать, что изменилось, какие паттерны вошли в SoloYolo methodology

**Allowed agents:** all (по AGENT-MAP)
**Blocked agents:** none

---

## How to update this plan

При закрытии фазы:
1. Отметить все `[x]`
2. Обновить **Current Phase** наверху (перенести 🟡)
3. Коммит: `chore(plan): complete Phase N`
4. В следующей сессии: «мы перешли в Phase X»

При изменении самого плана:
1. `[DECISION]` Issue или ADR draft
2. Обдумать пару дней (не менять процесс в моменте)
3. Обновить через PR (даже solo — audit trail)

---

<!-- TEMPLATE-TODO: После bootstrap'а адаптировать:
     - Подставить {{BRAND_NAME}}, {{OWNER_FIRST_NAME}}, {{ORG_NAME}}, {{SPRINT_LENGTH}}
     - Уточнить KPI в baseline.md / kpi-targets.md под реальные цели
     - Если Instagram — не единственная платформа (Threads/TikTok/YouTube) — добавить в Phase 2
     - Удалить этот комментарий -->
