# ol-has — Haswell-free ollama as a Claude Code gateway

Build [ollama](https://github.com/ollama/ollama) v0.33.0-rc2 from source with
Haswell-class CPU requirements disabled (AVX2/FMA/F16C/BMI2) — the binary runs on
any AVX-capable CPU (Sandy Bridge+). Not for local inference: it acts as a gateway
for Claude Code (Claude Code → ollama → ollama.com cloud models, authenticated via
`ollama signin`).

## Why

Stock ollama builds ship AVX2 kernels and crash with "haswell" errors on older CPUs
(e.g. MacBook Pro 11,3 / i7-4850HQ). This build disables those flags.

## Patches (`cmd/launch/claude.go`)

`ollama launch claude` sets these env vars for Claude Code:

| Variable | Value | Purpose |
|---|---|---|
| `CLAUDE_CODE_MAX_OUTPUT_TOKENS` | `64000` | max output tokens per response |
| `CLAUDE_CODE_MAX_CONTEXT_TOKENS` | `1048576` | model context window — lifts Claude Code's default 200K cap for unknown models |
| `CLAUDE_CODE_AUTO_COMPACT_WINDOW` | `1048576` | auto-compact at 1M (cloud models) |

Claude Code never reads context length from the API — it has a hardcoded per-model
table and defaults unknown models to 200K. `CLAUDE_CODE_MAX_CONTEXT_TOKENS` is the
documented override (requires Claude Code ≥ 2.1.193).

## Build

Requirements: go ≥ 1.26, cmake, ninja.

```bash
git submodule update --init --recursive
./build-ollama.sh
```

Result: `ollama/ollama` (client version 0.33.0-rc2). Full log: `build-ollama.log`.

## Run

```bash
OLLAMA_HOST=127.0.0.1:11434 ollama/ollama serve
ollama signin            # once, interactive
ollama pull <model-cloud>
ollama launch claude     # starts Claude Code through the gateway
```

## Layout

- `build-ollama.sh` — full build script (fetches llama.cpp pin b10488, CMake configure
  with CPU flags, parallel build, smoke test)
- `ollama/` — git submodule: [KrzysztofKowalski/ollama](https://github.com/KrzysztofKowalski/ollama)
  at v0.33.0-rc2 with the patches above (branch `ol-has`)
- `NOTES.md` — detailed notes (Polish)
