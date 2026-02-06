#!/bin/bash

input=$(cat)

remaining=$(echo "$input" | jq -r '.context_window.remaining_percentage // empty')
agent_name=$(echo "$input" | jq -r '.agent.name // empty')
model=$(echo "$input" | jq -r '.model.display_name // empty')
cost=$(echo "$input" | jq -r '.cost.total_cost_usd // empty')
input_tokens=$(echo "$input" | jq -r '.context_window.total_input_tokens // empty')
output_tokens=$(echo "$input" | jq -r '.context_window.total_output_tokens // empty')
lines_added=$(echo "$input" | jq -r '.cost.total_lines_added // empty')
lines_removed=$(echo "$input" | jq -r '.cost.total_lines_removed // empty')
duration_ms=$(echo "$input" | jq -r '.cost.total_duration_ms // empty')

SEP="·"

# Agent name
agent_indicator=""
[ -n "$agent_name" ] && agent_indicator="[${agent_name}]"

# Context remaining
context_info=""
if [ -n "$remaining" ]; then
    remaining_int=$(printf "%.0f" "$remaining")
    context_info="${remaining_int}%"
fi

# Model name
model_info=""
[ -n "$model" ] && model_info="$model"

# Cost
cost_info=""
if [ -n "$cost" ] && [ "$cost" != "0" ]; then
    cost_info=$(printf "\$%.1f" "$cost")
fi

# Tokens
token_info=""
if [ -n "$input_tokens" ]; then
    in_k=$(awk "BEGIN {printf \"%.1f\", $input_tokens / 1000}")
    out_k=$(awk "BEGIN {printf \"%.1f\", ${output_tokens:-0} / 1000}")
    token_info="${in_k}k/${out_k}k"
fi

# Lines changed
lines_info=""
if [ -n "$lines_added" ] || [ -n "$lines_removed" ]; then
    lines_info="+${lines_added:-0}/-${lines_removed:-0}"
fi

# Session duration
duration_info=""
if [ -n "$duration_ms" ]; then
    total_secs=$((duration_ms / 1000))
    mins=$((total_secs / 60))
    secs=$((total_secs % 60))
    if [ "$mins" -gt 0 ]; then
        duration_info="${mins}m${secs}s"
    else
        duration_info="${secs}s"
    fi
fi

parts=()
[ -n "$agent_indicator" ] && parts+=("$agent_indicator")
[ -n "$model_info" ] && parts+=("$model_info")
[ -n "$token_info" ] && parts+=("$token_info")
[ -n "$context_info" ] && parts+=("$context_info")
[ -n "$lines_info" ] && parts+=("$lines_info")
[ -n "$cost_info" ] && parts+=("$cost_info")
[ -n "$duration_info" ] && parts+=("$duration_info")

result=""
for i in "${!parts[@]}"; do
    [ "$i" -gt 0 ] && result+=" ${SEP} "
    result+="${parts[$i]}"
done

echo -n "$result"
