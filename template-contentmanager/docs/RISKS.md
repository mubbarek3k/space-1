# Risks & Anti-Patterns — {{BRAND_NAME}} контент-workflow

> Известные способы, которыми контент-workflow может пойти криво. Когда Claude видит эти паттерны в запросе, он ОБЯЗАН явно показать warning перед выполнением.

---

## Как Claude использует этот файл

Для каждого риска ниже:
- **Trigger** = что детектим в запросе
- **Warning** = точный текст, который Claude показывает ДО выполнения
- После warning — вопрос: «Continue anyway, или [рекомендуемый путь]?»
- Если owner говорит **«override»** / **«я знаю, продолжай»** → proceed
- Иначе — предложить безопасный путь

---

# Universal Risks (R1–R11)

Эти риски применяются к любому harness-проекту. Не удалять.

## R1. «Сразу постить» (Premature Publishing)

**Trigger:** Owner просит сгенерировать пост / pitch / reel сценарий, когда `PLAN.md` показывает Phase 0 (Corpus Collection) — бренд-материалы ещё не загружены.

**Warning:**
> ⚠️ Мы в **Phase 0 — Corpus Collection**. AI не знает голоса {{BRAND_NAME}}. Генерить сейчас = generic-контент (AI-slop) под брендом хаба.
>
> Типичная стоимость: первые 2 недели будет казаться «ок», потом shadowban + brand drift.
>
> Рекомендуется: закрыть corpus collection (брендбук + top-posts + voice-guide), потом вернуться.
>
> Skip ahead anyway?

---

## R2. «Один агент на всё» (Mixing Concerns)

**Trigger:** Owner просит один агент сделать несвязанные вещи («нагенери мне pitch в СМИ, reels-сценарий и проверь аналитику»).

**Warning:**
> ⚠️ Задача затрагивает **[N доменов]**: [list — e.g., media outreach / reels production / analytics].
>
> Один агент на всё → generic output, ниже качество, путаются форматы (pitch журналисту ≠ сценарий reel).
>
> Рекомендуется: разбить на [N] отдельных прогонов (MediaScout → ReelScripter → MetricsReality).

---

## R6. «Смена бренда в процессе» (Mid-Sprint Brand Drift)

**Trigger:** Owner редактирует `docs/corpus/voice-guide.md` или `brand-book.*` в середине текущего спринта.

**Warning:**
> ⚠️ Менять brand voice в середине спринта:
> - Контент первой половины спринта будет в одном голосе, второй — в другом
> - Агенты дадут mixed output до конца спринта
> - Аудитория читает «колеблющийся бренд»
>
> Рекомендуется:
> 1. Открыть `[DECISION]` Issue с описанием изменения
> 2. Закончить текущий спринт в старом voice
> 3. Применить новый voice со следующего спринта + ADR с обоснованием

---

## R7. «Пропуск фазы» (Phase Skipping)

**Trigger:** Owner просит работу, явно принадлежащую Phase X+2, когда PLAN.md показывает Phase X (напр. «давай сразу все 7 агентов настроим», когда Phase 1 — Agent MVP).

**Warning:**
> ⚠️ Ты в Phase [X], просишь Phase [Y] работу.
>
> Пропущенные шаги: [list]
>
> Обычные последствия:
> - 7 агентов одновременно → путаешься, какой для чего, какой использовать не тянет
> - Proof-of-value ($20/mo окупается) теряется — нет clear first win
> - Retro становится невозможен (много переменных)
>
> Рекомендуется: остаться в Phase [X], или формально скипнуть через `docs/decisions/NNN-skip-phase.md`.

---

## R8. «Хардкод секретов» (Secrets in Code/Content)

**Trigger:** Owner вставляет API key (fal.ai, ElevenLabs, Meta Graph API), пароли, личные email-подписи с sensitive info в файлы, которые могут попасть в git.

**Warning (CRITICAL — не proceed без явного override):**
> 🚨 SECURITY: detected potential secret.
>
> Риски:
> - API keys (fal.ai $X/month, ElevenLabs voice clone) → если репа публичная, кто-то злоупотребит
> - Meta/Instagram токены → может быть заблокирован аккаунт, impersonation
> - Даже в приватном репо — если когда-то откроется, history остаётся
>
> Required:
> 1. Все API keys в `.env.local` (уже в `.gitignore` template'а)
> 2. Ссылаться через environment variable (`process.env.FAL_KEY` или аналог в скриптах)
> 3. Добавить placeholder в `.env.example`
>
> Если уже закоммичено — **rotate immediately** в соответствующем сервисе.

---

## R10. «Решение без ADR» (Undocumented Decision)

**Trigger:** Owner делает нетривиальный выбор (новая платформа — TikTok/Threads; новый сервис — fal.ai vs Midjourney; pivot в audience; новый формат постов как регулярка) без записи.

**Warning:**
> 📝 Это значимое решение. Без ADR:
> - Через 3 месяца забудешь, почему выбрала fal.ai а не Midjourney
> - Новые агенты будут re-ask «а почему мы делаем так»
> - Retro нет базы для разбора
>
> Рекомендуется: `docs/decisions/NNN-<topic>.md` (context / options / chosen / why). 5-10 минут сейчас = час экономии через месяц.

---

## R11. «Research на неполных данных» (Unverified Research Promotion)

**Trigger:** Артефакт в `docs/research/` содержит любой caveat-marker — «⚠ caveat», «не проверено», «не нашёл», «training data», «MCP недоступен». Owner просит использовать такой артефакт как основу для pitch / поста / ADR / стратегии спринта.

**Warning:**
> ⚠️ Артефакт `[path]` сделан с ограничениями (найдено: `[caveat marker]`).
>
> Перенос в реальный pitch/пост без re-verify:
> - Pitch на неточных данных → журналист ловит ошибку → репутационный хит
> - Пост на фактах из AI training data → могут быть устаревшие (Astana Hub changes fast)
>
> Рекомендуется:
> 1. Перепроверить через актуальный WebSearch / прямой контакт источника
> 2. Только потом — использовать в публикации

---

## R-F. «Magic expectations» (AI Will Do It All)

**Trigger:** Owner формулирует задачу через фразы типа «AI сам напишет», «автопубликация», «агент ведёт аккаунт», «без моего участия».

**Warning:**
> ⚠️ Harness — это **тулзы, а не замена**. Разделение 70/30:
> - ~70% production — AI (черновики, картинки, research, первые версии)
> - ~30% стратегия/ревью — ты (что постим, тон, финальная правка, approval у supervisor)
>
> «Автопубликация без review» = R-IG-6 (AI-slop → shadowban, brand drift, supervisor gets angry).
>
> Рекомендуется: переформулировать задачу с explicit review-шагом (agent → draft → твоя правка → supervisor approval → publish).

---

# Instagram-Specific Risks (R-IG)

Правила Instagram меняются; эти риски — baseline по состоянию на {{BOOTSTRAP_DATE}}. Ревью каждые 3 месяца.

## R-IG-1. «Automation TOS violation» (Bots / Bulk Actions)

**Trigger:** Owner просит скрипт для auto-follow / auto-unfollow / auto-like / mass-DM / engagement-bots / scheduled posting через неофициальные API.

**Warning:**
> 🚨 Instagram TOS violation:
> - Bulk follow/unfollow → shadowban (1-2 недели no-reach)
> - Auto-DM → ban аккаунта (permanent возможен)
> - Неофициальные API → risk бан + утечка credentials
>
> Harness **не делает** automated engagement. Точка.
>
> Рекомендуется: planning/drafting в harness, публикация — вручную через Meta Business Suite или native IG app.

---

## R-IG-2. «Engagement pod trap» (Artificial Engagement)

**Trigger:** Owner упоминает «давай найдём pod / engagement group / взаимные лайки».

**Warning:**
> ⚠️ Engagement pods:
> - Algorithm detects artificial patterns → reach penalty
> - Audience quality gets diluted (pod members, not target audience)
> - Metrics становятся ложными (газлайтинг, как сейчас с +107 показывает, +30 реально)
>
> Рекомендуется: organic engagement через реальные collaborations — см. NetworkScout pipeline в AGENT-MAP.

---

## R-IG-3. «Disclosure missing» (FTC + Казахстан реклама-закон)

**Trigger:** Owner генерит спонсорский контент, review продукта, collab с брендом, коммерческое партнёрство — без явной метки.

**Warning:**
> ⚠️ Раскрытие рекламы обязательно:
> - FTC guidelines (для международных partnerships): `#ad`, `#sponsored`, `#partner` в **первых** строках caption'а
> - Закон РК о рекламе: явная пометка «реклама» или «на правах рекламы»
> - Instagram Paid Partnership tag (когда доступен)
>
> Без раскрытия:
> - Штраф от Ministry of Information / КЗ Антимонопольного агентства
> - Removal поста Instagram-модерацией
> - Репутационный хит + aud loss
>
> Рекомендуется: любой sponsored контент — через `docs/decisions/NNN-partnership-X.md` с explicit disclosure-строкой.

---

## R-IG-4. «Content theft» (No Repost Without Credit)

**Trigger:** Owner просит переиспользовать чужой reel, фото, caption, идею поста — без явного credit'а или permission'а.

**Warning:**
> ⚠️ Репостинг чужого контента без credit:
> - DMCA strike (особенно зарубежные брендs)
> - Репутационный хит в community (Kazakh tech-community маленькое, узнают)
> - AQMOLA HUB supervisor может получить жалобу
>
> Рекомендуется:
> - Всегда credit @handle автора + permission (DM screenshot в `docs/network/permissions/`)
> - AI-генерация вместо копирования (ImageStudio, ReelScripter)

---

## R-IG-5. «Over-posting» (Reach Suppression)

**Trigger:** Owner планирует 3+ feed posts в день или 10+ stories подряд.

**Warning:**
> ⚠️ Over-posting:
> - >2 feed posts/день → средний reach per post снижается ~30-40%
> - >8-10 stories подряд → большинство подписчиков свайпают без дочитывания
>
> Рекомендуется:
> - Feed: 1-2 posts/день максимум
> - Stories: разбивать на «утро / день / вечер» блоки по 3-5
> - Reels: не больше 1/день, иначе internal competition за reach

---

## R-IG-6. «AI-slop pipeline» (Auto-publish без human review)

**Trigger:** Owner формулирует workflow без explicit review-шага («агент сгенерил → опубликовали»).

**Warning (CRITICAL):**
> 🚨 AI-slop pipeline — главный риск этого harness:
>
> Последствия:
> - Shadowban IG за low-quality automated content
> - Brand voice drift (нельзя будет откатить через 3 месяца)
> - Supervisor {{BRAND_NAME}} увидит post, который она не одобрила → trust collapse
> - AQMOLA HUB репутация страдает через ecosystem (Astana Hub audits)
>
> **Non-negotiable workflow:** agent → draft → **ТВОЯ правка** → **supervisor approval** → публикация.
>
> Если хочется ускорения — ускоряй production (agents делают drafts), не review.

---

# Organizational Risks (R-Org) — {{ORG_NAME}} specific

Риски, связанные с тем, что ты — сотрудница {{ORG_NAME}} (не-фрилансер), и контент — их IP.

## R-Org-1. «Corporate IP in personal repo» (AQMOLA HUB content utechka)

**Trigger:** Owner добавляет в git: брендбук, внутренние документы, strategy decks, не-опубликованные материалы, персональные данные членов community, supervisor'ские сообщения.

**Warning:**
> 🚨 Corporate IP leakage:
> - Брендбук {{BRAND_NAME}} — IP работодателя, не твоё
> - Utечка → breach of employment contract + civil/criminal risk
> - Даже в приватном репо: если репо когда-либо станет публичным, откатить нельзя (git history)
>
> Required:
> 1. Все corporate materials → `docs/corpus/` (уже в .gitignore?)
> 2. Проверить `.gitignore` включает `docs/corpus/`
> 3. Если случайно закоммичено — `git filter-branch` / BFG cleanup + force push (до первого public release)
>
> Рекомендуется: любое новое corporate материал → сначала check `git status`, потом commit.

---

## R-Org-2. «Approval chain bypass» (AI as governance shortcut)

**Trigger:** Owner упоминает «давай сразу опубликуем», «supervisor в отпуске — сами решим», «быстро пост без approval».

**Warning:**
> ⚠️ AQMOLA HUB approval workflow **не обходится** harness'ом.
>
> Harness **ускоряет** production (drafts за минуты вместо часов) — **не заменяет** governance (supervisor review).
>
> Если supervisor в отпуске:
> - Либо дождаться return
> - Либо использовать pre-approved content из buffer (если есть)
> - Либо подтвердить через замещающего supervisor'а
>
> Публикация без approval = R-Org-2 breach → supervisor trust collapse + возможное disciplinary.

---

## R-Org-3. «Brand voice drift from {{ORG_NAME}} style» (Off-tone generation)

**Trigger:** AI-агент генерит контент, который значительно отличается от `docs/corpus/voice-guide.md` (напр. слишком неформально для government-adjacent бренда; использует memes/sarcasm не к месту).

**Warning:**
> ⚠️ Brand voice drift detected:
> - Сгенерированный контент сравнён с voice-guide: mismatch по [conкретное: formality / tone / topic-handling]
> - {{ORG_NAME}} — {{BRAND_CHARACTER}} (e.g., government-adjacent IT ecosystem — профессиональный, community-oriented, но не overly corporate)
>
> Рекомендуется:
> 1. Отклонить draft, вернуть в агента с правкой «переписать в voice-guide style»
> 2. Если повторяется часто — обновить agent prompt, чтобы читал voice-guide обязательно

---

## R-Org-4. «Government-adjacent sensitivity» (Political/Regulatory misstep)

**Trigger:** Тема контента касается: политиков, гос.программ (не-approved sources), международных отношений, региональных/этнических тем, санкций, президентских инициатив (если source не official).

**Warning (CRITICAL):**
> 🚨 Government-adjacent sensitivity:
> - AQMOLA HUB аффилиирован с Astana Hub (государственная инициатива)
> - Любая AI-ошибка в фактах/тоне → audit от Astana Hub + репутационный хит для регионального хаба
> - Kazakh media могут подхватить ошибку и усилить (не все дружественно)
>
> **Mandatory:**
> 1. AI **не пишет** автономно про политику, госпрограммы, международные темы, социально-sensitive контент
> 2. Такие темы — **только через supervisor** с AI как drafting-tool max
> 3. Все факты — проверить через official source (akorda.kz, gov.kz, astanahub.com), не AI training data
>
> Рекомендуется: отклонить task, вернуть в supervisor для human-led approach.

---

# Project-Specific Risks (R-X)

> **TEMPLATE-TODO:** добавить риски, специфичные для {{BRAND_NAME}} после первого месяца использования.
>
> Примеры что может появиться:
> - R-X1: Сезонная нагрузка (Nauryz, Новый год, Summit Astana Hub) — кризисные периоды
> - R-X2: Конкретные sensitive темы {{BRAND_NAME}} (регион. споры, этнические темы Акмолинской области)
> - R-X3: Specific editorial calendars супервайзера или HQ
>
> Сформулировать под опыт первых 3 спринтов.

<!-- Delete this TEMPLATE-TODO after filling in -->

---

## Как добавить новый риск

Когда обнаружили новый анти-паттерн:

1. Добавить секцию тем же форматом (Trigger / Warning)
2. Добавить через PR
3. В commit message — референс на инцидент

Keep this **finite and high-signal**. Если список перевалит ~20 — удалить наименее срабатывающие.
