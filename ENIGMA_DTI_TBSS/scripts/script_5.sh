#!/bin/bash
#$ -cwd
#$ -j y
#$ -N script_5

export parentDirectory="$1"
export subject_list="$2"
export ROIextraction="$3"
export demographics="$4"
export r_binary="$5"


subjects=(`cat ${subject_list}`)
cd $parentDirectory

dos2unix ${demographics}

mv script_4* logs/. &
wait $!

for DIFF in FA MD AD RD
do
  dirO1=${parentDirectory}/roi_extract/ENIGMA_ROI_part1
  dirO2=${parentDirectory}/roi_extract/ENIGMA_ROI_part2

  for subject in ${subjects[@]}
  do
   
  echo ${subject},${dirO2}/${subject}_${DIFF}_ROIout_avg.csv >> ${parentDirectory}/${DIFF}_individ/subjectList_${DIFF}.csv

  done
  
  Table=${demographics}
  subjectIDcol=subjectID
  subjectList=${parentDirectory}/${DIFF}_individ/subjectList_${DIFF}.csv
  outTable=${parentDirectory}/roi_extract/combinedROItable_${DIFF}.csv
  Nroi="all" 
  rois="all"
  
  if [[ $demographics == *.txt ]]
  then
  Ncov=`head -n 1 ${demographics} | awk '{print NF-1}'`
  covariates=`awk 'BEGIN{FS=" ";OFS=";"} FNR==1{$1=$1;$1="";sub(/\;/, "");print;exit}' ${demographics}`
  elif [[ $demographics == *.csv ]]
  then
  Ncov=`head -n 1 ${demographics} | awk -F ',' '{print NF-1}'`
  covariates=`awk 'BEGIN{FS=",";OFS=";"} FNR==1{$1=$1;$1="";sub(/\;/, "");print;exit}' ${demographics}`
  else
  echo "$demographics is not a compatible file format."
  fi  
  
  #location of R binary 
  #Rbin=/usr/local/R-2.9.2_64bit/bin/R
  Rbin=${r_binary}

  #Run the R code
  ${Rbin} --no-save --slave --args ${Table} ${subjectIDcol} ${subjectList} ${outTable} ${Ncov} ${covariates} ${Nroi} ${rois} < ${ROIextraction}/combine_subject_tables.R

done




