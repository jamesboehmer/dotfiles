#!/bin/bash

# TODD: make a pbserver launch agent
socat tcp-listen:8121,fork,bind=0.0.0.0 EXEC:'pbcopy' &>/dev/null &

socat -U tcp-listen:8122,fork,bind=0.0.0.0 EXEC:'pbpaste' &>/dev/null &
