#!/usr/bin/env bash
# Usage:
#   ./httpx_scan.sh -d example.com
#   ./httpx_scan.sh -l domains.txt [-o out.txt] [-t 50]

THREADS=50
OUT=""

usage() { echo "Usage: $0 (-d domain | -l list.txt) [-o output.txt] [-t threads]"; exit 1; }

while getopts "d:l:o:t:" opt; do
  case $opt in
    d) DOMAIN="$OPTARG" ;;
    l) LIST="$OPTARG" ;;
    o) OUT="$OPTARG" ;;
    t) THREADS="$OPTARG" ;;
    *) usage ;;
  esac
done

command -v httpx-toolkit >/dev/null || { echo "[-] httpx-toolkit not found (sudo apt install httpx-toolkit)"; exit 1; }

if [[ -n "$LIST" ]]; then
  [[ -f "$LIST" ]] || { echo "[-] File not found: $LIST"; exit 1; }
  INPUT=(-l "$LIST")
  NAME=$(basename "$LIST" .txt)
elif [[ -n "$DOMAIN" ]]; then
  INPUT=(-u "$DOMAIN")
  NAME="$DOMAIN"
else
  usage
fi

OUT="${OUT:-httpx.txt}"

echo "[+] Probing... output -> $OUT"
httpx-toolkit "${INPUT[@]}" \
  -threads "$THREADS" \
  -status-code -title -tech-detect -ip -content-length -web-server \
  -follow-redirects -silent \
  -o "$OUT"

echo "[+] Done. $(wc -l < "$OUT") live hosts."
