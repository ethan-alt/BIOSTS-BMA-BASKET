#!/bin/bash

#SBATCH -p general
#SBATCH -N 1
#SBATCH -n 1
#SBATCH -t 24:00:00
#SBATCH --mem 5000
#SBATCH --output=./../CLUSTER-OUT/K5-OPTIMAL-%a.out
#SBATCH --error=./../CLUSTER-ERR/K5-OPTIMAL-%a.err
#SBATCH --array=1-1

## add R module
module add r/3.3.1

## run R command
R CMD BATCH "--no-save --args $SLURM_ARRAY_TASK_ID" ./../PROGRAMS/K5-SIM-OPTIMAL.R ./../CLUSTER-LOG/K5-OPTIMAL-$SLURM_ARRAY_TASK_ID.Rout