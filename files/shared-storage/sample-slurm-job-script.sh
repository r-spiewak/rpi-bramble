#!/bin/bash
#SBATCH --partition production
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=1
#SBATCH --cpus-per-task=1
#SBATCH --time=5:00:00
#SBATCH --mem=2GB
#SBATCH --job-name=myTest
#SBATCH --mail-type=END
#SBATCH --mail-user=atd341@nyu.edu
#SBATCH --output=slurm_%j.out

module purge
module load go/1.17
##RUNDIR=${SCRATCH}/run-${SLURM_JOB_ID/.*}
##mkdir -p ${RUNDIR}
DATADIR=${SCRATCH}/inmap_sandbox
cd $SLURM_WORK_DIR
source $DATADIR/setup.sh
go run $DATADIR/