#!/bin/bash
#SBATCH --partition bramble
#SBATCH --nodes=4
#SBATCH --ntasks-per-node=1
#SBATCH --cpus-per-task=1
#SBATCH --time=5:00:00
#SBATCH --mem=2GB
#SBATCH --job-name=SlurmHosts
#SBATCH --mail-type=END
#SBATCH --mail-user=user@domain.com
#SBATCH --output=slurm_%j.out

module purge
#module load go/1.17
##RUNDIR=${SCRATCH}/run-${SLURM_JOB_ID/.*}
##mkdir -p ${RUNDIR}
#DATADIR=${SCRATCH}/inmap_sandbox
#cd $SLURM_WORK_DIR
#source $DATADIR/setup.sh
#go run $DATADIR/
/bin/hostname