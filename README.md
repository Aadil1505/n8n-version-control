# N8N Workflow GitHub Manager

A bash script to backup and version control your n8n workflows by exporting them to GitHub repositories.

## Overview

This script provides a clean, three-phase approach to managing n8n workflow backups:

1.  **Initialize** - Set up a local git repository linked to GitHub
2.  **Export** - Extract workflows from n8n to local files
3.  **Push** - Upload changes to GitHub with proper versioning

## Prerequisites

-   **n8n** - Must be installed and accessible via CLI
-   **git** - Required for repository operations
-   **GitHub account** - With a repository for storing workflows
-   **Authentication** - GitHub personal access token or SSH key configured

## Installation

1.  Download the script:

```bash
curl -O https://raw.githubusercontent.com/yourusername/repo/main/n8n-to-github.sh
# OR
wget https://raw.githubusercontent.com/yourusername/repo/main/n8n-to-github.sh
```

2.  Make it executable:

```bash
chmod +x n8n-to-github.sh
```

3.  Optionally, move to your PATH:

```bash
sudo mv n8n-to-github.sh /usr/local/bin/n8n-backup
```

## Quick Start

### Complete Workflow (First Time Setup)

```bash
# 1. Initialize repository
./n8n-to-github.sh init --repo https://github.com/username/n8n-workflows.git

# 2. Export all workflows
./n8n-to-github.sh export --all

# 3. Push to GitHub
./n8n-to-github.sh push --message "Initial workflow backup"
```

### Regular Updates

```bash
# Export new/updated workflows
./n8n-to-github.sh export --all --dir ./n8n-workflows

# Push changes
./n8n-to-github.sh push --dir ./n8n-workflows --message "Updated automation workflows"
```

## Commands

### `init` - Initialize Repository

Creates a new local git repository and connects it to GitHub.

```bash
./n8n-to-github.sh init [options]
```

**Options:**

-   `-r, --repo URL` - GitHub repository URL (required)
-   `-d, --dir PATH` - Local directory path (default: `./n8n-workflows`)
-   `-b, --branch NAME` - Git branch name (default: `main`)

**Example:**

```bash
./n8n-to-github.sh init \
  --repo https://github.com/myuser/workflows.git \
  --dir ./my-backup \
  --branch production
```

**What it creates:**

```
my-backup/
├── .git/              # Git repository
├── .gitignore         # Ignore rules
├── README.md          # Repository documentation
├── workflows/         # Workflow storage
└── credentials/       # Credential storage (optional)
```

### `export` - Export Workflows

Extracts workflows from n8n and saves them as JSON files.

```bash
./n8n-to-github.sh export [options]
```

**Options:**

-   `-d, --dir PATH` - Repository directory (default: `./n8n-workflows`)
-   `-w, --workflow-id ID` - Export specific workflow by ID
-   `-a, --all` - Export all workflows
-   `-c, --include-creds` - Also export credentials ⚠️ **Contains sensitive data**

**Examples:**

```bash
# Export all workflows
./n8n-to-github.sh export --all

# Export specific workflow
./n8n-to-github.sh export --workflow-id ABC123XYZ

# Export with credentials (be careful!)
./n8n-to-github.sh export --all --include-creds
```

### `push` - Push to GitHub

Commits changes and uploads them to GitHub.

```bash
./n8n-to-github.sh push [options]
```

**Options:**

-   `-d, --dir PATH` - Repository directory (default: `./n8n-workflows`)
-   `-m, --message TEXT` - Commit message (default: `"Update workflows"`)

**Example:**

```bash
./n8n-to-github.sh push \
  --dir ./my-backup \
  --message "Added customer onboarding automation"
```

## Usage Patterns

### Pattern 1: One-Time Setup + Regular Updates

```bash
# Initial setup (once)
./n8n-to-github.sh init --repo https://github.com/user/workflows.git
./n8n-to-github.sh export --all
./n8n-to-github.sh push --message "Initial backup"

# Regular updates
./n8n-to-github.sh export --all
./n8n-to-github.sh push --message "Weekly backup $(date)"
```

### Pattern 2: Specific Workflow Updates

```bash
# After creating/modifying a specific workflow
./n8n-to-github.sh export --workflow-id NEW_WORKFLOW_ID
./n8n-to-github.sh push --message "Added new email automation workflow"
```

### Pattern 3: Multiple Repositories

```bash
# Production workflows
./n8n-to-github.sh init --repo https://github.com/user/prod-workflows.git --dir ./prod
./n8n-to-github.sh export --workflow-id PROD_ID --dir ./prod
./n8n-to-github.sh push --dir ./prod --message "Production update"

# Development workflows
./n8n-to-github.sh init --repo https://github.com/user/dev-workflows.git --dir ./dev
./n8n-to-github.sh export --workflow-id DEV_ID --dir ./dev
./n8n-to-github.sh push --dir ./dev --message "Development update"
```

## Docker Usage

If you're running n8n in Docker, execute the script inside the container:

```bash
# Copy script to container
docker cp n8n-to-github.sh n8n-container:/tmp/

# Execute inside container
docker exec -u node -it n8n-container bash
cd /tmp
./n8n-to-github.sh init --repo https://github.com/user/workflows.git
./n8n-to-github.sh export --all
./n8n-to-github.sh push --message "Docker backup"
```

## GitHub Authentication

The script requires GitHub authentication. Choose one method:

### Method 1: Personal Access Token (Recommended)

1.  Go to GitHub Settings > Developer settings > Personal access tokens
2.  Create a token with `repo` permissions
3.  Use it as your password when prompted

### Method 2: SSH Key

1.  Set up SSH key with GitHub
2.  Use SSH URL: `git@github.com:username/repo.git`

### Method 3: GitHub CLI

```bash
gh auth login
# Then use the script normally
```

## File Structure

After running the script, your repository will have this structure:

```
n8n-workflows/
├── .git/                           # Git repository data
├── .gitignore                      # Git ignore rules
├── README.md                       # Repository documentation
├── workflows/                      # Exported workflows
│   ├── My_Automation_Workflow.json
│   ├── Data_Processing.json
│   └── Email_Notifications.json
└── credentials/                    # Exported credentials (if enabled)
    ├── Gmail_Credentials.json
    └── Slack_Credentials.json
```

## Security Considerations

### ⚠️ Credentials Warning

When using `--include-creds`:

-   **Credentials contain sensitive information** (passwords, API keys, tokens)
-   **Review files before committing** to ensure no secrets are exposed
-   **Consider using private repositories** for credential backups
-   **Use environment variables** in n8n when possible instead of hardcoded credentials

### Best Practices

1.  **Use private repositories** for sensitive workflows
2.  **Review changes** before pushing with `git status` and `git diff`
3.  **Rotate credentials** regularly if they're stored in the repository
4.  **Use `.gitignore`** to exclude sensitive files if needed

## Troubleshooting

### Common Issues

**Error: "n8n command not found"**

```bash
# Check if n8n is installed
which n8n
# If using Docker, run script inside container
docker exec -it n8n-container bash
```

**Error: "Not a git repository"**

```bash
# Run init command first
./n8n-to-github.sh init --repo YOUR_REPO_URL
```

**Error: "No changes detected"**

```bash
# Check if workflows were actually exported
ls -la workflows/
# Try exporting specific workflow
./n8n-to-github.sh export --workflow-id SPECIFIC_ID
```

**Authentication Failed**

```bash
# Set up personal access token or SSH key
# For token: use token as password when prompted
# For SSH: use git@github.com:user/repo.git format
```

### Debug Mode

Add debug information by modifying the script:

```bash
# Add this line after #!/bin/bash
set -x  # Enable debug mode
```

## Contributing

1.  Fork the repository
2.  Create a feature branch
3.  Make your changes
4.  Test thoroughly
5.  Submit a pull request

## License

MIT License - feel free to modify and distribute.

## Changelog

### v2.0.0

-   Refactored to three-command structure (init/export/push)
-   Added support for custom directories and branches
-   Improved error handling and user feedback
-   Added comprehensive documentation

### v1.0.0

-   Initial release with single-command operation
