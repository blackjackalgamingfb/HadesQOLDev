#!/bin/bash
# Script to create branches using GitHub API
# This attempts to create the three required branches via API calls

REPO_OWNER="blackjackalgamingfb"
REPO_NAME="HadesOverhaulQOL"
BASE_SHA="54f573fb02975b6ec0bd345713e0f949abc4d93e"  # dev branch commit

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
    
    response=$(curl -s -w "\n%{http_code}" -X POST \
        -H "Accept: application/vnd.github+json" \
        -H "Authorization: Bearer $GITHUB_TOKEN" \
        -H "X-GitHub-Api-Version: 2022-11-28" \
        https://api.github.com/repos/$REPO_OWNER/$REPO_NAME/git/refs \
        -d "{\"ref\":\"refs/heads/$branch_name\",\"sha\":\"$BASE_SHA\"}")
    
    http_code=$(echo "$response" | tail -n1)
    body=$(echo "$response" | head -n-1)
    
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
