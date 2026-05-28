#!/bin/bash

# --- 1. ENVIRONMENT & PERMISSION CHECKS ---

# Ensure the script is run as root (sudo)
if [ "$EUID" -ne 0 ]; then
    echo "Error: This script must be run as root or with sudo privileges." >&2
    exit 1
fi

# Ensure an input file argument was provided
if [ -z "$1" ]; then
    echo "Usage: $0 <input_file.txt>" >&2
    exit 1
fi

INPUT_FILE="$1"

# Check if the provided input file actually exists
if [ ! -f "$INPUT_FILE" ]; then
    echo "Error: Input file '$INPUT_FILE' not found." >&2
    exit 1
fi
