#!/bin/bash
set -e

MODEL_DIR="$HOME/.config/steno/models"
MODEL_PATH="$MODEL_DIR/ggml-base.en.bin"
MODEL_URL="https://huggingface.co/ggerganov/whisper.cpp/resolve/main/ggml-base.en.bin"

echo "Checking whisper-cpp..."
if ! command -v whisper-cli &>/dev/null; then
    echo "Installing whisper-cpp via Homebrew..."
    brew install whisper-cpp
else
    echo "whisper-cli found at $(which whisper-cli)"
fi

echo "Checking model..."
if [ ! -f "$MODEL_PATH" ]; then
    echo "Downloading ggml-base.en (~142MB)..."
    mkdir -p "$MODEL_DIR"
    curl -L "$MODEL_URL" -o "$MODEL_PATH" --progress-bar
    echo "Model saved to $MODEL_PATH"
else
    echo "Model already present at $MODEL_PATH"
fi

echo ""
echo "Setup complete. Run ./build.sh to build and launch Steno."
