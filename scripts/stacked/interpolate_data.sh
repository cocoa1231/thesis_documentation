#!/bin/bash

set -e

for dir in $(cat remaining_temperatures_interp.txt); do
  echo $dir
  julia -t 4 interpolate_MH.jl --sourcedir $PWD/$dir --step 0.01 > $dir.log  2>&1 &
done

wait