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
		[1] K5-SIM.R --> Perform base set of simulations to explore different design inputs.
		
			(i) This program (and all others) can be run in a windows environment or a linux HPC environment. 
			
			(ii) For each program (other than K5-SAMPLE-CALCS.R), there is a corresponding shell script that can be submitted to a 
			     SLURM scheduler in a linux HPC environment (i.e., sbatch BATCH-K5.sh).
			
			(iii) This program runs a large number of simulation studies to identify an optimal design. The program is designed to be used in a HPC environment.
		
		[2] K5-SIM-OPTIMAL.R --> Estimate properties of the optimal design.
		
			(i) This program is essentialy the same as [1] only the program is setup to perform design simulations only for the optimal design from the paper.
			
			(ii) This program will be most useful to those who wish to explore designs in a one-at-a-time format (i.e., test inputs and modify them rather than
			     perform a large scale grid search).
			
		[3] K5-SIM-TUNING.R	--> Perform simulations to investigate tuning parameter.
		
			(i) This program is essentialy the same as [2] only the program is setup to perform design simulations for the optimal design from the paper but with tuning
			    parameter values equal to 0, 2 (optimal), and 4 for comparison purposes.
			
		[4] Kx-SIM-TIMING.R	--> Perform simulations to estimate BMA design run times (single core).
		
			(i) This program performs design simulations for a varying number of baskets (4 to 10) using a single computing core for each set of design simulations.
			
			(ii) Five replicates of design simulations are performed for each number of baskets.
			
			(iii) The program and shell script is setup to run on an HPC environment for ease.
	
		[5] Kx-SIM-TIMING-MULTI.R --> Perform parallel simulations to estimate BMA design run times (25 cores).
		
			(i) This program performs design simulations for a varying number of baskets (4 to 12) using 25 computing cores for each set of design simulations.	

			(ii) The program and shell script is setup to run on an HPC environment for ease.			
			
		[6] K5-SAMPLE-CALCS.R --> Compute basket classification probabilities.
		
			(i) This program gives an example for computing posterior probabilities of response rate equivalence.

			(ii) No shell script is provided for this program as computations are for a single dataset and therefore instantaneous.
	
	SUBFOLDER: RESULTS_OPTIMAL
	Folder to store results for optimal design simulations.

	SUBFOLDER: RESULTS_TIMING
	Folder to store results for BMA simulations used to estimate run times.
	
	SUBFOLDER: RESULTS_TUNING
	Folder to store results for BMA simulations used to explore tuning parameter.
	
	SUBFOLDER: SOURCE
	Folder containing Rcpp code for BMA design method.	
	
	
===========================================================================================================================================
Folder: CBHM-SOFTWARE
Description: Contains SAS implementation of the CBHM design (Calibrated Bayesian hierarchical model)

===========================================================================================================================================
Folder: CUN-SOFTWARE
Description: Contains SAS implementation of the CUN design (Frequentist two-stage design)

===========================================================================================================================================
Folder: SIM-SOFTWARE
Description: Contains SAS implementation of Simon's Optimal Two-Stage Design 