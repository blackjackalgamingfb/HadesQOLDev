# Branch Creation Task

## Objective
Create three new branches off the `dev` branch:
1. **HadesSocketSystem** - For implementing the Hades Socket System feature
2. **ZagsBags** - For implementing the Zag's Bags feature
3. **ArmorSmith** - For implementing the Armor Smith feature

## Base Branch
All three branches should be created from: `dev` (commit: 54f573f)

## Methods to Create Branches

### Method 1: Using GitHub Actions Workflow (Recommended)
A GitHub Actions workflow has been created to automate the branch creation:

1. Go to the repository on GitHub: https://github.com/blackjackalgamingfb/HadesOverhaulQOL
2. Click on the "Actions" tab
3. Select "Create Feature Branches" workflow from the left sidebar
4. Click "Run workflow" button
5. Fill in the parameters:
   - **Base branch**: `dev` (already set as default)
   - **Branches to create**: `HadesSocketSystem,ZagsBags,ArmorSmith` (already set as default)
6. Click "Run workflow"

The workflow will automatically create all three branches from the `dev` branch and push them to the repository.

### Method 2: Using the Provided Script
A bash script has been created to automate the branch creation process:

```bash
./create-branches.sh
```

This script will:
- Fetch the latest `dev` branch
- Create each branch locally from `dev`
- Push each branch to the remote repository

### Method 3: Using GitHub CLI
If you have GitHub CLI (`gh`) installed and authenticated:

```bash
# Get the latest dev branch SHA
DEV_SHA=$(gh api repos/blackjackalgamingfb/HadesOverhaulQOL/git/refs/heads/dev --jq '.object.sha')

# Create HadesSocketSystem branch
gh api repos/blackjackalgamingfb/HadesOverhaulQOL/git/refs \
  -f ref='refs/heads/HadesSocketSystem' \
  -f sha="$DEV_SHA"

# Create ZagsBags branch
gh api repos/blackjackalgamingfb/HadesOverhaulQOL/git/refs \
  -f ref='refs/heads/ZagsBags' \
  -f sha="$DEV_SHA"

# Create ArmorSmith branch
gh api repos/blackjackalgamingfb/HadesOverhaulQOL/git/refs \
  -f ref='refs/heads/ArmorSmith' \
  -f sha="$DEV_SHA"
```

**Note:** The SHA is fetched dynamically to ensure you're using the latest dev commit.

### Method 4: Using GitHub Web UI
1. Go to https://github.com/blackjackalgamingfb/HadesOverhaulQOL
2. Click on the branch dropdown (currently showing "main" or "dev")
3. Type the branch name (e.g., "HadesSocketSystem")
4. Select "Create branch: HadesSocketSystem from 'dev'"
5. Repeat for "ZagsBags" and "ArmorSmith"

### Method 5: Manual Git Commands
If you have push access to the repository:

```bash
# Fetch the latest dev branch
git fetch origin dev:dev

# Create and push HadesSocketSystem
git checkout dev
git checkout -b HadesSocketSystem
git push -u origin HadesSocketSystem

# Create and push ZagsBags
git checkout dev
git checkout -b ZagsBags
git push -u origin ZagsBags

# Create and push ArmorSmith
git checkout dev
git checkout -b ArmorSmith
git push -u origin ArmorSmith
```

## Verification
After creating the branches, verify they exist:

```bash
# List all remote branches
git ls-remote --heads origin | grep -E "HadesSocketSystem|ZagsBags|ArmorSmith"
```

Or use GitHub CLI:
```bash
gh api repos/blackjackalgamingfb/HadesOverhaulQOL/branches --jq '.[].name' | grep -E "HadesSocketSystem|ZagsBags|ArmorSmith"
```

## Local Branch Status
The branches have been created locally in this workspace:
- ✓ HadesSocketSystem (local)
- ✓ ZagsBags (local)
- ✓ ArmorSmith (local)

All local branches are based on commit `54f573f` from the `dev` branch.

## Note on Environment Limitations
Due to authentication constraints in the automated environment, the branches could not be pushed to the remote repository automatically. A user with appropriate repository access needs to execute one of the methods above to complete the task.
