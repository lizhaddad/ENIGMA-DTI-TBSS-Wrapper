#!/bin/bash
#$ -cwd
#$ -j y
#$ -N script_2
#$ -hold_jid script_1

export parentDirectory="$1"

cd ${parentDirectory}

echo "Now running \"slicesdir\" to generate report of all input images"
cd FA
$FSLDIR/bin/slicesdir `$FSLDIR/bin/imglob *_FA.*` > grot 2>&1
cat grot | tail -n 2
/bin/rm grot

