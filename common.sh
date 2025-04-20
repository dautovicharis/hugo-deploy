#!/bin/bash

#########################################################################
# Hugo Deploy - Common Functions
#########################################################################

# Default config file location
CONFIG_FILE="hugo-deploy.conf"
DEPLOYMENT_BRANCH="gh-pages"
PUSH_TO_REMOTE=false  # Default is NOT to push to remote

# Load configuration from file
load_config() {
    if [ -f "$CONFIG_FILE" ]; then
        source "$CONFIG_FILE"
        # Override with config file value if it exists
        if [ ! -z "$DEFAULT_BRANCH" ]; then
            DEPLOYMENT_BRANCH="$DEFAULT_BRANCH"
        fi
        return 0
    else
        echo "Error: Configuration file $CONFIG_FILE not found."
        echo "Please create a configuration file with the following content:"
        echo ""
        echo "# Paths to repositories"
        echo "PRIVATE_REPO_PATH=\"path/to/your/private/hugo/repo\""
        echo "PUBLIC_REPO_PATH=\"path/to/your/public/repo\""
        echo ""
        echo "# Files to preserve in the public repository (space-separated)"
        echo "EXCLUDED_FILES=\"README.md CNAME .git .gitignore\""
        return 1
    fi
}

# Parse command line options
parse_options() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            --push)
                PUSH_TO_REMOTE=true
                shift
                ;;
            *)
                echo "Unknown option: $1"
                return 1
                ;;
        esac
    done
    return 0
}

# Check if public repository exists
check_public_repo() {
    if [ ! -d "$PUBLIC_REPO_PATH" ]; then
        echo "Error: Public repository not found at $PUBLIC_REPO_PATH"
        return 1
    fi
    return 0
}

# Check if deployment branch exists
check_deployment_branch() {
    cd "$PUBLIC_REPO_PATH"
    if ! git show-ref --verify --quiet refs/heads/$DEPLOYMENT_BRANCH; then
        echo "No deployments found. The $DEPLOYMENT_BRANCH branch doesn't exist yet."
        return 1
    fi
    return 0
}

# Switch to deployment branch
switch_to_deployment_branch() {
    cd "$PUBLIC_REPO_PATH"
    
    # Check if we're on the correct branch
    CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "none")
    if [ "$CURRENT_BRANCH" != "$DEPLOYMENT_BRANCH" ]; then
        echo "Switching to branch: $DEPLOYMENT_BRANCH"

        # Check if branch exists
        if git show-ref --verify --quiet refs/heads/$DEPLOYMENT_BRANCH; then
            # Branch exists, switch to it
            git checkout $DEPLOYMENT_BRANCH > /dev/null 2>&1
        else
            # Branch doesn't exist, create an orphan branch (no history)
            echo "Branch $DEPLOYMENT_BRANCH doesn't exist. Creating orphan branch..."
            git checkout --orphan $DEPLOYMENT_BRANCH
        fi

        if [ $? -ne 0 ]; then
            echo "Error: Failed to switch to branch $DEPLOYMENT_BRANCH"
            return 1
        fi
    fi
    return 0
}

# Push changes to remote if requested
push_to_remote() {
    local force_flag=""
    if [ "$1" = "force" ]; then
        force_flag="--force"
        echo "Force pushing to remote repository..."
    else
        echo "Pushing changes to remote repository..."
    fi

    git push $force_flag origin $DEPLOYMENT_BRANCH

    if [ $? -ne 0 ]; then
        echo "Error: Failed to push changes to remote repository"
        return 1
    fi

    echo "Changes pushed successfully to remote repository."
    return 0
}
