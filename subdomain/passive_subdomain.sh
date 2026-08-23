#!/bin/bash

# ---- Ask for target ----
read -p "Enter domain: " RAW_INPUT

# Strip protocol (http://, https://), www, trailing slash, and paths
DOMAIN=$(echo "$RAW_INPUT" | sed -E 's~https?://~~; s~^www\.~~; s~/.*~~')

SUBFILE="sub.txt"
TMPDIR=$(mktemp -d)

echo "[*] Target: $DOMAIN"
echo "[*] Output file: $SUBFILE (current directory)"

# ---- 1. Subfinder ----
echo "[*] Running subfinder..."
subfinder -d "$DOMAIN" -silent >> "$SUBFILE"

# ---- 2. Assetfinder ----
echo "[*] Running assetfinder..."
assetfinder --subs-only "$DOMAIN" >> "$SUBFILE"

# ---- 3. Amass ----
echo "[*] Running amass..."
amass enum -d "$DOMAIN" -silent -o "$TMPDIR/amass_tmp.txt" >/dev/null 2>&1
cat "$TMPDIR/amass_tmp.txt" >> "$SUBFILE" 2>/dev/null

# ---- 4. crt.sh ----
echo "[*] Querying crt.sh..."
curl -s "https://crt.sh/?q=${DOMAIN}&output=json" | jq -r '.[].name_value' >> "$SUBFILE"

# ---- Clean + organize ----
echo "[*] Cleaning and deduplicating..."
sed -i 's/\*\.//g' "$SUBFILE"                              # remove wildcard *.
sed -i '/^$/d' "$SUBFILE"                                  # remove empty lines
# keep only valid domain-looking lines (letters/digits/dots/hyphens ending in the target domain)
grep -E "^[a-zA-Z0-9._-]+\.${DOMAIN}$|^${DOMAIN}$" "$SUBFILE" > "$TMPDIR/sub_clean.txt"
sort -u "$TMPDIR/sub_clean.txt" -o "$SUBFILE"
rm -rf "$TMPDIR"

echo "[*] Done. Unique subdomains saved in: $SUBFILE"
echo "[*] Total found: $(wc -l < "$SUBFILE")"
