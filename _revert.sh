#!/bin/bash

#########################################################################
# Hugo Deploy - Revert Deployment Script
#########################################################################

# Source common functions
source "$(dirname "$0")/_common.sh"

# Revert to a previous deployment
revert_deployment() {
    if [ -z "$1" ]; then
        echo "Error: No commit hash or version specified."
        echo "Usage: ./hugo-deploy.sh revert <hash|version> [options]"
        exit 1
    fi

    REVERT_TARGET="$1"

    check_public_repo || exit 1
    cd "$PUBLIC_REPO_PATH"

    # Check if the deployment branch exists
    check_deployment_branch || exit 1

    # Switch to the deployment branch
    git checkout $DEPLOYMENT_BRANCH > /dev/null 2>&1

    # Check if it's a commit hash (exact match)
    if git rev-parse --verify --quiet "$REVERT_TARGET^{commit}" > /dev/null 2>&1; then
        echo "Reverting commit: $REVERT_TARGET"
        # Get the parent commit (the one before the specified commit)
        PARENT_HASH=$(git rev-parse "$REVERT_TARGET^1" 2>/dev/null)

        if [ $? -ne 0 ]; then
            echo "Error: Could not find parent commit. Is this the first commit?"
            exit 1
        fi

        COMMIT_HASH="$PARENT_HASH"
        echo "Will reset to previous commit: $COMMIT_HASH"
    else
        # Try to find by version in commit message
        echo "Looking for deployment with version: $REVERT_TARGET"
        TARGET_COMMIT=$(git log --pretty=format:"%h" --grep="Deploy version $REVERT_TARGET" -n 1)

        if [ -z "$TARGET_COMMIT" ]; then
            echo "Error: Could not find a deployment with version $REVERT_TARGET"
            exit 1
        fi

        echo "Found version $REVERT_TARGET at commit: $TARGET_COMMIT"

        # Get the parent commit (the one before the specified version)
        PARENT_HASH=$(git rev-parse "$TARGET_COMMIT^1" 2>/dev/null)

        if [ $? -ne 0 ]; then
            echo "Error: Could not find parent commit. Is this the first deployment?"
            exit 1
        fi

        COMMIT_HASH="$PARENT_HASH"
        echo "Will reset to previous version: $(git log -1 --pretty=format:"%s" $COMMIT_HASH | sed 's/Deploy version //')"
    fi

    # Reset to the parent commit
    echo "Resetting to commit $COMMIT_HASH..."
    git reset --hard "$COMMIT_HASH"

    if [ $? -ne 0 ]; then
        echo "Error: Failed to reset to the specified deployment"
        exit 1
    fi

    echo "Successfully reverted to previous deployment."

    # Push to remote if requested
    if [ "$PUSH_TO_REMOTE" = true ]; then
        push_to_remote "force" || exit 1
    else
        echo "Skipping push to remote repository (use --push option to push)."
        echo "To push manually, run: git push --force origin $DEPLOYMENT_BRANCH"
    fi

    # Return to the private repository directory
    cd "$PRIVATE_REPO_PATH"

    echo "Revert completed successfully!"
}

# Main function
main() {
    # Check if a target was specified
    if [ $# -eq 0 ]; then
        echo "Error: No commit hash or version specified for revert."
        echo "Usage: ./hugo-deploy.sh revert <hash|version> [options]"
        exit 1
    fi

    # Get the revert target
    REVERT_TARGET="$1"
    shift

    # Parse options
    parse_options "$@" || exit 1

    # Load configuration
    load_config || exit 1

    # Revert deployment
    revert_deployment "$REVERT_TARGET"
}

# If this script is run directly, execute main function
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
