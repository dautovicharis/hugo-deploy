#!/bin/bash

#########################################################################
# Hugo Deploy - Main Entry Script
#########################################################################
#
# Description:
#   Main entry point for Hugo Deploy that routes to the appropriate command.
#
# Usage:
#   ./hugo-deploy.sh <version> [options]  Deploy with specified version (e.g., 1.2.3)
#   ./hugo-deploy.sh list                List previous deployments
#   ./hugo-deploy.sh revert <hash|version> [options] Revert to a previous deployment
#   ./hugo-deploy.sh help                Show help message
#
#########################################################################

# Get the directory where this script is located
SCRIPT_DIR="$(dirname "$0")"

# Check if a command was provided
if [ $# -eq 0 ]; then
    echo "Error: Command required."
    echo "Usage: ./hugo-deploy.sh <version> | list | revert <hash|version> | help"
    exit 1
fi

# First argument is the command
COMMAND=$1
shift

# Process the command
case $COMMAND in
    help)
        # Show help
        "$SCRIPT_DIR/_help.sh"
        ;;
    list)
        # List deployments
        "$SCRIPT_DIR/_list.sh"
        ;;
    revert)
        # Revert to a previous deployment
        "$SCRIPT_DIR/_revert.sh" "$@"
        ;;
    *)
        # Assume it's a version number for deployment
        "$SCRIPT_DIR/_deploy.sh" "$COMMAND" "$@"
        ;;
esac
