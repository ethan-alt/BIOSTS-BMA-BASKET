#!/bin/bash

#SBATCH -p general
#SBATCH -N 1
#SBATCH -n 1
#SBATCH -t 96:00:00
#SBATCH --mem 8000
#SBATCH --output=./../CLUSTER-OUT/Kx-TIMING-MULTI-%a.out
#SBATCH --error=./../CLUSTER-ERR/Kx-TIMING-MULTI-%a.err
#SBATCH --array=1-225

## add R module
module add r/3.3.1

## run R command
R CMD BATCH "--no-save --args $SLURM_ARRAY_TASK_ID" ./../PROGRAMS/Kx-SIM-TIMING-MULTI.R ./../CLUSTER-LOG/Kx-TIMING-MULTI-$SLURM_ARRAY_TASK_ID.Rout