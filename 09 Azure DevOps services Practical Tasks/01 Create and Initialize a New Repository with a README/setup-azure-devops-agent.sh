#!/bin/bash

# Variables
ORGANIZATION_URL="https://dev.azure.com/StanislavKostenich0849"  
PAT_TOKEN="..."                        
AGENT_POOL="devLinux"                             
AGENT_NAME="myAgent"                             
AGENT_DIR="$HOME/myagent"                        
LOG_FILE="$AGENT_DIR/setup.log"                  

# Ensure the agent directory exists
mkdir -p "$AGENT_DIR"
cd "$AGENT_DIR" || exit

# Logging function
log() {
  echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a "$LOG_FILE"
}

# Step 1: Download the Azure DevOps agent
log "Downloading Azure DevOps agent..."
AGENT_VERSION="4.251.0"
AGENT_URL="https://vstsagentpackage.azureedge.net/agent/$AGENT_VERSION/vsts-agent-linux-x64-$AGENT_VERSION.tar.gz"
wget -q "$AGENT_URL" -O agent.tar.gz || { log "Failed to download agent."; exit 1; }

# Step 2: Extract the agent
log "Extracting agent..."
tar zxvf agent.tar.gz || { log "Failed to extract agent."; exit 1; }

# Step 3: Configure the agent
log "Configuring agent..."
./config.sh --unattended \
  --url "$ORGANIZATION_URL" \
  --auth pat \
  --token "$PAT_TOKEN" \
  --pool "$AGENT_POOL" \
  --agent "$AGENT_NAME" \
  --acceptTeeEula || { log "Failed to configure agent."; exit 1; }

# Step 4: Install the agent as a service
log "Installing agent as a service..."
sudo ./svc.sh install || { log "Failed to install agent service."; exit 1; }

# Step 5: Start the agent service
log "Starting agent service..."
sudo ./svc.sh start || { log "Failed to start agent service."; exit 1; }

# Step 6: Verify the agent status
log "Checking agent status..."
AGENT_STATUS=$(sudo ./svc.sh status)
echo "$AGENT_STATUS" | tee -a "$LOG_FILE"

# Step 7: Output Azure resources in table format
log "Listing Azure resources..."
az vm list --output table | tee -a "$LOG_FILE"

# Step 8: Log completion
log "Azure DevOps agent setup completed successfully."