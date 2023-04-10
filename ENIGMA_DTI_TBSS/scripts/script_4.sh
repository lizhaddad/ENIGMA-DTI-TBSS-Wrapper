#!/bin/bash
#$ -cwd
#$ -j y
#$ -N script_4

export parentDirectory="$1"
export subject_list="$2"
export ROIextraction="$3"

cd $parentDirectory

dirO1=${parentDirectory}/roi_extract/ENIGMA_ROI_part1
dirO2=${parentDirectory}/roi_extract/ENIGMA_ROI_part2

SUBJECT=(`cat ${subject_list}`)
SUBJ_ID=${SUBJECT[${SGE_TASK_ID}-1]}

for DIFF in FA MD AD RD
do
  ${ROIextraction}/singleSubjROI_exe ${ROIextraction}/ENIGMA_look_up_table.txt ${ROIextraction}/mean_FA_skeleton.nii.gz ${ROIextraction}/JHU-WhiteMatter-labels-1mm.nii.gz ${dirO1}/${SUBJ_ID}_${DIFF}_ROIout ${parentDirectory}/${DIFF}_individ/${SUBJ_ID}/stats/${SUBJ_ID}_masked_${DIFF}skel.nii.gz
   
  ${ROIextraction}/averageSubjectTracts_exe ${dirO1}/${SUBJ_ID}_${DIFF}_ROIout.csv ${dirO2}/${SUBJ_ID}_${DIFF}_ROIout_avg.csv

done
