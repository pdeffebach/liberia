#!/bin/bash
#SBATCH --job-name=liberia
#SBATCH --time=24:00:00
#SBATCH --partition=broadwl
#SBATCH --mem=16000
#SBATCH --cpus-per-task=16
#SBATCH --output=liberia.out
module load stata/15
stata-mp  do master.do
