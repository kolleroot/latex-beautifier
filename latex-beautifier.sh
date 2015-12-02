#!/bin/bash

source_dir="$(dirname "$(readlink -f "$0")")"

file=$1

cat $file | awk -f "$source_dir/latex-beautifier.awk"
