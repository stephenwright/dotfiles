#!/bin/bash

# Output "x" only when there's an active window
# Exit non-zero when no active window to hide the module

if hyprctl activewindow -j 2>/dev/null | jq -e '.address' >/dev/null 2>&1; then
    echo '{ "text": "x", "class": "" }'
else
    echo '{ "text": "", "class": "hidden" }'
fi


