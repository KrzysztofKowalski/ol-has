# ol-has — ollama bez wymagań Haswell jako bramka dla Claude Code

## Cel
Zbudowana ze źródeł ollama v0.33.0-rc2 (CMake) z wyłączonymi flagami CPU klasy Haswell
(AVX2/FMA/F16C/BMI2), działająca na każdym CPU z AVX. Nie do lokalnej inferencji —
jako bramka: Claude Code → ollama (127.0.0.1:11435) → modele cloud z konta ollama.com
(autoryzacja przez `ollama signin`). Ollama nie potrafi być proxy do api.anthropic.com.

## Pliki
- `build-ollama.sh` — pełny skrypt budowy (pobiera llama.cpp pin b10488, CMake configure
  z flagami CPU, build równoległy, test serve na 11435). Uruchamianie: ./build-ollama.sh
- `ollama/` — klon upstream (github.com/ollama/ollama, tag v0.33.0-rc2), NIE jest częścią
  tego repo (.gitignore)

## Budowa
Wymagane: go >= 1.26, cmake, ninja. `./build-ollama.sh` robi wszystko; log w build-ollama.log.
Wynik: binarka `ollama/ollama` (client version 0.33.0-rc2).

## Uruchomienie bramki
serve: `OLLAMA_HOST=127.0.0.1:11435 ollama/ollama serve`
potem raz: `ollama signin` (interaktywne), `ollama pull <model-cloud>`, `ollama cp` (alias).
Claude Code: env w ~/.claude/settings.json (ANTHROPIC_BASE_URL=http://127.0.0.1:11435,
ANTHROPIC_AUTH_TOKEN=ollama, ANTHROPIC_API_KEY="", cztery zmienne modelowe).

UWAGA: nie używać portu 11434 (wcześniej AUR ollama).
