#!/bin/bash
# ffmpeg-presets.sh — preset commands dla optymalizacji wideo web
# Source: library/skills/webapp/video-web-integration/
# Konsumowany przez: optimize-media.sh (E10 paczki portfolio)
#
# Wymaga: ffmpeg (apt install ffmpeg / brew install ffmpeg)
#
# Użycie:
#   source ffmpeg-presets.sh
#   convert_hero_mp4 input.mov output.mp4
#   convert_hero_webm input.mov output.webm
#   extract_poster input.mov output.webp 0.5

set -euo pipefail

# =========================================================================
# Preset 1: HERO video MP4 (H.264 baseline, web-optimized)
# Target: < 2MB dla 30s clip, 1080p max
# =========================================================================
convert_hero_mp4 {
  local input="$1"
  local output="$2"

  ffmpeg -i "$input" \
    -c:v libx264 \
    -preset slow \
    -crf 26 \
    -profile:v baseline \
    -level 3.1 \
    -pix_fmt yuv420p \
    -vf "scale='min(1920,iw)':'-2'" \
    -movflags +faststart \
    -an \
    -y "$output"

  echo "✅ MP4 saved: $output ($(du -h "$output" | cut -f1))"
}

# =========================================================================
# Preset 2: HERO video WebM (VP9, smaller bitrate)
# Target: < 1.5MB dla 30s clip
# =========================================================================
convert_hero_webm {
  local input="$1"
  local output="$2"

  ffmpeg -i "$input" \
    -c:v libvpx-vp9 \
    -crf 32 \
    -b:v 0 \
    -row-mt 1 \
    -tile-columns 2 \
    -threads 4 \
    -vf "scale='min(1920,iw)':'-2'" \
    -an \
    -y "$output"

  echo "✅ WebM saved: $output ($(du -h "$output" | cut -f1))"
}

# =========================================================================
# Preset 3: CASE STUDY video MP4 (wyższa jakość, dłuższe wideo)
# Target: < 10MB dla 2-3 min clip
# =========================================================================
convert_case_study_mp4 {
  local input="$1"
  local output="$2"

  ffmpeg -i "$input" \
    -c:v libx264 \
    -preset slow \
    -crf 23 \
    -profile:v main \
    -level 4.0 \
    -pix_fmt yuv420p \
    -vf "scale='min(1920,iw)':'-2'" \
    -movflags +faststart \
    -c:a aac \
    -b:a 96k \
    -y "$output"

  echo "✅ Case-study MP4 saved: $output ($(du -h "$output" | cut -f1))"
}

# =========================================================================
# Preset 4: CASE STUDY video WebM (audio included)
# =========================================================================
convert_case_study_webm {
  local input="$1"
  local output="$2"

  ffmpeg -i "$input" \
    -c:v libvpx-vp9 \
    -crf 28 \
    -b:v 0 \
    -row-mt 1 \
    -tile-columns 2 \
    -threads 4 \
    -vf "scale='min(1920,iw)':'-2'" \
    -c:a libopus \
    -b:a 96k \
    -y "$output"

  echo "✅ Case-study WebM saved: $output ($(du -h "$output" | cut -f1))"
}

# =========================================================================
# Preset 5: Extract POSTER frame (WebP)
# Param 3: timestamp (sekundy lub fraction, default 0.5s = pierwszy interesujący frame)
# =========================================================================
extract_poster {
  local input="$1"
  local output="$2"
  local timestamp="${3:-0.5}"

  ffmpeg -ss "$timestamp" -i "$input" \
    -vframes 1 \
    -vf "scale='min(1920,iw)':'-2'" \
    -c:v libwebp \
    -quality 80 \
    -y "$output"

  echo "✅ Poster (WebP) saved: $output ($(du -h "$output" | cut -f1))"
}

# =========================================================================
# Preset 6: Extract POSTER fallback JPEG (dla starszych przeglądarek)
# =========================================================================
extract_poster_jpeg {
  local input="$1"
  local output="$2"
  local timestamp="${3:-0.5}"

  ffmpeg -ss "$timestamp" -i "$input" \
    -vframes 1 \
    -vf "scale='min(1920,iw)':'-2'" \
    -q:v 3 \
    -y "$output"

  echo "✅ Poster (JPEG) saved: $output ($(du -h "$output" | cut -f1))"
}

# =========================================================================
# Preset 7: Extract AUDIO (dla Whisper transcription)
# =========================================================================
extract_audio {
  local input="$1"
  local output="$2"

  ffmpeg -i "$input" \
    -vn \
    -acodec libmp3lame \
    -b:a 128k \
    -y "$output"

  echo "✅ Audio saved: $output ($(du -h "$output" | cut -f1))"
}

# =========================================================================
# Preset 8: Verify video properties (debugging)
# =========================================================================
inspect_video {
  local input="$1"

  echo "=== $input ==="
  ffprobe -v error -show_format -show_streams "$input" | grep -E "^(codec_name|width|height|duration|bit_rate|nb_frames|size)="
  echo "File size: $(du -h "$input" | cut -f1)"
}

# =========================================================================
# Preset 9: BATCH convert wszystkich wideo w katalogu
# Użycie: batch_convert_hero raw/ public/media/
# =========================================================================
batch_convert_hero {
  local input_dir="$1"
  local output_dir="$2"

  mkdir -p "$output_dir"

  for input in "$input_dir"/*.{mov,mp4,MOV,MP4,avi,mkv}; do
    [ -f "$input" ] || continue
    local basename=$(basename "$input")
    local name="${basename%.*}"

    echo "Processing: $basename"
    convert_hero_mp4 "$input" "$output_dir/${name}.mp4"
    convert_hero_webm "$input" "$output_dir/${name}.webm"
    extract_poster "$input" "$output_dir/${name}-poster.webp"
  done

  echo "✅ Batch convert done. Output: $output_dir/"
}

# =========================================================================
# Help
# =========================================================================
if [[ "${1:-}" == "--help" ]] || [[ "${1:-}" == "-h" ]]; then
  cat <<EOF
ffmpeg-presets.sh — FFmpeg presets dla web video

Funkcje:
  convert_hero_mp4       INPUT OUTPUT       — MP4 H.264 baseline, < 2MB / 30s
  convert_hero_webm      INPUT OUTPUT       — WebM VP9, < 1.5MB / 30s
  convert_case_study_mp4 INPUT OUTPUT       — MP4 z audio, dłuższe wideo
  convert_case_study_webm INPUT OUTPUT      — WebM z audio
  extract_poster         INPUT OUTPUT [SEC] — WebP poster, default 0.5s
  extract_poster_jpeg    INPUT OUTPUT [SEC] — JPEG poster fallback
  extract_audio          INPUT OUTPUT       — MP3 dla Whisper
  inspect_video          INPUT              — debug: codec, size, duration
  batch_convert_hero     INPUT_DIR OUT_DIR  — batch process

Wymagania:
  - ffmpeg (apt install ffmpeg / brew install ffmpeg)
  - libwebp, libvpx-vp9, libx264 (zwykle w paczce ffmpeg)

Użycie:
  source ffmpeg-presets.sh
  convert_hero_mp4 raw/hero.mov public/media/hero.mp4
EOF
fi
