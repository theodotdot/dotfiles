#!/bin/bash

# Get keyboard layouts from niri
keyboard_info=$(niri msg keyboard-layouts)

# Extract the active layout (marked with *)
active_layout=$(echo "$keyboard_info" | grep '^\s*\*' | sed 's/^\s*\* [0-9]\+ //')

# Determine the formatted output
if echo "$active_layout" | grep -q 'US' && echo "$active_layout" | grep -q 'intl'; then
    formatted_info='us intl'
elif echo "$active_layout" | grep -q 'Lafayette'; then
    formatted_info='lafayette'
elif echo "$active_layout" | grep -q 'Ergo'; then
    formatted_info='ergo-l'
else
    formatted_info="$active_layout"
fi

# Display the result
echo " $formatted_info"
