#!/usr/bin/env python3
"""Strażnik promptów — sprawdza treść, zanim trafi do modelu.

    python straznik.py "treść promptu"
    cat prompt.txt | python straznik.py
    python straznik.py --pelny "treść"     # dokłada skaner wykrywający prompt injection

Kod wyjścia 0 = przepuszczone, 1 = odrzucone. Dzięki temu wpina się jako krok w pipeline.

To kopia używana przez akcję `.github/actions/straznik-promptu`. Wersja ćwiczeniowa
w `labs/lab09-llm-firewall/start/` żyje osobno — zmiany wzorców wprowadzaj tutaj.

Tryb domyślny używa wyłącznie skanerów regułowych — działają natychmiast i nie pobierają
modeli. Tryb `--pelny` dokłada `PromptInjection`, który pobiera model z Hugging Face
(kilkaset MB przy pierwszym uruchomieniu). Na szkoleniu uruchom go raz przed blokiem,
żeby model był już w cache.
"""

import argparse
import re
import sys

# Wzorce sekretów, które chcemy zatrzymać zanim opuszczą organizację.
# Lista jest krótka celowo — pełna lista i tak nie istnieje, o czym mówimy w demo.
WZORCE = [
    (r"AKIA[0-9A-Z]{16}", "klucz dostępowy AWS"),
    (r"(?i)aws_secret_access_key\s*[=:]\s*\S{20,}", "sekret AWS"),
    (r"gh[pousr]_[A-Za-z0-9]{36,}", "token GitHuba"),
    (r"-----BEGIN [A-Z ]*PRIVATE KEY-----", "klucz prywatny"),
    (r"(?i)(postgres(ql)?|mysql|mongodb)://[^\s:]+:[^\s@]+@", "connection string z hasłem"),
    (r"(?i)\b(hasło|password|passwd)\s*[=:]\s*\S{6,}", "hasło w treści"),
    # ARN ma stały prefiks i sześć pól: arn:partycja:usługa:region:konto:zasób.
    # Region i konto bywają puste (IAM, S3), więc dopuszczamy puste pola.
    (r"\barn:aws(-cn|-us-gov)?:[a-z0-9-]+:[a-z0-9-]*:(\d{12})?:\S+", "ARN zasobu AWS"),
    # Samo 12 cyfr to też telefon czy numer faktury — wymagamy słowa „konto"/„account"
    # najwyżej 20 znaków przed numerem. Łapiemy też zapis konsoli 1234-5678-9012.
    (
        r"(?i)\b(kont(o|a|u|em)?|koncie|account(s|_?id)?|acct)\b[^\d\n]{0,20}"
        r"(?<!\d)\d{4}-?\d{4}-?\d{4}(?!\d)",
        "identyfikator konta AWS",
    ),
    # PESEL: 11 cyfr RRMMDDxxxxx. Stulecie jest zakodowane w miesiącu (+20 dla 2000–2099,
    # +80 dla 1800–1899 itd.), więc poprawny miesiąc to cyfra parzysta + 1–9 albo
    # nieparzysta + 0–2. Wymóg poprawnej daty odsiewa większość losowych 11 cyfr.
    # Sumy kontrolnej regex nie sprawdzi — filtr celowo blokuje trochę za dużo.
    (
        r"(?<!\d)\d{2}([02468][1-9]|[13579][0-2])(0[1-9]|[12]\d|3[01])\d{5}(?!\d)",
        "numer PESEL",
    ),
]


def zbuduj_skanery(pelny: bool):
    from llm_guard.input_scanners import Regex, Secrets
    from llm_guard.input_scanners.regex import MatchType

    skanery = [
        Secrets(redact_mode="all"),
        Regex(
            patterns=[wzorzec for wzorzec, _ in WZORCE],
            is_blocked=True,
            match_type=MatchType.SEARCH,
        ),
    ]

    if pelny:
        from llm_guard.input_scanners import PromptInjection

        skanery.append(PromptInjection(threshold=0.85))

    return skanery


def main() -> int:
    parser = argparse.ArgumentParser(description="Strażnik promptów")
    parser.add_argument("prompt", nargs="?", help="treść promptu; bez tego czyta ze stdin")
    parser.add_argument("--pelny", action="store_true", help="dołącz skaner prompt injection")
    args = parser.parse_args()

    prompt = args.prompt if args.prompt else sys.stdin.read()
    if not prompt.strip():
        print("Pusty prompt — nie ma czego sprawdzać.", file=sys.stderr)
        return 1

    from llm_guard import scan_prompt

    skanery = zbuduj_skanery(args.pelny)
    _, wyniki, ryzyko = scan_prompt(skanery, prompt)

    odrzucone = [nazwa for nazwa, ok in wyniki.items() if not ok]

    if odrzucone:
        # Logujemy, KTÓRY skaner zareagował — nigdy samej treści, bo to właśnie ona
        # zawiera sekret, który próbujemy zatrzymać.
        print("ODRZUCONE. Zareagowały skanery: " + ", ".join(odrzucone), file=sys.stderr)
        if "Regex" in odrzucone:
            # Etykieta wzorca mówi, CO znaleziono, bez pokazywania dopasowanego fragmentu.
            powody = [opis for wzorzec, opis in WZORCE if re.search(wzorzec, prompt)]
            print("Powód: " + ", ".join(powody), file=sys.stderr)
        print(f"Poziom ryzyka: {ryzyko}", file=sys.stderr)
        print("Treść promptu nie została zalogowana — to ona jest problemem.", file=sys.stderr)
        return 1

    print("Przepuszczone.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
