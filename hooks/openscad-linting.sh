#!/usr/bin/env bash

if ! grep -q '!' *.scad; then
  echo '! markers in .scad files'
fi
