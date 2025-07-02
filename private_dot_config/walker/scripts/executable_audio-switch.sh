#!/bin/bash

# Function to get sink data (ID and name)
get_sinks() {
    wpctl status -k | grep -zoP '(?<=Sinks:)(?s).*?(?=├─)' | grep -a "\." | sed 's/^[^0-9]*\([0-9]\+\)\. \(.*\)$/\1|\2/' | sed 's/ \[vol:.*\]//'
}

# Function to list sinks
list_sinks() {
    get_sinks | while IFS='|' read -r id name; do
        echo "$id: $name"
    done
}

# Function to switch sink
switch_sink() {
    local input="$1"
    local target_id
    local found=false

    # Extract ID from input (everything before the first colon)
    if [[ "$input" =~ ^([0-9]+): ]]; then
        target_id="${BASH_REMATCH[1]}"
    else
        echo "Error: Invalid format. Expected format: 'ID: Name'"
        exit 1
    fi

    while IFS='|' read -r id name; do
        if [[ "$id" == "$target_id" ]]; then
            wpctl set-default "$id"
            notify-send "Audio" "Switched to: $name"
            found=true
            break
        fi
    done < <(get_sinks)

    if [[ "$found" == false ]]; then
        notify-send "Error: Sink ID $target_id not found"
        exit 1
    fi
}

# Main logic
case "$1" in
    -l|--list)
        list_sinks
        ;;
    -i|--id)
        if [[ -z "$2" ]]; then
            echo "Error: Sink line required"
            echo "Usage: $0 -i 'ID: Name'"
            exit 1
        fi
        switch_sink "$2"
        ;;
    *)
        echo "Usage: $0 [-l|--list] [-i|--id 'ID: Name']"
        echo "  -l, --list    List available audio sinks"
        echo "  -i, --id      Switch to sink by providing full line from list"
        exit 1
        ;;
esac
