#!/usr/bin/env bash

set -euo pipefail

# === CONFIGURATION ===
STATE_FILE="terraform.tfstate"
BASE_URL="https://app.terraform.io/api/v2"

# === FUNCTIONS ===

# Get workspace ID
get_workspace_id() {
  curl -s \
    --header "Authorization: Bearer $TFC_TOKEN" \
    --header "Content-Type: application/vnd.api+json" \
    "${BASE_URL}/organizations/${ORG_NAME}/workspaces/${WORKSPACE_NAME}" \
  | jq -r '.data.id'
}

create_workspace() {
  curl -s \
    --header "Authorization: Bearer $TFC_TOKEN" \
    --header "Content-Type: application/vnd.api+json" \
    --request POST \
    --data "{
      \"data\": {
        \"type\": \"workspaces\",
        \"attributes\": {
          \"name\": \"${WORKSPACE_NAME}\"
        }
      }
    }" \
    "${BASE_URL}/organizations/${ORG_NAME}/workspaces" \
  | jq -r '.data.id'
}

lock_workspace() {
  local ws_id=$1
  curl -s \
    --header "Authorization: Bearer $TFC_TOKEN" \
    --header "Content-Type: application/vnd.api+json" \
    --request POST \
    "${BASE_URL}/workspaces/${ws_id}/actions/lock"
}


# Create state version
push_tf_state() {
  local ws_id=$1
  local state_b64
  local md5
  local serial
  local lineage

  state_b64=$(base64 -w0 "$STATE_FILE")
  md5=$(md5sum "$STATE_FILE" | awk '{print $1}')
  serial=$(jq .serial < "$STATE_FILE")
  lineage=$(jq -r .lineage < "$STATE_FILE")

  lock_workspace "$ws_id"
  echo "✅ Workspace locked."

  curl -s \
    --header "Authorization: Bearer $TFC_TOKEN" \
    --header "Content-Type: application/vnd.api+json" \
    --request POST \
    --data "{
      \"data\": {
        \"type\": \"state-versions\",
        \"attributes\": {
          \"serial\": $serial,
          \"lineage\": \"$lineage\",
          \"md5\": \"$md5\",
          \"state\": \"$state_b64\"
        }
      }
    }" \
    "${BASE_URL}/workspaces/${ws_id}/state-versions"
}

# Get latest state download URL
get_latest_state_url() {
  local ws_id=$1
  curl -s \
    --header "Authorization: Bearer $TFC_TOKEN" \
    "${BASE_URL}/workspaces/${ws_id}/current-state-version" \
  | jq -r '.data.attributes."hosted-state-download-url" // empty'
}

# Download latest state file
pull_tf_state_latest() {
  local ws_id=$1
  local url
  url=$(get_latest_state_url "$ws_id")
  if [ -n "$url" ]; then
    curl -sL  \
      --header "Authorization: Bearer $TFC_TOKEN" \
      -o terraform.tfstate  \
      "$url"
    echo "✅ Latest state downloaded to latest.tfstate"
  else
    echo "⚠️ No state found for this workspace yet."
  fi
}


# === MAIN ===

ACTION=$1

if [ -z "$ACTION" ]; then
  echo "Usage: $0 [pull|push]"
  exit 1
fi

workspace_id=$(get_workspace_id)

if [ -z "$workspace_id" ] || [ "$workspace_id" = "null" ]; then
  echo "Workspace not found. Creating..."
  workspace_id=$(create_workspace)
  if [ -z "$workspace_id" ]; then
    echo "❌ Failed to create workspace"
    exit 1
  fi
  echo "✅ Workspace created with ID: $workspace_id"
else
  echo "✅ Workspace exists with ID: $workspace_id"
fi

case "$ACTION" in
  pull)
    echo "Fetching latest state..."
    pull_tf_state_latest "$workspace_id"
    echo "✅ State file fetched!"
    ;;
  push)
    echo "Uploading new state file..."
    push_tf_state "$workspace_id"
    echo "✅ State version created and uploaded!"
    ;;
  *)
    echo "Invalid action. Use 'pull' or 'push'."
    exit 1
    ;;
esac