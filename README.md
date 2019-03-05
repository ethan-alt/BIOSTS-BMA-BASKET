# Software for paper "Bayesian Adaptive Basket Trial Design Using Model Averaging" by Psioda et al.

===========================================================================================================================================
Folder: BMA-SOFTWARE
	Description: Contains all programs and scripts necessary to perform BMA design analyses. Several programs are provided that perform various
	simulations presented in the paper. Each program calls the function "BMA_Design" which performs a set of simulations. The function requires the
	following inputs:
		
		[1]  integer      - nSims      -> Integer number of simulation studies to perform
		[2]  vector (dbl) - eRates     -> vector of rates for interarrival times for Poisson process accrual  in each basket
		[3]  vector (dbl) - rRates     -> vector of response probabilities for each basket
		[4]  vector (dbl) - aParms     -> mean and standard deviation for normal distribution that is used to simulate follow-up times (i.e., outcome ascertainment times)
		[5]  vector (dbl) - ppEffCrit  -> vector of posterior probability critical values for each basket to declare activity
		[6]  vector (dbl) - ppFutCrit  -> vector of posterior probability critical values for each basket to declare inactivity	
		[7]  integer      - futOnly    -> indicator for whether individual baskets should only stop early for futility (i.e., inactivity)
		[8]  vector (dbl) - rRatesNull -> vector of null response rates for the baskets (can all be equal to same value if desired)
		[9]  vector (dbl) - rRatesAlt  -> vector of target response rates for the baskets (can all be equal to the same value if desired)
	    [10] integer      - minSSFut   -> minimum sample size to assess futility (inactivity)
		[11] integer      - minSSEff   -> minimum sample size to assess efficacy (activity)
		[12] matrix (int) - minSSEnr   -> minimum sample size to enrollment in each basket between analyses
		[13] matrix (int) - maxSSEnr   -> maximum sample size to enrollment in each basket between analyses
		[14] vector (int) - targSSPer  -> target sample size for each basket between analyses
		[15] int          - I0         -> maximum number of analyses
		[16] double       - pmp0       -> prior model probability tuning parameter
		[17] double       - mu0        -> beta prior mean
		[18] double       - phi0       -> beta prior dispersion parameter;

	SUBFOLDER: CLUSTER-ERR
	Contain *.err files from jobs executed on a SLURM cluster (only used by SLURM cluster).
	
	SUBFOLDER: CLUSTER-LOG
	Contain *.ROUT files from jobs executed on a SLURM cluster (only used by SLURM cluster).	
	
	SUBFOLDER: CLUSTER-OUT
	Contain *.out files from jobs executed on a SLURM cluster (only used by SLURM cluster).	

	SUBFOLDER: CLUSTER-OUT
	Contain Linux  shell scripts for running jobs on SLURM cluster (only used by SLURM cluster). Example below:
	
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
		
			(i) This program (and all others) can be run in a windows environment or a Linux  HPC environment. 
			
			(ii) For each program (other than K5-SAMPLE-CALCS.R), there is a corresponding shell script that can be submitted to a 
			     SLURM scheduler in a Linux  HPC environment (i.e., sbatch BATCH-K5.sh).
			
			(iii) This program runs a large number of simulation studies to identify an optimal design. The program is designed to be used in a HPC environment.
		
		[2] K5-SIM-OPTIMAL.R --> Estimate properties of the optimal design.
		
			(i) This program is essentially  the same as [1] only the program is setup to perform design simulations only for the optimal design from the paper.
			
			(ii) This program will be most useful to those who wish to explore designs in a one-at-a-time format (i.e., test inputs and modify them rather than
			     perform a large scale grid search).
			
		[3] K5-SIM-TUNING.R	--> Perform simulations to investigate tuning parameter.
		
			(i) This program is essentially  the same as [2] only the program is setup to perform design simulations for the optimal design from the paper but with tuning
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