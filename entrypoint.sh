#!/bin/bash

mount -t debugfs none /sys/kernel/debug/

exec "$@"
