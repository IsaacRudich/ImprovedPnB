#!/bin/bash
#SBATCH --time=01:00:00
#SBATCH --nodes=1
#SBATCH --cpus-per-task=1
#SBATCH --mem=1G
#SBATCH --mail-user=isaac.rudich@gmail.com
#SBATCH --mail-type=END
#SBATCH --mail-type=FAIL



for i in {11..41}
do
    # Set the input parameter to the current value of the loop variable
    instance=$i
    
    # Submit the Julia script, passing the input parameter as an environment variable
    sleep 30
    sbatch --export=instance=$instance z_sop_experiment_parallel.sh
done