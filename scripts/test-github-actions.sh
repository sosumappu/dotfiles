#!/usr/bin/env bash
# Test GitHub Actions workflows locally using act
#
# Usage:
#   ./scripts/test-github-actions.sh                    # Interactive menu
#   ./scripts/test-github-actions.sh <workflow-name>    # Test specific workflow
#   ./scripts/test-github-actions.sh all                # Test all workflows

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Act configuration
ACT_PLATFORM="-P ubuntu-24.04=catthehacker/ubuntu:act-latest"
ACT_DAEMON_SOCKET=""
ACT_OFFLINE="--action-offline-mode"
ACT_SECRET_FILE="--secret-file .envrc"
ACT_EVENT="push"

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

cd "${PROJECT_ROOT}"

# Check if act is installed
if ! command -v act &> /dev/null; then
    echo -e "${RED}Error: 'act' is not installed${NC}"
    echo "Install it with: brew install act"
    exit 1
fi

# Check if .envrc exists
if [[ ! -f .envrc ]]; then
    echo -e "${YELLOW}Warning: .envrc not found. Some workflows may fail due to missing secrets.${NC}"
    ACT_SECRET_FILE=""
fi

# Available workflows with their preferred events
declare -A WORKFLOWS=(
    ["ci-docker"]=".github/workflows/ci-docker.yaml:push"
    ["ci-host"]=".github/workflows/ci-host.yaml:push"
    ["security-scan"]=".github/workflows/security-scan.yaml:workflow_dispatch"
    ["cleanup-containers"]=".github/workflows/cleanup-containers.yaml:workflow_dispatch"
)

# Function to print header
print_header() {
    echo -e "${BLUE}================================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}================================================${NC}"
}

# Function to test a single workflow
test_workflow() {
    local workflow_name="$1"
    local workflow_config="${WORKFLOWS[$workflow_name]}"

    if [[ -z "${workflow_config}" ]]; then
        echo -e "${RED}Error: Unknown workflow '${workflow_name}'${NC}"
        return 1
    fi

    # Parse workflow file and event
    local workflow_file="${workflow_config%%:*}"
    local workflow_event="${workflow_config##*:}"

    if [[ -z "${workflow_event}" ]] || [[ "${workflow_event}" == "${workflow_file}" ]]; then
        workflow_event="${ACT_EVENT}"
    fi

    if [[ ! -f "${workflow_file}" ]]; then
        echo -e "${RED}Error: Workflow file not found: ${workflow_file}${NC}"
        return 1
    fi

    print_header "Testing workflow: ${workflow_name}"
    echo -e "${GREEN}Workflow file: ${workflow_file}${NC}"
    echo -e "${GREEN}Event: ${workflow_event}${NC}"
    echo ""

    # Build act command
    local act_cmd="act ${workflow_event} -W ${workflow_file} ${ACT_PLATFORM} ${ACT_OFFLINE} ${ACT_DAEMON_SOCKET}"

    # Add secret file if it exists
    if [[ -n "${ACT_SECRET_FILE}" ]]; then
        act_cmd="${act_cmd} ${ACT_SECRET_FILE}"
    fi

    # Special handling for docker workflows
    if [[ "${workflow_name}" == "ci-docker" ]]; then
        echo -e "${YELLOW}Note: Testing with matrix os:ubuntu${NC}"
        act_cmd="${act_cmd} --matrix os:ubuntu"
    fi

    echo -e "${BLUE}Running: ${act_cmd}${NC}"
    echo ""

    # Run act
    if eval "${act_cmd}"; then
        echo ""
        echo -e "${GREEN}✓ Workflow '${workflow_name}' completed${NC}"
        return 0
    else
        echo ""
        echo -e "${RED}✗ Workflow '${workflow_name}' failed${NC}"
        return 1
    fi
}

# Function to test all workflows
test_all_workflows() {
    print_header "Testing All Workflows"

    local failed_workflows=()
    local passed_workflows=()

    for workflow_name in "${!WORKFLOWS[@]}"; do
        echo ""
        if test_workflow "${workflow_name}"; then
            passed_workflows+=("${workflow_name}")
        else
            failed_workflows+=("${workflow_name}")
        fi
        echo ""
        echo -e "${BLUE}----------------------------------------${NC}"
    done

    # Print summary
    echo ""
    print_header "Test Summary"
    echo -e "${GREEN}Passed: ${#passed_workflows[@]}${NC}"
    for workflow in "${passed_workflows[@]}"; do
        echo -e "  ${GREEN}✓${NC} ${workflow}"
    done

    if [[ ${#failed_workflows[@]} -gt 0 ]]; then
        echo ""
        echo -e "${RED}Failed: ${#failed_workflows[@]}${NC}"
        for workflow in "${failed_workflows[@]}"; do
            echo -e "  ${RED}✗${NC} ${workflow}"
        done
        return 1
    fi

    return 0
}

# Function to show interactive menu
show_menu() {
    print_header "GitHub Actions Workflow Tester"
    echo ""
    echo "Available workflows:"
    echo ""

    local i=1
    local workflow_list=()
    for workflow_name in "${!WORKFLOWS[@]}"; do
        workflow_list+=("${workflow_name}")
        echo "  ${i}) ${workflow_name}"
        ((i++))
    done

    echo "  ${i}) Test all workflows"
    echo "  0) Exit"
    echo ""

    read -p "Select a workflow to test: " choice

    if [[ "${choice}" == "0" ]]; then
        echo "Exiting..."
        exit 0
    elif [[ "${choice}" == "${i}" ]]; then
        test_all_workflows
    elif [[ "${choice}" =~ ^[0-9]+$ ]] && [[ "${choice}" -ge 1 ]] && [[ "${choice}" -lt "${i}" ]]; then
        local selected_workflow="${workflow_list[$((choice-1))]}"
        test_workflow "${selected_workflow}"
    else
        echo -e "${RED}Invalid choice${NC}"
        exit 1
    fi
}

# Main script logic
main() {
    if [[ $# -eq 0 ]]; then
        # No arguments - show interactive menu
        show_menu
    elif [[ "$1" == "all" ]]; then
        # Test all workflows
        test_all_workflows
    elif [[ "$1" == "list" ]]; then
        # List available workflows
        echo "Available workflows:"
        for workflow_name in "${!WORKFLOWS[@]}"; do
            echo "  - ${workflow_name}"
        done
    elif [[ "$1" == "help" ]] || [[ "$1" == "-h" ]] || [[ "$1" == "--help" ]]; then
        # Show help
        echo "Usage: $0 [workflow-name|all|list]"
        echo ""
        echo "Options:"
        echo "  <workflow-name>  Test a specific workflow"
        echo "  all              Test all workflows"
        echo "  list             List available workflows"
        echo "  (no args)        Interactive menu"
        echo ""
        echo "Available workflows:"
        for workflow_name in "${!WORKFLOWS[@]}"; do
            echo "  - ${workflow_name}"
        done
    else
        # Test specific workflow
        if [[ -v "WORKFLOWS[$1]" ]]; then
            test_workflow "$1"
        else
            echo -e "${RED}Error: Unknown workflow '$1'${NC}"
            echo ""
            echo "Available workflows:"
            for workflow_name in "${!WORKFLOWS[@]}"; do
                echo "  - ${workflow_name}"
            done
            exit 1
        fi
    fi
}

main "$@"
