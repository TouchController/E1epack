#!/bin/bash

set -e

REPIN=1 bazel run @maven_fabric_1.21.9//:pin
REPIN=1 bazel run @maven_fabric_1.21.10//:pin
REPIN=1 bazel run @maven_fabric_1.21.11//:pin
REPIN=1 bazel run @maven_fabric_26.1//:pin
REPIN=1 bazel run @maven_fabric_26.1.1//:pin
REPIN=1 bazel run @maven_fabric_26.1.2//:pin
REPIN=1 bazel run @maven_fabric_26.2//:pin
