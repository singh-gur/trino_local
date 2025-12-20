#!/usr/bin/env bash
# Test script to verify Trino setup is working correctly

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Test counters
TESTS_PASSED=0
TESTS_FAILED=0

# Helper functions
print_header() {
    echo -e "\n${BLUE}========================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}========================================${NC}\n"
}

print_test() {
    echo -e "${YELLOW}▶ Testing: $1${NC}"
}

print_success() {
    echo -e "${GREEN}✓ $1${NC}"
    TESTS_PASSED=$((TESTS_PASSED + 1))
}

print_error() {
    echo -e "${RED}✗ $1${NC}"
    TESTS_FAILED=$((TESTS_FAILED + 1))
}

print_info() {
    echo -e "${BLUE}ℹ $1${NC}"
}

# Test functions
test_docker() {
    print_test "Docker installation"
    if command -v docker &> /dev/null; then
        print_success "Docker is installed ($(docker --version))"
    else
        print_error "Docker is not installed"
        return 1
    fi
}

test_docker_compose() {
    print_test "Docker Compose installation"
    if command -v docker-compose &> /dev/null; then
        print_success "Docker Compose is installed ($(docker-compose --version))"
    else
        print_error "Docker Compose is not installed"
        return 1
    fi
}

test_env_file() {
    print_test "Environment file (.env)"
    if [ -f .env ]; then
        print_success ".env file exists"
        
        # Check required variables
        source .env
        local missing=0
        
        if [ -z "${S3_ENDPOINT:-}" ]; then
            print_error "S3_ENDPOINT is not set in .env"
            missing=1
        else
            print_success "S3_ENDPOINT is set: $S3_ENDPOINT"
        fi
        
        if [ -z "${S3_ACCESS_KEY:-}" ]; then
            print_error "S3_ACCESS_KEY is not set in .env"
            missing=1
        else
            print_success "S3_ACCESS_KEY is set"
        fi
        
        if [ -z "${S3_SECRET_KEY:-}" ]; then
            print_error "S3_SECRET_KEY is not set in .env"
            missing=1
        else
            print_success "S3_SECRET_KEY is set"
        fi
        
        return $missing
    else
        print_error ".env file not found. Run 'just setup' first."
        return 1
    fi
}

test_config_files() {
    print_test "Configuration files"
    local missing=0
    
    if [ -f etc/config.properties ]; then
        print_success "etc/config.properties exists"
    else
        print_error "etc/config.properties not found"
        missing=1
    fi
    
    if [ -f etc/jvm.config ]; then
        print_success "etc/jvm.config exists"
    else
        print_error "etc/jvm.config not found"
        missing=1
    fi
    
    if [ -f etc/node.properties ]; then
        print_success "etc/node.properties exists"
    else
        print_error "etc/node.properties not found"
        missing=1
    fi
    
    if [ -f catalog/iceberg.properties ]; then
        print_success "catalog/iceberg.properties exists"
    else
        print_error "catalog/iceberg.properties not found"
        missing=1
    fi
    
    return $missing
}

test_trino_running() {
    print_test "Trino container status"
    if docker ps | grep -q trino-server; then
        print_success "Trino container is running"
    else
        print_error "Trino container is not running. Start with 'just up'"
        return 1
    fi
}

test_trino_health() {
    print_test "Trino health endpoint"
    if curl -sf http://localhost:8080/v1/info > /dev/null 2>&1; then
        print_success "Trino is responding to health checks"
        
        # Get version info
        local version=$(curl -s http://localhost:8080/v1/info | grep -o '"nodeVersion":"[^"]*"' | cut -d'"' -f4)
        if [ -n "$version" ]; then
            print_info "Trino version: $version"
        fi
    else
        print_error "Trino is not responding. Check logs with 'just logs'"
        return 1
    fi
}

test_trino_catalogs() {
    print_test "Trino catalogs"
    local catalogs=$(docker exec trino-server trino --execute "SHOW CATALOGS" 2>/dev/null || echo "")
    
    if echo "$catalogs" | grep -q "iceberg"; then
        print_success "Iceberg catalog is available"
    else
        print_error "Iceberg catalog not found"
        return 1
    fi
    
    if echo "$catalogs" | grep -q "system"; then
        print_success "System catalog is available"
    else
        print_error "System catalog not found"
        return 1
    fi
}

test_s3_connectivity() {
    print_test "S3 endpoint connectivity"
    source .env
    
    if [ -z "${S3_ENDPOINT:-}" ]; then
        print_error "S3_ENDPOINT not set, skipping connectivity test"
        return 1
    fi
    
    # Extract host and port from endpoint
    local endpoint_url="${S3_ENDPOINT#http://}"
    endpoint_url="${endpoint_url#https://}"
    local host="${endpoint_url%%:*}"
    local port="${endpoint_url##*:}"
    
    if [ "$host" = "$port" ]; then
        port="9000"  # Default MinIO port
    fi
    
    if timeout 5 bash -c "cat < /dev/null > /dev/tcp/$host/$port" 2>/dev/null; then
        print_success "S3 endpoint is reachable at $host:$port"
    else
        print_error "Cannot connect to S3 endpoint at $host:$port"
        print_info "Make sure your S3-compatible service is running"
        return 1
    fi
}

test_web_ui() {
    print_test "Web UI accessibility"
    if curl -sf http://localhost:8080 > /dev/null 2>&1; then
        print_success "Web UI is accessible at http://localhost:8080"
    else
        print_error "Web UI is not accessible"
        return 1
    fi
}

# Main test execution
main() {
    print_header "Trino Local Setup - Test Suite"
    
    print_info "This script will verify your Trino setup is working correctly"
    echo ""
    
    # Pre-flight checks (don't require Trino to be running)
    print_header "Pre-flight Checks"
    test_docker || true
    test_docker_compose || true
    test_env_file || true
    test_config_files || true
    
    # Runtime checks (require Trino to be running)
    print_header "Runtime Checks"
    
    if ! test_trino_running; then
        print_info "Trino is not running. Skipping runtime tests."
        print_info "Start Trino with 'just up' and run this script again."
    else
        # Wait a bit for Trino to be fully ready
        print_info "Waiting for Trino to be fully ready..."
        sleep 2
        
        test_trino_health || true
        test_web_ui || true
        test_trino_catalogs || true
        test_s3_connectivity || true
    fi
    
    # Summary
    print_header "Test Summary"
    echo -e "${GREEN}Tests Passed: $TESTS_PASSED${NC}"
    echo -e "${RED}Tests Failed: $TESTS_FAILED${NC}"
    echo ""
    
    if [ $TESTS_FAILED -eq 0 ]; then
        echo -e "${GREEN}✓ All tests passed! Your Trino setup is working correctly.${NC}"
        echo ""
        print_info "Next steps:"
        echo "  - Access CLI: just cli"
        echo "  - Open Web UI: just web"
        echo "  - View sample queries: cat examples/sample-queries.sql"
        exit 0
    else
        echo -e "${RED}✗ Some tests failed. Please review the errors above.${NC}"
        echo ""
        print_info "Troubleshooting:"
        echo "  - Check logs: just logs"
        echo "  - Validate config: just validate"
        echo "  - Reset setup: just clean && just setup"
        exit 1
    fi
}

# Run main function
main
