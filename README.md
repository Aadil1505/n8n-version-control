# N8N Workflow GitHub Manager

A bash script to backup and version control your n8n workflows by exporting them to GitHub repositories with full import/export capabilities.

## Overview

This script provides a clean, six-phase approach to managing n8n workflow backups:

1. **Initialize** - Set up a new local git repository linked to GitHub
2. **Clone** - Download an existing GitHub repository with workflows
3. **Export** - Extract workflows from n8n to local files
4. **Push** - Upload changes to GitHub with proper versioning
5. **Pull** - Download latest changes from GitHub
6. **Import** - Load workflows from local files back into n8n

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

**For a NEW repository:**
```bash
# 1. Initialize new repository
./n8n-to-github.sh init --repo https://github.com/username/n8n-workflows.git

# 2. Export all workflows
./n8n-to-github.sh export --all

# 3. Push to GitHub
./n8n-to-github.sh push --message "Initial workflow backup"
```

**For an EXISTING repository:**
```bash
# 1. Clone existing repository
./n8n-to-github.sh clone --repo https://github.com/username/n8n-workflows.git

# 2. Export all workflows
./n8n-to-github.sh export --all

# 3. Push to GitHub
./n8n-to-github.sh push --message "Added new workflows"
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

### `clone` - Clone Existing Repository

Downloads an existing GitHub repository that already contains workflows.

```bash
./n8n-to-github.sh clone [options]
```

**Options:**
- `-r, --repo URL` - GitHub repository URL (required)
- `-d, --dir PATH` - Local directory path (default: `./n8n-workflows`)
- `-b, --branch NAME` - Git branch name (default: `main`)

**Example:**
```bash
./n8n-to-github.sh clone \
  --repo https://github.com/myuser/workflows.git \
  --dir ./my-backup \
  --branch production
```

**When to use:**
- The GitHub repository **already exists** and has content
- You want to download existing workflows to a new machine
- You're collaborating and need to get someone else's workflows
- You previously created workflows and want to work with them on a different machine

**What it does:**
- Downloads the entire repository with all existing workflows
- Sets up the proper directory structure
- Switches to the specified branch
- Shows available workflows for import

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

**File Naming:**
All exported workflows use consistent naming: `workflow_[ID].json`
- Individual export: `workflow_gCrLpxSIpaxfuXBr.json`
- Bulk export: `workflow_gCrLpxSIpaxfuXBr.json` (same format)

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

## When to Use Each Command

### `init` vs `clone` - Which should I use?

**Use `init` when:**
- Creating a **brand new** GitHub repository
- Starting completely fresh
- The GitHub repository is empty or doesn't exist yet

**Use `clone` when:**
- The GitHub repository **already exists** with workflows
- You want to work with existing workflows on a new machine
- You're joining a team and need existing workflows
- You previously backed up workflows and want to access them

### Common Scenarios

**Scenario 1: First time backup (new repository)**
```bash
# Create new repository and back up workflows
./n8n-to-github.sh init --repo https://github.com/user/new-workflows.git
./n8n-to-github.sh export --all
./n8n-to-github.sh push --message "Initial backup"
```

**Scenario 2: Working with existing backups**
```bash
# Download existing workflows
./n8n-to-github.sh clone --repo https://github.com/user/existing-workflows.git
./n8n-to-github.sh import --all
```

## Usage Patterns
```bash
# Work with existing repository
./n8n-to-github.sh clone --repo https://github.com/user/workflows.git
./n8n-to-github.sh export --workflow-id NEW_ID
./n8n-to-github.sh push --message "Added new workflow"
```

### Pattern 1: Complete Workflow Management

**Starting fresh (new repository):**
```bash
# Machine A: Create and backup workflows
./n8n-to-github.sh init --repo https://github.com/user/workflows.git
./n8n-to-github.sh export --all
./n8n-to-github.sh push --message "Initial backup"

# Machine B: Download and import workflows
./n8n-to-github.sh clone --repo https://github.com/user/workflows.git
./n8n-to-github.sh import --all
```

**Working with existing repository:**
```bash
# Machine A: Work with existing workflows
./n8n-to-github.sh clone --repo https://github.com/user/workflows.git
./n8n-to-github.sh export --all
./n8n-to-github.sh push --message "Updated workflows"

# Machine B: Get updates
./n8n-to-github.sh pull
./n8n-to-github.sh import --all
```

### Pattern 2: Automated Synchronization

```bash
# Create an automated sync script for existing repository
#!/bin/bash
echo "Syncing n8n workflows..."
./n8n-to-github.sh clone --repo https://github.com/user/workflows.git --dir ./temp-sync
./n8n-to-github.sh import --all --yes --dir ./temp-sync  # Auto-confirm imports
./n8n-to-github.sh export --all --dir ./temp-sync
./n8n-to-github.sh push --dir ./temp-sync --message "Auto-sync $(date)"
rm -rf ./temp-sync
echo "Sync completed!"
```

### Pattern 3: Specific Workflow Updates

```bash
# After creating/modifying a specific workflow in existing repo
./n8n-to-github.sh clone --repo https://github.com/user/workflows.git  # if not already cloned
./n8n-to-github.sh export --workflow-id NEW_WORKFLOW_ID
./n8n-to-github.sh push --message "Added new email automation workflow"

# On another machine, get the specific workflow
./n8n-to-github.sh pull
./n8n-to-github.sh import --file workflows/workflow_NEW_WORKFLOW_ID.json
```

### Pattern 4: Multiple Repositories

```bash
# Production workflows (existing repo)
./n8n-to-github.sh clone --repo https://github.com/user/prod-workflows.git --dir ./prod
./n8n-to-github.sh export --workflow-id PROD_ID --dir ./prod
./n8n-to-github.sh push --dir ./prod --message "Production update"

# Development workflows (new repo)
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

# For new repository
./n8n-to-github.sh init --repo https://github.com/user/workflows.git
./n8n-to-github.sh export --all
./n8n-to-github.sh push --message "Docker backup"

# For existing repository
./n8n-to-github.sh clone --repo https://github.com/user/workflows.git
./n8n-to-github.sh import --all
./n8n-to-github.sh export --all
./n8n-to-github.sh push --message "Docker sync"
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

**Error: "Repository directory does not exist"**
```bash
# Use clone for existing repositories
./n8n-to-github.sh clone --repo YOUR_REPO_URL
# Or init for new repositories
./n8n-to-github.sh init --repo YOUR_REPO_URL
```

**Error: "divergent branches" during pull**
```bash
# This happens when using init with existing repository
# Solution: Use clone instead
rm -rf ./n8n-workflows
./n8n-to-github.sh clone --repo YOUR_REPO_URL
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

### v2.2.0
- Added `clone` command for existing repositories
- Fixed divergent branches issue when working with existing repos
- Standardized workflow file naming (`workflow_[ID].json` for all exports)
- Added clear guidance on when to use `init` vs `clone`
- Enhanced documentation with practical scenarios

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
