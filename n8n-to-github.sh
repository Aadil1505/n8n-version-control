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
    echo "  clone    Clone an existing GitHub repository"
    echo "  export   Export workflows to the local repository"
    echo "  push     Push changes to GitHub"
    echo "  pull     Pull latest changes from GitHub"
    echo "  import   Import workflows from local repository to n8n"
    echo ""
    echo "Init Options:"
    echo "  -d, --dir PATH         Local directory path (default: ./n8n-workflows)"
    echo "  -r, --repo URL         GitHub repository URL"
    echo "  -b, --branch NAME      Git branch name (default: main)"
    echo ""
    echo "Clone Options:"
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
    echo "Pull Options:"
    echo "  -d, --dir PATH         Local repository directory"
    echo ""
    echo "Import Options:"
    echo "  -d, --dir PATH         Local repository directory"
    echo "  -a, --all             Import all workflow files (with prompts)"
    echo "  -f, --file PATH       Import specific workflow file"
    echo "  -y, --yes             Auto-confirm all prompts (skip confirmations)"
    echo ""
    echo "Examples:"
    echo "  # Initialize a new repository"
    echo "  $0 init --repo https://github.com/user/workflows.git --dir ./my-workflows"
    echo ""
    echo "  # Clone an existing repository"
    echo "  $0 clone --repo https://github.com/user/workflows.git --dir ./my-workflows"
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
    echo "  # Pull latest changes from GitHub"
    echo "  $0 pull --dir ./my-workflows"
    echo ""
    echo "  # Import workflows to n8n"
    echo "  $0 import --all --dir ./my-workflows"
    echo "  $0 import --file workflows/specific_workflow.json"
    echo "  $0 import --all --yes  # Auto-confirm all imports"
    echo ""
    echo "  # Complete workflow (can be chained):"
    echo "  $0 init --repo https://github.com/user/workflows.git"
    echo "  $0 export --all"
    echo "  $0 push --message 'Initial workflow backup'"
    echo "  $0 pull"
    echo "  $0 import --all"
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

# Function to clone existing repository
clone_repository() {
    local repo_dir="./n8n-workflows"
    local repo_url=""
    local branch="main"
    
    # Parse clone-specific arguments
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
                print_error "Unknown clone option: $1"
                show_usage
                exit 1
                ;;
        esac
    done
    
    if [ -z "$repo_url" ]; then
        print_error "Repository URL is required for clone. Use --repo option."
        exit 1
    fi
    
    print_status "Cloning existing repository to: $repo_dir"
    print_status "Repository URL: $repo_url"
    print_status "Branch: $branch"
    
    # Check if directory already exists
    if [ -d "$repo_dir" ]; then
        print_warning "Directory already exists: $repo_dir"
        read -p "Do you want to remove it and clone fresh? (y/N): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            rm -rf "$repo_dir"
            print_status "Removed existing directory"
        else
            print_status "Aborted by user"
            exit 0
        fi
    fi
    
    # Clone the repository
    print_status "Cloning repository..."
    if git clone "$repo_url" "$repo_dir"; then
        print_success "Repository cloned successfully!"
        
        cd "$repo_dir"
        
        # Switch to specified branch if not main
        if [ "$branch" != "main" ] && [ "$branch" != "master" ]; then
            if git show-ref --verify --quiet "refs/remotes/origin/$branch"; then
                print_status "Checking out branch: $branch"
                git checkout "$branch"
            else
                print_status "Creating new branch: $branch"
                git checkout -b "$branch"
            fi
        fi
        
        # Ensure directories exist
        mkdir -p "$WORKFLOWS_DIR"
        mkdir -p "$CREDENTIALS_DIR"
        
        print_status "Repository structure:"
        ls -la
        
        print_success "Clone completed successfully!"
        print_status "Next steps:"
        print_status "  1. Export workflows: $0 export --all --dir $repo_dir"
        print_status "  2. Push to GitHub: $0 push --dir $repo_dir"
        print_status "  Or import existing workflows: $0 import --all --dir $repo_dir"
        
    else
        print_error "Failed to clone repository"
        print_error "Please check:"
        print_error "  1. Repository URL is correct"
        print_error "  2. You have access to the repository"
        print_error "  3. Your GitHub authentication is set up"
        exit 1
    fi
}


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

# Function to pull from GitHub
pull_from_github() {
    local repo_dir="./n8n-workflows"
    
    # Parse pull-specific arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            -d|--dir)
                repo_dir="$2"
                shift 2
                ;;
            -h|--help)
                show_usage
                exit 0
                ;;
            *)
                print_error "Unknown pull option: $1"
                show_usage
                exit 1
                ;;
        esac
    done
    
    # Check if repository directory exists
    if [ ! -d "$repo_dir" ]; then
        print_error "Repository directory does not exist: $repo_dir"
        print_error "Run 'init' command first"
        exit 1
    fi
    
    if [ ! -d "$repo_dir/.git" ]; then
        print_error "Not a git repository: $repo_dir"
        print_error "Run 'init' command first"
        exit 1
    fi
    
    cd "$repo_dir"
    print_status "Working in repository: $(pwd)"
    
    # Get current branch
    local current_branch=$(git branch --show-current)
    print_status "Pulling from branch: $current_branch"
    
    # Check if there are local changes
    if ! git diff --quiet || ! git diff --cached --quiet || [ -n "$(git ls-files --others --exclude-standard)" ]; then
        print_warning "You have local changes. Consider committing or stashing them first."
        print_status "Local changes:"
        git status --porcelain
        read -p "Continue with pull anyway? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            print_status "Pull cancelled by user"
            exit 0
        fi
    fi
    
    # Pull from remote
    print_status "Pulling latest changes from GitHub..."
    if git pull origin "$current_branch"; then
        print_success "Successfully pulled from GitHub!"
        
        # Show what changed
        print_status "Recent changes:"
        git log --oneline -5
        
        # Show workflow files
        if [ -d "workflows" ] && [ "$(find workflows -name "*.json" | wc -l)" -gt 0 ]; then
            print_status "Available workflow files:"
            find workflows -name "*.json" -exec basename {} \;
            print_status "Use 'import' command to load workflows into n8n"
        fi
    else
        print_error "Failed to pull from GitHub"
        print_error "This might be due to:"
        print_error "  1. Network connectivity issues"
        print_error "  2. Authentication problems"
        print_error "  3. Merge conflicts"
        exit 1
    fi
}

# Function to import workflows to n8n
import_workflows() {
    local repo_dir="./n8n-workflows"
    local import_all=false
    local specific_file=""
    local auto_yes=false
    
    # Parse import-specific arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            -d|--dir)
                repo_dir="$2"
                shift 2
                ;;
            -a|--all)
                import_all=true
                shift
                ;;
            -f|--file)
                specific_file="$2"
                shift 2
                ;;
            -y|--yes)
                auto_yes=true
                shift
                ;;
            -h|--help)
                show_usage
                exit 0
                ;;
            *)
                print_error "Unknown import option: $1"
                show_usage
                exit 1
                ;;
        esac
    done
    
    # Validate arguments
    if [ "$import_all" = false ] && [ -z "$specific_file" ]; then
        print_error "Either --all or --file must be specified"
        show_usage
        exit 1
    fi
    
    # Check if repository directory exists
    if [ ! -d "$repo_dir" ]; then
        print_error "Repository directory does not exist: $repo_dir"
        exit 1
    fi
    
    cd "$repo_dir"
    print_status "Working in repository: $(pwd)"
    
    # Check if workflows directory exists
    if [ ! -d "workflows" ]; then
        print_error "Workflows directory not found. Run 'export' command first."
        exit 1
    fi
    
    # Safety warning (unless auto-yes is enabled)
    if [ "$auto_yes" = false ]; then
        print_warning "This will import workflows into n8n and may overwrite existing workflows with the same IDs."
        print_warning "Consider exporting your current workflows first as a backup."
        read -p "Do you want to continue? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            print_status "Import cancelled by user"
            exit 0
        fi
    else
        print_status "Auto-confirmation enabled - skipping safety prompts"
        print_warning "This will import workflows and may overwrite existing ones with the same IDs"
    fi
    
    local imported_count=0
    local skipped_count=0
    
    if [ "$import_all" = true ]; then
        # Import all workflow files
        print_status "Scanning for workflow files..."
        
        # Find all JSON files in workflows directory
        local workflow_files=($(find workflows -name "*.json" -type f))
        
        if [ ${#workflow_files[@]} -eq 0 ]; then
            print_warning "No workflow files found in workflows/ directory"
            exit 0
        fi
        
        print_status "Found ${#workflow_files[@]} workflow files:"
        for file in "${workflow_files[@]}"; do
            print_status "  - $(basename "$file")"
        done
        echo
        
        # Import each file with confirmation (unless auto-yes)
        for file in "${workflow_files[@]}"; do
            local filename=$(basename "$file")
            local should_import=false
            
            if [ "$auto_yes" = true ]; then
                should_import=true
                print_status "Auto-importing $filename..."
            else
                read -p "Import '$filename'? (y/N): " -n 1 -r
                echo
                if [[ $REPLY =~ ^[Yy]$ ]]; then
                    should_import=true
                fi
            fi
            
            if [ "$should_import" = true ]; then
                if n8n import:workflow --input="$file"; then
                    print_success "Imported $filename"
                    ((imported_count++))
                else
                    print_error "Failed to import $filename"
                fi
            else
                print_status "Skipped $filename"
                ((skipped_count++))
            fi
            echo
        done
        
    else
        # Import specific file
        if [ ! -f "$specific_file" ]; then
            print_error "File not found: $specific_file"
            exit 1
        fi
        
        local filename=$(basename "$specific_file")
        print_status "Importing specific file: $filename"
        
        local should_import=false
        
        if [ "$auto_yes" = true ]; then
            should_import=true
            print_status "Auto-importing $filename..."
        else
            read -p "Import '$filename'? This may overwrite an existing workflow. (y/N): " -n 1 -r
            echo
            if [[ $REPLY =~ ^[Yy]$ ]]; then
                should_import=true
            fi
        fi
        
        if [ "$should_import" = true ]; then
            if n8n import:workflow --input="$specific_file"; then
                print_success "Imported $filename"
                ((imported_count++))
            else
                print_error "Failed to import $filename"
                exit 1
            fi
        else
            print_status "Import cancelled by user"
            exit 0
        fi
    fi
    
    # Summary
    print_success "Import completed!"
    print_status "Summary: $imported_count imported, $skipped_count skipped"
    
    if [ $imported_count -gt 0 ]; then
        print_status "Imported workflows should now be available in your n8n instance"
        print_status "You may need to:"
        print_status "  - Configure credentials for the imported workflows"
        print_status "  - Activate the workflows if needed"
        print_status "  - Test the workflows to ensure they work correctly"
    fi
}
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
        clone)
            clone_repository "$@"
            ;;
        export)
            check_n8n_command
            export_workflows "$@"
            ;;
        push)
            push_to_github "$@"
            ;;
        pull)
            pull_from_github "$@"
            ;;
        import)
            check_n8n_command
            import_workflows "$@"
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
