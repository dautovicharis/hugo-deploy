#!/bin/bash

#########################################################################
# Hugo Deploy - Main Deployment Script
#########################################################################
#
# Description:
#   A streamlined script for deploying Hugo websites from a private repo
#   to a public repo with version tracking.
#
# Usage:
#   ./deploy.sh <version> [options]  Deploy with specified version (e.g., 1.2.3)
#
#########################################################################

# Source common functions
source "$(dirname "$0")/common.sh"

# Deploy the site
deploy_site() {
    VERSION="$1"

    # Step 1: Prepare exclude parameters for Hugo build
    echo "Preparing excluded files..."

    # Create a temporary directory to store excluded files
    TEMP_DIR=$(mktemp -d)

    # Copy excluded files to temporary directory
    cd "$PUBLIC_REPO_PATH"
    for file in $EXCLUDED_FILES; do
        if [ -e "$file" ]; then
            cp -a "$file" "$TEMP_DIR/"
        fi
    done

    # Step 2: Build the site with Hugo directly to the public repository
    echo "Building site with Hugo directly to public repository..."
    cd "$PRIVATE_REPO_PATH"
    hugo --cleanDestinationDir --minify --destination="$PUBLIC_REPO_PATH"

    if [ $? -ne 0 ]; then
        echo "Error: Hugo build failed"
        # Cleanup temp directory
        rm -rf "$TEMP_DIR"
        exit 1
    fi

    # Step 3: Restore excluded files from temporary directory
    echo "Restoring excluded files..."
    cd "$PUBLIC_REPO_PATH"
    for file in $EXCLUDED_FILES; do
        if [ -e "$TEMP_DIR/$file" ]; then
            cp -a "$TEMP_DIR/$file" "$PUBLIC_REPO_PATH/"
        fi
    done

    # Cleanup temporary directory
    rm -rf "$TEMP_DIR"

    if [ $? -ne 0 ]; then
        echo "Error: Failed to restore excluded files"
        exit 1
    fi

    # Step 4: Git operations
    echo "Preparing deployment..."
    cd "$PUBLIC_REPO_PATH"

    # Switch to deployment branch
    switch_to_deployment_branch || exit 1

    # Add all changes
    git add .

    if [ $? -ne 0 ]; then
        echo "Error: Failed to stage changes"
        exit 1
    fi

    # Commit changes
    echo "Committing deployment version: $VERSION"
    git commit -m "Deploy version $VERSION"

    # Check if there were changes to commit
    if [ $? -ne 0 ]; then
        echo "No changes to commit or commit failed"
        exit 1
    fi

    # Push to remote if requested
    if [ "$PUSH_TO_REMOTE" = true ]; then
        push_to_remote || exit 1
    else
        echo "Skipping push to remote repository (use --push option to push)."
        echo "To push manually, run: git push origin $DEPLOYMENT_BRANCH"
    fi

    # Step 5: Return to the private repository directory
    cd "$PRIVATE_REPO_PATH"

    echo "Deployment completed successfully!"
    echo "Deployed version: $VERSION"
}

# Main function
main() {
    # Check if a version was specified
    if [ $# -eq 0 ]; then
        echo "Error: No version specified."
        echo "Usage: ./deploy.sh <version> [options]"
        exit 1
    fi

    # Get the version
    VERSION="$1"
    shift

    # Parse options
    parse_options "$@" || { source "$(dirname "$0")/help.sh"; exit 1; }

    # Load configuration
    load_config || exit 1

    # Check public repository
    check_public_repo || exit 1

    # Deploy site
    deploy_site "$VERSION"
}

# If this script is run directly, execute main function
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi


