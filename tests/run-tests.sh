#!/bin/bash
set -e

KAAPPI="${KAAPPI:-kaappi}"
C0C_DIR="$(cd "$(dirname "$0")/.." && pwd)"
PASS=0
FAIL=0

run_test() {
    local name="$1"
    local c0_file="$2"
    local expected="$3"

    if "$KAAPPI" --no-jit --lib-path "$C0C_DIR/lib" "$C0C_DIR/c0c.scm" \
        "$c0_file" -o "/tmp/c0c-test-$$" --runtime "$C0C_DIR/runtime" 2>/dev/null; then
        local actual
        actual=$(/tmp/c0c-test-$$ 2>&1)
        if [ "$actual" = "$expected" ]; then
            echo "  PASS: $name"
            PASS=$((PASS + 1))
        else
            echo "  FAIL: $name"
            echo "    expected: $(echo "$expected" | head -3)"
            echo "    actual:   $(echo "$actual" | head -3)"
            FAIL=$((FAIL + 1))
        fi
    else
        echo "  FAIL: $name (compilation failed)"
        FAIL=$((FAIL + 1))
    fi
    rm -f "/tmp/c0c-test-$$" "/tmp/c0c-test-$$.c"
}

echo "=== c0c Integration Tests ==="

run_test "hello world" "$C0C_DIR/tests/programs/hello.c0" "42"

run_test "arithmetic" "$C0C_DIR/tests/programs/arith.c0" \
"13
7
30
3
1
15
-10
-1
16
4
1
7
6
255"

run_test "control flow" "$C0C_DIR/tests/programs/control.c0" \
"1
1
55
120
8
99
0
1"

run_test "pointers" "$C0C_DIR/tests/programs/pointers.c0" \
"42
50
1
1
101"

run_test "arrays" "$C0C_DIR/tests/programs/arrays.c0" \
"10
50
150
2
49"

run_test "structs" "$C0C_DIR/tests/programs/structs.c0" \
"3
4
25
60"

run_test "strings" "$C0C_DIR/tests/programs/strings.c0" \
"5
hello world
1
hello
1
-3"

run_test "typedef" "$C0C_DIR/tests/programs/typedef.c0" \
"30
42
300"

run_test "contracts" "$C0C_DIR/tests/programs/contracts.c0" \
"5
3
60"

run_test "comprehensive" "$C0C_DIR/tests/programs/comprehensive.c0" \
"3
60
720
0
1
1 3 4 5 8
Hello C0!
254
1024
3"

echo ""
echo "Results: $PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ] || exit 1
