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
OUTPUT_DIR="./output_files"                  # Directory to store output files
TMP_OUTPUT_FILE="${OUTPUT_DIR}/${OUTPUT_FILE}_temp"  # Temporary raw file
FORMATTED_OUTPUT_FILE="${OUTPUT_DIR}/${OUTPUT_FILE}" # Final (formatted) output file

# Ensure the output directory exists
mkdir -p "$OUTPUT_DIR"

# SSH options for single-password prompt, with control master for session reuse
SSH_TIMEOUT=15
CONTROL_PATH="/tmp/ssh_ctrl_%C"
SSH_ARGS="-o StrictHostKeyChecking=no -o ConnectTimeout=$SSH_TIMEOUT -o ControlMaster=auto -o ControlPath=$CONTROL_PATH -o ControlPersist=5"

# Catch premature script exits and ensure cleanup
cleanup() {
  # echo "Cleaning up temporary files and SSH control socket..." #Uncomment for debugging if needed
  rm -f "$TMP_OUTPUT_FILE"  # Remove the temporary file
  # Terminate SSH control socket if it exists
  if [[ -S $CONTROL_PATH ]]; then
    echo "Terminating SSH control socket..."
    ssh -O exit -S "$CONTROL_PATH" "$REMOTE_USER@$REMOTE_HOST" 2>/dev/null
  else
   # echo "No control socket found to clean up." #Uncomment for debugging if needed
  fi
}

trap cleanup ERR INT TERM EXIT  # Perform cleanup on error, interrupt, or exit

# Add hostname or a header to output file
echo -e "\n### BIG-IP hostname => $REMOTE_HOST ###\n" > "$TMP_OUTPUT_FILE"

# ESTABLISH MASTER SSH CONNECTION
echo "Making SSH connection to $REMOTE_HOST..."
if ! ssh $SSH_ARGS -fN "$REMOTE_USER@$REMOTE_HOST" 2>/dev/null; then
  echo "ERROR: Unable to connect to $REMOTE_HOST. Check the host connectivity or SSH configuration."
  exit 1
fi

# SUCCESSFUL CONNECTION: Announce execution
echo "Executing TMSH commands on BIG-IP ($REMOTE_HOST)..."

# Loop through each command in the commands file and execute them remotely via SSH
while IFS= read -r command; do
  if [[ "$command" != "" ]]; then
    OUTPUT=$(ssh $SSH_ARGS "$REMOTE_USER@$REMOTE_HOST" "tmsh $command" 2>&1)

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

# Notify user of the formatted output file location
echo "Formatted output saved to: $FORMATTED_OUTPUT_FILE"