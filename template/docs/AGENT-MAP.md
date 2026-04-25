# Agent Usage Map — {{PROJECT_NAME}}

> Говорит Claude, КАКОГО агента использовать для КАКОЙ задачи на КАКОЙ фазе {{PROJECT_NAME}}.
> Читается вместе с `PLAN.md` — знать, что разрешено прямо сейчас.

---

## By Phase (что разрешено когда)

### Phase 0: Setup
- ✅ `Explore` — сканировать research, references, похожие проекты
- ✅ `docs-lookup` — доки фреймворков / платформ / API
- ✅ `planner` — разбивать задачи на подзадачи
- ✅ `architect` — **только** для первого ADR (если он про стэк/архитектуру)
- ❌ `tdd-guide`, code reviewers, build-resolvers — **кода нет**
- ❌ `tech-scout` — нечего публиковать

### Phase 1: Validation
- ✅ `Explore`, `docs-lookup`, `planner`
- ✅ `product-manager` — structuring feedback, anonymization при любом разборе с third parties
- ❌ code agents — код всё ещё запрещён
- ❌ `tech-scout` — валидация обычно приватна

### Phase 2+: Build (кода много)
- ✅ `architect` — HLD для data model, архитектуры
- ✅ `planner` — декомпозиция фичи на дни работы
- ✅ **`tdd-guide` — primary** (TDD mandatory per rules/common/testing.md)
- ✅ `code-reviewer` — после каждой фичи (обязательно перед merge)
- ✅ Reviewer по стэку (выбрать после ADR 001):
  - Swift → skills (`swiftui-patterns`, `swift-concurrency-6-2`) + `code-reviewer`
  - Flutter/Dart → `flutter-reviewer`
  - Kotlin → `kotlin-reviewer`
  - TypeScript/JS → `typescript-reviewer`
  - Python → `python-reviewer`
  - Go → `go-reviewer`
  - Rust → `rust-reviewer`
  - Java → `java-reviewer`
  - C++ → `cpp-reviewer`
- ✅ Build-resolver по стэку (аналогично)
- ✅ `Explore` — навигация по своему коду
- ✅ `security-reviewer` — **обязателен** при PR, трогающем: auth, storage, permissions, network, secrets
- ✅ `refactor-cleaner` — раз в 2 недели audit
- ✅ `performance-optimizer` — если field-log фиксирует lag
- ✅ `e2e-runner` — для web; для mobile подбери custom skill (XCUITest / Espresso / Detox)

### Phase N+ (public / external users)
- ✅ All agents
- ✅ `security-reviewer` — усиленно (external-user data в игре)
- ⚠️ `tech-scout` — только с consent external users, анонимизировано

---

## By Task Type

| Task | Pipeline |
|---|---|
| Первое нетривиальное решение (стэк, storage, и т.п.) | `docs-lookup` → `Explore` (github примеры) → `architect` → ADR |
| Validation iteration (Phase 1) | `product-manager` (session-log structure) → owner → `docs-lookup` (по ходу) |
| Новая фича в коде | `planner` → `tdd-guide` (тесты сначала) → implement → reviewer-per-stack → `code-reviewer` → PR |
| Bug | `Explore` → `tdd-guide` (regression test) → fix → `code-reviewer` |
| Build сломан | build-resolver-per-stack |
| Retro (конец фазы) | `product-manager` (structure) → owner заполнение → update `docs/methodology/` в **SoloYolo** если есть инсайт про harness |
| ADR | owner draft → `product-manager` sanity check → PR |
| Dead code audit | `refactor-cleaner` |
| Docs update | `doc-updater` |

---

## By File Type

| File pattern | Reviewer agent |
|---|---|
| `docs/idea.md`, `docs/validation/**` | `product-manager` (structure) + manual review |
| `docs/decisions/**` | author → code-reviewer перед merge |
| `docs/research/**` | `docs-lookup` (verify sources) + manual caveat-check |
| `*.swift` | skills + `code-reviewer` |
| `*.dart` | `flutter-reviewer` |
| `*.kt`, `*.kts` | `kotlin-reviewer` |
| `*.ts`, `*.tsx`, `*.js`, `*.mjs` | `typescript-reviewer` |
| `*.py` | `python-reviewer` |
| `*.go` | `go-reviewer` |
| `*.rs` | `rust-reviewer` |
| `*.java` | `java-reviewer` |
| `*.cpp`, `*.h`, `*.hpp`, `*.cc` | `cpp-reviewer` |
| `*.sql` / migrations | `database-reviewer` |
| `.claude/agents/**` | `code-reviewer` |
| `.claude/scripts/**` | `code-reviewer` + ручная проверка на побочные эффекты |
| `.github/workflows/**` | `code-reviewer` + security-aware review |

---

## Mandatory Pre-PR Gates

### Phase 0–1 (docs only)
1. `product-manager` sanity check (если крупные изменения или касается внешних людей)
2. Manual diff review owner'ом
3. ADR (для нетривиальных решений — R10)

### Phase 2+ (код)
1. Tests pass, coverage ≥80%
2. Linter clean
3. `code-reviewer` agent
4. Reviewer-per-stack agent
5. `security-reviewer` — если PR трогает: storage, auth, permissions, network, secrets
6. Manual diff review

---

## Parallel Agent Rules

- ✅ **Parallel** когда агенты работают на разных файлах / worktrees
- ❌ **Sequential обязательно** когда:
  - Два агента меняют один файл
  - Dependency (test до кода, research до ADR)
  - Одна Claude-сессия без worktrees

---

## Specialized ECC Commands

| Command | Что делает |
|---|---|
| `/plan` | planner с prompt-scaffolding |
| `/code-review` | code-reviewer на current diff |
| `/security-review` | security-reviewer (обязателен при sensitive изменениях) |
| `/verify` | full pre-PR check |
| `/build-fix` | build-error-resolver (per-stack) |
| `/tdd` | TDD workflow |
| `/save-session` | save session state |
| `/resume-session` | restore previous session |

---

## Когда Map не покрывает твою задачу

1. Спроси Claude: «Какой ECC-агент лучше для [описание]?»
2. Claude предлагает 1–2 из `~/.claude/agents/`
3. Если не уверены → `general-purpose`
4. После выполнения — если задача повторяющаяся, **добавь строку в этот файл**

Keep this alive.

---

<!-- TEMPLATE-TODO: После bootstrap адаптируй:
     - Убери строки про стэки, которые не используешь
     - Добавь project-specific pipelines (например, compliance-pipeline для kids-app, discovery-pipeline для consulting)
     - Скорректируй allowed/blocked agents под phases из PLAN.md
     Delete this comment after adaptation. -->
