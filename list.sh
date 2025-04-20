#!/bin/bash

#########################################################################
# Hugo Deploy - List Deployments Script
#########################################################################

# Source common functions
source "$(dirname "$0")/common.sh"

# List previous deployments
list_deployments() {
    check_public_repo || exit 1
    
    echo "Previous deployments:"
    echo "-------------------"
    cd "$PUBLIC_REPO_PATH"

    # Check if the deployment branch exists
    check_deployment_branch || exit 0
    
    # Switch to the deployment branch
    git checkout $DEPLOYMENT_BRANCH > /dev/null 2>&1

    # Show the last 10 deployments
    git log -10 --pretty=format:"%h %ad | %s" --date=short
}

# Main function
main() {
    # Load configuration
    load_config || exit 1
    
    # List deployments
    list_deployments
}

# If this script is run directly, execute main function
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main
fi
