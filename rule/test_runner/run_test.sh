#!/bin/bash
set -o pipefail
"./$1" 2>&1 | "./$2" "${@:3}"
