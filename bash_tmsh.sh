#!/bin/bash

# Check for required arguments
if [[ $# -lt 4 ]]; then
  echo "Usage: $0 <commands_file> <remote_user> <remote_host> <output_file>"
  echo "Example: $0 commands.txt admin 10.0.0.1 output_file_tmsh.txt"
  exit 1
fi

# Collect arguments
COMMAND_FILE="$1"          # First argument: Path to file containing TMSH commands
REMOTE_USER="$2"           # Second argument: Remote username for SSH
REMOTE_HOST="$3"           # Third argument: Remote host IP or hostname for SSH
OUTPUT_FILE="$4"           # Fourth argument: Name of the output file

# Output file config
OUTPUT_DIR="./output_files"         # Directory to store output files
TMP_OUTPUT_FILE="${OUTPUT_DIR}/${OUTPUT_FILE}"           # Temporary raw file
FORMATTED_OUTPUT_FILE="${TMP_OUTPUT_FILE}_formatted"     # Parsed/formatted output file

# Ensure the output directory exists
mkdir -p "$OUTPUT_DIR"

# Check if the commands file exists
if [[ ! -f "$COMMAND_FILE" ]]; then
  echo "ERROR: Commands file '$COMMAND_FILE' does not exist."
  exit 1
fi

# Add hostname or a header to output file
echo -e "\n### BIG-IP hostname => $REMOTE_HOST ###\n" > "$TMP_OUTPUT_FILE"

# Check if SSH Key is being used
SSH_KEY=${SSH_KEY:-"$HOME/.ssh/id_rsa"}  # Default SSH key location

# Loop through each command in the commands file and execute them remotely via SSH
echo "Executing TMSH commands on BIG-IP ($REMOTE_HOST)..."
while IFS= read -r command; do
  if [[ "$command" != "" ]]; then
    OUTPUT=$(ssh -i "$SSH_KEY" -o StrictHostKeyChecking=no "$REMOTE_USER@$REMOTE_HOST" "tmsh $command" 2>&1)
    echo "$OUTPUT" >> "$TMP_OUTPUT_FILE"
  fi
done < "$COMMAND_FILE"

# Format the output file (Example: Replace commas with newlines for better readability)
echo "Formatting output file..."
sed 's/,/\n/g' "$TMP_OUTPUT_FILE" > "$FORMATTED_OUTPUT_FILE"

# Clean Up: Remove temporary unformatted file
echo "Cleaning up temporary files..."
rm -f "$TMP_OUTPUT_FILE"

echo "Formatted output saved to: $FORMATTED_OUTPUT_FILE"
