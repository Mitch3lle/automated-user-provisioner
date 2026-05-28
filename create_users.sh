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

# --- 2. CONFIGURATION & LOGGING SETUP ---

LOG_FILE="/var/log/user_management.log"
SECURE_STORE="/var/secure"
PASSWORD_FILE="$SECURE_STORE/user_passwords.csv"

# Create the secure directory if it doesn't exist
if [ ! -d "$SECURE_STORE" ]; then
    mkdir -p "$SECURE_STORE"
    chmod 700 "$SECURE_STORE"
fi

# Create or touch files and secure their permissions
touch "$LOG_FILE"
chmod 644 "$LOG_FILE"

if [ ! -f "$PASSWORD_FILE" ]; then
    touch "$PASSWORD_FILE"
    echo "username,password" > "$PASSWORD_FILE"
fi
chmod 600 "$PASSWORD_FILE"

# Function to write messages to the log file cleanly
log_message() {
    local TIMESTAMP
    TIMESTAMP=$(date "+%Y-%m-%d %H:%M:%S")
    echo "$TIMESTAMP - $1" >> "$LOG_FILE"
    echo "$1" # Print to terminal as well
}
# --- 3. BATCH PROCESSING LOOP ---

log_message "Starting user provisioning process using input file: $INPUT_FILE"

# Read file line by line, handling potential missing trailing newlines
while IFS= read -r line || [ -n "$line" ]; do
    
    # Trim leading/trailing whitespaces and skip empty lines or comments
    line=$(echo "$line" | xargs)
    if [ -z "$line" ] || [[ "$line" == \#* ]]; then
        continue
    fi

    # Parse the line using ';' as the delimiter
    IFS=';' read -r username main_group extra_groups <<< "$line"

    # Sanitize inputs by removing internal spaces
    username=$(echo "$username" | xargs)
    main_group=$(echo "$main_group" | xargs)
    extra_groups=$(echo "$extra_groups" | xargs)

    # Validate that at least username and main_group exist
    if [ -z "$username" ] || [ -z "$main_group" ]; then
        log_message "Warning: Skipping invalid line standard format: '$line'"
        continue
    fi
# --- 4. OS GROUP & ACCOUNT CREATION ---

    # Ensure the primary department group exists
    if ! getent group "$main_group" > /dev/null 2>&1; then
        if groupadd "$main_group"; then
            log_message "Group '$main_group' created successfully."
        else
            log_message "Error: Failed to create group '$main_group'. Skipping user '$username'."
            continue
        fi
    fi

    # Check if the user account already exists on the system
    if id "$username" > /dev/null 2>&1; then
        log_message "Warning: User '$username' already exists. Skipping account creation."
        continue
    fi

    # Create the user with a home directory and primary group assignment
    if useradd -m -g "$main_group" -s /bin/bash "$username"; then
        log_message "User '$username' created successfully with primary group '$main_group'."
    else
        log_message "Error: Failed to create user account for '$username'."
        continue
    fi
# --- 5. SUPPLEMENTARY GROUPS & SECURITY ---

    # Process additional secondary groups if specified
    if [ -n "$extra_groups" ]; then
        # Swap commas to spaces for iteration
        IFS=',' read -ra ADDR <<< "$extra_groups"
        for ext_g in "${ADDR[@]}"; do
            ext_g=$(echo "$ext_g" | xargs)
            if [ -n "$ext_g" ]; then
                # Ensure secondary group exists before adding user
                if ! getent group "$ext_g" > /dev/null 2>&1; then
                    groupadd "$ext_g"
                    log_message "Secondary group '$ext_g' created dynamically."
                fi
                usermod -aG "$ext_g" "$username"
                log_message "User '$username' added to secondary group '$ext_g'."
            fi
        done
    fi

    # Generate a cryptographically secure 12-character alphanumeric password
    password=$(openssl rand -base64 12 | tr -dc 'a-zA-Z0-9' | head -c 12)

    # Set the user's password in the system database
    echo "$username:$password" | chpasswd

    # Force a password change instantly upon the user's initial login attempt
    chage -d 0 "$username"
    log_message "Password policy applied: Force password change on first login set for '$username'."

    # Safely archive credentials into our root-only access matrix
    echo "$username,$password" >> "$PASSWORD_FILE"

done < "$INPUT_FILE"

log_message "User provisioning batch task completed successfully."
exit 0
