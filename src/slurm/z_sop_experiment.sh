#!/bin/bash
#SBATCH --time=01:20:00
#SBATCH --nodes=1
#SBATCH --cpus-per-task=1
#SBATCH --mem=600G
#SBATCH --mail-user=isaac.rudich@gmail.com
#SBATCH --mail-type=FAIL

module load julia
julia z_sop_experiment.jl $instance