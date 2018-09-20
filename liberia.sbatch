#!/bin/bash
#SBATCH --job-name=liberia
#SBATCH --output=liberia.out
#SBATCH --time=24:00:00
#SBATCh --partition=broadwl
#SBATCH --exlusive

stata-mp  do master.do
