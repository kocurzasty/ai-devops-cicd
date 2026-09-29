# Skills vs komendy (slash commands) w Claude Code

Wyjaśnienie różnicy na przykładach z tego repo: komenda `.claude/commands/dokumentacja.md`
oraz skille `.claude/skills/` (np. `tf-review`, `security-audit`, `pr-review`, `postmortem`).

## 1. Struktura pliku

**Komenda** to jeden plik markdown z prostym frontmatterem:

```
.claude/commands/dokumentacja.md
---
description: Udokumentuj decyzję techniczną albo wybór rozwiązania jako krótki ADR
---
Temat do udokumentowania: $ARGUMENTS
[...stały szablon promptu...]
```

To dosłownie zamrożony prompt-template. `$ARGUMENTS` to placeholder na to, co user wpisze
po nazwie komendy.

**Skill** to katalog, w którym `SKILL.md` może być tylko wejściem do czegoś większego —
dodatkowych plików referencyjnych, szablonów, skryptów, którymi skill posiłkuje się w trakcie
działania. Np. `security-audit` (pełny audyt Terraform + GitHub Actions + k8s + kod aplikacji)
czy `postmortem` (post-mortem na bazie logów i metryk) to zwykle wieloetapowe procedury,
nie jeden prompt.

## 2. Jak się je uruchamia

- **Komenda**: user musi jawnie wpisać `/dokumentacja "migracja bucketa S3 na wersjonowany"`.
  Bez wpisania nazwy — nie odpali się.
- **Skill**: da się wywołać tak samo (`/tf-review`), ale opis skilla (`description`) jest
  stale załadowany do kontekstu modelu, więc agent może sam rozpoznać, że zadanie pasuje,
  i uruchomić skill bez proszenia o nazwę. Przykład: gdy user napisze „sprawdź, czy repo jest
  bezpieczne” — bez żadnego `/` — agent rozpoznaje to jako pasujące do opisu skilla
  `security-audit` i sam go uruchamia.

## 3. Do czego się ich używa w praktyce

| | Komenda | Skill |
|---|---|---|
| Typowe zastosowanie | krótki, powtarzalny prompt na żądanie (np. „wygeneruj mi ADR na temat X”) | rozbudowany playbook zależny od kontekstu repo (np. audyt bezpieczeństwa całego stanu, recenzja PR jako drugi recenzent) |
| Argumenty | `$ARGUMENTS` — jeden string z linii wywołania | częściej działa na bazie kontekstu rozmowy/repo, niekoniecznie jednego argumentu |
| Kto decyduje o uruchomieniu | zawsze user | user albo model, na podstawie dopasowania `description` do zadania |
| Złożoność | zwykle 1 plik | może mieć dodatkowe pliki (checklisty, szablony, skrypty), czasem odpala się jako subagent w tle |

## Skrót do zapamiętania

Komenda = „zrób dokładnie to, co user wpisał po `/`”.
Skill = „rozpoznaj, że to jest ten typ zadania, i sam wiedz, jak go zrobić” — nawet jeśli
user o tym nie wspomniał wprost, tylko opisał problem swoimi słowami.
