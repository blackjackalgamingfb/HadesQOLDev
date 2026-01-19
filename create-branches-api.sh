#!/bin/bash
# Script to create branches using GitHub API
# This attempts to create the three required branches via API calls

REPO_OWNER="blackjackalgamingfb"
REPO_NAME="HadesOverhaulQOL"

# Get the latest SHA from the dev branch (or use provided BASE_SHA env var)
if [ -z "$BASE_SHA" ]; then
  echo "Fetching latest dev branch SHA..."
  
  # Try using GitHub API if GITHUB_TOKEN is available
  if [ -n "$GITHUB_TOKEN" ]; then
    BASE_SHA=$(curl -s -H "Authorization: Bearer $GITHUB_TOKEN" \
      -H "Accept: application/vnd.github+json" \
      "https://api.github.com/repos/$REPO_OWNER/$REPO_NAME/git/refs/heads/dev" \
      | grep -o '"sha": *"[^"]*"' | head -1 | cut -d'"' -f4)
  fi
  
  # Fall back to git ls-remote if API didn't work
  if [ -z "$BASE_SHA" ]; then
    BASE_SHA=$(git ls-remote https://github.com/$REPO_OWNER/$REPO_NAME.git refs/heads/dev | cut -f1)
  fi
  
  if [ -z "$BASE_SHA" ]; then
    echo "ERROR: Failed to fetch dev branch SHA"
    exit 1
  fi
  echo "Using dev branch SHA: $BASE_SHA"
else
  echo "Using provided BASE_SHA: $BASE_SHA"
fi

# Branch names
BRANCHES=("HadesSocketSystem" "ZagsBags" "ArmorSmith")

echo "Attempting to create branches via GitHub API..."
echo "Base commit (dev): $BASE_SHA"
echo ""

# Check if GITHUB_TOKEN is available
if [ -z "$GITHUB_TOKEN" ]; then
    echo "ERROR: GITHUB_TOKEN environment variable is not set"
    echo "Please set it with: export GITHUB_TOKEN='your_token_here'"
    exit 1
fi

# Function to create a branch
create_branch() {
    local branch_name=$1
    echo "Creating branch: $branch_name"
    
    response=$(curl -s -w "\n%{http_code}" \
        --max-time 30 \
        --connect-timeout 10 \
        -X POST \
        -H "Accept: application/vnd.github+json" \
        -H "Authorization: Bearer $GITHUB_TOKEN" \
        -H "X-GitHub-Api-Version: 2022-11-28" \
        https://api.github.com/repos/$REPO_OWNER/$REPO_NAME/git/refs \
        -d "{\"ref\":\"refs/heads/$branch_name\",\"sha\":\"$BASE_SHA\"}")
    
    http_code=$(echo "$response" | tail -n1)
    body=$(echo "$response" | head -n-1)
    
    # Check for curl errors (empty response or non-numeric http_code)
    if [ -z "$http_code" ] || ! [[ "$http_code" =~ ^[0-9]+$ ]]; then
        echo "  ✗ Network error: Failed to connect to GitHub API"
        return 1
    fi
    
    if [ "$http_code" -eq 201 ]; then
        echo "  ✓ Successfully created $branch_name"
        return 0
    elif [ "$http_code" -eq 422 ]; then
        echo "  ⚠ Branch $branch_name already exists"
        return 0
    else
        echo "  ✗ Failed to create $branch_name (HTTP $http_code)"
        echo "  Response: $body"
        return 1
    fi
}

# Create each branch
success_count=0
for branch in "${BRANCHES[@]}"; do
    if create_branch "$branch"; then
        ((success_count++))
    fi
    echo ""
done

echo "Summary: Successfully created/verified $success_count out of ${#BRANCHES[@]} branches"

if [ $success_count -eq ${#BRANCHES[@]} ]; then
    echo "All branches are ready!"
    exit 0
else
    echo "Some branches could not be created. Please check the errors above."
    exit 1
fi
