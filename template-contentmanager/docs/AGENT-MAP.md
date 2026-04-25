# Agent Usage Map — {{BRAND_NAME}} контент-workflow

> Говорит Claude, КАКОГО агента использовать для КАКОЙ задачи на КАКОЙ фазе.
> Читается вместе с `PLAN.md` — знать, что разрешено прямо сейчас.

---

## Content Agents (primary 7 — твоя команда)

Эти агенты устанавливаются в `.claude/agents/` в процессе Phase 1-2. Все — content-workflow, не dev.

### 1. MediaScout (PRIMARY — запускаем первым)

**Назначение:** research СМИ + draft pitch-писем + persona-specific adaptation.

**Input:**
- Новая история / событие / milestone {{BRAND_NAME}} (from `docs/corpus/` или ad-hoc brief)
- Tier-список СМИ (в `docs/media/outlets.md`) с per-outlet preferences
- Research из `docs/research/smi-regional-hubs.md` (патterns, что работает)

**Output:**
- 3 версии pitch'а на одну историю (Tier 1 / Tier 2 / Tier 3 media)
- Персонализация под конкретного журналиста если известен
- Draft follow-up письма через 7 дней без ответа

**Rules:**
- Требует **3+ из 7 patterns** (named human, numbers, international, gov-strategy, named entity, recognizable brand, time-bound milestone)
- Если patterns не хватает — отказывается генерить, просит больше input'а
- Не copy-paste один pitch на все tiers
- Избегает повторения прошлых неуспешных pitches (log в `docs/media/pitches/rejected.md`)

**Trigger for use:** новый informativni повод, который можно pitch'нуть.

---

### 2. ContentPlanner

**Назначение:** 3-недельный контент-календарь с балансом категорий.

**Input:**
- KPI-цели спринта из `docs/metrics/kpi-targets.md`
- Обязательные даты (отчёты, HQ push, национальные события)
- Прошлый спринт retro из `docs/metrics/sprint-N.md`
- Topics buffer из `docs/content-calendar/ideas-backlog.md`

**Output:**
- `docs/content-calendar/sprint-N.md` — таблица по дням: тема / формат / агент-исполнитель / статус
- Балансировка: обязательные отчёты / HQ push / свой контент под новую аудиторию / entertainment
- Flags на дни, где load перегружен (нужен help / postpone)

**Rules:**
- Не больше 1-2 feed posts/день (R-IG-5)
- 20% buffer на ad-hoc (событие / новость подойдёт)
- Sensitive-темы помечает для mandatory supervisor review (R-Org-4)

**Trigger for use:** начало каждого нового спринта (Day 1).

---

### 3. ImageStudio

**Назначение:** замена Figma через AI-картинки под брендбук.

**Input:**
- Брендбук {{BRAND_NAME}} из `docs/corpus/brand-book.*` (цвета, шрифты, логотип, композиционные принципы)
- Brief на картинку (тема, формат — post/story/reel cover, aspect ratio)
- Референсы `docs/corpus/visual-assets/`

**Output:**
- Prompts для fal.ai (Nano Banana / Flux / SDXL — зависит от задачи)
- Brand-consistency check после генерации
- Файл в `docs/content-calendar/sprint-N/visuals/` с метаданными (prompt, model, date)

**Rules:**
- Все картинки — через брендбук (цвета проверяет, не отклоняется)
- Не генерит людей как primary subject без consent (правовой риск)
- Логотип — **никогда** в AI-генерации, только overlay в post-processing

**Trigger for use:** нужна картинка для поста/reel/отчёта.

---

### 4. ReelScripter

**Назначение:** сценарии reels 15-60 сек + b-roll prompts.

**Input:**
- Тема из content-calendar
- Тип reel (event recap / educational / human-interest / trend / announcement)
- Доступные ассеты: люди, локации, события, архив

**Output:**
- Сценарий: hook (0-3сек) / body (3-45сек) / CTA (последние 5-10 сек)
- Shot-list с таймингами
- Voice-over текст для твоей записи (native голос, не AI)
- B-roll prompts для fal.ai (если не хватает native материала)

**Rules:**
- Voice-over — **твой голос**, не AI cloning (trust + brand voice)
- Captions (subtitles) — на русском, для stories/feeds с охватом kz-speakers — варианты на казахском
- Длительность: первые 3 секунды = hook (иначе swipe-through)

**Trigger for use:** нужен reel сценарий.

---

### 5. MetricsReality

**Назначение:** real vs shown analytics — что работает, что slop.

**Input:**
- Export из IG Insights (ручной — Meta Business Suite → export)
- История публикаций за спринт
- Предыдущие retro из `docs/metrics/`

**Output:**
- `docs/metrics/sprint-N.md` — разбор:
  - Real reach vs bot-inflated numbers (фильтр по bounce rate, time-on-post)
  - Top-3 что сработало (с гипотезой почему)
  - Bottom-3 что не сработало
  - Recommendations для следующего спринта

**Rules:**
- Не считает vanity metrics (followers count без engagement)
- Flagит аномалии: +500 followers за ночь = bot-volna, не рост
- Cross-reference с ContentPlanner: какие категории работают, какие нет

**Trigger for use:** mid-sprint check (Day 10) + end-of-sprint (Day 20).

---

### 6. EventRecap

**Назначение:** отчётные reels/posts по шаблону после событий {{BRAND_NAME}}.

**Input:**
- Афиша / summary события (тема, спикеры, участников, результат)
- 3-5 кадров с события (фото/видео)
- Template из прошлых успешных recap'ов

**Output:**
- 1 reel-сценарий (30-60сек) — event recap
- 1 carousel post (3-5 слайдов) — summary + key takeaways
- 1 story serie (3-5 frames) — live-feel
- Caption под каждый — с тегом supervisor'а / partners / участников

**Rules:**
- Credit всех спикеров + participating orgs (tag или @mention)
- Fact-check цифры (участников, продолжительность) перед публикацией
- Template-based, не заново генерить структуру каждый раз

**Trigger for use:** после каждого события {{BRAND_NAME}} (meetup, workshop, demo day, hackathon).

---

### 7. NetworkScout

**Назначение:** research локальных блогеров/вузов/бизнесов + draft outreach + простой CRM.

**Input:**
- Регион {{BRAND_REGION}} (e.g., Акмолинская область / Кокшетау)
- Сегменты целевых партнёров (вузы, tech-блогеры, бизнес-сообщества, gov-adjacent orgs)
- История прошлых contacts из `docs/network/contacts.md`

**Output:**
- `docs/network/contacts.md` update: новые контакты с source, relevance, status
- Draft outreach письма под каждого (3-5 параграфов, персонализировано)
- Follow-up reminders (через 7/14/30 дней)
- Collaboration ideas под конкретного контакта

**Rules:**
- Offline-first: контакты в `docs/network/` должны быть реальными людьми с контактами, не scraper lists
- Exchange-based для старта (не платные коллаборации до proven relationship)
- Max 3-5 outreach/неделю (качество > количество)

**Trigger for use:** раз в неделю — поиск + outreach; daily — update contacts статус.

---

## By Phase (что разрешено когда)

### Phase 0: Corpus Collection
- ✅ `Explore` — разобрать твой контент-архив, IG-профиль, прошлые pitches
- ✅ `planner` — структура corpus
- ✅ `docs-lookup` — Instagram best practices, кейсы региональных хабов
- ✅ `product-manager` — audience research, personas
- ❌ **Все 7 content-agents** — им нечего читать (corpus ещё пуст)
- ❌ `tech-scout` — твой продукт пока не публичный (сам harness personal tool)

### Phase 1: Agent Setup MVP
- ✅ **Primary content-agent** (один из 7 — обычно MediaScout) — **только он**
- ✅ `Explore`, `docs-lookup`, `planner`
- ✅ `product-manager` — structure первого retro
- ❌ Остальные 6 content-agents — не настроены ещё
- ❌ `tech-scout`

### Phase 2: Full Agent Farm
- ✅ Все 7 content-agents (по мере ввода)
- ✅ `Explore`, `docs-lookup`, `planner`, `product-manager`
- ✅ `doc-updater` — обновление README / playbook'ов
- ⚠️ `tech-scout` — **только** для постов в твой собственный канал (если есть), с anonymization AQMOLA HUB

### Phase 3: Sprint Rhythm
- ✅ Все content-agents в координации
- ✅ `product-manager` — retro после каждого спринта
- ✅ Все support-agents
- ⚠️ `tech-scout` — с consent supervisor'а на публичный контент про harness

---

## By Task Type

| Задача | Pipeline |
|---|---|
| Bootstrap (Phase 0) | `Explore` (IG-архив) → `product-manager` (personas) → ручное заполнение corpus |
| Первое решение по платформам/тулам | `docs-lookup` → `Explore` (примеры) → owner → ADR |
| СМИ pitch | `MediaScout` с input из `docs/research/` → твоя правка → supervisor approval → отправка |
| Новый спринт (Day 1) | `MetricsReality` retro → `ContentPlanner` → календарь ручно ревьюишь |
| Post / reel production | `ContentPlanner` назначает → `ImageStudio` / `ReelScripter` / `EventRecap` → твоя правка → supervisor → publish |
| Event recap | `EventRecap` с input от события → `ImageStudio` для visuals → твоя правка → supervisor |
| Network research | `NetworkScout` (weekly) → твоя фильтрация → outreach drafts → ручная отправка |
| Аналитика / retro | `MetricsReality` → owner заполнение insights → update `docs/corpus/` patterns |
| ADR | owner draft → `product-manager` sanity check → PR |

---

## By File Type

| File pattern | Reviewer agent |
|---|---|
| `docs/corpus/**` | manual review (IP-sensitive, не в public git) |
| `docs/media/pitches/**` | `MediaScout` self-check + твоя правка |
| `docs/content-calendar/**` | `ContentPlanner` self-check |
| `docs/network/**` | `NetworkScout` + manual CRM update |
| `docs/metrics/**` | `MetricsReality` + owner interpretation |
| `docs/research/**` | `docs-lookup` (verify sources) + R11 caveat check |
| `docs/decisions/**` | owner draft → `product-manager` sanity → manual review |
| `.claude/agents/**` | manual review + test-run перед коммитом |

---

## Mandatory Pre-Publish Gates

Любой контент, идущий в IG {{BRAND_NAME}}:

1. **Agent draft** создан (через соответствующий агент из 7)
2. **Твоя правка** применена (tone, факты, тон)
3. **Check RISKS.md:** R-IG-3 (disclosure если спонсорство), R-IG-4 (credit), R-Org-3 (brand voice match), R-Org-4 (government-sensitive)
4. **Supervisor review** получен (email/chat, screenshot в `docs/network/permissions/`)
5. Только после этого — **publish** через native IG / Meta Business Suite

Skip любого gate = R-IG-6 violation.

---

## Parallel Agent Rules

- ✅ **Parallel** когда агенты работают на разных задачах: MediaScout на pitch + ContentPlanner на календарь + ImageStudio на картинку — OK
- ❌ **Sequential** когда:
  - Один output — input другого (ContentPlanner → ReelScripter)
  - Один файл трогают оба (два агента на `docs/content-calendar/sprint-N.md` = хаос)
  - `MetricsReality` retro должен быть до `ContentPlanner` на новый спринт

---

## Specialized ECC Commands (general-purpose)

| Command | Что делает |
|---|---|
| `/plan` | planner с prompt-scaffolding |
| `/save-session` | сохраняет состояние сессии (для resume завтра) |
| `/resume-session` | восстанавливает предыдущую сессию |
| `/docs` | lookup документации фреймворка / API |

Код-команды (`/code-review`, `/tdd`, `/build-fix`) — **не используются** в этом workflow.

---

## Когда Map не покрывает твою задачу

1. Спроси Claude: «Какой агент лучше для [описание]?»
2. Claude предлагает 1-2 из existing 7 content-agents или general-purpose
3. Если не уверена — `general-purpose`
4. После выполнения — если задача повторяющаяся, **добавь строку в этот файл**

Keep this alive.

---

<!-- TEMPLATE-TODO: После bootstrap адаптировать:
     - Подставить {{BRAND_NAME}}, {{BRAND_REGION}}
     - Если есть дополнительные платформы (TikTok, Threads, YouTube) — добавить platform-specific agents
     - Если supervisor review идёт через специфичный tool (Slack/Telegram) — указать в Mandatory Gates
     - Удалить этот комментарий -->
