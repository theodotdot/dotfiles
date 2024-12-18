#!/bin/bash

# Extract the keyboard name and active keymap for the main keyboard
keyboard_info=$(hyprctl devices | rg -B 5 'main: yes' | rg 'active keymap:' | sed 's/.*active keymap: //')

# Determine the formatted output
if echo "$keyboard_info" | grep -q 'US' && echo "$keyboard_info" | grep -q 'intl'; then
    formatted_info='us intl'
elif echo "$keyboard_info" | grep -q 'Lafayette'; then
    formatted_info='lafayette'
elif echo "$keyboard_info" | grep -q 'Ergo'; then
    formatted_info='ergo-l'
else
    formatted_info="$keyboard_info"
fi

# Display the result
echo " $formatted_info"

