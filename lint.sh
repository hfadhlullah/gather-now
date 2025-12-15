#!/bin/bash
# Lint only project files, excluding addons
gdformat scenes/ scripts/ ui/ networking/ test/
gdlint scenes/ scripts/ ui/ networking/ test/
