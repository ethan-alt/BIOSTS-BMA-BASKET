#!/bin/bash

#SBATCH -p general
#SBATCH -N 1
#SBATCH -n 1
#SBATCH -t 72:00:00
#SBATCH --mem 8000
#SBATCH --output=./../CLUSTER-OUT/Kx-TIMING-%a.out
#SBATCH --error=./../CLUSTER-ERR/Kx-TIMING-%a.err
#SBATCH --array=1-35

## add R module
module add r/3.3.1

## run R command
R CMD BATCH "--no-save --args $SLURM_ARRAY_TASK_ID" ./../PROGRAMS/Kx-SIM-TIMING.R ./../CLUSTER-LOG/Kx-TIMING-$SLURM_ARRAY_TASK_ID.Rout