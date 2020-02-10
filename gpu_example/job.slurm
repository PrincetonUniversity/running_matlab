#!/bin/bash
#SBATCH --job-name=matlab-svd    # create a short name for your job
#SBATCH --nodes=1                # node count
#SBATCH --ntasks=1               # total number of tasks across all nodes
#SBATCH --cpus-per-task=1        # cpu-cores per task (>1 if multi-threaded tasks)
#SBATCH --mem-per-cpu=1G         # memory per cpu-core (4G per cpu-core is default)
#SBATCH --time=00:00:30          # total run time limit (HH:MM:SS)
#SBATCH --gres=gpu:1             # number of gpus per node

module purge
module load matlab/R2019b

matlab -singleCompThread -nodisplay -nosplash -r svd_matlab
