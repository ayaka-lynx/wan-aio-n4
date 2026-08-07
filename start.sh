#!/usr/bin/env bash
set -euo pipefail

COMFY_DIR="/ComfyUI"
VOLUME="/workspace"
MODELS_DIR="${VOLUME}/models"

# make models directory on the $MODELS_DIR/
mkdir -p "${MODELS_DIR}"
for sub in checkpoints vae loras unet clip text_encoders controlnet upscale_models embeddings; do
    mkdir -p "${MODELS_DIR}/${sub}"
done
rm -rf "${COMFY_DIR}/models"
ln -sfn "${MODELS_DIR}" "${COMFY_DIR}/models"

# check CIVITAI_TOKEN
if [ -z "${CIVITAI_TOKEN:-}" ]; then
    echo "HEY YOU!!!!!!!!!"
    echo "You have not set the CIVITAI_TOKEN environment variable!"
    echo "So we cannot download LoRAs from Civitai."
fi

# ---- Model collection helper ----
# Download a model file, skipping it if it already exists.
# Usage: dl <repo_id> <file_in_repo> <models_subdir>
dl() {
    local repo="$1" file="$2" subdir="$3"
    local dest="${MODELS_DIR}/${subdir}"
    if [ -f "${dest}/${file}" ]; then
        echo "[skip] ${subdir}/${file} already exists."
        return 0
    fi
    echo "[download] ${repo} -> ${subdir}/${file}"
    hf download "${repo}" "${file}" --local-dir "${dest}"
}

dl_civitai() {
    local version_id="$1" subdir="$2" fname="$3"
    local dest="${MODELS_DIR}/${subdir}"
    if [ -f "${dest}/${fname}" ]; then
        echo "[skip] ${subdir}/${fname} already exists."
        return 0
    fi
    mkdir -p "${dest}"
    echo "[download] civitai:${version_id} -> ${subdir}/${fname}"
    curl -L --fail \
        -H "Authorization: Bearer ${CIVITAI_TOKEN}" \
        -o "${dest}/${fname}" \
        "https://civitai.com/api/download/models/${version_id}"
}

# ---- Download models ----
dl Phr00t/WAN2.2-14B-Rapid-AllInOne Mega-v12/wan2.2-rapid-mega-aio-nsfw-v12.2.safetensors

# ---- Boot ComfyUI ----
cd /ComfyUI
exec python main.py \
    --listen 0.0.0.0 \
    --port 8188 \
    ${COMFYUI_EXTRA_ARGS:-}