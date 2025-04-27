#!/bin/bash

#########################################################################
# Hugo Deploy - Help Script
#########################################################################

# Display help information
show_help() {
    echo "Hugo Deploy - Simple Hugo Deployment Script"
    echo ""
    echo "Usage:"
    echo "  ./hugo-deploy.sh <version> [options]  Deploy with specified version (e.g., 1.2.3)"
    echo "  ./hugo-deploy.sh list                List previous deployments"
    echo "  ./hugo-deploy.sh revert <hash|version> [options] Revert to a previous deployment"
    echo "  ./hugo-deploy.sh help                Show this help message"
    echo ""
    echo "Options:"
    echo "  --push                        Push to remote repository"
    echo ""
    echo "Examples:"
    echo "  ./hugo-deploy.sh 1.2.3             Deploy version 1.2.3"
    echo "  ./hugo-deploy.sh 1.2.3 --push      Deploy and push to remote"
    echo "  ./hugo-deploy.sh list              List previous deployments"
    echo "  ./hugo-deploy.sh revert 1.2.3      Revert to version before 1.2.3"
    echo "  ./hugo-deploy.sh revert abc123f    Revert to commit before abc123f"
    echo "  ./hugo-deploy.sh revert 1.2.3 --push  Revert and force push to remote"
    echo ""
}

# If this script is run directly, show help
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    show_help
fi
