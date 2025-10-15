#!/bin/bash

# Test All Environments Script

# This script tests the InSpec profile against all Docker test containers

# and generates comprehensive reports for comparison

set -e

# Colors for output

RED=’\033[0;31m’
GREEN=’\033[0;32m’
YELLOW=’\033[1;33m’
BLUE=’\033[0;34m’
CYAN=’\033[0;36m’
NC=’\033[0m’ # No Color

# Configuration

SCRIPT_DIR=”$(cd “$(dirname “${BASH_SOURCE[0]}”)” && pwd)”
REPORT_DIR=”${SCRIPT_DIR}/reports/multi-env-$(date +%Y%m%d_%H%M%S)”
TIMESTAMP=$(date +%Y%m%d_%H%M%S)

# Test environments

declare -A ENVIRONMENTS=(
[“ubuntu-2204”]=“ssh://testuser@localhost:2222”
[“ubuntu-2004”]=“ssh://testuser@localhost:2223”
[“centos-8”]=“ssh://testuser@localhost:2224”
[“debian-11”]=“ssh://testuser@localhost:2225”
[“secure-baseline”]=“ssh://secureuser@localhost:2226”
)

declare -A PASSWORDS=(
[“ubuntu-2204”]=“testpass123”
[“ubuntu-2004”]=“testpass123”
[“centos-8”]=“testpass123”
[“debian-11”]=“testpass123”
[“secure-baseline”]=“SecurePass123!”
)

# Functions

print_header() {
echo -e “${CYAN}”
echo “==========================================================”
echo “  Multi-Environment InSpec Security Testing”
echo “  Testing against ${#ENVIRONMENTS[@]} environments”
echo “==========================================================”
echo -e “${NC}”
}

print_section() {
echo -e “\n${BLUE}==== $1 ====${NC}\n”
}

print_success() {
echo -e “${GREEN}✓ $1${NC}”
}

print_error() {
echo -e “${RED}✗ $1${NC}”
}

print_warning() {
echo -e “${YELLOW}⚠ $1${NC}”
}

print_info() {
echo -e “${CYAN}ℹ $1${NC}”
}

check_prerequisites() {
print_section “Checking Prerequisites”

```
# Check InSpec
if ! command -v inspec &> /dev/null; then
    print_error "InSpec is not installed"
    exit 1
fi
print_success "InSpec installed: $(inspec --version)"

# Check Docker
if ! command -v docker &> /dev/null; then
    print_error "Docker is not installed"
    exit 1
fi
print_success "Docker installed: $(docker --version)"

# Check Docker Compose
if ! command -v docker-compose &> /dev/null; then
    print_error "Docker Compose is not installed"
    exit 1
fi
print_success "Docker Compose installed: $(docker-compose --version)"

# Check jq for JSON parsing
if ! command -v jq &> /dev/null; then
    print_warning "jq not installed - summary statistics will be limited"
else
    print_success "jq installed"
fi
```

}

start_test_environments() {
print_section “Starting Test Environments”

```
# Check if containers are already running
if docker-compose ps | grep -q "Up"; then
    print_info "Test containers already running"
else
    print_info "Starting Docker Compose test environment..."
    docker-compose up -d
    
    print_info "Waiting for SSH services to be ready..."
    sleep 10
fi

# Verify containers are running
for env in "${!ENVIRONMENTS[@]}"; do
    container_name="inspec-${env}"
    if docker ps --format '{{.Names}}' | grep -q "^${container_name}$"; then
        print_success "${env}: Container running"
    else
        print_error "${env}: Container not running"
    fi
done
```

}

create_report_directory() {
mkdir -p “${REPORT_DIR}”
print_success “Report directory created: ${REPORT_DIR}”
}

test_environment() {
local env_name=$1
local target=$2
local password=$3

```
print_section "Testing: ${env_name}"

local json_report="${REPORT_DIR}/${env_name}-report.json"
local html_report="${REPORT_DIR}/${env_name}-report.html"
local cli_report="${REPORT_DIR}/${env_name}-report.txt"

# Run InSpec with multiple reporters
inspec exec . \
    -t "${target}" \
    --password "${password}" \
    --reporter cli:"${cli_report}" \
    --reporter json:"${json_report}" \
    --reporter html:"${html_report}" \
    --no-distinct-exit 2>&1 | tee -a "${REPORT_DIR}/execution.log"

local exit_code=${PIPESTATUS[0]}

if [ ${exit_code} -eq 0 ]; then
    print_success "${env_name}: All controls passed"
elif [ ${exit_code} -eq 100 ]; then
    print_warning "${env_name}: Some controls failed"
else
    print_error "${env_name}: InSpec execution had errors"
fi

# Extract statistics if jq is available
if command -v jq &> /dev/null && [ -f "${json_report}" ]; then
    local total=$(jq '.profiles[0].controls | length' "${json_report}")
    local passed=$(jq '[.profiles[0].controls[] | select(.results[0].status == "passed")] | length' "${json_report}")
    local failed=$((total - passed))
    local compliance=$((passed * 100 / total))
    
    echo "  Total Controls: ${total}"
    echo "  Passed: ${passed}"
    echo "  Failed: ${failed}"
    echo "  Compliance: ${compliance}%"
    
    # Store for summary
    echo "${env_name},${total},${passed},${failed},${compliance}" >> "${REPORT_DIR}/summary.csv"
fi

echo ""
```

}

generate_summary_report() {
print_section “Generating Summary Report”

```
local summary_file="${REPORT_DIR}/SUMMARY.md"

cat > "${summary_file}" << EOF
```

# InSpec Multi-Environment Test Summary

**Test Date**: $(date)
**Profile**: Linux Security Baseline
**Environments Tested**: ${#ENVIRONMENTS[@]}

## Environment Results

|Environment|Total|Passed|Failed|Compliance|
|-----------|-----|------|------|----------|
|EOF        |     |      |      |          |

```
if [ -f "${REPORT_DIR}/summary.csv" ]; then
    while IFS=',' read -r env total passed failed compliance; do
        echo "| ${env} | ${total} | ${passed} | ${failed} | ${compliance}% |" >> "${summary_file}"
    done < "${REPORT_DIR}/summary.csv"
fi

cat >> "${summary_file}" << EOF
```

## Report Files

EOF

```
for env in "${!ENVIRONMENTS[@]}"; do
    echo "- **${env}**:" >> "${summary_file}"
    echo "  - [HTML Report](${env}-report.html)" >> "${summary_file}"
    echo "  - [JSON Report](${env}-report.json)" >> "${summary_file}"
    echo "  - [CLI Report](${env}-report.txt)" >> "${summary_file}"
    echo "" >> "${summary_file}"
done

cat >> "${summary_file}" << EOF
```

## Key Findings

### Most Common Failures

Review the individual reports to identify controls that failed across multiple environments.
These indicate areas needing immediate attention:

EOF

```
# Find common failures if jq is available
if command -v jq &> /dev/null; then
    echo "Analyzing common failures across environments..." >> "${summary_file}"
    
    # This would require more complex jq processing
    # Simplified version here
    echo "" >> "${summary_file}"
    echo "*Review individual environment reports for detailed findings.*" >> "${summary_file}"
fi

cat >> "${summary_file}" << EOF
```

## Recommendations

1. Review failed controls in each environment
1. Prioritize fixes based on:
- Impact level (critical/high/medium/low)
- Number of environments affected
- Ease of remediation
1. Create remediation tickets
1. Re-test after fixes applied
1. Update baseline expectations

## Next Steps

- [ ] Review all failure reports
- [ ] Create remediation plan
- [ ] Schedule follow-up scan
- [ ] Update security documentation

-----

**Report Generated**: $(date)
**Report Location**: ${REPORT_DIR}
EOF

```
print_success "Summary report generated: ${summary_file}"
```

}

open_reports() {
print_section “Opening Reports”

```
# Try to open the summary in default browser/editor
if command -v xdg-open &> /dev/null; then
    xdg-open "${REPORT_DIR}/SUMMARY.md" 2>/dev/null &
elif command -v open &> /dev/null; then
    open "${REPORT_DIR}/SUMMARY.md" 2>/dev/null &
fi

print_info "Reports available in: ${REPORT_DIR}"
print_info "Open SUMMARY.md for overview"
```

}

cleanup() {
print_section “Cleanup”

```
read -p "Stop and remove test containers? (y/N) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    docker-compose down
    print_success "Test containers stopped and removed"
else
    print_info "Test containers left running"
fi
```

}

# Main execution

main() {
print_header

```
check_prerequisites
start_test_environments
create_report_directory

# Create CSV header for summary
echo "Environment,Total,Passed,Failed,Compliance" > "${REPORT_DIR}/summary.csv"

# Test each environment
for env in "${!ENVIRONMENTS[@]}"; do
    test_environment "${env}" "${ENVIRONMENTS[$env]}" "${PASSWORDS[$env]}"
    sleep 2  # Brief pause between tests
done

generate_summary_report
open_reports

print_section "Test Complete"
print_success "All environments tested successfully"
print_info "Reports saved to: ${REPORT_DIR}"

cleanup
```

}

# Handle script interruption

trap ‘echo -e “\n${RED}Script interrupted${NC}”; exit 1’ INT TERM

# Run main function

main “$@”
