#!/usr/bin/env bash

name="$1"
sc_dir="$2"
out="${sc_dir}/${name}.png"

# check if name already exists
if [ -f "${out}" ]; then
    exit 1
fi
sleep 3
gnome-screenshot -af "${out}"
