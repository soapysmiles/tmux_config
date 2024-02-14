#!/bin/bash
# Sessions are the overall 'categories' to make
# Windows are accessed in the same order and created nested under the associated session
## Window names in tmux will be the name given, minus the _command or _sh suffix
## Windows utilise the suffixes of _command or _sh, depending on their usecase
### _command will run a command directly in the newly created window (example might be changing directory)
### _sh will run a script (example might be builds)

session_to_start_with="misc"
path_to_window_commands="${HOME}/scripts/tmux/commands"
path_to_window_scripts="${HOME}/scripts/tmux/scripts"

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
    # Create the session if it doesn't already exist
    if ! tmux has-session -t "$session_name" 2>/dev/null; then
        echo "Creating session $session_name"
        tmux new-session -s "$session_name" -d -n ''
    fi

    tmux switch-client -t "$session_name"

    # Convert the session windows to array
    session_windows=(`echo "${windows[$index]}"`)

    for window_name in "${session_windows[@]}"; do
        # Extract base window name without suffix
        base_window_name="${window_name%_*}"

        # If the window already exists, we don't do anything
        if tmux has-session -t "$session_name:$base_window_name" 2>/dev/null; then
            echo "Window already exists"
            continue
        fi

        echo "Creating window $window_name"
        tmux new-window -a -t "$session_name" -n "$base_window_name"

        # Bit rough here, better implementation if I had more time - but will suffice :)

        # Check if bash script exists
        if [[ "$window_name" =~ _sh$ ]]; then
            tmux send-keys -t "$session_name:$base_window_name" "sh $path_to_window_scripts/${base_window_name}.sh &" C-m
        # Check if command script exists
        elif [[ "$window_name" =~ _command$ ]]; then
            tmux send-keys -t "$session_name:$base_window_name" "$(cat "$path_to_window_commands/${base_window_name}.sh")" C-m
        fi
    done

    ((index++))
done

# Load up tmux server and select the session we want to start with
tmux attach -t "$session_to_start_with"

echo "Finished setting up sessions and windows with commands."