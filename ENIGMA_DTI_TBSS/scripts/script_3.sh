#!/bin/bash
#$ -cwd
#$ -j y
#$ -N script_3

export subject_list="$1"
export parentDirectory="$2"
export ENIGMA_files="$3"
export dtifit_folder="$4"

SUBJECT=(`cat ${subject_list}`)
SUBJ_ID=${SUBJECT[${SGE_TASK_ID}-1]}

echo $FSLDIR


cd $parentDirectory/FA

touch ${SUBJ_ID}_dti_FA_FA_to_ENIGMA_warp.msf
$FSLDIR/bin/fsl_reg ${SUBJ_ID}_dti_FA_FA.nii.gz ${ENIGMA_files}/ENIGMA_DTI_FA.nii.gz ${SUBJ_ID}_dti_FA_FA_to_ENIGMA -e -FA

# wait until tbss_2_reg is finished before moving to step 3    
t2r_inputs=(`ls ${SUBJ_ID}_dti_FA_FA.nii.gz`)
t2r_outputs=(`ls ${SUBJ_ID}_dti_FA_FA_to_ENIGMA_warp.nii.gz`)
while [[ ${#t2r_inputs[@]} != ${#t2r_outputs[@]} ]]; do
    sleep 30s
    t2r_outputs=(`ls ${SUBJ_ID}_dti_FA_FA_to_ENIGMA_warp.nii.gz`)
    echo "waiting for warps to finish..."
done

$FSLDIR/bin/applywarp -i ${SUBJ_ID}_dti_FA_FA.nii.gz -o ${SUBJ_ID}_dti_FA_FA_to_ENIGMA -r ${ENIGMA_files}/ENIGMA_DTI_FA.nii.gz -w ${SUBJ_ID}_dti_FA_FA_to_ENIGMA_warp --rel

cd $parentDirectory

for DIFF in FA MD AD RD; do

    # make individual metric directories
    mkdir -p ${DIFF}_individ/${SUBJ_ID}/${DIFF}/
    mkdir -p ${DIFF}_individ/${SUBJ_ID}/stats/
    
    if [ "$DIFF" == "FA" ]; then

        # copy FA images to the individual folders
        cp ./FA/${SUBJ_ID}_*.nii.gz ./FA_individ/${SUBJ_ID}/FA/

        # mask FA image
        $FSLDIR/bin/fslmaths ./FA_individ/${SUBJ_ID}/FA/${SUBJ_ID}_*FA_to_ENIGMA.nii.gz -mas ${ENIGMA_files}/ENIGMA_DTI_FA_mask.nii.gz ./FA_individ/${SUBJ_ID}/FA/${SUBJ_ID}_masked_FA.nii.gz

        # skeletonize
        $FSLDIR/bin/tbss_skeleton -i ./FA_individ/${SUBJ_ID}/FA/${SUBJ_ID}_masked_FA.nii.gz -p 0.049 ${ENIGMA_files}/ENIGMA_DTI_FA_skeleton_mask_dst ${FSLDIR}/data/standard/LowerCingulum_1mm.nii.gz ./FA_individ/${SUBJ_ID}/FA/${SUBJ_ID}_masked_FA.nii.gz ./FA_individ/${SUBJ_ID}/stats/${SUBJ_ID}_masked_FAskel.nii.gz -s ${ENIGMA_files}/ENIGMA_DTI_FA_skeleton_mask.nii.gz

    else

        mkdir -p ${DIFF}/origdata/

        if [ "$DIFF" == "MD" ]; then

            # copy MD images to the individual folders
            cp ${dtifit_folder}/${SUBJ_ID}/*_MD.nii.gz ${parentDirectory}/MD/${SUBJ_ID}_MD.nii.gz

            elif [ "$DIFF" == "AD" ]; then

                # copy AD images to the individual folders
                cp ${dtifit_folder}/${SUBJ_ID}/*_L1.nii.gz ${parentDirectory}/AD/${SUBJ_ID}_AD.nii.gz

            elif [ "$DIFF" == "RD" ]; then

                # make RD image and copy to the individual folders
                $FSLDIR/bin/fslmaths ${dtifit_folder}/${SUBJ_ID}/*_L2.nii.gz -add ${dtifit_folder}/${SUBJ_ID}/*_L3.nii.gz -div 2 ${parentDirectory}/RD/${SUBJ_ID}_RD.nii.gz
        fi
            
         # mask metric images  
        $FSLDIR/bin/fslmaths ${parentDirectory}/${DIFF}/${SUBJ_ID}_${DIFF}.nii.gz -mas ${parentDirectory}/FA/${SUBJ_ID}*_FA_mask.nii.gz ${parentDirectory}/${DIFF}_individ/${SUBJ_ID}/${DIFF}/${SUBJ_ID}_${DIFF}
 
        # move unmasked to origdata folder
        $FSLDIR/bin/immv ${parentDirectory}/${DIFF}/${SUBJ_ID}_${DIFF} ${parentDirectory}/${DIFF}/origdata/
 
        # apply FA_TO_ENIGMA warp to metric images
        $FSLDIR/bin/applywarp -i ${parentDirectory}/${DIFF}_individ/${SUBJ_ID}/${DIFF}/${SUBJ_ID}_${DIFF} -o ${parentDirectory}/${DIFF}_individ/${SUBJ_ID}/${DIFF}/${SUBJ_ID}_${DIFF}_to_ENIGMA -r $FSLDIR/data/standard/FMRIB58_FA_1mm -w ${parentDirectory}/FA/${SUBJ_ID}*_FA_to_ENIGMA_warp.nii.gz
 
        # mask metric warped images
        $FSLDIR/bin/fslmaths ${parentDirectory}/${DIFF}_individ/${SUBJ_ID}/${DIFF}/${SUBJ_ID}_${DIFF}_to_ENIGMA -mas ${ENIGMA_files}/ENIGMA_DTI_FA_mask.nii.gz ${parentDirectory}/${DIFF}_individ/${SUBJ_ID}/${DIFF}/${SUBJ_ID}_masked_${DIFF}.nii.gz	
 
        # skeletonize metric images
        $FSLDIR/bin/tbss_skeleton -i ./FA_individ/${SUBJ_ID}/FA/${SUBJ_ID}_masked_FA.nii.gz -p 0.049 ${ENIGMA_files}/ENIGMA_DTI_FA_skeleton_mask_dst.nii.gz $FSLDIR/data/standard/LowerCingulum_1mm.nii.gz ${parentDirectory}/FA_individ/${SUBJ_ID}/FA/${SUBJ_ID}_masked_FA.nii.gz ${parentDirectory}/${DIFF}_individ/${SUBJ_ID}/stats/${SUBJ_ID}_masked_${DIFF}skel -a ${parentDirectory}/${DIFF}_individ/${SUBJ_ID}/${DIFF}/${SUBJ_ID}_masked_${DIFF}.nii.gz -s ${ENIGMA_files}/ENIGMA_DTI_FA_skeleton_mask.nii.gz

	fi
    done

