#!/usr/bin/env bash
###
# File: start-fake-udev.sh
# Project: bin
# File Created: Sunday, 12th October 2025 7:00:00 pm
# Author: GitHub Copilot
# -----
# Last Modified: Sunday, 12th October 2025 7:00:00 pm
# Modified By: GitHub Copilot
###
set -e

# CATCH TERM SIGNAL:
_term() {
    kill -TERM "$fake_udev_pid" 2>/dev/null
}
trap _term SIGTERM SIGINT


# EXECUTE PROCESS:
# Start fake-udev
fake-udev &
fake_udev_pid=$!

# WAIT FOR CHILD PROCESS:
wait "$fake_udev_pid"
