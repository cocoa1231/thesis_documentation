#!/bin/bash

set -e

for dir in $(cat remaining_temperatures_interp.txt); do
  echo "Submitting task for K = $dir"
  julia -t 4 calculate_free_energies.jl --sourcedir $PWD/$dir --rtol 10 --ofile free_energy_10p.csv > $dir.log  2>&1 &
done

wait
