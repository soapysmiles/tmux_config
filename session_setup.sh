#!/bin/bash
# Create new sessions in the /sessions directory
# Within each session you can define commands and scripts to run

## /sessions/<session_name>/commands
### Use this to run command in the window's terminal session directly
### Example might be to change a directory

## /sessions/<session_name>/scripts
### Use this to run a script in the window
### Example might be to run builds

session_to_start_with="cloud:cloud" # Sets which session:window is set to automatically start with

create_tmux_window() {
    session_name=$1
    window_name=$2

    # If the window already exists, we don't do anything
    if tmux has-session -t "$session_name:$window_name" 2>/dev/null; then
        echo "Window already exists"
        return
    fi

    echo "Creating window $window_name"
    tmux new-window -a -t "$session_name" -n "$window_name"
}

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
sessions_base_dir="$SCRIPT_DIR/sessions"

for session_dir in "$sessions_base_dir"/*; do
    session_name=$(basename "$session_dir")
    # Create the session if it doesn't already exist
    if ! tmux has-session -t "$session_name" 2>/dev/null; then
        echo "Creating session $session_name"
        tmux new-session -s "$session_name" -d -n ''
    fi

    tmux switch-client -t "$session_name"

    for window_file in "$session_dir"/commands/*; do
        window_name=$(basename "$window_file")
        base_window_name="${window_name%.*}"
        create_tmux_window "$session_name" "$base_window_name"

        tmux send-keys -t "$session_name:$base_window_name" "$(cat "$window_file")" C-m
    done

    for window_file in "$session_dir"/scripts/*; do
        window_name=$(basename "$window_file")
        base_window_name="${window_name%.*}"
        create_tmux_window "$session_name" "$base_window_name"

        tmux send-keys -t "$session_name:$base_window_name" "sh $window_file &" C-m
    done
done

# Load up tmux server and select the session we want to start with
tmux attach -t "$session_to_start_with"

echo "Finished setting up sessions and windows with commands."