#!/bin/bash
#SBATCH --time=01:30:00
#SBATCH --nodes=1
#SBATCH --cpus-per-task=5
#SBATCH --mem=400G
#SBATCH --mail-user=isaac.rudich@gmail.com
#SBATCH --mail-type=FAIL

export JULIA_NUM_THREADS=5
module load julia
julia z_tsptwm_experiment_parallel.jl $setnum $instance