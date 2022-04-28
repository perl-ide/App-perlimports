#!/bin/bash

# This script is used to tidy this repository

find t lib -type f | grep -E "\.(pm|t)$" | xargs perl -Ilib script/perlimports -i
tidyall -g
