#!/bin/bash
# Script to create three branches off the dev branch
# Branches: HadesSocketSystem, ZagsBags, ArmorSmith

set -e

echo "Creating branches off dev..."

# Fetch the latest dev branch
git fetch origin dev
git checkout dev
git reset --hard origin/dev

# Create and push HadesSocketSystem branch
echo "Creating HadesSocketSystem branch..."
git checkout dev
git checkout -b HadesSocketSystem
git push -u origin HadesSocketSystem
echo "✓ HadesSocketSystem branch created and pushed"

# Create and push ZagsBags branch
echo "Creating ZagsBags branch..."
git checkout dev
git checkout -b ZagsBags
git push -u origin ZagsBags
echo "✓ ZagsBags branch created and pushed"

# Create and push ArmorSmith branch
echo "Creating ArmorSmith branch..."
git checkout dev
git checkout -b ArmorSmith
git push -u origin ArmorSmith
echo "✓ ArmorSmith branch created and pushed"

echo ""
echo "All branches created successfully!"
echo "Branches created:"
echo "  - HadesSocketSystem (from dev)"
echo "  - ZagsBags (from dev)"
echo "  - ArmorSmith (from dev)"
