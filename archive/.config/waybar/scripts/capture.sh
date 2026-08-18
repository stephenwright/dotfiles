#!/bin/bash

# Waybar module: shows record state of `stew capture`.
# Glyph built via printf hex so source-transfer can't mangle it.
# U+23FA = BLACK CIRCLE FOR RECORD. Color (via CSS class) signals state.

glyph=$(printf '\xe2\x8f\xba')

if ~/bin/stew capture status 2>/dev/null | grep -q recording; then
    printf '{ "text": "%s", "class": "recording", "tooltip": "Recording \xe2\x80\x94 click to stop" }\n' "$glyph"
else
    printf '{ "text": "%s", "class": "idle", "tooltip": "Screen capture \xe2\x80\x94 click to start" }\n' "$glyph"
fi
