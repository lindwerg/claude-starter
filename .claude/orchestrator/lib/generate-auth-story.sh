#!/bin/bash
###############################################################################
# Generate STORY-000: Basic JWT Authentication
# Called by ralph when detecting 401 Unauthorized blocker
#
# Usage:
#   generate-auth-story.sh <blocked_task_id>
###############################################################################

set -e

BLOCKED_TASK_ID="$1"
TASK_QUEUE=".bmad/task-queue.yaml"

if [ -z "$BLOCKED_TASK_ID" ]; then
    echo "Error: blocked_task_id required"
    exit 1
fi

if [ ! -f "$TASK_QUEUE" ]; then
    echo "Error: task-queue.yaml not found"
    exit 1
fi

echo "Generating STORY-000: Basic JWT Authentication"

# Check if STORY-000 already exists
if yq '.tasks[] | select(.story_id == "STORY-000")' "$TASK_QUEUE" | grep -q .; then
    echo "STORY-000 already exists, skipping generation"
    exit 0
fi

# Get index of blocked task
BLOCKED_INDEX=$(yq '.tasks | to_entries | .[] | select(.value.id == "'$BLOCKED_TASK_ID'") | .key' "$TASK_QUEUE")

if [ -z "$BLOCKED_INDEX" ]; then
    echo "Error: Blocked task $BLOCKED_TASK_ID not found in queue"
    exit 1
fi

echo "Blocked task index: $BLOCKED_INDEX"
echo "Inserting STORY-000 tasks before index $BLOCKED_INDEX"

# Insert auth tasks one by one BEFORE blocked task index
# TASK-000-A
yq -i ".tasks |= (.[0:$BLOCKED_INDEX] + [{
  \"id\": \"TASK-000-A\",
  \"story_id\": \"STORY-000\",
  \"title\": \"Add /auth endpoints to openapi.yaml\",
  \"type\": \"api\",
  \"estimated_minutes\": 30,
  \"status\": \"pending\",
  \"depends_on\": [],
  \"outputs\": [\"openapi.yaml\"],
  \"acceptance\": [
    \"POST /api/v1/auth/register endpoint defined\",
    \"POST /api/v1/auth/login endpoint defined\",
    \"RegisterRequest/Response schemas\",
    \"LoginRequest/Response schemas\"
  ],
  \"retries\": 0,
  \"max_retries\": 3
}] + .[$BLOCKED_INDEX:])" "$TASK_QUEUE"

# Update index after insertion
BLOCKED_INDEX=$((BLOCKED_INDEX + 1))

# TASK-000-B
yq -i ".tasks |= (.[0:$BLOCKED_INDEX] + [{
  \"id\": \"TASK-000-B\",
  \"story_id\": \"STORY-000\",
  \"title\": \"Implement JWT auth service\",
  \"type\": \"backend\",
  \"estimated_minutes\": 45,
  \"status\": \"pending\",
  \"depends_on\": [\"TASK-000-A\"],
  \"outputs\": [
    \"backend/src/features/auth/register/service.ts\",
    \"backend/src/features/auth/login/service.ts\",
    \"backend/src/shared/lib/jwt.ts\"
  ],
  \"acceptance\": [
    \"Password hashing (bcrypt)\",
    \"JWT token generation\",
    \"Token verification utility\",
    \"User registration logic\",
    \"Login logic with password check\"
  ],
  \"retries\": 0,
  \"max_retries\": 3
}] + .[$BLOCKED_INDEX:])" "$TASK_QUEUE"

BLOCKED_INDEX=$((BLOCKED_INDEX + 1))

# TASK-000-C
yq -i ".tasks |= (.[0:$BLOCKED_INDEX] + [{
  \"id\": \"TASK-000-C\",
  \"story_id\": \"STORY-000\",
  \"title\": \"Create auth controllers\",
  \"type\": \"backend\",
  \"estimated_minutes\": 30,
  \"status\": \"pending\",
  \"depends_on\": [\"TASK-000-B\"],
  \"outputs\": [
    \"backend/src/features/auth/register/controller.ts\",
    \"backend/src/features/auth/login/controller.ts\",
    \"backend/src/features/auth/register/dto.ts\",
    \"backend/src/features/auth/login/dto.ts\"
  ],
  \"acceptance\": [
    \"POST /api/v1/auth/register implemented\",
    \"POST /api/v1/auth/login implemented\",
    \"Zod validation for requests\",
    \"Returns JWT token on success\"
  ],
  \"retries\": 0,
  \"max_retries\": 3
}] + .[$BLOCKED_INDEX:])" "$TASK_QUEUE"

BLOCKED_INDEX=$((BLOCKED_INDEX + 1))

# TASK-000-D
yq -i ".tasks |= (.[0:$BLOCKED_INDEX] + [{
  \"id\": \"TASK-000-D\",
  \"story_id\": \"STORY-000\",
  \"title\": \"Add JWT auth middleware\",
  \"type\": \"backend\",
  \"estimated_minutes\": 30,
  \"status\": \"pending\",
  \"depends_on\": [\"TASK-000-C\"],
  \"outputs\": [\"backend/src/shared/middleware/auth.ts\"],
  \"acceptance\": [
    \"requireAuth middleware verifies JWT\",
    \"Attaches user to request context\",
    \"Returns 401 if no token or invalid\"
  ],
  \"retries\": 0,
  \"max_retries\": 3
}] + .[$BLOCKED_INDEX:])" "$TASK_QUEUE"

BLOCKED_INDEX=$((BLOCKED_INDEX + 1))

# TASK-000-E
yq -i ".tasks |= (.[0:$BLOCKED_INDEX] + [{
  \"id\": \"TASK-000-E\",
  \"story_id\": \"STORY-000\",
  \"title\": \"Frontend auth hooks and storage\",
  \"type\": \"frontend\",
  \"estimated_minutes\": 45,
  \"status\": \"pending\",
  \"depends_on\": [\"TASK-000-D\"],
  \"outputs\": [
    \"frontend/src/shared/api/auth.ts\",
    \"frontend/src/shared/hooks/useAuth.ts\"
  ],
  \"acceptance\": [
    \"useAuth hook provides login/register/logout\",
    \"JWT token stored in localStorage\",
    \"Authorization header added to API calls\",
    \"TanStack Query mutations for auth\"
  ],
  \"retries\": 0,
  \"max_retries\": 3
}] + .[$BLOCKED_INDEX:])" "$TASK_QUEUE"

BLOCKED_INDEX=$((BLOCKED_INDEX + 1))

# TASK-000-F
yq -i ".tasks |= (.[0:$BLOCKED_INDEX] + [{
  \"id\": \"TASK-000-F\",
  \"story_id\": \"STORY-000\",
  \"title\": \"Auth integration tests\",
  \"type\": \"test\",
  \"estimated_minutes\": 30,
  \"status\": \"pending\",
  \"depends_on\": [\"TASK-000-E\"],
  \"outputs\": [
    \"backend/src/features/auth/register/register.test.ts\",
    \"backend/src/features/auth/login/login.test.ts\"
  ],
  \"acceptance\": [
    \"Test user registration flow\",
    \"Test login with valid credentials\",
    \"Test login with invalid credentials\",
    \"Test protected endpoint with JWT\",
    \"Coverage >= 80%\"
  ],
  \"retries\": 0,
  \"max_retries\": 3
}] + .[$BLOCKED_INDEX:])" "$TASK_QUEUE"

# Update blocked task to depend on last auth task
yq -i "
  (.tasks[] | select(.id == \"$BLOCKED_TASK_ID\").depends_on) += [\"TASK-000-F\"]
" "$TASK_QUEUE"

# Update summary
TOTAL_TASKS=$(yq '.tasks | length' "$TASK_QUEUE")
PENDING_TASKS=$(yq '[.tasks[] | select(.status == "pending")] | length' "$TASK_QUEUE")

yq -i ".summary.total_tasks = $TOTAL_TASKS" "$TASK_QUEUE"
yq -i ".summary.pending_tasks = $PENDING_TASKS" "$TASK_QUEUE"

echo "✅ STORY-000 created with 6 tasks (TASK-000-A through TASK-000-F)"
echo "✅ $BLOCKED_TASK_ID now depends on TASK-000-F"
echo "✅ Total tasks: $TOTAL_TASKS"
