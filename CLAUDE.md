# CLAUDE.md — dogfood-harness (bootstrap)

> Это **bootstrap-режим**. Активен пока не запущен `/onboard`. После онбординга этот файл заменяется на project-specific `CLAUDE.md` из выбранного template'а.

## First-run check

Если **нет** файла `.harness/state.json` (или он есть, но `onboarded: false`) — это значит harness ещё не настроен под текущий проект.

**Действия в bootstrap-режиме:**

1. Первой репликой кратко поприветствовать и предложить запустить `/onboard`:
   > Привет. Это dogfood-harness, ещё не настроен под твой проект. Запусти `/onboard` — это 6 коротких вопросов (~3 минуты), после чего harness подстроится под тип/стек/цель и можно вайбкодить.

2. **Не модифицировать файлы. Не отвечать содержательно на «сделай X».** Если человек начнёт ставить задачи — мягко переадресовать на `/onboard`.

3. **Override:** если человек явно говорит «без онбординга» / «знаю что делаю» / «skip onboard» / «я сам настрою» — уважить и работать без него. Тогда поведение — обычное (внимание к assumption'ам, simplicity-first, surgical changes).

Если `.harness/state.json` есть и `onboarded: true` → читать его как контекст проекта. После онбординга **этот bootstrap-CLAUDE.md уже должен быть заменён** на project-specific версию из template'а (это делает `/onboard` step 4.2 — overwrite). Если ты видишь этот текст после онбординга — что-то не доехало; сообщи и предложи re-run `/onboard`.

## Language

Default — русский. Tech identifiers, conventional-commit types, CLI/API — English.

## Agent dispatch (bootstrap-mode defaults)

- Code change >20 lines → **code-reviewer** после
- auth / secrets / crypto / payments → **security-reviewer** (mandatory)
- ≥3 независимых задач → parallel Agent calls в одном сообщении

После `/onboard` эти пороги адаптируются под выбранный severity (`strict` / `chill`).

---

Source: github.com/qartelio/dogfood-harness — derived from SoloYolo methodology.
