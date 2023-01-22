#!/bin/bash
#SBATCH --time=10:00:00
#SBATCH --nodes=1
#SBATCH --cpus-per-task=1
#SBATCH --mem=1G
#SBATCH --mail-user=isaac.rudich@gmail.com
#SBATCH --mail-type=END
#SBATCH --mail-type=FAIL

for i in {1..50}
do
    # Set the input parameter to the current value of the loop variable
    instance=$i

    # Submit the Julia script, passing the input parameter as an environment variable
    sleep 20
    sbatch --export=setnum=1,instance=$instance z_tsptw_experiment.sh
    sleep 20
    sbatch --export=setnum=1,instance=$instance z_tsptwm_experiment.sh
done

for i in {1..130}
do
    # Set the input parameter to the current value of the loop variable
    instance=$i

    # Submit the Julia script, passing the input parameter as an environment variable
    sleep 20
    sbatch --export=setnum=2,instance=$instance z_tsptw_experiment.sh
    sleep 20
    sbatch --export=setnum=2,instance=$instance z_tsptwm_experiment.sh
done

for i in {1..70}
do
    # Set the input parameter to the current value of the loop variable
    instance=$i

    # Submit the Julia script, passing the input parameter as an environment variable
    sleep 20
    sbatch --export=setnum=3,instance=$instance z_tsptw_experiment.sh
    sleep 20
    sbatch --export=setnum=3,instance=$instance z_tsptwm_experiment.sh
done


for i in {1..25}
do
    # Set the input parameter to the current value of the loop variable
    instance=$i

    # Submit the Julia script, passing the input parameter as an environment variable
    sleep 20
    sbatch --export=setnum=4,instance=$instance z_tsptw_experiment.sh
    sleep 20
    sbatch --export=setnum=4,instance=$instance z_tsptwm_experiment.sh
done

for i in {1..27}
do
    # Set the input parameter to the current value of the loop variable
    instance=$i

    # Submit the Julia script, passing the input parameter as an environment variable
    sbatch --export=setnum=5,instance=$instance z_tsptw_experiment.sh
    sleep 20
    sbatch --export=setnum=5,instance=$instance z_tsptwm_experiment.sh
    sleep 20
done

for i in {1..30}
do
    # Set the input parameter to the current value of the loop variable
    instance=$i

    # Submit the Julia script, passing the input parameter as an environment variable
    sleep 20
    sbatch --export=setnum=6,instance=$instance z_tsptw_experiment.sh
    sleep 20
    sbatch --export=setnum=6,instance=$instance z_tsptwm_experiment.sh
done

for i in {1..135}
do
    # Set the input parameter to the current value of the loop variable
    instance=$i

    # Submit the Julia script, passing the input parameter as an environment variable
    sleep 20
    sbatch --export=setnum=7,instance=$instance z_tsptw_experiment.sh
    sleep 20
    sbatch --export=setnum=7,instance=$instance z_tsptwm_experiment.sh
done

# for i in {1..41}
# do
#     # Set the input parameter to the current value of the loop variable
#     instance=$i
    
#     # Submit the Julia script, passing the input parameter as an environment variable
#     sleep 20
#     sbatch --export=instance=$instance z_sop_experiment.sh
# done