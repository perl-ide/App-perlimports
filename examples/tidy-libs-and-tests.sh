#!/bin/bash

# This script is used to tidy this repository

find t lib -type f | grep -E "\.(pm|t)$" | xargs -L 1 perl -Ilib script/perlimports --libs lib,t/lib -i --no-preserve-unused --no-preserve-duplicates --log-level notice -f

tidyall -g
