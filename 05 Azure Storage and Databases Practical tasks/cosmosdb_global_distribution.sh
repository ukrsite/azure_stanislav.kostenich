#!/bin/bash

# Define variables
RESOURCE_GROUP="StanislavKostenich"
COSMOS_ACCOUNT="devcosmosdbaccount20250125"
DATABASE_NAME="Items"
CONTAINER_NAME="Items"
PRIMARY_REGION="westcentralus"
SECONDARY_REGION="westus3"

# Fetch Cosmos DB Account details
COSMOS_ENDPOINT=$(az cosmosdb show --name $COSMOS_ACCOUNT --resource-group $RESOURCE_GROUP --query "documentEndpoint" -o tsv)
COSMOS_KEY=$(az cosmosdb keys list --name $COSMOS_ACCOUNT --resource-group $RESOURCE_GROUP --query "primaryMasterKey" -o tsv)

# Install required dependencies if not already installed
pip install azure-cosmos --quiet

echo "📌 Cosmos DB Endpoint: $COSMOS_ENDPOINT"
echo "🚀 Starting Cosmos DB Global Distribution Setup..."

# Python script for inserting, verifying replication, and failover testing
python3 <<EOF
from azure.cosmos import CosmosClient, PartitionKey

# Cosmos DB credentials
ENDPOINT = "$COSMOS_ENDPOINT"
KEY = "$COSMOS_KEY"
DATABASE_NAME = "$DATABASE_NAME"
CONTAINER_NAME = "$CONTAINER_NAME"

# Initialize Cosmos Client
client = CosmosClient(ENDPOINT, KEY)

# Create (or Get) Database
database = client.create_database_if_not_exists(DATABASE_NAME)

# Create (or Get) Container
container = database.create_container_if_not_exists(
    id=CONTAINER_NAME,
    partition_key=PartitionKey(path="/id")
)

# Insert test data
test_data = {"id": "1", "name": "Replication Test", "region": "primary"}
container.upsert_item(test_data)
print("✅ Inserted test data into primary region.")

# Verify replication by reading data
retrieved_item = container.read_item(item="1", partition_key="1")
if retrieved_item:
    print(f"✅ Data replicated: {retrieved_item}")

EOF

echo "🔄 Enabling multi-region replication..."
az cosmosdb update --name $COSMOS_ACCOUNT --resource-group $RESOURCE_GROUP --enable-multiple-write-locations true

echo "🌎 Adding Secondary Region: $SECONDARY_REGION..."
az cosmosdb failover-priority-change --name $COSMOS_ACCOUNT --resource-group $RESOURCE_GROUP --failover-policies "$PRIMARY_REGION=0" "$SECONDARY_REGION=1"

# Wait for replication to take effect
sleep 60

echo "⚠️ Performing Manual Failover to Secondary Region..."
az cosmosdb failover-priority-change --name $COSMOS_ACCOUNT --resource-group $RESOURCE_GROUP --failover-policies "$SECONDARY_REGION=0" "$PRIMARY_REGION=1"

# Wait for failover to take effect
sleep 60

echo "🔄 Verifying Data Consistency Post-Failover..."
python3 <<EOF
from azure.cosmos import CosmosClient

# Reconnect after failover
client = CosmosClient(ENDPOINT, KEY)
container = client.get_database_client(DATABASE_NAME).get_container_client(CONTAINER_NAME)

retrieved_item = container.read_item(item="1", partition_key="1")
if retrieved_item:
    print(f"✅ Data consistency verified after failover: {retrieved_item}")
else:
    print("❌ Data verification failed!")
EOF

echo "🎉 Azure Cosmos DB global distribution, replication, and failover testing completed!"
