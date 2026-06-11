#!/usr/bin/env bash
# library/scripts/optimize-media.sh
#
# Batch optymalizacja mediów dla portfolio (i innych projektów webapp):
#   - PNG/JPG → WebP + AVIF (opcjonalnie)
#   - MOV/MP4 → MP4 (H.264 baseline) + WebM (VP9)
#   - Video → poster JPEG/WebP (FFmpeg ekstrakt frame 0.5s)
#   - VTT scaffolding (opcjonalnie)
#
# Origin: paczka af-pack-<nazwa> (E10 plan 2026-05-13).
# Konsumuje: library/skills/webapp/video-web-integration/ffmpeg-presets.sh
#
# Użycie:
#   ./optimize-media.sh raw/ public/media/                  # batch convert
#   ./optimize-media.sh --hero raw/hero.mov public/media/   # single hero video
#   ./optimize-media.sh --case raw/case-1.mov public/media/ # single case-study video
#   ./optimize-media.sh --image raw/photo.jpg public/media/ # single image PNG/JPG → WebP/AVIF
#   ./optimize-media.sh --help
#
# Wymagania:
#   - ffmpeg (apt install ffmpeg / brew install ffmpeg)
#   - libwebp, libvpx-vp9, libx264 (zwykle w paczce ffmpeg)
#   - cwebp (apt install webp / brew install webp) — dla optymalizacji JPG/PNG
#   - avifenc (opcjonalnie, apt install libavif-tools) — dla AVIF

set -euo pipefail

SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"
FFMPEG_PRESETS="$SCRIPT_DIR/../skills/webapp/video-web-integration/ffmpeg-presets.sh"

if [[ ! -f "$FFMPEG_PRESETS" ]]; then
  # Fallback dla projektów po `/pack` deploy do `.claude/skills/`
  FFMPEG_PRESETS=".claude/skills/webapp/video-web-integration/ffmpeg-presets.sh"
fi

if [[ ! -f "$FFMPEG_PRESETS" ]]; then
  echo "ERROR: ffmpeg-presets.sh not found" >&2
  echo "Looked in:" >&2
  echo "  $SCRIPT_DIR/../skills/webapp/video-web-integration/ffmpeg-presets.sh" >&2
  echo "  .claude/skills/webapp/video-web-integration/ffmpeg-presets.sh" >&2
  exit 1
fi

source "$FFMPEG_PRESETS"

# =========================================================================
# Functions
# =========================================================================

check_dependencies {
  local missing=
  command -v ffmpeg >/dev/null 2>&1 || missing+=("ffmpeg")

  if [[ ${#missing[@]} -gt 0 ]]; then
    echo "ERROR: Missing dependencies: ${missing[*]}" >&2
    echo "Install:" >&2
    echo "  Ubuntu/Debian: sudo apt install ${missing[*]}" >&2
    echo "  macOS: brew install ${missing[*]}" >&2
    exit 1
  fi
}

convert_image {
  local input="$1"
  local output_dir="$2"

  local basename=$(basename "$input")
  local name="${basename%.*}"
  local ext="${basename##*.}"

  case "$ext" in
    jpg|JPG|jpeg|JPEG|png|PNG)
      ;;
    *)
      echo "SKIP: $input — not an image" >&2
      return 0
      ;;
  esac

  mkdir -p "$output_dir"

  # WebP via cwebp (lepsze niż ffmpeg dla obrazów)
  if command -v cwebp >/dev/null 2>&1; then
    cwebp -q 80 "$input" -o "$output_dir/${name}.webp" 2>/dev/null
    echo "✅ WebP: $output_dir/${name}.webp ($(du -h "$output_dir/${name}.webp" | cut -f1))"
  else
    # Fallback przez ffmpeg
    ffmpeg -i "$input" -c:v libwebp -quality 80 -y "$output_dir/${name}.webp" 2>/dev/null
    echo "✅ WebP (via ffmpeg): $output_dir/${name}.webp ($(du -h "$output_dir/${name}.webp" | cut -f1))"
  fi

  # AVIF (opcjonalnie)
  if command -v avifenc >/dev/null 2>&1; then
    avifenc --min 25 --max 35 "$input" "$output_dir/${name}.avif" >/dev/null 2>&1
    echo "✅ AVIF: $output_dir/${name}.avif ($(du -h "$output_dir/${name}.avif" | cut -f1))"
  fi
}

process_hero_video {
  local input="$1"
  local output_dir="$2"
  local basename=$(basename "$input")
  local name="${basename%.*}"

  mkdir -p "$output_dir"

  echo "🎬 Processing hero video: $basename"
  convert_hero_mp4 "$input" "$output_dir/${name}.mp4"
  convert_hero_webm "$input" "$output_dir/${name}.webm"
  extract_poster "$input" "$output_dir/${name}-poster.webp" 0.5
  extract_poster_jpeg "$input" "$output_dir/${name}-poster.jpg" 0.5
  echo "✅ Hero done. Audio dropped, ≤30s recommended."
}

process_case_video {
  local input="$1"
  local output_dir="$2"
  local basename=$(basename "$input")
  local name="${basename%.*}"

  mkdir -p "$output_dir"

  echo "🎬 Processing case-study video: $basename"
  convert_case_study_mp4 "$input" "$output_dir/${name}.mp4"
  convert_case_study_webm "$input" "$output_dir/${name}.webm"
  extract_poster "$input" "$output_dir/${name}-poster.webp" 5.0  # 5s = ciekawszy frame
  extract_audio "$input" "$output_dir/${name}-audio.mp3"
  echo "✅ Case-study done. Audio preserved + extracted MP3 (dla Whisper transcription)."
  echo "📝 Next: generate VTT captions z $output_dir/${name}-audio.mp3 (Whisper API)"
}

batch_process_dir {
  local input_dir="$1"
  local output_dir="$2"

  echo "📂 Batch processing: $input_dir → $output_dir"

  if [[ ! -d "$input_dir" ]]; then
    echo "ERROR: Input dir not found: $input_dir" >&2
    exit 1
  fi

  mkdir -p "$output_dir"

  # Images
  for input in "$input_dir"/*.{jpg,jpeg,png,JPG,JPEG,PNG} 2>/dev/null; do
    [ -f "$input" ] || continue
    convert_image "$input" "$output_dir"
  done

  # Videos — heuristic: jeśli pliki mają w nazwie "hero" → hero preset, inne → case-study
  for input in "$input_dir"/*.{mov,mp4,MOV,MP4,avi,mkv} 2>/dev/null; do
    [ -f "$input" ] || continue
    local basename=$(basename "$input")
    if echo "$basename" | grep -qiE '\bhero\b'; then
      process_hero_video "$input" "$output_dir"
    else
      process_case_video "$input" "$output_dir"
    fi
  done

  echo ""
  echo "📊 Output summary:"
  ls -lh "$output_dir/" 2>/dev/null || true
}

# =========================================================================
# Main
# =========================================================================

if [[ $# -eq 0 ]] || [[ "${1:-}" == "--help" ]] || [[ "${1:-}" == "-h" ]]; then
  cat <<EOF
optimize-media.sh — batch optymalizacja media dla portfolio

Użycie:
  $0 <input_dir> <output_dir>             # batch
  $0 --hero <input> <output_dir>          # single hero video (≤30s, no audio)
  $0 --case <input> <output_dir>          # single case-study video (audio preserved)
  $0 --image <input> <output_dir>         # single image PNG/JPG → WebP[+AVIF]
  $0 --help

Heuristic dla batch:
  - Pliki z 'hero' w nazwie → hero preset (no audio)
  - Inne wideo → case-study preset (audio preserved + MP3 extract)
  - Obrazy (jpg/png) → WebP via cwebp (jeśli zainstalowany) + AVIF (jeśli avifenc)

Wymagania:
  - ffmpeg (must)
  - cwebp (recommended: apt install webp)
  - avifenc (opcjonalnie: apt install libavif-tools)

Output:
  - hero: <name>.mp4 + <name>.webm + <name>-poster.webp + <name>-poster.jpg
  - case-study: <name>.mp4 + <name>.webm + <name>-poster.webp + <name>-audio.mp3
  - image: <name>.webp + (opcjonalnie) <name>.avif
EOF
  exit 0
fi

check_dependencies

case "$1" in
  --hero)
    shift
    [[ $# -lt 2 ]] && { echo "Usage: $0 --hero <input> <output_dir>" >&2; exit 1; }
    process_hero_video "$1" "$2"
    ;;
  --case)
    shift
    [[ $# -lt 2 ]] && { echo "Usage: $0 --case <input> <output_dir>" >&2; exit 1; }
    process_case_video "$1" "$2"
    ;;
  --image)
    shift
    [[ $# -lt 2 ]] && { echo "Usage: $0 --image <input> <output_dir>" >&2; exit 1; }
    convert_image "$1" "$2"
    ;;
  *)
    # Batch: $1=input_dir $2=output_dir
    [[ $# -lt 2 ]] && { echo "Usage: $0 <input_dir> <output_dir>" >&2; exit 1; }
    batch_process_dir "$1" "$2"
    ;;
esac

echo ""
echo "🎉 Optimize-media done."
