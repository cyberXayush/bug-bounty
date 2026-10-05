#!/bin/bash

# ---- Ask for target ----
read -p "Enter domain: " RAW_INPUT
DOMAIN=$(echo "$RAW_INPUT" | sed -E 's~https?://~~; s~^www\.~~; s~/.*~~')

WORDLIST="/usr/share/wordlists/SecLists/Discovery/DNS/subdomains-top1million-110000.txt"
RESOLVERS="resolvers.txt"
OUTFILE="active_sub.txt"
RATE=300   # requests per second, safe-ish default

echo "[*] Target: $DOMAIN"

# ---- Check wordlist exists ----
if [ ! -f "$WORDLIST" ]; then
    echo "[!] Wordlist not found at $WORDLIST"
    echo "[!] Check path with: locate subdomains-top1million"
    exit 1
fi

# ---- Get fresh trusted resolvers (avoids relying on only 8.8.8.8) ----
if [ ! -f "$RESOLVERS" ]; then
    echo "[*] Fetching trusted resolvers list..."
    curl -s https://raw.githubusercontent.com/trickest/resolvers/main/resolvers.txt -o "$RESOLVERS"
fi

# ---- Step 1: Permutations from existing known subs (optional, uses alterx) ----
if [ -f "sub.txt" ] && command -v alterx >/dev/null 2>&1; then
    echo "[*] Generating smart permutations from sub.txt..."
    alterx -l sub.txt -o permutations.txt
fi

# ---- Step 2: Brute-force with puredns (rate-limited) ----
echo "[*] Running puredns bruteforce (rate-limit: $RATE)..."
puredns bruteforce "$WORDLIST" "$DOMAIN" \
    -r "$RESOLVERS" \
    --rate-limit "$RATE" \
    -w "$OUTFILE"

# ---- Step 3: Also resolve permutations if generated ----
if [ -f "permutations.txt" ]; then
    echo "[*] Resolving permutations..."
    puredns resolve permutations.txt -r "$RESOLVERS" --rate-limit "$RATE" -w permutations_resolved.txt
    cat permutations_resolved.txt >> "$OUTFILE"
    rm -f permutations.txt permutations_resolved.txt
fi

# ---- Clean + merge with passive sub.txt if present ----
sort -u "$OUTFILE" -o "$OUTFILE"

if [ -f "sub.txt" ]; then
    cat sub.txt "$OUTFILE" | sort -u > all_sub.txt
    echo "[*] Merged with passive results -> all_sub.txt"
fi

echo "[*] Done. Active brute-force results: $OUTFILE"
echo "[*] Total found: $(wc -l < "$OUTFILE")"
