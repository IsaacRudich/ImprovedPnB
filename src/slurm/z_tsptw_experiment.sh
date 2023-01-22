#!/bin/bash
#SBATCH --time=01:30:00
#SBATCH --nodes=1
#SBATCH --cpus-per-task=1
#SBATCH --mem=186G
#SBATCH --mail-user=isaac.rudich@gmail.com
#SBATCH --mail-type=FAIL

module load julia
julia z_tsptw_experiment.jl $setnum $instance