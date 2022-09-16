#!/usr/bin/env bash

OUTPUT=$(tail -10 outfile.log | tr -d \")
if [[ ("${OUTPUT^^}" != *"FAILURE!"* && "${OUTPUT}" != *"failed with an unexpected trap"* ) ]]; then
    exit 0
  else
    echo "unexpected failure or error"
    exit 1
fi
