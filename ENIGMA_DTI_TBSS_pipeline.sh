#!/bin/bash
#$ -cwd
#$ -j y

## ENIGMA-DTI TBSS Pipeline Wrapper (04/2023)
## Elizabeth Haddad, Neda Jahanshad
## elizabeth.haddad@loni.usc.edu, neda.jahanshad@ini.usc.edu
## This wrapper provides an all-in-one inclusive script, with an option for qsub systems


## Orginal pipeline by:
# Neda Jahanshad, Emma Sprooten, Peter Kochunov (April 2014)


# The following steps will allow you to register and skeletonize your FA images to the DTI atlas being used for ENIGMA-DTI for tract-based spatial statistics (TBSS; Smith et al., 2006). It also conducts ROI analysis for FA and all other diffisivity measures (MD,AD,RD).
# Here we assume preprocessing steps including motion/Eddy current correction, masking, tensor calculation, and creation of FA maps has already been performed, along with quality control.


display_usage() { 
	echo "This script runs the ENIGMA-DTI TBSS pipeline for you." 
	echo -e "\nUsage: $0 \n\t-e \tfull path to ENIGMA_DTI_TBSS folder \n\t-o \tfull path to where to run this pipeline \n\t-d \tfull path to dtifit subject folders \n\t-s \tfull path to subject list text file \n\t-i \tfull path to subject info (demographics) text or csv file \n\t-r \tfull path to R binary \n\t-q \t[optional; only for qsub use] 1=stops after registrations for user QC; 2=resumes script after QC\n" 
	} 

# if less than two arguments supplied, display usage 
	if [  $# -le 1 ] 
	then 
		display_usage
		exit 1
	fi 
 
# check whether user had supplied -h or --help . If yes display usage 
	if [[ ( $# == "--help") ||  $# == "-h" ]] 
	then 
		display_usage
		exit 0
	fi 

# assign arguments
while getopts e:o:d:s:i:r:q: flag
do
    case "${flag}" in
        e) enigma_files=${OPTARG};;
        o) out_folder=${OPTARG};;
        d) dtifit_folder=${OPTARG};;
        s) subject_list=${OPTARG};;
        i) demographics=${OPTARG};;
        r) r_binary=${OPTARG};;
        q) qsub=${OPTARG};;
    esac
done

ENIGMA_files=$enigma_files
parentDirectory=$out_folder
ROIextraction=${enigma_files}/ROIextraction

subjects=(`cat ${subject_list}`)

cd ${parentDirectory}

if [ "$qsub" == "" ]; then

# copy FA images to your run_tbss folder
for subj in ${subjects[@]}; do
    cp ${dtifit_folder}/${subj}/*FA.nii.gz ${parentDirectory}/${subj}_dti_FA.nii.gz
done

# run tbss steps
$FSLDIR/bin/tbss_1_preproc *.nii.gz

cd $parentDirectory/FA

for subj in ${subjects[@]}; do
    touch ${subj}_dti_FA_FA_to_ENIGMA_warp.msf
    $FSLDIR/bin/fsl_reg ${subj}_dti_FA_FA.nii.gz ${ENIGMA_files}/ENIGMA_DTI_FA.nii.gz ${subj}_dti_FA_FA_to_ENIGMA -e -FA

    # wait until tbss_2_reg is finished before moving to step 3    
    t2r_inputs=(`ls ${subj}_dti_FA_FA.nii.gz`)
    t2r_outputs=(`ls ${subj}_dti_FA_FA_to_ENIGMA_warp.nii.gz`)
    while [[ ${#t2r_inputs[@]} != ${#t2r_outputs[@]} ]]; do
        sleep 30s
        t2r_outputs=(`ls ${subj}_dti_FA_FA_to_ENIGMA_warp.nii.gz`)
        echo "waiting for warps to finish..."
    done

    $FSLDIR/bin/applywarp -i ${subj}_dti_FA_FA.nii.gz -o ${subj}_dti_FA_FA_to_ENIGMA -r ${ENIGMA_files}/ENIGMA_DTI_FA.nii.gz -w ${subj}_dti_FA_FA_to_ENIGMA_warp --rel

done &
wait $!

sleep 10s
#fslmerge -t all_FA_for_QC `$FSLDIR/bin/imglob *_FA_to_ENIGMA.*`

cd $parentDirectory


#tbss_4_prestats -0.049


for DIFF in FA MD AD RD; do

    for subj in ${subjects[@]}; do

    # make individual metric directories
    mkdir -p ${DIFF}_individ/${subj}/${DIFF}/
    mkdir -p ${DIFF}_individ/${subj}/stats/
    
    if [ "$DIFF" == "FA" ]; then

        # copy FA images to the individual folders
        cp ./FA/${subj}_*.nii.gz ./FA_individ/${subj}/FA/

        # mask FA image
        $FSLDIR/bin/fslmaths ./FA_individ/${subj}/FA/${subj}_*FA_to_ENIGMA.nii.gz -mas ${ENIGMA_files}/ENIGMA_DTI_FA_mask.nii.gz ./FA_individ/${subj}/FA/${subj}_masked_FA.nii.gz

        # skeletonize
        $FSLDIR/bin/tbss_skeleton -i ./FA_individ/${subj}/FA/${subj}_masked_FA.nii.gz -p 0.049 ${ENIGMA_files}/ENIGMA_DTI_FA_skeleton_mask_dst ${FSLDIR}/data/standard/LowerCingulum_1mm.nii.gz ./FA_individ/${subj}/FA/${subj}_masked_FA.nii.gz ./FA_individ/${subj}/stats/${subj}_masked_FAskel.nii.gz -s ${ENIGMA_files}/ENIGMA_DTI_FA_skeleton_mask.nii.gz

    else

        mkdir -p ${DIFF}/origdata/

        if [ "$DIFF" == "MD" ]; then

            # copy MD images to the individual folders
            cp ${dtifit_folder}/${subj}/*_MD.nii.gz ${parentDirectory}/MD/${subj}_MD.nii.gz

            elif [ "$DIFF" == "AD" ]; then

                # copy AD images to the individual folders
                cp ${dtifit_folder}/${subj}/*_L1.nii.gz ${parentDirectory}/AD/${subj}_AD.nii.gz

            elif [ "$DIFF" == "RD" ]; then

                # make RD image and copy to the individual folders
                $FSLDIR/bin/fslmaths ${dtifit_folder}/${subj}/*_L2.nii.gz -add ${dtifit_folder}/${subj}/*_L3.nii.gz -div 2 ${parentDirectory}/RD/${subj}_RD.nii.gz
        fi
            
         # mask metric images  
        $FSLDIR/bin/fslmaths ${parentDirectory}/${DIFF}/${subj}_${DIFF}.nii.gz -mas ${parentDirectory}/FA/${subj}*_FA_mask.nii.gz ${parentDirectory}/${DIFF}_individ/${subj}/${DIFF}/${subj}_${DIFF}
 
        # move unmasked to origdata folder
        $FSLDIR/bin/immv ${parentDirectory}/${DIFF}/${subj}_${DIFF} ${parentDirectory}/${DIFF}/origdata/
 
        # apply FA_TO_ENIGMA warp to metric images
        $FSLDIR/bin/applywarp -i ${parentDirectory}/${DIFF}_individ/${subj}/${DIFF}/${subj}_${DIFF} -o ${parentDirectory}/${DIFF}_individ/${subj}/${DIFF}/${subj}_${DIFF}_to_ENIGMA -r $FSLDIR/data/standard/FMRIB58_FA_1mm -w ${parentDirectory}/FA/${subj}*_FA_to_ENIGMA_warp.nii.gz
 
        # mask metric warped images
        $FSLDIR/bin/fslmaths ${parentDirectory}/${DIFF}_individ/${subj}/${DIFF}/${subj}_${DIFF}_to_ENIGMA -mas ${ENIGMA_files}/ENIGMA_DTI_FA_mask.nii.gz ${parentDirectory}/${DIFF}_individ/${subj}/${DIFF}/${subj}_masked_${DIFF}.nii.gz	
 
        # skeletonize metric images
        $FSLDIR/bin/tbss_skeleton -i ./FA_individ/${subj}/FA/${subj}_masked_FA.nii.gz -p 0.049 ${ENIGMA_files}/ENIGMA_DTI_FA_skeleton_mask_dst.nii.gz $FSLDIR/data/standard/LowerCingulum_1mm.nii.gz ${parentDirectory}/FA_individ/${subj}/FA/${subj}_masked_FA.nii.gz ${parentDirectory}/${DIFF}_individ/${subj}/stats/${subj}_masked_${DIFF}skel -a ${parentDirectory}/${DIFF}_individ/${subj}/${DIFF}/${subj}_masked_${DIFF}.nii.gz -s ${ENIGMA_files}/ENIGMA_DTI_FA_skeleton_mask.nii.gz

	fi
    done
done

## QC Images
read -s -n 1 -p "Script Paused! QC any images and move to a separate folder if you want to exclude. Once complete press Any Key to Continue. `echo $'\n> '`"

### end part 1, have user check images

for DIFF in FA MD AD RD
do
   mkdir -p ${parentDirectory}/roi_extract/ENIGMA_ROI_part1
   dirO1=${parentDirectory}/roi_extract/ENIGMA_ROI_part1
 
   mkdir -p ${parentDirectory}/roi_extract/ENIGMA_ROI_part2
   dirO2=${parentDirectory}/roi_extract/ENIGMA_ROI_part2
 
   for subject in ${subjects[@]}
   do

    if [ -f ${parentDirectory}/${DIFF}_individ/${subject}/stats/${subject}_masked_${DIFF}skel.nii.gz ]; then
    ${ROIextraction}/singleSubjROI_exe ${ROIextraction}/ENIGMA_look_up_table.txt ${ROIextraction}/mean_FA_skeleton.nii.gz ${ROIextraction}/JHU-WhiteMatter-labels-1mm.nii.gz ${dirO1}/${subject}_${DIFF}_ROIout ${parentDirectory}/${DIFF}_individ/${subject}/stats/${subject}_masked_${DIFF}skel.nii.gz
    fi
    
    if [ -f ${dirO1}/${subject}_${DIFF}_ROIout.csv ]; then
    ${ROIextraction}/averageSubjectTracts_exe ${dirO1}/${subject}_${DIFF}_ROIout.csv ${dirO2}/${subject}_${DIFF}_ROIout_avg.csv
    fi
   
   # can create subject list here for part 3!
   echo ${subject},${dirO2}/${subject}_${DIFF}_ROIout_avg.csv >> ${parentDirectory}/${DIFF}_individ/subjectList_${DIFF}.csv

   done
 
   dos2unix ${demographics}

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

    elif [ "$qsub" == "1" ]; then

    echo $FSLDIR

    count=$(cat $subject_list| wc -w)

    cd $parentDirectory
    mkdir FA
    mkdir origdata
    
    qsub -t 1-$count ${ENIGMA_files}/scripts/script_1.sh ${subject_list} ${dtifit_folder} ${parentDirectory}

    qsub -hold_jid "script_1" ${ENIGMA_files}/scripts/script_2.sh ${parentDirectory}

    qsub -hold_jid "script_2" -t 1-$count ${ENIGMA_files}/scripts/script_3.sh ${subject_list} ${parentDirectory} ${ENIGMA_files} ${dtifit_folder}

    sleep 20s
    cd $parentDirectory
    until [ -f script_3.o*.1 ]
    do
     sleep 20s
    done

    printf "\ntbss_1_preproc is now complete (feel free to QC the FA/slicesdir/index.html). Image registrations have now been qsubbed. To ensure that all registrations are done before moving on to subsequent steps, you will be prompted that *_to_ENIGMA.nii.gz files cannot be found. This is normal and will continue until all subjects are finished.\n\n"

    cd $parentDirectory/FA
    for subj in ${subjects[@]}; do
        t2r_inputs=(`ls ${subj}_dti_FA_FA.nii.gz`)
        t2r_outputs=(`ls ${subj}_dti_FA_FA_to_ENIGMA.nii.gz`)
        while [[ ${#t2r_inputs[@]} != ${#t2r_outputs[@]} ]]; do
        sleep 30s
        t2r_outputs=(`ls ${subj}_dti_FA_FA_to_ENIGMA.nii.gz`)
        echo "waiting for warps to finish..."
        done
    done &
    wait $!

    #fslmerge -t all_FA_for_QC `$FSLDIR/bin/imglob *_FA_to_ENIGMA.*` &
    #wait $!

    cd $parentDirectory
    mkdir logs
    mv script* logs/. &
    wait $!

    printf "\nPart 1 complete! QC images and move to a separate folder if you want to exclude. Once complete, run the same command except now with -q 2"

    elif [ "$qsub" == "2" ]; then
    
    for DIFF in FA MD AD RD
    do
    mkdir -p ${parentDirectory}/roi_extract/ENIGMA_ROI_part1
    mkdir -p ${parentDirectory}/roi_extract/ENIGMA_ROI_part2
    done &

    wait $!
    
    count=$(cat $subject_list | wc -w)

    qsub -t 1-$count ${ENIGMA_files}/scripts/script_4.sh ${parentDirectory} ${subject_list} ${ROIextraction}

    qsub -hold_jid "script_4" ${ENIGMA_files}/scripts/script_5.sh ${parentDirectory} ${subject_list} ${ROIextraction} ${demographics} ${r_binary}

    printf "\nThe ROI extraction script has been qsubbed. Once complete, please check any outputs in the  'roi_extract' folder. For troubleshooting, logs can be found in the 'logs' folder\n"
    fi