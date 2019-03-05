# BMA-design-basket
Bayesian Model Averaging (BMA) Basket trial design software 


===========================================================================================================================================
Folder: BMA-SOFTWARE
Description: Contains all programs and scripts necessary to perform BMA design analyses.


	SUBFOLDER: CLUSTER-ERR
	Contain *.err files from jobs executed on a SLURM cluster (only used by SLURM cluster).
	
	SUBFOLDER: CLUSTER-LOG
	Contain *.ROUT files from jobs executed on a SLURM cluster (only used by SLURM cluster).	
	
	SUBFOLDER: CLUSTER-OUT
	Contain *.out files from jobs executed on a SLURM cluster (only used by SLURM cluster).	

	SUBFOLDER: CLUSTER-OUT
	Contain linux shell scripts for running jobs on SLURM cluster (only used by SLURM cluster). Example below:
	
	++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
	#!/bin/bash

	#SBATCH -p general
	#SBATCH -N 1
	#SBATCH -n 1
	#SBATCH -t 24:00:00
	#SBATCH --mem 5000
	#SBATCH --output=./../CLUSTER-OUT/K5-TUNING-%a.out
	#SBATCH --error=./../CLUSTER-ERR/K5-TUNING-%a.err
	#SBATCH --array=1-1

	## add R module
	module add r/3.3.1

	## run R command
	R CMD BATCH "--no-save --args $SLURM_ARRAY_TASK_ID" ./../PROGRAMS/K5-SIM-TUNING.R ./../CLUSTER-LOG/K5-TUNING-$SLURM_ARRAY_TASK_ID.Rout

	++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

	SUBFOLDER: PROGRAMS
	Contain R programs for BMA design simulations.
	
		RUN ORDER:
		[1] K5-SIM.R 				--> Perform Bbse set of simulations to explore different design inputs.
		[2] K5-SIM-OPTIMAL.R 		--> Estimate properties of the optimal design.
		[3] K5-SIM-TUNING.R			--> Perform simulations to investigate tuning parameter.
		[4] Kx-SIM-TIMING.R			--> Perform simulations to estimate BMA design run times (single core).
		[5] Kx-SIM-TIMING-MULTI.R	--> Perform parallel simulations to estimate BMA design run times (25 cores).
		[6] K5-SAMPLE-CALCS.R		--> Compute basket classification probabilities.
	
	SUBFOLDER: RESULTS_OPTIMAL
	Folder to store results for optimal design simulations.

	SUBFOLDER: RESULTS_TIMING
	Folder to store results for BMA simulations used to estimate run times.
	
	SUBFOLDER: RESULTS_TUNING
	Folder to store results for BMA simulations used to explore tuning parameter.
	
	SUBFOLDER: SOURCE
	Folder containing Rcpp code for BMA design method.	