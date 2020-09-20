#!/usr/bin/env bash

if grep -q '!' *.scad; then
  echo 'ERROR: ! markers in .scad files'
  exit 1
fi

if egrep -q '\s+$' *.scad; then
  echo 'ERROR: trailing space .scad files'
  exit 1
fi
