#!/bin/bash

# Check for required arguments
if [[ $# -lt 1 ]]; then
  echo "Usage: $0 <commands_file>"
  echo "Example: $0 commands.txt"
  exit 1
fi

# Variables
COMMAND_FILE="$1"
if [[ ! -f "$COMMAND_FILE" ]]; then
  echo "ERROR: Commands file '$COMMAND_FILE' does not exist."
  exit 1
fi

# Prompt for remote username
echo
read -rp "Enter your remote username: " REMOTE_USER

# Prompt for remote host
read -rp "Enter the remote host IP (or hostname): " REMOTE_HOST

# Prompt for output filename
read -rp "Enter the output filename: " OUTPUT_FILE

# File variables
OUTPUT_DIR="./output_files"
TMP_OUTPUT_FILE="${OUTPUT_DIR}/${OUTPUT_FILE}_temp"
FORMATTED_OUTPUT_FILE="${OUTPUT_DIR}/${OUTPUT_FILE}"
mkdir -p "$OUTPUT_DIR"

# ----------------------------------
# Check if output file already exists
# ----------------------------------
while [[ -f "$FORMATTED_OUTPUT_FILE" ]]; do
  echo
  echo "WARNING: The file '$FORMATTED_OUTPUT_FILE' already exists."
  read -rp "Do you want to overwrite it? (yes/no): " USER_RESPONSE
  
  # Default to "no" if the user does not explicitly enter "yes" or "y" (case-insensitive)
  if [[ "${USER_RESPONSE,,}" == "yes" || "${USER_RESPONSE,,}" == "y" ]]; then
    echo
    echo "Proceeding to overwrite '$FORMATTED_OUTPUT_FILE'..."
    break
  else
    echo
    read -rp "Enter a new filename: " OUTPUT_FILE
    TMP_OUTPUT_FILE="${OUTPUT_DIR}/${OUTPUT_FILE}_temp"      # Update TMP file path
    FORMATTED_OUTPUT_FILE="${OUTPUT_DIR}/${OUTPUT_FILE}"    # Update final output file path
  fi
done

# SSH settings
SSH_TIMEOUT=15
CONTROL_PATH="/tmp/ssh_%C"
SSH_ARGS="-o StrictHostKeyChecking=no -o ConnectTimeout=$SSH_TIMEOUT -o ControlMaster=auto -o ControlPath=$CONTROL_PATH -o ControlPersist=5"

cleanup() {
  rm -f "$TMP_OUTPUT_FILE"
  [ -S "$CONTROL_PATH" ] && ssh -O exit -S "$CONTROL_PATH" "$REMOTE_USER@$REMOTE_HOST" 2>/dev/null
}
trap cleanup ERR INT TERM EXIT

# ----------------------------------
# Ensure TMP_OUTPUT_FILE exists
# ----------------------------------
> "$TMP_OUTPUT_FILE" # Touch or empty the TMP file

# ----------------------------------
# Establish SSH connection
# ----------------------------------
echo
echo "Establishing SSH connection to $REMOTE_HOST..."
echo
if ! ssh $SSH_ARGS -fN "$REMOTE_USER@$REMOTE_HOST" 2>/dev/null; then
  echo "ERROR: Unable to establish SSH connection to $REMOTE_HOST."
  exit 1
fi

# ----------------------------------
# Announce Execution of Commands
# ----------------------------------
echo
echo "Executing TMSH commands on BIG-IP ($REMOTE_HOST)..."
echo

# ----------------------------------
# Read commands from the file
# ----------------------------------
mapfile -t commands < "$COMMAND_FILE"

# ----------------------------------
# Process each command
# ----------------------------------
execution_counter=0  # Counter for valid commands

for command_idx in "${!commands[@]}"; do
  command="${commands[$command_idx]}"

  # Skip blank lines and lines starting with '#' (after removing leading whitespace)
  if [[ -z "${command// }" || "${command// }" == "#"* ]]; then
    continue
  fi

  # Increment the execution counter for valid commands
  ((execution_counter++))

  echo "Executing command [$execution_counter]: $command"

  # Safely capture the current TMP_OUTPUT_FILE state
  if [[ -f "$TMP_OUTPUT_FILE" ]]; then
    PREVIOUS_CONTENTS=$(cat "$TMP_OUTPUT_FILE")
  else
    PREVIOUS_CONTENTS=""
  fi

  # Execute command and separate stdout and stderr
  STDOUT_OUTPUT=$(ssh $SSH_ARGS "$REMOTE_USER@$REMOTE_HOST" "tmsh $command" 2>/tmp/stderr_output.tmp)
  STDERR_OUTPUT=$(cat /tmp/stderr_output.tmp)

  # Combine outputs
  COMBINED_OUTPUT="${STDOUT_OUTPUT}${STDERR_OUTPUT}"

  # Rebuild TMP_OUTPUT_FILE with previous contents and new outputs
  {
    echo "$PREVIOUS_CONTENTS"  # Ensure previous content remains intact
    if [[ -n "${STDOUT_OUTPUT// }" || -n "${STDERR_OUTPUT// }" ]]; then
      # Append raw output
      echo "$COMBINED_OUTPUT"
    else
      # Append a success message for silent commands
      echo "Command completed silently: $command"
    fi
  } > "$TMP_OUTPUT_FILE"

  # Clean temporary files
  rm -f /tmp/stderr_output.tmp
done

# ----------------------------------
# Add header, blank lines, and format the output file
# ----------------------------------
sed 's/,/\n/g' "$TMP_OUTPUT_FILE" > "$FORMATTED_OUTPUT_FILE"
sed -i '1i\\n### BIG-IP hostname => '"$REMOTE_HOST"'\n' "$FORMATTED_OUTPUT_FILE"
sed -i '3d' "$FORMATTED_OUTPUT_FILE"  # Remove extra blank line below header

# ----------------------------------
# Announce Completion
# ----------------------------------
echo
echo "Formatted output saved to: $FORMATTED_OUTPUT_FILE"
echo