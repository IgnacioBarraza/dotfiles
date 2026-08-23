#!/bin/bash

# Based on original by discomanfulanito [https://github.com/Discomanfulanito/pokefetch]
# for everyone — as code should be

set -u

FETCHER_BIN="fastfetch"
FETCHER_ARGS=(--logo none)

# Columns reserved for the sprite, and manual nudges on top of the centering.
WIDTH=40
EXTRA_PADDING_H=2
EXTRA_PADDING_W=0

CACHE_FILE="${XDG_CACHE_HOME:-$HOME/.cache}/pokemon-fetch-height"
FETCHER_CONFIG="${XDG_CONFIG_HOME:-$HOME/.config}/fastfetch/config.jsonc"

for dep in "$FETCHER_BIN" pokeget; do
    if ! command -v "$dep" &> /dev/null; then
        echo "pokemon.sh: $dep is not installed" >&2
        exit 1
    fi
done

# The height of the info block only changes when the fastfetch config or the
# terminal width changes, so it is cached. Measuring it on every prompt would
# mean running fastfetch twice per shell.
fetcher_height() {
    local cols height cached_cols cached_height
    cols="$(tput cols 2>/dev/null || echo 80)"

    if [ -r "$CACHE_FILE" ]; then
        read -r cached_cols cached_height < "$CACHE_FILE" || true
        if [ "${cached_cols:-}" = "$cols" ] &&
           [ -n "${cached_height:-}" ] &&
           [ ! "$FETCHER_CONFIG" -nt "$CACHE_FILE" ]; then
            echo "$cached_height"
            return 0
        fi
    fi

    height="$("$FETCHER_BIN" "${FETCHER_ARGS[@]}" | wc -l)"

    # Braces on purpose: a failing redirection is reported by the shell itself
    # before the command runs, so `echo ... 2>/dev/null` would not silence it.
    mkdir -p "$(dirname "$CACHE_FILE")" 2>/dev/null
    { echo "$cols $height" > "$CACHE_FILE"; } 2>/dev/null || true

    echo "$height"
}

# pokeget's random picker covers every sprite; the per-region list is only a
# fallback for versions where "random" is unavailable.
sprite="$(pokeget random --hide-name 2>/dev/null)"

if [ -z "$sprite" ]; then
    REGIONS=(kanto johto hoenn sinnoh unova kalos alola galar)
    sprite="$(pokeget "${REGIONS[RANDOM % ${#REGIONS[@]}]}" --hide-name 2>/dev/null)"
fi

if [ -z "$sprite" ]; then
    echo "pokemon.sh: could not fetch a Pokémon sprite" >&2
    exit 1
fi

fetcher_height="$(fetcher_height)"
height="$(printf '%s\n' "$sprite" | wc -l)"

# The escapes have to be stripped before measuring: pokeget emits a color
# sequence per pixel, so a raw line is roughly 32x its visible width. Note
# that `awk length()` is not an option here, since mawk counts bytes and the
# sprites are drawn with multi-byte block characters.
sprite_width="$(printf '%s\n' "$sprite" | sed 's/\x1b\[[0-9;]*m//g' | wc -L)"

pad_top=$(( (fetcher_height - height) / 2 + EXTRA_PADDING_H ))
[ "$pad_top" -lt 0 ] && pad_top=0

pad_lat=$(( (WIDTH - sprite_width) / 2 + EXTRA_PADDING_W ))
[ "$pad_lat" -lt 0 ] && pad_lat=0

printf '%s\n' "$sprite" | "$FETCHER_BIN" "${FETCHER_ARGS[@]}" \
    --file-raw - \
    --logo-padding-top "$pad_top" \
    --logo-padding-left "$pad_lat" \
    --logo-padding-right "$pad_lat"
