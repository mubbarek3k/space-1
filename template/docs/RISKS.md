# Risks & Anti-Patterns — {{PROJECT_NAME}}

> Известные способы, которыми этот проект может пойти криво. Когда Claude видит
> эти паттерны в запросе, он ОБЯЗАН явно показать warning перед выполнением.

---

## Как Claude использует этот файл

Для каждого риска ниже:
- **Trigger** = что детектим в запросе пользователя
- **Warning** = точный текст, который Claude показывает ДО выполнения
- После warning — вопрос: «Continue anyway, или [рекомендуемый путь]?»
- Если user говорит **«override»** / **«я знаю, продолжай»** → proceed
- Иначе — предложить безопасный путь

---

# Universal Risks (R1–R11)

Эти риски применяются к любому проекту с phase-дисциплиной. Не удалять.

## R1. «Сразу кодить» (Premature Coding)

**Trigger:** User просит написать код, CLI, stack-scaffolding, установить dependency, запустить code-агенты, когда `PLAN.md` показывает Phase 0 или фазу, где код ещё запрещён (см. AGENT-MAP).

**Warning:**
> ⚠️ Мы в **[current phase]**. Писать код сейчас означает, что какой-то upstream документ/валидация отсутствует.
> Типичная стоимость rework при skip'е валидации: 5–10× времени экономии.
>
> Рекомендуется: закрыть [specific missing item], потом вернуться.
>
> Skip ahead anyway?

---

## R2. «Один агент на всё» (Mixing Concerns)

**Trigger:** User просит один агент (или один промпт) сделать несвязанные вещи.

**Warning:**
> ⚠️ Задача затрагивает **[N доменов]**: [list].
>
> Один агент на всё → context pollution, ниже качество, тяжелее ревью.
>
> Рекомендуется: разбить на [N] отдельных прогонов.

---

## R3. «Тесты потом» (Skipping Tests)

**Trigger:** User говорит «tests later», «сначала фича, тесты потом», «no tests» или PR без тестов при добавлении логики. Активен с фазы, где появляется код.

**Warning:**
> ⚠️ TDD mandatory по `CLAUDE.md`, `AGENT-MAP.md` и rules/common/testing.md (80%+ coverage).
>
> Рекомендуется: `tdd-guide` агент первым.

---

## R4. «Прямой push в main» (Bypassing PR)

**Trigger:** User запускает `git push origin main` с code-изменениями.

**Warning:**
> ⚠️ `main` защищён **PR-дисциплиной**, физический push возможен.
>
> Прямой push:
> - Пропускает CI-проверки
> - Пропускает `code-reviewer` self-review
> - Ломает audit trail (в solo — это твоя единственная память процесса)
>
> Recommended: feature branch + PR даже в solo-режиме.

---

## R5. «Параллель без worktrees» (Unsafe Parallelism)

**Trigger:** User открывает вторую Claude-сессию в той же папке на другой ветке.

**Warning:**
> ⚠️ Две Claude-сессии в одной физической папке = git state conflicts.
>
> Рекомендуется:
> ```
> git worktree add ../{{PROJECT_SLUG}}-<task> dev/<task>
> ```

---

## R6. «Изменить концепцию во время реализации» (Mid-Build Spec Drift)

**Trigger:** User редактирует `docs/idea.md` или `docs/validation/mvp-scope.md` когда активная разработка идёт.

**Warning:**
> ⚠️ Менять концепцию во время реализации:
> - Invalidates текущие архитектурные решения
> - Создаёт полу-завершённые фичи
>
> Рекомендуется:
> 1. Открыть `[DECISION]` Issue с описанием изменения
> 2. Либо дождаться конца текущей волны задач, либо явно cancel затронутые Issues + новый ADR

---

## R7. «Пропуск фазы» (Phase Skipping)

**Trigger:** User просит работу, явно принадлежащую Phase X+2, когда PLAN.md показывает Phase X.

**Warning:**
> ⚠️ Ты в Phase [X], просишь Phase [Y] работу.
>
> Пропущенные шаги: [list]
>
> Обычные последствия:
> - Rework когда всплывает недостающий контекст
> - AI-агенты галлюцинируют, потому что input-docs не существует
>
> Рекомендуется: оставаться в Phase [X], или формально скипнуть через `docs/decisions/NNN-skip-phase.md`.

---

## R8. «Хардкод секретов» (Secrets in Code)

**Trigger:** User вставляет API key, токен, DB connection string в код или коммитит `.env`.

**Warning (CRITICAL — не proceed без явного override):**
> 🚨 SECURITY: detected potential secret in code/commit.
>
> Риски:
> - Секреты в GitHub-history → **навсегда** (даже после force-push и rotation reflog может остаться в fork'ах и кэшах)
> - Auto-scanners (GitGuardian, Trufflehog) flag публично
>
> Required:
> 1. Перенести в `.env.local` или platform-specific secure storage
> 2. Ссылаться через environment variable
> 3. Добавить placeholder в `.env.example`
>
> Если уже закоммичен — **rotate immediately**.

---

## R9. «Большой PR» (Mega-PR)

**Trigger:** User стейджит 500+ строк в 10+ файлов одним коммитом/PR.

**Warning:**
> ⚠️ PR [X строк / Y файлов] превышает review threshold.
>
> В solo-режиме это особенно опасно: `code-reviewer` агент плохо работает на таких объёмах.
>
> Рекомендуется: split по concern.

---

## R10. «Решение без ADR» (Undocumented Decision)

**Trigger:** User делает нетривиальный выбор (библиотека, паттерн, архитектура, storage, IAP provider) без записи.

**Warning:**
> 📝 Это значимое решение. Без ADR:
> - Через 3 месяца забудешь, почему выбрал это
> - Будущее «а давай просто X» станет бесконечным
>
> Рекомендуется: `docs/decisions/NNN-<topic>.md` (context / options / chosen / why).

---

## R11. «Research на неполных данных» (Unverified Research Promotion)

**Trigger:** артефакт содержит любую из строк — `⚠ caveat`, «не проверено», «не нашёл», «training data», «MCP недоступен». User просит использовать такой артефакт как основу для `docs/decisions/**`, submission, или production-фичи.

**Warning:**
> ⚠️ Артефакт `[path]` сделан с ограничениями (найдено: `[caveat marker]`).
>
> Перенос в authoritative docs без re-verify:
> - Решение на training data, а не актуальной информации
> - Caveats «растворяются» в ADR
>
> Рекомендуется:
> 1. Создать Issue с label `needs-reverify`
> 2. Прогнать research заново с рабочими WebSearch / фреш MCP
> 3. Только потом — переносить

---

## R-G. «SoloYolo dogfood-feedback neglect» (One-way loop)

**Trigger:** Активная работа над проектом идёт, но в SoloYolo (`docs/methodology/` / `docs/decisions/`) нет retro-ADR упоминающего этот проект за последние 30 дней.

**Warning:**
> ⚠️ {{PROJECT_NAME}} — dogfood для SoloYolo. Если методика не обновляется по итогам этого проекта, dogfood-loop работает в одну сторону.
>
> Рекомендуется: каждые 30 дней — `docs/decisions/NNN-dogfood-retro-MM.md` (в SoloYolo) с инсайтами: что из harness survived, что пришлось менять.

---

# Project-Specific Risks (R-X)

> **TEMPLATE-TODO:** добавь риски, специфичные для этого проекта. Шаблон:
>
> ```
> ## R-X. «<Короткое имя>» (<English tag>)
>
> **Trigger:** <что детектим>
>
> **Warning:**
> > ⚠️ <точный текст>
> >
> > <последствия>
> >
> > Рекомендуется: <безопасный путь>
> ```
>
> Примеры из существующих dogfood'ов:
> - SoloYolo: R-A (Generic AI consulting trap), R-E (Consulting scope creep), R-F (Magic expectations от клиента)
> - dailyquest: R-K (Kids Category compliance), R-C (Child PII exposure), R-D2 (MVP feature creep)
>
> Сформулируй под свой домен. Минимум 2-3 project-specific риска.

<!-- Delete this TEMPLATE-TODO block after filling in project-specific risks. -->

---

## Как добавить новый риск

Когда ты (или Claude) обнаружили новый анти-паттерн:

1. Добавь секцию тем же форматом (Trigger / Warning)
2. Добавь через PR
3. В commit message — референс на инцидент, который выявил риск

Keep this **finite and high-signal**. Если список перевалит ~15 — удалить наименее срабатывающие.
