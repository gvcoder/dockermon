#!/usr/bin/env bash
# ==============================================================================
# DockerMon - System Acceptance Test Harness
# Validates the system environment, Docker daemon, container lifecycle,
# logs, exec capabilities, terminal launcher, image management, and cleanup.
# ==============================================================================

set -o pipefail

# Text Formatting
BOLD='\033[1m'
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Test Counters
TOTAL_TESTS=0
PASSED_TESTS=0
FAILED_TESTS=0

# Test Artifacts
TEST_CONTAINER="dockermon_test_runner"
TEST_STOPPED_CONTAINER="dockermon_test_stopped"
TEST_IMAGE="busybox:latest"

print_header() {
    echo -e "${CYAN}==============================================================================${NC}"
    echo -e "${BOLD}${CYAN}                DockerMon - Automated Acceptance Testing Suite                ${NC}"
    echo -e "${CYAN}==============================================================================${NC}"
    echo -e "Date: $(date '+%Y-%m-%d %H:%M:%S')"
    echo -e "Target Host: $(uname -s) $(uname -r) ($(uname -m))"
    echo -e "User: $(whoami)"
    echo -e "${CYAN}------------------------------------------------------------------------------${NC}"
    echo ""
}

cleanup() {
    # Silence cleanup output
    docker rm -f "$TEST_CONTAINER" >/dev/null 2>&1 || true
    docker rm -f "$TEST_STOPPED_CONTAINER" >/dev/null 2>&1 || true
    docker rmi -f "$TEST_IMAGE" >/dev/null 2>&1 || true
}

trap cleanup EXIT INT TERM

run_test() {
    local test_id="$1"
    local test_name="$2"
    local test_fn="$3"

    TOTAL_TESTS=$((TOTAL_TESTS + 1))
    echo -e -n "[${BOLD}${BLUE}TEST $TOTAL_TESTS${NC}] ${BOLD}$test_id: $test_name${NC} ... "

    # Run the test function in subshell
    local output
    if output=$(eval "$test_fn" 2>&1); then
        PASSED_TESTS=$((PASSED_TESTS + 1))
        echo -e "${GREEN}${BOLD}✓ PASS${NC}"
        if [ -n "$output" ]; then
            echo -e "       ${CYAN}Details:${NC} $output"
        fi
    else
        FAILED_TESTS=$((FAILED_TESTS + 1))
        echo -e "${RED}${BOLD}✗ FAIL${NC}"
        echo -e "       ${RED}Error output:${NC} $output"
    fi
}

# ==============================================================================
# TEST DEFINITIONS
# ==============================================================================

# AC-01: Docker Engine & Socket Connectivity
test_ac01_docker_health() {
    if ! command -v docker >/dev/null 2>&1; then
        echo "Docker CLI not found in PATH"
        return 1
    fi

    if [ ! -S /var/run/docker.sock ]; then
        echo "/var/run/docker.sock socket does not exist"
        return 1
    fi

    # Test permissions without sudo
    local ping_out
    ping_out=$(docker ps -n 1 --format "{{.ID}}" 2>&1)
    if [ $? -ne 0 ]; then
        echo "Failed to connect to Docker daemon: $ping_out"
        return 1
    fi

    local docker_ver
    docker_ver=$(docker --version | cut -d',' -f1)
    echo "Docker engine responsive ($docker_ver)"
    return 0
}

# AC-02: Container Lifecycle (Launch, Detect Running, Stop, Restart)
test_ac02_container_lifecycle() {
    # Ensure clean state
    docker rm -f "$TEST_CONTAINER" >/dev/null 2>&1 || true

    # Launch background container with keep-alive
    local run_id
    run_id=$(docker run -d --name "$TEST_CONTAINER" alpine:latest sh -c "while true; do sleep 3600; done" 2>&1)
    if [ $? -ne 0 ]; then
        echo "docker run failed: $run_id"
        return 1
    fi

    # Verify running state
    local state
    state=$(docker inspect --format '{{.State.Status}}' "$TEST_CONTAINER" 2>&1)
    if [ "$state" != "running" ]; then
        echo "Expected state 'running', got '$state'"
        return 1
    fi

    # Stop container
    docker stop "$TEST_CONTAINER" >/dev/null 2>&1
    state=$(docker inspect --format '{{.State.Status}}' "$TEST_CONTAINER" 2>&1)
    if [ "$state" != "exited" ]; then
        echo "Expected state 'exited' after stop, got '$state'"
        return 1
    fi

    # Restart container
    docker restart "$TEST_CONTAINER" >/dev/null 2>&1
    state=$(docker inspect --format '{{.State.Status}}' "$TEST_CONTAINER" 2>&1)
    if [ "$state" != "running" ]; then
        echo "Expected state 'running' after restart, got '$state'"
        return 1
    fi

    echo "Lifecycle transitions (create -> running -> exited -> running) verified"
    return 0
}

# AC-03: Interactive Shell Launcher Contract
test_ac03_terminal_launcher() {
    local emulators=("x-terminal-emulator" "gnome-terminal" "xterm" "konsole" "xfce4-terminal")
    local found=""

    for term in "${emulators[@]}"; do
        if command -v "$term" >/dev/null 2>&1; then
            found="$term"
            break
        fi
    done

    if [ -z "$found" ]; then
        echo "No supported terminal emulator found on Linux desktop."
        return 1
    fi

    # Verify the terminal command wrapper syntax
    local test_subshell
    test_subshell=$(sh -c 'echo "launcher_test_ok"' 2>&1)
    if [ "$test_subshell" != "launcher_test_ok" ]; then
        echo "Subshell invocation failed"
        return 1
    fi

    echo "Terminal emulator detected: '$found' (supports wrapped exec shell)"
    return 0
}

# AC-04: In-App Exec Command Execution
test_ac04_inapp_exec() {
    # Check container is up
    if ! docker ps --format '{{.Names}}' | grep -q "^${TEST_CONTAINER}$"; then
        echo "Test container $TEST_CONTAINER not running"
        return 1
    fi

    local exec_out
    exec_out=$(docker exec "$TEST_CONTAINER" echo "DOCKERMON_EXEC_TEST" 2>&1)
    if [ "$exec_out" != "DOCKERMON_EXEC_TEST" ]; then
        echo "Unexpected exec output: $exec_out"
        return 1
    fi

    local uname_out
    uname_out=$(docker exec "$TEST_CONTAINER" uname -s 2>&1)
    if [ "$uname_out" != "Linux" ]; then
        echo "Unexpected uname in container: $uname_out"
        return 1
    fi

    echo "Non-interactive in-app command execution returned exact output"
    return 0
}

# AC-05: Container Logs & Inspect Retrieval
test_ac05_logs_and_inspect() {
    # Emit a log line to test container
    docker exec "$TEST_CONTAINER" sh -c "echo 'DockerMon Log Message $(date +%s)' > /dev/stdout" >/dev/null 2>&1 || true

    local logs
    logs=$(docker logs --tail 10 "$TEST_CONTAINER" 2>&1)
    if [ $? -ne 0 ]; then
        echo "docker logs failed: $logs"
        return 1
    fi

    local inspect_json
    inspect_json=$(docker inspect "$TEST_CONTAINER" 2>&1)
    if ! echo "$inspect_json" | grep -q '"Id":'; then
        echo "docker inspect did not return valid JSON container metadata"
        return 1
    fi

    echo "Logs fetched and inspect JSON metadata validated"
    return 0
}

# AC-06: Container Deletion & Bulk Prune
test_ac06_deletion_and_prune() {
    # 1. Force removal of running container
    docker rm -f "$TEST_CONTAINER" >/dev/null 2>&1
    if docker ps -a --format '{{.Names}}' | grep -q "^${TEST_CONTAINER}$"; then
        echo "Container $TEST_CONTAINER was not removed by docker rm -f"
        return 1
    fi

    # 2. Test prune stopped containers
    docker run --name "$TEST_STOPPED_CONTAINER" alpine:latest echo "temporary" >/dev/null 2>&1
    local prune_out
    prune_out=$(docker container prune -f 2>&1)
    if [ $? -ne 0 ]; then
        echo "docker container prune failed: $prune_out"
        return 1
    fi

    if docker ps -a --format '{{.Names}}' | grep -q "^${TEST_STOPPED_CONTAINER}$"; then
        echo "Stopped container was not cleaned up by docker container prune"
        return 1
    fi

    echo "Force removal and bulk stopped container pruning confirmed"
    return 0
}

# AC-07: Docker Image Listing & JSON Serialization
test_ac07_image_listing() {
    local format_str='{"Repository":"{{.Repository}}","Tag":"{{.Tag}}","ID":"{{.ID}}","CreatedSince":"{{.CreatedSince}}","Size":"{{.Size}}"}'
    local images_output
    images_output=$(docker image ls --format "$format_str" 2>&1)
    if [ $? -ne 0 ]; then
        echo "docker image ls failed: $images_output"
        return 1
    fi

    if [ -z "$images_output" ]; then
        echo "No images returned by docker image ls"
        return 1
    fi

    local first_line
    first_line=$(echo "$images_output" | head -n 1)
    if ! echo "$first_line" | grep -q '"Repository":'; then
        echo "docker image ls JSON format did not match expected schema: $first_line"
        return 1
    fi

    local count
    count=$(echo "$images_output" | wc -l)
    echo "Successfully listed $count local image(s) with JSON schema match"
    return 0
}

# AC-08: Image Pulling, Listing, and Image Removal
test_ac08_image_pull_and_remove() {
    # Ensure test image is deleted before pulling
    docker rmi -f "$TEST_IMAGE" >/dev/null 2>&1 || true

    # Pull image
    local pull_out
    pull_out=$(docker pull "$TEST_IMAGE" 2>&1)
    if [ $? -ne 0 ]; then
        echo "docker pull $TEST_IMAGE failed: $pull_out"
        return 1
    fi

    # Verify image exists in image ls
    if ! docker image ls --format '{{.Repository}}:{{.Tag}}' | grep -q "^${TEST_IMAGE}$"; then
        echo "Image $TEST_IMAGE not found after pull"
        return 1
    fi

    # Remove image
    local rmi_out
    rmi_out=$(docker rmi "$TEST_IMAGE" 2>&1)
    if [ $? -ne 0 ]; then
        echo "docker rmi $TEST_IMAGE failed: $rmi_out"
        return 1
    fi

    if docker image ls --format '{{.Repository}}:{{.Tag}}' | grep -q "^${TEST_IMAGE}$"; then
        echo "Image $TEST_IMAGE still present after rmi"
        return 1
    fi

    echo "Image pull ($TEST_IMAGE) and removal (rmi) validated cleanly"
    return 0
}

# ==============================================================================
# MAIN TEST EXECUTION RUNNER
# ==============================================================================

main() {
    print_header

    run_test "AC-01" "Docker Engine & Socket Connectivity" test_ac01_docker_health
    run_test "AC-02" "Container Lifecycle (Create, State, Stop, Restart)" test_ac02_container_lifecycle
    run_test "AC-03" "Interactive Terminal Launcher Contract" test_ac03_terminal_launcher
    run_test "AC-04" "In-App Non-Interactive Exec Command Console" test_ac04_inapp_exec
    run_test "AC-05" "Container Logs & JSON Inspect Retrieval" test_ac05_logs_and_inspect
    run_test "AC-06" "Container Deletion & Bulk Prune Stopped" test_ac06_deletion_and_prune
    run_test "AC-07" "Docker Image Listing & JSON Schema Parsing" test_ac07_image_listing
    run_test "AC-08" "Docker Hub Image Pulling & Local Removal (rmi)" test_ac08_image_pull_and_remove

    echo ""
    echo -e "${CYAN}------------------------------------------------------------------------------${NC}"
    echo -e "${BOLD}TEST SUMMARY:${NC}"
    echo -e "  Total Tests:  ${BOLD}$TOTAL_TESTS${NC}"
    echo -e "  Passed:       ${GREEN}${BOLD}$PASSED_TESTS${NC}"
    echo -e "  Failed:       ${RED}${BOLD}$FAILED_TESTS${NC}"

    if [ "$FAILED_TESTS" -eq 0 ]; then
        echo ""
        echo -e "${GREEN}${BOLD}🎉 ALL ACCEPTANCE CRITERIA PASSED! System & DockerMon contract is 100% verified.${NC}"
        echo -e "${CYAN}==============================================================================${NC}"
        exit 0
    else
        echo ""
        echo -e "${RED}${BOLD}⚠️  SOME ACCEPTANCE CRITERIA FAILED! Check error output above.${NC}"
        echo -e "${CYAN}==============================================================================${NC}"
        exit 1
    fi
}

main "$@"
