#!/usr/bin/env bash

if grep -q '!' *.scad; then
  echo 'ERROR: ! markers in .scad files'
  exit 1
fi
