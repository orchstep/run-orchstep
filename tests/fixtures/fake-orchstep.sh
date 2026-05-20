#!/usr/bin/env bash
# A stand-in for the orchstep CLI used by run.sh unit tests.
# Echoes its arguments and exits with $FAKE_EXIT (default 0).
echo "fake-orchstep called with: $*"
exit "${FAKE_EXIT:-0}"
