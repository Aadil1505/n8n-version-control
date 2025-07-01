#!/bin/bash

# N8N Workflow to GitHub Script - Refactored
# Clean separation of concerns: init repo, export workflows, push to GitHub

set -e  # Exit on any error

# Configuration
WORKFLOWS_DIR="workflows"
CREDENTIALS_DIR="credentials"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to show usage
show_usage() {
    echo "N8N Workflow GitHub Manager"
    echo ""
    echo "Usage: $0 <command> [options]"
    echo ""
    echo "Commands:"
    echo "  init     Initialize a new local git repository"
    echo "  export   Export workflows to the local repository"
    echo "  push     Push changes to GitHub"
    echo ""
    echo "Init Options:"
    echo "  -d, --dir PATH         Local directory path (default: ./n8n-workflows)"
    echo "  -r, --repo URL         GitHub repository URL"
    echo "  -b, --branch NAME      Git branch name (default: main)"
    echo ""
    echo "Export Options:"
    echo "  -d, --dir PATH         Local repository directory"
    echo "  -w, --workflow-id ID   Export specific workflow by ID"
    echo "  -a, --all             Export all workflows"
    echo "  -c, --include-creds   Also export credentials (WARNING: sensitive data)"
    echo ""
    echo "Push Options:"
    echo "  -d, --dir PATH         Local repository directory"
    echo "  -m, --message TEXT     Commit message (default: 'Update workflows')"
    echo ""
    echo "Examples:"
    echo "  # Initialize a new repository"
    echo "  $0 init --repo https://github.com/user/workflows.git --dir ./my-workflows"
    echo ""
    echo "  # Export all workflows to existing repository"
    echo "  $0 export --all --dir ./my-workflows"
    echo ""
    echo "  # Export specific workflow"
    echo "  $0 export --workflow-id 123 --dir ./my-workflows"
    echo ""
    echo "  # Push changes to GitHub"
    echo "  $0 push --dir ./my-workflows --message 'Added new automation'"
    echo ""
    echo "  # Complete workflow (can be chained):"
    echo "  $0 init --repo https://github.com/user/workflows.git"
    echo "  $0 export --all"
    echo "  $0 push --message 'Initial workflow backup'"
}

# Function to check if n8n command is available
check_n8n_command() {
    if ! command -v n8n &> /dev/null; then
        print_error "n8n command not found. Please ensure n8n is installed and available in PATH."
        exit 1
    fi
}

# Function to check if git is available
check_git_command() {
    if ! command -v git &> /dev/null; then
        print_error "git command not found. Please install git."
        exit 1
    fi
}

# Function to initialize repository
init_repository() {
    local repo_dir="./n8n-workflows"
    local repo_url=""
    local branch="main"
    
    # Parse init-specific arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            -d|--dir)
                repo_dir="$2"
                shift 2
                ;;
            -r|--repo)
                repo_url="$2"
                shift 2
                ;;
            -b|--branch)
                branch="$2"
                shift 2
                ;;
            -h|--help)
                show_usage
                exit 0
                ;;
            *)
                print_error "Unknown init option: $1"
                show_usage
                exit 1
                ;;
        esac
    done
    
    if [ -z "$repo_url" ]; then
        print_error "Repository URL is required for init. Use --repo option."
        exit 1
    fi
    
    print_status "Initializing repository in: $repo_dir"
    print_status "Repository URL: $repo_url"
    print_status "Branch: $branch"
    
    # Create directory if it doesn't exist
    mkdir -p "$repo_dir"
    cd "$repo_dir"
    
    # Initialize git repository
    if [ -d ".git" ]; then
        print_warning "Git repository already exists in this directory"
        read -p "Do you want to continue? This may overwrite existing configuration. (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            print_status "Aborted by user"
            exit 0
        fi
    fi
    
    # Initialize git
    git init
    git remote remove origin 2>/dev/null || true  # Remove existing origin if present
    git remote add origin "$repo_url"
    
    # Create directory structure
    mkdir -p "$WORKFLOWS_DIR"
    mkdir -p "$CREDENTIALS_DIR"
    
    # Create README if it doesn't exist
    if [ ! -f "README.md" ]; then
        cat > README.md << EOF
# N8N Workflows

This repository contains n8n workflow backups.

## Structure

- \`workflows/\` - Contains exported n8n workflows
- \`credentials/\` - Contains exported credentials (if included)

## Usage

Workflows are exported in JSON format and can be imported back into n8n using the CLI or web interface.

Last updated: $(date)
EOF
    fi
    
    # Create .gitignore
    cat > .gitignore << EOF
# N8N specific
.n8n/
*.log
node_modules/

# OS specific
.DS_Store
Thumbs.db

# Editor specific
.vscode/
.idea/

# Temporary files
*.tmp
*.temp
EOF
    
    # Initial commit
    git add .
    git commit -m "Initial repository setup"
    
    # Set branch
    git branch -M "$branch"
    
    print_success "Repository initialized successfully!"
    print_status "Next steps:"
    print_status "  1. Export workflows: $0 export --all --dir $repo_dir"
    print_status "  2. Push to GitHub: $0 push --dir $repo_dir"
}

# Function to export workflows
export_workflows() {
    local repo_dir="./n8n-workflows"
    local workflow_id=""
    local export_all=false
    local include_creds=false
    
    # Parse export-specific arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            -d|--dir)
                repo_dir="$2"
                shift 2
                ;;
            -w|--workflow-id)
                workflow_id="$2"
                shift 2
                ;;
            -a|--all)
                export_all=true
                shift
                ;;
            -c|--include-creds)
                include_creds=true
                shift
                ;;
            -h|--help)
                show_usage
                exit 0
                ;;
            *)
                print_error "Unknown export option: $1"
                show_usage
                exit 1
                ;;
        esac
    done
    
    # Validate arguments
    if [ "$export_all" = false ] && [ -z "$workflow_id" ]; then
        print_error "Either --workflow-id or --all must be specified"
        exit 1
    fi
    
    # Check if repository directory exists
    if [ ! -d "$repo_dir" ]; then
        print_error "Repository directory does not exist: $repo_dir"
        print_error "Run 'init' command first or specify correct directory with --dir"
        exit 1
    fi
    
    if [ ! -d "$repo_dir/.git" ]; then
        print_error "Not a git repository: $repo_dir"
        print_error "Run 'init' command first"
        exit 1
    fi
    
    cd "$repo_dir"
    print_status "Working in repository: $(pwd)"
    
    # Ensure directories exist
    mkdir -p "$WORKFLOWS_DIR"
    mkdir -p "$CREDENTIALS_DIR"
    
    # Export workflows
    if [ "$export_all" = true ]; then
        print_status "Exporting all workflows..."
        if n8n export:workflow --all --separate --pretty --output="$WORKFLOWS_DIR/"; then
            print_success "All workflows exported to $WORKFLOWS_DIR/"
            workflow_count=$(find "$WORKFLOWS_DIR" -name "*.json" | wc -l)
            print_status "Exported $workflow_count workflow files"
        else
            print_error "Failed to export workflows"
            exit 1
        fi
    else
        print_status "Exporting workflow ID: $workflow_id"
        local output_file="$WORKFLOWS_DIR/workflow_${workflow_id}.json"
        if n8n export:workflow --id="$workflow_id" --pretty --output="$output_file"; then
            print_success "Workflow exported to $output_file"
        else
            print_error "Failed to export workflow $workflow_id"
            exit 1
        fi
    fi
    
    # Export credentials if requested
    if [ "$include_creds" = true ]; then
        print_warning "Exporting credentials - this includes sensitive information!"
        read -p "Are you sure you want to continue? (y/N): " -n 1 -r
        echo
        
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            print_status "Exporting credentials..."
            if n8n export:credentials --all --separate --pretty --output="$CREDENTIALS_DIR/"; then
                print_success "Credentials exported to $CREDENTIALS_DIR/"
                cred_count=$(find "$CREDENTIALS_DIR" -name "*.json" | wc -l)
                print_status "Exported $cred_count credential files"
                print_warning "Review credential files before committing!"
            else
                print_error "Failed to export credentials"
                exit 1
            fi
        else
            print_status "Skipping credentials export"
        fi
    fi
    
    # Show status
    print_status "Repository status:"
    git status --porcelain
    
    print_success "Export completed successfully!"
    print_status "Next step: $0 push --dir $repo_dir --message 'Your commit message'"
}

# Function to push to GitHub
push_to_github() {
    local repo_dir="./n8n-workflows"
    local commit_message="Update workflows"
    
    # Parse push-specific arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            -d|--dir)
                repo_dir="$2"
                shift 2
                ;;
            -m|--message)
                commit_message="$2"
                shift 2
                ;;
            -h|--help)
                show_usage
                exit 0
                ;;
            *)
                print_error "Unknown push option: $1"
                show_usage
                exit 1
                ;;
        esac
    done
    
    # Check if repository directory exists
    if [ ! -d "$repo_dir" ]; then
        print_error "Repository directory does not exist: $repo_dir"
        exit 1
    fi
    
    if [ ! -d "$repo_dir/.git" ]; then
        print_error "Not a git repository: $repo_dir"
        exit 1
    fi
    
    cd "$repo_dir"
    print_status "Working in repository: $(pwd)"
    
    # Check for changes
    if git diff --quiet && git diff --cached --quiet && [ -z "$(git ls-files --others --exclude-standard)" ]; then
        print_warning "No changes detected. Nothing to commit."
        print_status "Current git status:"
        git status
        exit 0
    fi
    
    # Show what will be committed
    print_status "Changes to be committed:"
    git add .
    git status --porcelain
    
    # Commit with timestamp
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    local full_message="$commit_message - $timestamp"
    
    print_status "Committing with message: $full_message"
    git commit -m "$full_message"
    
    # Get current branch
    local current_branch=$(git branch --show-current)
    print_status "Pushing to branch: $current_branch"
    
    # Push to remote
    if git push origin "$current_branch"; then
        print_success "Successfully pushed to GitHub!"
    else
        print_error "Failed to push to GitHub"
        print_error "You may need to:"
        print_error "  1. Set up authentication (personal access token or SSH key)"
        print_error "  2. Check if the remote repository exists"
        print_error "  3. Verify you have push permissions"
        exit 1
    fi
    
    # Show final status
    print_status "Final repository status:"
    git log --oneline -5
}

# Main function
main() {
    if [ $# -eq 0 ]; then
        print_error "No command specified"
        show_usage
        exit 1
    fi
    
    local command="$1"
    shift
    
    # Check prerequisites for all commands
    check_git_command
    
    case $command in
        init)
            init_repository "$@"
            ;;
        export)
            check_n8n_command
            export_workflows "$@"
            ;;
        push)
            push_to_github "$@"
            ;;
        -h|--help|help)
            show_usage
            ;;
        *)
            print_error "Unknown command: $command"
            show_usage
            exit 1
            ;;
    esac
}

# Run main function with all arguments
main "$@"
