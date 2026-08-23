#!/usr/bin/env bash
set -euo pipefail

LOG="/home/k/Projects/ol-has/build-ollama.log"

# Cały output skryptu trafia jednocześnie na konsolę i do pliku logu
exec > >(tee -a "$LOG") 2>&1

echo "=== Budowanie Ollamy v0.33.0-rc2 (CMake) ==="
echo "Log: $LOG"
echo

# --- Preflight: sprawdzenie zależności ---
for tool in go cmake ninja; do
    if ! command -v "$tool" >/dev/null 2>&1; then
        echo "BLAD: brak narzedzia '$tool'."
        echo "Zainstaluj brakujace zaleznosci poleceniem:"
        echo "  sudo pacman -S --needed go cmake ninja"
        exit 1
    fi
done
echo "OK: narzedzia go, cmake, ninja — obecne."
echo "  go:      $(go version)"
echo "  cmake:   $(cmake --version | head -1)"
echo "  ninja:   $(ninja --version)"

# --- Preflight: istnienie repo ---
REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/ollama" && pwd)"
if [ ! -d "$REPO" ]; then
    echo "BLAD: repo nie istnieje w: $REPO"
    exit 1
fi
cd "$REPO"
echo "Repo: $REPO"
echo

# --- Konfiguracja ---
echo "Konfiguracja CMake..."
cmake -B build . \
    -DOLLAMA_VERSION=v0.33.0-rc2 \
    -DGGML_CPU_ALL_VARIANTS=OFF \
    -DGGML_AVX2=OFF \
    -DGGML_FMA=OFF \
    -DGGML_F16C=OFF \
    -DGGML_BMI2=OFF
echo

# --- Build ---
echo "Build (rdzeni: $(nproc))..."
cmake --build build --parallel "$(nproc)"
echo

# --- Weryfikacja wersji ---
echo "Weryfikacja wersji..."
./ollama --version
echo

# --- Smoke test na porcie 11435 (NIGDY 11434!) ---
SERVER_PID=""
cleanup() {
    if [ -n "${SERVER_PID:-}" ] && kill -0 "$SERVER_PID" 2>/dev/null; then
        kill "$SERVER_PID" 2>/dev/null || true
        wait "$SERVER_PID" 2>/dev/null || true
        echo "Serwer testowy zatrzymany."
    fi
}
trap cleanup EXIT

echo "Uruchamianie serwera na 127.0.0.1:11435..."
OLLAMA_HOST=127.0.0.1:11435 ./ollama serve &
SERVER_PID=$!

echo "Polling http://127.0.0.1:11435/api/version (maks. 30 s)..."
ok=0
for i in $(seq 1 30); do
    if curl -sf http://127.0.0.1:11435/api/version >/dev/null 2>&1; then
        ok=1
        break
    fi
    sleep 1
done

if [ "$ok" -eq 1 ]; then
    echo "SUKCES: serwer odpowiada na http://127.0.0.1:11435/api/version"
else
    echo "BLAD: serwer nie odpowiedzial w ciagu 30 sekund."
    exit 1
fi

echo
echo "=== Budowa zakonczona sukcesem ==="
echo "Binarka: $REPO/ollama"
echo "Pełny log: $LOG"
