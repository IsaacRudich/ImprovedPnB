#!/bin/bash
#SBATCH --time=01:20:00
#SBATCH --nodes=1
#SBATCH --cpus-per-task=24
#SBATCH --mem=186G
#SBATCH --mail-user=isaac.rudich@gmail.com
#SBATCH --mail-type=FAIL

export JULIA_NUM_THREADS=24
module load julia
julia z_sop_experiment_parallel.jl 4