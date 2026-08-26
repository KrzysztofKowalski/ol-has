# ol-has — ollama bez wymagań Haswell jako bramka dla Claude Code

## Cel
Zbudowana ze źródeł ollama v0.33.0-rc2 (CMake) z wyłączonymi flagami CPU klasy Haswell
(AVX2/FMA/F16C/BMI2), działająca na każdym CPU z AVX. Nie do lokalnej inferencji —
jako bramka: Claude Code → ollama (127.0.0.1:11434) → modele cloud z konta ollama.com
(autoryzacja przez `ollama signin`). Ollama nie potrafi być proxy do api.anthropic.com.

## Pliki
- `build-ollama.sh` — pełny skrypt budowy (pobiera llama.cpp pin b10488, CMake configure
  z flagami CPU, build równoległy, test serve). Uruchamianie: ./build-ollama.sh
- `ollama/` — git submodule: fork KrzysztofKowalski/ollama (branch `ol-has`), v0.33.0-rc2
  + patche w `cmd/launch/claude.go`. Klon: `git submodule update --init --recursive`
- `README.md` — opis projektu (EN)

## Budowa
Wymagane: go >= 1.26, cmake, ninja. `./build-ollama.sh` robi wszystko; log w build-ollama.log.
Wynik: binarka `ollama/ollama` (client version 0.33.0-rc2).

## Uruchomienie bramki
serve: `OLLAMA_HOST=127.0.0.1:11434 ollama/ollama serve`
potem raz: `ollama signin` (interaktywne), `ollama pull <model-cloud>`, `ollama cp` (alias).
Claude Code: `ollama launch claude` (ustawia ANTHROPIC_BASE_URL na OLLAMA_HOST,
ANTHROPIC_AUTH_TOKEN=ollama i zmienne modelowe).

## Patche w cmd/launch/claude.go (wbite w binarkę)
Lista envów ustawianych przez `ollama launch claude` (claude.go, `envVars`):
- `CLAUDE_CODE_MAX_OUTPUT_TOKENS=64000` — max output na odpowiedź
- `CLAUDE_CODE_MAX_CONTEXT_TOKENS=1048576` — context window modelu (znosi domyślny cap 200K
  Claude Code dla nieznanych modeli)
- `CLAUDE_CODE_AUTO_COMPACT_WINDOW=1048576` (dla modeli cloud) — auto-kompresja przy 1M

Mechanizm: `cmd.Env = append(os.Environ(), c.envVars(model)...)` (claude.go:63) — env shella
przechodzi bez czyszczenia, klucze ollamy dopisane na końcu wygrywają.

### Dlaczego CLAUDE_CODE_MAX_CONTEXT_TOKENS
Claude Code NIE czyta context length z API — ma twardo wpisaną tabelę context window per model.
Dla nieznanego modelu (np. `deepseek-v4-flash:cloud`) i custom base URL wpada na domyślne 200K
(„capped to 200k by model"). `CLAUDE_CODE_MAX_CONTEXT_TOKENS=1048576` to udokumentowany override
(wymaga CC >= 2.1.193). Model raportuje `deepseek4.context_length: 1048576` (1M).

### Testy
`claude_test.go` — `TestClaudeEnvVars` i `TestClaudeModelEnvVars` zaktualizowane pod patche.
Weryfikacja: `go build ./cmd/launch/` + `go test ./cmd/launch/ -run TestClaude`.
