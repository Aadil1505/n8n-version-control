# N8N Workflow GitHub Manager

A bash script to backup and version control your n8n workflows by exporting them to GitHub repositories with full import/export capabilities.

## Overview

This script provides a clean, five-phase approach to managing n8n workflow backups:

1. **Initialize** - Set up a local git repository linked to GitHub
2. **Export** - Extract workflows from n8n to local files
3. **Push** - Upload changes to GitHub with proper versioning
4. **Pull** - Download latest changes from GitHub
5. **Import** - Load workflows from local files back into n8n

## Prerequisites

- **n8n** - Must be installed and accessible via CLI
- **git** - Required for repository operations
- **GitHub account** - With a repository for storing workflows
- **Authentication** - GitHub personal access token or SSH key configured

## Installation

1. Download the script:
```bash
curl -O https://raw.githubusercontent.com/Aadil1505/n8n-version-control/refs/heads/main/n8n-to-github.sh
# OR
wget https://raw.githubusercontent.com/Aadil1505/n8n-version-control/refs/heads/main/n8n-to-github.sh
```

2. Make it executable:
```bash
chmod +x n8n-to-github.sh
```

3. Optionally, move to your PATH:
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

# 4. Later: Pull updates from another location
./n8n-to-github.sh pull

# 5. Import workflows into n8n
./n8n-to-github.sh import --all
```

### Regular Updates

```bash
# Export new/updated workflows
./n8n-to-github.sh export --all --dir ./n8n-workflows

# Push changes
./n8n-to-github.sh push --dir ./n8n-workflows --message "Updated automation workflows"

# Pull latest from another machine
./n8n-to-github.sh pull --dir ./n8n-workflows

# Import workflows to n8n
./n8n-to-github.sh import --all --dir ./n8n-workflows
```

## Commands

### `init` - Initialize Repository

Creates a new local git repository and connects it to GitHub.

```bash
./n8n-to-github.sh init [options]
```

**Options:**
- `-r, --repo URL` - GitHub repository URL (required)
- `-d, --dir PATH` - Local directory path (default: `./n8n-workflows`)
- `-b, --branch NAME` - Git branch name (default: `main`)

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
- `-d, --dir PATH` - Repository directory (default: `./n8n-workflows`)
- `-w, --workflow-id ID` - Export specific workflow by ID
- `-a, --all` - Export all workflows
- `-c, --include-creds` - Also export credentials ⚠️ **Contains sensitive data**

**Examples:**
```bash
# Export all workflows
./n8n-to-github.sh export --all

# Export specific workflow
./n8n-to-github.sh export --workflow-id ABC123XYZ

# Export with credentials (be careful!)
./n8n-to-github.sh export --all --include-creds
```

### `pull` - Pull from GitHub

Downloads the latest changes from your GitHub repository.

```bash
./n8n-to-github.sh pull [options]
```

**Options:**
- `-d, --dir PATH` - Repository directory (default: `./n8n-workflows`)

**Example:**
```bash
./n8n-to-github.sh pull --dir ./my-backup
```

**What it does:**
- Checks for local uncommitted changes and warns you
- Pulls latest changes from GitHub (`git pull`)
- Shows what files changed
- Lists available workflow files for import

### `import` - Import Workflows to n8n

Loads workflow JSON files from your local repository into n8n.

```bash
./n8n-to-github.sh import [options]
```

**Options:**
- `-d, --dir PATH` - Repository directory (default: `./n8n-workflows`)
- `-a, --all` - Import all workflow files (with individual prompts)
- `-f, --file PATH` - Import specific workflow file
- `-y, --yes` - Auto-confirm all prompts (skip confirmations)

**Examples:**
```bash
# Import all workflows with prompts
./n8n-to-github.sh import --all

# Import specific workflow
./n8n-to-github.sh import --file workflows/Email_Automation.json

# Auto-import all workflows without prompts
./n8n-to-github.sh import --all --yes

# Import with custom directory
./n8n-to-github.sh import --all --dir ./my-backup
```

**Safety Features:**
- **Always prompts before importing** (unless `--yes` flag used)
- **Warns about overwrites** - existing workflows with same IDs will be replaced
- **Individual confirmations** - When using `--all`, asks about each file
- **Backup reminder** - Suggests exporting current workflows first

### `push` - Push to GitHub

Commits changes and uploads them to GitHub.

```bash
./n8n-to-github.sh push [options]
```

**Options:**
- `-d, --dir PATH` - Repository directory (default: `./n8n-workflows`)
- `-m, --message TEXT` - Commit message (default: `"Update workflows"`)

**Example:**
```bash
./n8n-to-github.sh push \
  --dir ./my-backup \
  --message "Added customer onboarding automation"
```

## Usage Patterns

### Pattern 1: Complete Workflow Management

```bash
# Machine A: Create and backup workflows
./n8n-to-github.sh init --repo https://github.com/user/workflows.git
./n8n-to-github.sh export --all
./n8n-to-github.sh push --message "Initial backup"

# Machine B: Download and import workflows
./n8n-to-github.sh init --repo https://github.com/user/workflows.git
./n8n-to-github.sh pull
./n8n-to-github.sh import --all

# Regular updates on either machine
./n8n-to-github.sh export --all
./n8n-to-github.sh push --message "Updated workflows"
./n8n-to-github.sh pull  # on other machine
./n8n-to-github.sh import --all  # on other machine
```

### Pattern 2: Automated Synchronization

```bash
# Create an automated sync script
#!/bin/bash
echo "Syncing n8n workflows..."
./n8n-to-github.sh pull
./n8n-to-github.sh import --all --yes  # Auto-confirm all imports
./n8n-to-github.sh export --all
./n8n-to-github.sh push --message "Auto-sync $(date)"
echo "Sync completed!"
```

### Pattern 3: Specific Workflow Updates

```bash
# After creating/modifying a specific workflow
./n8n-to-github.sh export --workflow-id NEW_WORKFLOW_ID
./n8n-to-github.sh push --message "Added new email automation workflow"

# On another machine, get the specific workflow
./n8n-to-github.sh pull
./n8n-to-github.sh import --file workflows/NEW_WORKFLOW_NAME.json
```

### Pattern 4: Multiple Repositories

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

# Later: Pull and import on the same or different container
./n8n-to-github.sh pull
./n8n-to-github.sh import --all
```

## GitHub Authentication

The script requires GitHub authentication. Choose one method:

### Method 1: Personal Access Token (Recommended)

1. Go to GitHub Settings > Developer settings > Personal access tokens
2. Create a token with `repo` permissions
3. Use it as your password when prompted

### Method 2: SSH Key

1. Set up SSH key with GitHub
2. Use SSH URL: `git@github.com:username/repo.git`

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
- **Credentials contain sensitive information** (passwords, API keys, tokens)
- **Review files before committing** to ensure no secrets are exposed
- **Consider using private repositories** for credential backups
- **Use environment variables** in n8n when possible instead of hardcoded credentials

### Best Practices

1. **Use private repositories** for sensitive workflows
2. **Review changes** before pushing with `git status` and `git diff`
3. **Rotate credentials** regularly if they're stored in the repository
4. **Use `.gitignore`** to exclude sensitive files if needed

## Import Workflow Examples

### Interactive Import (Default)
```bash
$ ./n8n-to-github.sh import --all
[WARNING] This will import workflows into n8n and may overwrite existing workflows with the same IDs.
[WARNING] Consider exporting your current workflows first as a backup.
Do you want to continue? (y/N): y

[INFO] Found 3 workflow files:
[INFO]   - Email_Automation.json
[INFO]   - Data_Processing.json
[INFO]   - Slack_Notifications.json

Import 'Email_Automation.json'? (y/N): y
[SUCCESS] Imported Email_Automation.json

Import 'Data_Processing.json'? (y/N): n
[INFO] Skipped Data_Processing.json

Import 'Slack_Notifications.json'? (y/N): y
[SUCCESS] Imported Slack_Notifications.json

[SUCCESS] Import completed!
[INFO] Summary: 2 imported, 1 skipped
```

## Troubleshooting
```bash
$ ./n8n-to-github.sh import --all --yes
[INFO] Auto-confirmation enabled - skipping safety prompts
[WARNING] This will import workflows and may overwrite existing ones with the same IDs

[INFO] Found 3 workflow files:
[INFO]   - Email_Automation.json
[INFO]   - Data_Processing.json
[INFO]   - Slack_Notifications.json

[INFO] Auto-importing Email_Automation.json...
[SUCCESS] Imported Email_Automation.json

[INFO] Auto-importing Data_Processing.json...
[SUCCESS] Imported Data_Processing.json

[INFO] Auto-importing Slack_Notifications.json...
[SUCCESS] Imported Slack_Notifications.json

[SUCCESS] Import completed!
[INFO] Summary: 3 imported, 0 skipped
```

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

**Import Errors**
```bash
# If import fails, check n8n is running and accessible
n8n --version
# Ensure workflow files exist
ls -la workflows/
# Try importing a specific file first
./n8n-to-github.sh import --file workflows/specific_workflow.json
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

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly
5. Submit a pull request

## License

MIT License - feel free to modify and distribute.

## Changelog

### v2.1.0
- Added `pull` command to download latest changes from GitHub
- Added `import` command to load workflows from repository into n8n
- Added `--yes` flag for auto-confirming imports
- Enhanced safety with import prompts and warnings
- Added comprehensive examples for complete workflow management

### v2.0.0
- Refactored to three-command structure (init/export/push)
- Added support for custom directories and branches
- Improved error handling and user feedback
- Added comprehensive documentation

### v1.0.0
- Initial release with single-command operation
