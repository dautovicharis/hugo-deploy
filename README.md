# Hugo Deploy

A simple deployment script for Hugo-based websites that manages the workflow between private content repositories and public deployment repositories.

## Overview

This script automates the deployment process for Hugo websites, particularly when you maintain:
- A private repository containing your Hugo source files, content, and configuration
- A public repository where the generated static site is hosted (e.g., GitHub Pages)

## Features

- Builds your Hugo site with minification
- Preserves specified files in the public repository (like CNAME, README.md, etc.)
- Automatically manages the gh-pages branch
- Uses version numbers for deployment tracking
- Simple command structure
- Comprehensive error handling
- Revert functionality to undo deployments

## Installation

1. Make the scripts executable:
   ```bash
   chmod +x hugo-deploy.sh common.sh deploy.sh list.sh revert.sh help.sh
   ```

2. Create a configuration file named `hugo-deploy.conf`

3. Edit the configuration file to match your setup (see Configuration section below)

## Configuration

Before using the script, you need to create a configuration file named `hugo-deploy.conf` with the following content:
   ```bash
   # Paths to repositories
   PRIVATE_REPO_PATH="/path/to/your/private/hugo/repo"
   PUBLIC_REPO_PATH="/path/to/your/public/repo"

   # Files to preserve in the public repository (space-separated)
   EXCLUDED_FILES="README.md CNAME .git .gitignore"
   ```

**Note**: The configuration file is required. The script will exit with an error if it cannot find the configuration file.

## Usage

```bash
./hugo-deploy.sh <command> [options]
```

### Commands

- `<version>`: Deploy with specified version number (e.g., `./hugo-deploy.sh 1.2.3`)
- `list`: List previous deployments
- `revert <hash|version>`: Revert (undo) the specified deployment by going back to the previous version
- `help`: Display help message

### Options

- `--push`: Push to remote repository after deployment

### Examples

```bash
# Deploy version 1.2.3
./hugo-deploy.sh 1.2.3

# Deploy version 2.0.0
./hugo-deploy.sh 2.0.0

# Deploy and push to remote
./hugo-deploy.sh 1.2.3 --push

# List previous deployments
./hugo-deploy.sh list

# Revert (undo) version 1.2.3 by going back to the previous version
./hugo-deploy.sh revert 1.2.3

# Revert a specific commit by going back to the previous commit
./hugo-deploy.sh revert abc123f

# Revert and force push to remote
./hugo-deploy.sh revert 1.2.3 --push

# Show help
./hugo-deploy.sh help
```

## Workflow

1. Builds the site with Hugo
2. Deletes old content in public repository (preserving excluded files)
3. Copies new content to public repository
4. Switches to or creates **gh-pages** branch
5. Commits changes with version as message
6. Pushes to remote repository (if --push option is used)

## Script Architecture

The project uses a modular script architecture for easier maintenance:

- **hugo-deploy.sh**: Main entry script that routes commands to other scripts
- **common.sh**: Common functions and configuration loading shared by all scripts
- **deploy.sh**: Handles the deployment process
- **list.sh**: Lists previous deployments
- **revert.sh**: Reverts to previous deployments
- **help.sh**: Displays help information
