#!/bin/bash

# Get the current mode from i3
mode=$(i3-msg -t get_binding_state | jq -r '.name')

# Output the mode
echo "$mode"
