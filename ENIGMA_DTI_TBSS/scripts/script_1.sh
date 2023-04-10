#!/bin/bash
#$ -cwd
#$ -j y
#$ -N script_1

export subject_list="$1"
export dtifit_folder="$2"
export parentDirectory="$3"

cd ${parentDirectory}

SUBJECT=(`cat ${subject_list}`)
SUBJ_ID=${SUBJECT[${SGE_TASK_ID}-1]}

cp ${dtifit_folder}/${SUBJ_ID}/*FA.nii.gz ${parentDirectory}/${SUBJ_ID}_dti_FA.nii.gz

f=${SUBJ_ID}_dti_FA

echo processing $f

# erode a little and zero end slices
X=`${FSLDIR}/bin/fslval $f dim1`; X=`echo "$X 2 - p" | dc -`
Y=`${FSLDIR}/bin/fslval $f dim2`; Y=`echo "$Y 2 - p" | dc -`
Z=`${FSLDIR}/bin/fslval $f dim3`; Z=`echo "$Z 2 - p" | dc -`
$FSLDIR/bin/fslmaths $f -min 1 -ero -roi 1 $X 1 $Y 1 $Z 0 1 FA/${f}_FA

# create mask (for use in FLIRT & FNIRT)
$FSLDIR/bin/fslmaths FA/${f}_FA -bin FA/${f}_FA_mask

$FSLDIR/bin/fslmaths FA/${f}_FA_mask -dilD -dilD -sub 1 -abs -add FA/${f}_FA_mask FA/${f}_FA_mask -odt char

$FSLDIR/bin/immv $f origdata

