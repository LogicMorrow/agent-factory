#!/usr/bin/env bash
# library/scripts/generate-video-poster.sh
#
# Generuje poster (still frame) z wideo przez FFmpeg — WebP + JPEG fallback.
# Standalone wrapper dla najczęstszego use case (operator wrzuca wideo, chce poster).
#
# Origin: paczka af-pack-<nazwa> (E10 plan 2026-05-13).
# Konsumuje: library/skills/webapp/video-web-integration/ffmpeg-presets.sh
#
# Użycie:
#   ./generate-video-poster.sh input.mp4                       # 0.5s frame → input-poster.webp + .jpg
#   ./generate-video-poster.sh input.mp4 output-poster.webp     # custom output
#   ./generate-video-poster.sh input.mp4 output.webp 5.0        # 5s frame
#   ./generate-video-poster.sh --help

set -euo pipefail

SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"
FFMPEG_PRESETS="$SCRIPT_DIR/../skills/webapp/video-web-integration/ffmpeg-presets.sh"

if [[ ! -f "$FFMPEG_PRESETS" ]]; then
  FFMPEG_PRESETS=".claude/skills/webapp/video-web-integration/ffmpeg-presets.sh"
fi

if [[ ! -f "$FFMPEG_PRESETS" ]]; then
  echo "ERROR: ffmpeg-presets.sh not found" >&2
  exit 1
fi

source "$FFMPEG_PRESETS"

if [[ $# -eq 0 ]] || [[ "${1:-}" == "--help" ]]; then
  cat <<EOF
generate-video-poster.sh — extract poster (still frame) from video

Użycie:
  $0 <input.mp4> [output.webp] [timestamp_sec]

Examples:
  $0 hero.mp4                            # → hero-poster.webp + hero-poster.jpg, frame 0.5s
  $0 hero.mp4 custom-poster.webp         # → custom-poster.webp + custom-poster.jpg, 0.5s
  $0 hero.mp4 poster.webp 5.0            # → poster.webp + poster.jpg, frame 5.0s

Defaults:
  - Output: <input_basename>-poster.webp + .jpg
  - Timestamp: 0.5s (pierwszy interesujący frame, omija ewentualne black intro)
EOF
  exit 0
fi

INPUT="$1"
[[ ! -f "$INPUT" ]] && { echo "ERROR: input file not found: $INPUT" >&2; exit 1; }

OUTPUT_WEBP="${2:-}"
TIMESTAMP="${3:-0.5}"

if [[ -z "$OUTPUT_WEBP" ]]; then
  BASENAME=$(basename "$INPUT")
  NAME="${BASENAME%.*}"
  OUTPUT_DIR=$(dirname "$INPUT")
  OUTPUT_WEBP="$OUTPUT_DIR/${NAME}-poster.webp"
fi

# Derive JPEG path z WebP path
OUTPUT_JPEG="${OUTPUT_WEBP%.webp}.jpg"

echo "🎬 Extracting poster from: $INPUT"
echo "   Timestamp: ${TIMESTAMP}s"
echo "   WebP output: $OUTPUT_WEBP"
echo "   JPEG output: $OUTPUT_JPEG"

extract_poster "$INPUT" "$OUTPUT_WEBP" "$TIMESTAMP"
extract_poster_jpeg "$INPUT" "$OUTPUT_JPEG" "$TIMESTAMP"

echo ""
echo "🎉 Done. Embed w HTML/JSX:"
echo "   <video poster=\"$OUTPUT_WEBP\" preload=\"metadata\" muted autoplay playsinline>...</video>"
echo ""
echo "   Tip: preload jako LCP element:"
echo "   <link rel=\"preload\" as=\"image\" href=\"$OUTPUT_WEBP\">"
