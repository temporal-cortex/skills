#!/usr/bin/env bash
# validate-structure.sh — Validates the skill directory structure and file integrity
set -euo pipefail

SKILL_DIR="calendar-scheduling"
ERRORS=0

# Navigate to repo root (parent of tests/)
cd "$(dirname "$0")/.."

pass() { echo "  PASS: $1"; }
fail() { echo "  FAIL: $1"; ERRORS=$((ERRORS + 1)); }

echo "=== Validating Directory Structure ==="

# 1. Required directories
for dir in \
  "${SKILL_DIR}/scripts" \
  "${SKILL_DIR}/references" \
  "${SKILL_DIR}/assets/presets"; do
  if [[ -d "$dir" ]]; then
    pass "Directory exists: ${dir}"
  else
    fail "Missing directory: ${dir}"
  fi
done

echo ""
echo "=== Validating Required Files ==="

# 2. Required files
REQUIRED_FILES=(
  "${SKILL_DIR}/SKILL.md"
  "${SKILL_DIR}/.mcp.json"
  "${SKILL_DIR}/scripts/setup.sh"
  "${SKILL_DIR}/scripts/configure.sh"
  "${SKILL_DIR}/scripts/status.sh"
  "${SKILL_DIR}/references/BOOKING-SAFETY.md"
  "${SKILL_DIR}/references/MULTI-CALENDAR.md"
  "${SKILL_DIR}/references/RRULE-GUIDE.md"
  "${SKILL_DIR}/references/TOOL-REFERENCE.md"
  "${SKILL_DIR}/assets/presets/personal-assistant.json"
  "${SKILL_DIR}/assets/presets/recruiter-agent.json"
  "${SKILL_DIR}/assets/presets/team-coordinator.json"
)

for f in "${REQUIRED_FILES[@]}"; do
  if [[ -f "$f" ]]; then
    pass "File exists: ${f}"
  else
    fail "Missing file: ${f}"
  fi
done

echo ""
echo "=== Validating Scripts ==="

# 3. Scripts have shebangs and are executable
for script in "${SKILL_DIR}"/scripts/*.sh; do
  if [[ ! -f "$script" ]]; then
    continue
  fi

  # Check shebang
  FIRST_LINE=$(head -n 1 "$script")
  if [[ "$FIRST_LINE" == "#!/usr/bin/env bash" ]] || [[ "$FIRST_LINE" == "#!/bin/bash" ]]; then
    pass "Shebang present: ${script}"
  else
    fail "Missing or invalid shebang in ${script} (got: ${FIRST_LINE})"
  fi

  # Check executable (git tracks this; skip on fresh checkout if not set)
  if [[ -x "$script" ]]; then
    pass "Executable: ${script}"
  else
    # Not a hard failure — CI sets executable via git update-index
    echo "  WARN: Not executable: ${script} (set with: chmod +x ${script})"
  fi
done

echo ""
echo "=== Validating JSON Files ==="

# 4. JSON files are valid
for json_file in "${SKILL_DIR}"/assets/presets/*.json "${SKILL_DIR}"/.mcp.json; do
  if [[ ! -f "$json_file" ]]; then
    continue
  fi

  if JSON_FILE="$json_file" python3 -c "import json, os; json.load(open(os.environ['JSON_FILE']))" 2>/dev/null; then
    pass "Valid JSON: ${json_file}"
  else
    fail "Invalid JSON: ${json_file}"
  fi
done

echo ""
echo "=== Validating File Sizes ==="

# 5. SKILL.md body < 500 lines (total file can be longer due to frontmatter)
if [[ -f "${SKILL_DIR}/SKILL.md" ]]; then
  TOTAL_LINES=$(wc -l < "${SKILL_DIR}/SKILL.md" | tr -d ' ')
  if [[ $TOTAL_LINES -lt 520 ]]; then
    pass "SKILL.md total ${TOTAL_LINES} lines (within budget)"
  else
    fail "SKILL.md has ${TOTAL_LINES} lines (body should be < 500)"
  fi
fi

# 6. Reference files should be focused (< 300 lines each)
for ref in "${SKILL_DIR}"/references/*.md; do
  if [[ ! -f "$ref" ]]; then
    continue
  fi

  REF_LINES=$(wc -l < "$ref" | tr -d ' ')
  if [[ $REF_LINES -lt 300 ]]; then
    pass "Reference ${ref} is ${REF_LINES} lines (< 300)"
  else
    fail "Reference ${ref} is ${REF_LINES} lines (exceeds 300)"
  fi
done

echo ""
if [[ $ERRORS -eq 0 ]]; then
  echo "RESULT: All structure checks passed"
  exit 0
else
  echo "RESULT: ${ERRORS} error(s) found"
  exit 1
fi
