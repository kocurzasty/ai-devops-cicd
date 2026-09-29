---
description: Udokumentuj decyzję techniczną albo wybór rozwiązania jako krótki ADR
---

Temat do udokumentowania: $ARGUMENTS

Napisz krótki dokument decyzyjny (lekki ADR) w tej strukturze — bez pomijania sekcji:

1. **Podsumowanie** — 3–5 zdań: jaki problem rozwiązujemy, jakie rozwiązanie proponujemy
   i w jakim kontekście (który blok szkolenia, który komponent — `app/`, `infra/`, CI/CD).
   Bez żargonu, tak żeby zrozumiał to ktoś, kto nie widział kodu.

2. **Plusy i minusy** — tabela albo lista, dla samego proponowanego rozwiązania (nie porównanie
   z alternatywami, to osobna sekcja). Każdy punkt konkretny, nie ogólnikowy — nie „lepsza wydajność",
   tylko co dokładnie i w jakich warunkach.

3. **Alternatywy** — co najmniej jedna realna alternatywa, którą rozważono i odrzucono, plus powód
   odrzucenia. Jeśli nie znasz realnych alternatyw dla tego kontekstu, powiedz to wprost zamiast
   wymyślać opcje na siłę.

4. **Koszty** — jeśli dotyczy infrastruktury: konkretne zasoby AWS w `eu-central-1` i rząd wielkości
   kosztu (miesięcznie albo za godziny szkolenia — dopasuj do kontekstu). Jeśli dotyczy narzędzia/AI:
   koszt licencji albo tokenów. Ceny, których nie jesteś pewien, oznacz `[do sprawdzenia]` —
   nie zgaduj liczb.

Zasady:
- Jeśli temat dotyczy zasobów albo konwencji z repo, trzymaj się nazewnictwa i tagów z `.claude/CLAUDE.md`
- Teksty po polsku, nazwy techniczne (typy zasobów, flagi, nazwy pól) po angielsku
- Nie oceniaj czy decyzja jest słuszna — dokumentujesz wybór, nie rekomendujesz go na nowo,
  chyba że użytkownik wprost o to poprosi

Zapisz wynik jako plik Markdown. Jeśli w repo istnieje katalog na tego typu dokumenty
(np. `docs/decisions/`, `docs/adr/`), użyj go i zapytaj o numer/nazwę pliku tylko jeśli konwencja
numeracji nie jest oczywista z istniejących plików; w przeciwnym razie zaproponuj nazwę pliku
i lokalizację przed zapisaniem.
