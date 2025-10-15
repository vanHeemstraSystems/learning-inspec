#!/bin/bash

# InSpec Profile Execution Script

# This script provides easy ways to run the Linux Security Baseline profile

# with different options and report formats.

set -e

# Colors for output

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Script directory

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROFILE_PATH="${SCRIPT_DIR}"

# Default values

TARGET="local"
REPORT_DIR="${SCRIPT_DIR}/reports"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)

# Functions

print_header() {
echo -e "${BLUE}"
echo "=================================================="
echo "  Linux Security Baseline - InSpec Profile"
echo "  Author: Willem van Heemstra"
echo "=================================================="
echo -e "${NC}"
}

print_success() {
echo -e "${GREEN}✓ $1${NC}"
}

print_error() {
echo -e "${RED}✗ $1${NC}"
}

print_warning() {
echo -e "${YELLOW}⚠ $1${NC}"
}

print_info() {
echo -e "${BLUE}ℹ $1${NC}"
}

check_inspec() {
if ! command -v inspec &> /dev/null; then
print_error "InSpec is not installed!"
echo ""
echo "Install InSpec:"
echo "  macOS:  brew install inspec"
echo "  Linux:  curl https://omnitruck.chef.io/install.sh | sudo bash -s -- -P inspec"
echo ""
exit 1
fi

print_success "InSpec is installed (version: $(inspec --version))"

}

create_report_dir() {
if [ ! -d "$REPORT_DIR" ]; then
mkdir -p "$REPORT_DIR"
print_success "Created reports directory: $REPORT_DIR"
fi
}

show_usage() {
cat << EOF
Usage: $0 [OPTIONS]

Options:
-t, --target <target>       Target to scan (default: local)
Examples:
local
ssh://user@hostname
ssh://user@hostname:2222
docker://container_id

-r, --reporter <format>     Report format (default: cli)
                            Options: cli, json, html, yaml
                            
-o, --output <file>         Output file for report (auto-generated if not specified)

-c, --controls <pattern>    Run specific controls (e.g., "filesystem-*" or "user-01")

-i, --input-file <file>     Custom input file for profile parameters

-k, --key <path>            SSH private key path (for SSH targets)

-w, --waiver <file>         Waiver file path

--show-progress             Show progress during execution

--no-distinct-exit          Always exit with code 0 (useful for CI/CD)

-h, --help                  Show this help message

Examples:
# Run locally with CLI output
$0

# Run locally with HTML report
$0 -r html

# Run against remote SSH server
$0 -t ssh://admin@192.168.1.100 -k ~/.ssh/id_rsa -r json

# Run specific controls
$0 -c "filesystem-*"

# Run with multiple reporters
$0 -r cli -r json -r html

# Run in CI/CD mode (always exit 0)
$0 --no-distinct-exit -r json

EOF
}

# Parse command line arguments

REPORTERS=()
CONTROLS=""
INPUT_FILE=""
SSH_KEY=""
WAIVER_FILE=""
OUTPUT_FILE=""
SHOW_PROGRESS=""
NO_DISTINCT_EXIT=""

while [[ $# -gt 0 ]]; do
case $1 in
-t|--target)
TARGET="$2"
shift 2
;;
-r|--reporter)
REPORTERS+=("$2")
shift 2
;;
-o|--output)
OUTPUT_FILE="$2"
shift 2
;;
-c|--controls)
CONTROLS="$2"
shift 2
;;
-i|--input-file)
INPUT_FILE="$2"
shift 2
;;
-k|--key)
SSH_KEY="$2"
shift 2
;;
-w|--waiver)
WAIVER_FILE="$2"
shift 2
;;
--show-progress)
SHOW_PROGRESS="--show-progress"
shift
;;
--no-distinct-exit)
NO_DISTINCT_EXIT="--no-distinct-exit"
shift
;;
-h|--help)
show_usage
exit 0
;;
*)
print_error "Unknown option: $1"
show_usage
exit 1
;;
esac
done

# Default reporter if none specified

if [ ${#REPORTERS[@]} -eq 0 ]; then
REPORTERS=("cli")
fi

# Main execution

print_header
check_inspec
create_report_dir

# Build InSpec command

INSPEC_CMD="inspec exec ${PROFILE_PATH}"

# Add target

if [ "$TARGET" != "local" ]; then
INSPEC_CMD="${INSPEC_CMD} -t ${TARGET}"
fi

# Add SSH key if specified

if [ -n "$SSH_KEY" ]; then
INSPEC_CMD="${INSPEC_CMD} -i ${SSH_KEY}"
fi

# Add controls filter if specified

if [ -n "$CONTROLS" ]; then
INSPEC_CMD="${INSPEC_CMD} --controls ${CONTROLS}"
fi

# Add input file if specified

if [ -n "$INPUT_FILE" ]; then
INSPEC_CMD="${INSPEC_CMD} --input-file ${INPUT_FILE}"
fi

# Add waiver file if specified

if [ -n "$WAIVER_FILE" ]; then
INSPEC_CMD="${INSPEC_CMD} --waiver-file ${WAIVER_FILE}"
fi

# Add reporters

REPORTER_ARGS=""
for reporter in "${REPORTERS[@]}"; do
case $reporter in
cli)
REPORTER_ARGS="${REPORTER_ARGS} --reporter cli"
;;
json)
JSON_FILE="${OUTPUT_FILE:-${REPORT_DIR}/inspec_report_${TIMESTAMP}.json}"
REPORTER_ARGS="${REPORTER_ARGS} --reporter json:${JSON_FILE}"
print_info "JSON report will be saved to: ${JSON_FILE}"
;;
html)
HTML_FILE="${OUTPUT_FILE:-${REPORT_DIR}/inspec_report_${TIMESTAMP}.html}"
REPORTER_ARGS="${REPORTER_ARGS} --reporter html:${HTML_FILE}"
print_info "HTML report will be saved to: ${HTML_FILE}"
;;
yaml)
YAML_FILE="${OUTPUT_FILE:-${REPORT_DIR}/inspec_report_${TIMESTAMP}.yaml}"
REPORTER_ARGS="${REPORTER_ARGS} --reporter yaml:${YAML_FILE}"
print_info "YAML report will be saved to: ${YAML_FILE}"
;;
*)
print_warning "Unknown reporter: $reporter (using cli)"
REPORTER_ARGS="${REPORTER_ARGS} --reporter cli"
;;
esac
done

INSPEC_CMD="${INSPEC_CMD} ${REPORTER_ARGS}"

# Add optional flags

if [ -n "$SHOW_PROGRESS" ]; then
INSPEC_CMD="${INSPEC_CMD} ${SHOW_PROGRESS}"
fi

if [ -n "$NO_DISTINCT_EXIT" ]; then
INSPEC_CMD="${INSPEC_CMD} ${NO_DISTINCT_EXIT}"
fi

# Display execution info

echo ""
print_info "Executing InSpec profile..."
print_info "Target: ${TARGET}"
print_info "Profile: ${PROFILE_PATH}"
if [ -n "$CONTROLS" ]; then
print_info "Controls filter: ${CONTROLS}"
fi
echo ""
echo "Command: ${INSPEC_CMD}"
echo ""

# Execute InSpec

eval $INSPEC_CMD
EXIT_CODE=$?

echo ""
if [ $EXIT_CODE -eq 0 ]; then
print_success "All controls passed!"
elif [ $EXIT_CODE -eq 100 ]; then
print_warning "Some controls failed - review the report"
elif [ $EXIT_CODE -eq 101 ]; then
print_error "InSpec execution failed - check errors above"
else
print_error "InSpec exited with code: $EXIT_CODE"
fi

echo ""
print_info "Reports saved in: ${REPORT_DIR}"
echo ""

exit $EXIT_CODE
