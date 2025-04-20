#!/bin/bash

#########################################################################
# Hugo Deploy - Simple Hugo Deployment Script
#########################################################################
#
# Description:
#   A streamlined script for deploying Hugo websites from a private repo
#   to a public repo with version tracking.
#
# Usage:
#   ./deploy-simple.sh <version>     Deploy with specified version (e.g., 1.2.3)
#   ./deploy-simple.sh list          List previous deployments
#   ./deploy-simple.sh help          Show this help message
#
#########################################################################

# Default config file location
CONFIG_FILE="hugo-deploy.conf"
DEPLOYMENT_BRANCH="gh-pages"
PUSH_TO_REMOTE=false  # Default is NOT to push to remote

# Display help information
show_help() {
    echo "Hugo Deploy - Simple Hugo Deployment Script"
    echo ""
    echo "Usage:"
    echo "  ./deploy.sh <version> [options]  Deploy with specified version (e.g., 1.2.3)"
    echo "  ./deploy.sh list               List previous deployments"
    echo "  ./deploy.sh revert <hash|version> Revert (undo) the specified deployment"
    echo "  ./deploy.sh help               Show this help message"
    echo ""
    echo "Options:"
    echo "  --push                        Push to remote repository"
    exit 0
}

# List previous deployments
list_deployments() {
    if [ ! -d "$PUBLIC_REPO_PATH" ]; then
        echo "Error: Public repository not found at $PUBLIC_REPO_PATH"
        exit 1
    fi

    echo "Previous deployments:"
    echo "-------------------"
    cd "$PUBLIC_REPO_PATH"

    # Check if the deployment branch exists
    if ! git show-ref --verify --quiet refs/heads/$DEPLOYMENT_BRANCH; then
        echo "No deployments found. The $DEPLOYMENT_BRANCH branch doesn't exist yet."
        exit 0
    fi

    # Switch to the deployment branch
    git checkout $DEPLOYMENT_BRANCH > /dev/null 2>&1

    # Show the last 10 deployments
    git log -10 --pretty=format:"%h %ad | %s" --date=short

    exit 0
}

# Revert to a previous deployment
revert_deployment() {
    if [ -z "$1" ]; then
        echo "Error: No commit hash or version specified."
        echo "Usage: ./deploy.sh revert <hash|version>"
        exit 1
    fi

    REVERT_TARGET="$1"

    if [ ! -d "$PUBLIC_REPO_PATH" ]; then
        echo "Error: Public repository not found at $PUBLIC_REPO_PATH"
        exit 1
    fi

    cd "$PUBLIC_REPO_PATH"

    # Check if the deployment branch exists
    if ! git show-ref --verify --quiet refs/heads/$DEPLOYMENT_BRANCH; then
        echo "Error: No deployments found. The $DEPLOYMENT_BRANCH branch doesn't exist yet."
        exit 1
    fi

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
        echo "Force pushing revert to remote repository..."
        git push --force origin $DEPLOYMENT_BRANCH

        if [ $? -ne 0 ]; then
            echo "Error: Failed to push revert to remote repository"
            exit 1
        fi

        echo "Revert force-pushed successfully to remote repository."
    else
        echo "Skipping push to remote repository (use --push option to push)."
        echo "To push manually, run: git push --force origin $DEPLOYMENT_BRANCH"
    fi

    # Return to the private repository directory
    cd "$PRIVATE_REPO_PATH"

    echo "Revert completed successfully!"
    exit 0
}

# Parse command line arguments
if [ $# -eq 0 ]; then
    echo "Error: Command required."
    echo "Usage: ./deploy.sh <version> | list | revert <hash|version> | help"
    exit 1
fi

# First argument is the command
COMMAND=$1
shift

# For revert command, the next argument is the target
if [ "$COMMAND" = "revert" ] && [ $# -gt 0 ]; then
    REVERT_TARGET=$1
    shift
fi

# Parse any additional options
while [[ $# -gt 0 ]]; do
    case $1 in
        --push)
            PUSH_TO_REMOTE=true
            shift
            ;;
        *)
            echo "Unknown option: $1"
            show_help
            ;;
    esac
done

# Process the command
case $COMMAND in
    help)
        show_help
        ;;
    list)
        # Load configuration from file
        if [ -f "$CONFIG_FILE" ]; then
            source "$CONFIG_FILE"
            list_deployments
        else
            echo "Error: Configuration file $CONFIG_FILE not found."
            exit 1
        fi
        ;;
    revert)
        # Check if a target was specified
        if [ -z "$REVERT_TARGET" ]; then
            echo "Error: No commit hash or version specified for revert."
            echo "Usage: ./deploy.sh revert <hash|version>"
            exit 1
        fi

        # Load configuration from file
        if [ -f "$CONFIG_FILE" ]; then
            source "$CONFIG_FILE"
            revert_deployment "$REVERT_TARGET"
        else
            echo "Error: Configuration file $CONFIG_FILE not found."
            exit 1
        fi
        ;;
    *)
        # Assume it's a version number for deployment
        VERSION="$COMMAND"
        ;;
esac

# Load configuration from file
if [ -f "$CONFIG_FILE" ]; then
    source "$CONFIG_FILE"
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
    exit 1
fi

# Step 1: Build the site with Hugo
echo "Building site with Hugo..."
cd "$PRIVATE_REPO_PATH"
hugo --cleanDestinationDir --minify

if [ $? -ne 0 ]; then
    echo "Error: Hugo build failed"
    exit 1
fi

# Step 2: Create exclude parameters for rsync
EXCLUDE_PARAMS=""
for file in $EXCLUDED_FILES; do
    EXCLUDE_PARAMS="$EXCLUDE_PARAMS --exclude=$file"
done

# Step 3: Delete old content in public repository (preserving excluded files)
echo "Preparing public repository..."
cd "$PUBLIC_REPO_PATH"

# Create a find command that excludes the specified files
FIND_EXCLUDE=""
for file in $EXCLUDED_FILES; do
    FIND_EXCLUDE="$FIND_EXCLUDE -not -name $file"
done

# Find and delete all files/directories except excluded ones
find . -mindepth 1 -maxdepth 1 $FIND_EXCLUDE -exec rm -rf {} \;

if [ $? -ne 0 ]; then
    echo "Error: Failed to clean public repository"
    exit 1
fi

# Step 4: Copy files to public repository using rsync
echo "Copying files to public repository..."
rsync -a $EXCLUDE_PARAMS "$PRIVATE_REPO_PATH/public/" "$PUBLIC_REPO_PATH/"

if [ $? -ne 0 ]; then
    echo "Error: Failed to copy files to public repository"
    exit 1
fi

# Step 5: Git operations
echo "Preparing deployment..."
cd "$PUBLIC_REPO_PATH"

# Check if we're on the correct branch
CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "none")
if [ "$CURRENT_BRANCH" != "$DEPLOYMENT_BRANCH" ]; then
    echo "Switching to branch: $DEPLOYMENT_BRANCH"

    # Check if branch exists
    if git show-ref --verify --quiet refs/heads/$DEPLOYMENT_BRANCH; then
        # Branch exists, switch to it
        git checkout $DEPLOYMENT_BRANCH
    else
        # Branch doesn't exist, create an orphan branch (no history)
        echo "Branch $DEPLOYMENT_BRANCH doesn't exist. Creating orphan branch..."
        git checkout --orphan $DEPLOYMENT_BRANCH
    fi

    if [ $? -ne 0 ]; then
        echo "Error: Failed to switch to branch $DEPLOYMENT_BRANCH"
        exit 1
    fi
fi

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
    echo "Pushing changes to remote repository..."
    git push origin $DEPLOYMENT_BRANCH

    if [ $? -ne 0 ]; then
        echo "Error: Failed to push changes to remote repository"
        exit 1
    fi

    echo "Changes pushed successfully to remote repository."
else
    echo "Skipping push to remote repository (use --push option to push)."
    echo "To push manually, run: git push origin $DEPLOYMENT_BRANCH"
fi

# Step 6: Return to the private repository directory
cd "$PRIVATE_REPO_PATH"

echo "Deployment completed successfully!"
echo "Deployed version: $VERSION"
