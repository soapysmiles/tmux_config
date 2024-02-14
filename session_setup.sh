#!/bin/bash


declare -a sessions=(
    "misc"
    "cloud"
    "learn"
    "workato"
    "usagedata"
    "local_jenkins"
)

declare -a windows=(
    ""
    "cloud_command cloud_builds_sh"
    "learn_command learn_builds_sh"
    "workato_connector_command"
    "usagedata_athena_command usagedata_collection_command"
    "local_jenkins_command"
)

index=0
for session_name in "${sessions[@]}"; do
    if ! tmux has-session -t "$session_name" 2>/dev/null; then
        echo "Creating session $session_name"
        tmux new-session -s "$session_name" -d -n ''
    fi

    tmux switch-client -t "$session_name"  # Attach to existing session if needed

    session_windows=(`echo "${windows[$index]}"`)

    for window_name in "${session_windows[@]}"; do
        base_window_name="${window_name%_*}"

        if tmux has-session -t "$session_name:$base_window_name" 2>/dev/null; then
            echo "Window already exists"
            continue
        fi

        echo "Creating window $window_name"
        # Extract base window name without suffix

        tmux new-window -a -t "$session_name" -n "$base_window_name"

        command_path_sh="${HOME}/scripts/tmux/sessions/${base_window_name}.sh"
        command_path="${HOME}/scripts/tmux/sessions/${base_window_name}.sh"

        # Check if .sh script exists
        if [[ "$window_name" =~ _sh$ ]]; then
            tmux send-keys -t "$session_name:$base_window_name" "sh $command_path_sh &" C-m
#        # Check if non-.sh script exists
        elif [[ "$window_name" =~ _command$ ]]; then
            tmux send-keys -t "$session_name:$base_window_name" "$(cat "$command_path")" C-m
        else
            echo "Warning: Command file not found: $command_path_sh or $command_path"
        fi
    done

    ((index++))
done
tmux attach -t "misc"

echo "Finished setting up sessions and windows with commands."