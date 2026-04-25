# CLAUDE.md

Behavioral guidelines for Claude working on **{{PROJECT_NAME}}**. Merge with task-specific context as needed.

**Tradeoff:** These guidelines bias toward caution over speed. For trivial tasks, use judgment.

## 1. Think Before Coding

**Don't assume. Don't hide confusion. Surface tradeoffs.**

Before implementing:
- State your assumptions explicitly. If uncertain, ask.
- If multiple interpretations exist, present them — don't pick silently.
- If a simpler approach exists, say so. Push back when warranted.
- If something is unclear, stop. Name what's confusing. Ask.

## 2. Simplicity First

**Minimum code that solves the problem. Nothing speculative.**

- No features beyond what was asked.
- No abstractions for single-use code.
- No "flexibility" or "configurability" that wasn't requested.
- No error handling for impossible scenarios.
- If you write 200 lines and it could be 50, rewrite it.

Ask yourself: "Would a senior engineer say this is overcomplicated?" If yes, simplify.

## 3. Surgical Changes

**Touch only what you must. Clean up only your own mess.**

When editing existing code:
- Don't "improve" adjacent code, comments, or formatting.
- Don't refactor things that aren't broken.
- Match existing style, even if you'd do it differently.
- If you notice unrelated dead code, mention it — don't delete it.

The test: Every changed line should trace directly to the request.

## 4. Goal-Driven Execution

**Define success criteria. Loop until verified.**

Transform tasks into verifiable goals:
- "Add validation" → "Write tests for invalid inputs, then make them pass"
- "Fix the bug" → "Write a test that reproduces it, then make it pass"
- "Refactor X" → "Ensure tests pass before and after"

For multi-step tasks, state a brief plan and the check after each step.

---

# Project: {{PROJECT_NAME}}

> Owner: @qartelio (solo)
> Status: Phase 0 — Setup
> One-line pitch: **{{ONE_LINE_PITCH}}**
> First user (v1): {{FIRST_USER}}

Harness портирован из `qartelio/dogfood-harness` (bootstrap {{BOOTSTRAP_DATE}}). Любые изменения структуры harness'а фиксируй в `docs/decisions/` и — при желании — промотируй обратно в `dogfood-harness` через PR.

---

# Relationship to SoloYolo

**{{PROJECT_NAME}} — dogfood-контур SoloYolo.** Это значит:

- Harness-методика пришла из SoloYolo (через `dogfood-harness` template)
- {{PROJECT_NAME}} **не зависит от SoloYolo в runtime** — все файлы harness живут здесь самостоятельно
- Служит:
  - proof-of-concept для SoloYolo discovery calls («методика работает в ещё одном домене»)
  - R&D-loop: что из паттернов survived в этом проекте? Что не переносится?
- Обратная связь — **только через retro-ADR** (`docs/decisions/NNN-dogfood-retro-MM.md`), не через редактирование SoloYolo-файлов из этой сессии

---

# Language Policy

**Working language: Russian.** Дефолт для всех документов.

**Russian (ru):**
- Все файлы в `docs/`
- GitHub Issues/PRs (titles, descriptions, comments)
- Commit message bodies (subject остаётся conventional-commits English)
- Code comments where needed

**English (en) — не переводить:**
- Code identifiers, file names, framework terms
- Conventional-commit types (`feat`, `fix`, `chore`, etc.)
- CLI commands, API paths, URLs
- Этот файл (`CLAUDE.md`), `PLAN.md`, `RISKS.md`, `AGENT-MAP.md` — LLM-facing instruction docs

---

# Documentation Map

| When... | Read |
|---|---|
| Starting any session | `docs/PLAN.md` (🟡 marker) |
| Choosing an agent | `docs/AGENT-MAP.md` |
| Non-trivial action | `docs/RISKS.md` |
| ADR | `docs/decisions/NNN-*.md` |
| Research context | `docs/research/` |

Если нужного файла нет — проверь `docs/PLAN.md`. Если текущая фаза не производит этот файл — это R1 (см. RISKS).

---

# CRITICAL: Phase Discipline

**Before responding to any non-trivial task:**

1. **Check current phase** in `docs/PLAN.md` (🟡 marker)
2. **Check `docs/AGENT-MAP.md`** — какие агенты разрешены сейчас
3. **Scan request against `docs/RISKS.md`** — если совпадает с Trigger, показать Warning перед выполнением
4. **If user asks for future-phase work** — объяснить, что не сделано из intermediate фаз, и спросить: «Skip ahead anyway, or finish current phase first?»

**MANDATORY before asking «готов закрыть сессию?»:**

1. Run: `bash .claude/scripts/session-state.sh`
2. Вывод — **целиком и дословно** — в closing message (внутри fenced code block)
3. Только после этого — «готов закрыть сессию?»
4. Если скрипт отсутствует/падает — явно так и сказать. **Никогда не выдумывать вывод.**

**Также предложить (non-blocking):**
- Обновить чекбоксы `docs/PLAN.md`
- Создать ADR `docs/decisions/NNN-*.md` если принято нетривиальное решение
- Создать GitHub Issue для обсуждённой, но не сделанной работы
- Запустить `/save-session` при плотном контексте

**Override:** user говорит «override» / «я знаю, продолжай» / «ignore phase» → proceed без warning. Иначе — всегда warn first.

---

# Research discipline

Перед каждым нетривиальным решением (выбор инструмента, паттерна, зависимости) — **короткий research-pass** (WebSearch/docs/github). Все research-артефакты пишутся в `docs/research/` с **явными caveats** (что training data, что свежий источник, что не проверено). Research с caveats не промотируется в `docs/decisions/**` без re-verify (R11).

---

# Quick Reference

- **Фаза?** → `docs/PLAN.md`
- **Какой агент?** → `docs/AGENT-MAP.md`
- **Риск?** → `docs/RISKS.md`

При сомнении о фазе — спроси: «Какая сейчас фаза по `docs/PLAN.md`?» до того, как делать работу.

---

<!-- TEMPLATE-TODO: Adapt this file to project specifics after bootstrap:
     - Add project-specific sections (e.g., domain-data discipline, client confidentiality, compliance)
     - Remove SoloYolo relationship block if not applicable
     - Add project-specific Quick Reference entries
     Delete this comment after adaptation. -->
