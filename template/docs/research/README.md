# Research

> Папка для research-артефактов. Каждый нетривиальный решенческий вопрос (стэк, платформа, рынок, compliance) → отдельный markdown.

## Правила (из CLAUDE.md)

- Все research-артефакты — с **явными caveats** (что training data, что свежий источник, что не проверено)
- Research с caveats НЕ промотируется в `docs/decisions/**` без re-verify (R11)
- Формат каждого файла: краткое summary сверху, detailed findings ниже, citations в конце

## Пример структуры файла

```markdown
# <topic> — Research YYYY-MM

*Подготовлено: YYYY-MM-DD | Источников: N | Для: <зачем>*

## Summary
<3-5 строк главных выводов>

## 1. <section>
<findings с inline citations>

## 2. <section>
...

## Caveats
- <что не проверено>
- <что training data>
- <что требует re-verify>

## Sources
- [Title](url) — YYYY-MM-DD, primary/secondary
```
