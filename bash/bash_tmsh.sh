#!/bin/bash

# Check for required arguments
if [[ $# -lt 1 ]]; then
  echo "Usage: $0 <commands_file>"
  echo "Example: $0 commands.txt"
  exit 1
fi

# Collect the commands file from the arguments
COMMAND_FILE="$1"  # First argument: Path to file containing TMSH commands

# Check if the commands file exists
if [[ ! -f "$COMMAND_FILE" ]]; then
  echo "ERROR: Commands file '$COMMAND_FILE' does not exist."
  exit 1
fi

# Prompt the user for remote username
read -rp "Enter the remote username: " REMOTE_USER

# Prompt the user for remote host IP or hostname
read -rp "Enter the remote host (IP/hostname): " REMOTE_HOST

# Prompt the user for output file name and location
read -rp "Enter the output file name: " OUTPUT_FILE

# Output file config
OUTPUT_DIR="./output_files"                # Directory to store output files
TMP_OUTPUT_FILE="${OUTPUT_DIR}/${OUTPUT_FILE}_temp"  # Temporary raw file
FORMATTED_OUTPUT_FILE="${OUTPUT_DIR}/${OUTPUT_FILE}" # Final (formatted) output file

# Ensure the output directory exists
mkdir -p "$OUTPUT_DIR"

# Catch premature script exits and ensure cleanup
trap 'echo "An error occurred. Cleaning up temporary files..."; rm -f "$TMP_OUTPUT_FILE"; exit 1' ERR INT TERM

# Add hostname or a header to output file
echo -e "\n### BIG-IP hostname => $REMOTE_HOST ###\n" > "$TMP_OUTPUT_FILE"

# Check if SSH Key is being used
SSH_KEY=${SSH_KEY:-"$HOME/.ssh/id_rsa"}  # Default SSH key location

# SSH timeout value (in seconds)
SSH_TIMEOUT=15

# Loop through each command in the commands file and execute them remotely via SSH
echo "Executing TMSH commands on BIG-IP ($REMOTE_HOST)..."
while IFS= read -r command; do
  if [[ "$command" != "" ]]; then
    OUTPUT=$(ssh -i "$SSH_KEY" -o StrictHostKeyChecking=no -o ConnectTimeout="$SSH_TIMEOUT" "$REMOTE_USER@$REMOTE_HOST" "tmsh $command" 2>&1)
    
    # Check if the SSH command failed
    if [[ $? -ne 0 ]]; then
      echo "ERROR: Unable to execute command '$command' on $REMOTE_HOST. Check the host connectivity or SSH configuration."
      echo "[ERROR] $OUTPUT" >> "$TMP_OUTPUT_FILE"  # Log error into the temporary file
      continue  # Skip remaining commands for this iteration
    fi

    # Append successful output to the temporary file
    echo "$OUTPUT" >> "$TMP_OUTPUT_FILE"
  fi
done < "$COMMAND_FILE"

# Format the output file (Example: Replace commas with newlines for better readability)
echo "Formatting output file..."
sed 's/,/\n/g' "$TMP_OUTPUT_FILE" > "$FORMATTED_OUTPUT_FILE"

# Clean Up: Remove temporary unformatted file
echo "Cleaning up temporary files..."
rm -f "$TMP_OUTPUT_FILE"

# Notify user of the formatted output file location
echo "Formatted output saved to: $FORMATTED_OUTPUT_FILE"