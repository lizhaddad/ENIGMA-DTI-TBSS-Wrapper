# ENIGMA-DTI TBSS Pipeline Wrapper
Elizabeth Haddad, Neda Jahanshad\
elizabeth.haddad@loni.usc.edu, neda.jahanshad@ini.usc.edu

**This wrapper provides an all-in-one inclusive script, with an option for qsub systems, to run the original [ENIGMA-DTI Pipeline](https://github.com/ENIGMA-git/ENIGMA_DTI_04_DTI_TBSS) including the following 3 protocols:**

&nbsp;&nbsp;&nbsp;&nbsp; 1. TBSS analysis using the ENIGMA-DTI template ([:octocat:](https://github.com/ENIGMA-git/ENIGMA_DTI_04_DTI_TBSS/blob/master/README.md#protocol-for-tbss-analysis-using-the-enigma-dti-template))\
&nbsp;&nbsp;&nbsp;&nbsp; 2. ROI analysis using the ENIGMA-DTI template ([:octocat:](https://github.com/ENIGMA-git/ENIGMA_DTI_04_DTI_TBSS/blob/master/README.md#protocol-for-roi-analysis-using-the-enigma-dti-template))\
&nbsp;&nbsp;&nbsp;&nbsp; 3. Applying FA skeletonizations/ROI analysis to diffusivity measures using the ENIGMA-DTI template ([:octocat:](https://github.com/ENIGMA-git/ENIGMA_DTI_04_DTI_TBSS/blob/master/README.md#protocol-for-applying-tbss-skeletonizations-from-fa-analysis-to-diffusivity-and-obtaining-roi-measures-using-the-enigma-dti-template))

&nbsp;&nbsp;&nbsp;&nbsp; **_Originally authored by:_**\
&nbsp;&nbsp;&nbsp;&nbsp;_Neda Jahanshad, Emma Sprooten, Rene Mandl, Peter Kochunov_
<br>

## Set up

First, let's get setup. To run this pipeline, we assume you have preprocessed and QC'ed your data and have run DTIFIT on your data.

The following pages may be helpful before running this pipeline:
    
&nbsp;&nbsp;&nbsp;&nbsp; 1. ENIGMA_DTI_01_Preprocessing ([:octocat:](https://github.com/ENIGMA-git/ENIGMA_DTI_01_Preprocessing))\
&nbsp;&nbsp;&nbsp;&nbsp; 2. ENIGMA_DTI_02_EPI_Correction ([:octocat:](https://github.com/ENIGMA-git/ENIGMA_DTI_02_EPI_Correction))\
&nbsp;&nbsp;&nbsp;&nbsp; 3. ENIGMA_DTI_03_Quality_Control ([:octocat:](https://github.com/ENIGMA-git/ENIGMA_DTI_03_Quality_Control))

We also assume that your FSL installation can be found under the following alias: `$FSLDIR`.

## Running the script

    ./ENIGMA_DTI_TBSS_pipeline.sh --help
    This script runs the ENIGMA-DTI TBSS pipeline for you.

    Usage: ENIGMA_DTI_TBSS_pipeline.sh 
                -e  full path to ENIGMA_DTI_TBSS folder 
                -o  full path to where to run this pipeline 
                -d  full path to dtifit subject folders 
                -s  full path to subject list text file 
                -i  full path to subject info (demographics) text or csv file 
                -r  full path to R binary 
                -q  [optional; only for qsub use] 1=stops after registrations for user QC; 2=resumes script after QC

The script registers and skeletonizes your FA images to the DTI atlas being used for ENIGMA-DTI for tract-based spatial statistics (TBSS; Smith et al., 2006). It also conducts ROI analysis for FA and all other diffisivity measures (MD,AD,RD).

It will pause after performing tbss steps 1 & 2 and allow you to quality control (QC) your data. If you are not running on a sun grid engine (SGE), within the command-line, you will be prompted that the script is paused for QC. At this point, it is advised that you QC and move any subjects that haven't passed QC to another folder. Pressing any key will then allow the script to continue with the subsequent steps. 

If you are using a SGE task system, you will be able to run this script twice. With the `-q 1` flag, this script will complete tbss steps 1 & 2. Once successfully run, the user will be able to QC their data and move any subjects that haven't passed to another folder. By then running the same initial command, but this time with `-q 2`, the script will continue and finish the subsequent steps. 

**TODO**: Coming soon, a QC script will be added to this wrapper that will accomodate both small batches of data and larger ones. For now, one can still view the slicedir folder from tbss step 1, and use [existing QC scripts](https://enigma.ini.usc.edu/wp-content/uploads/DTI_Protocols/ENIGMA_FA_Skel_QC_protocol_USC.pdf) to view post-registration images. 

<br>

Below is information about the required flags

### `-e`: path to the ENIGMA_DTI_TBSS folder

This is the **full path** to where you've downloaded the [ENIGMA_DTI_TBSS](ENIGMA_DTI_TBSS) folder located in this repository.

Example:\
&nbsp;`/Users/liz/ENIGMA/ENIGMA_DTI_TBSS`


### `-o`: path to output folder

This is the **full path** path to where you want the output of this pipeline to write to.

Example:\
&nbsp;`/Users/liz/ENIGMA/my_ENIGMA_DTI_analysis/run_tbss`


### `-d`: path to DTIFIT subject folders

This is the **full path** to where the DTIFIT outputs are located.

Example:\
&nbsp;`/Users/liz/ENIGMA/my_ENIGMA_DTI_analysis/DTIFIT_folders`

#### DTIFIT folder setup

This pipeline requires your DTIFIT data to be formatted in the following way:


 ```
└── ${DTIFIT_folders}                      # folder with all DTIFIT output (input for the -d flag)
     ├── ${subjectID_1}                     # folders named as the subjectID (these will be listed in a text file for the input -s flag)
     │    ├── ${subjectID_1}_dti_FA.nii.gz  # DTIFIT maps prefixed with the subject ID
     │    ├── ${subjectID_1}_dti_MD.nii.gz
     │    ├── ${subjectID_1}_dti_L1.nii.gz
     │    ├── ${subjectID_1}_dti_L2.nii.gz
     │    └── ${subjectID_1}_dti_L3.nii.gz
     ├── ${subjectID_2}
     │    ├── ${subjectID_2}_dti_FA.nii.gz
     │    ├── ${subjectID_2}_dti_MD.nii.gz
     │    ├── ${subjectID_2}_dti_L1.nii.gz
     │    ├── ${subjectID_2}_dti_L2.nii.gz
     │    └── ${subjectID_2}_dti_L3.nii.gz
     └── ${subjectID_n}
          ├── ...
          └── ...
 ```

_**Note**: it's ok to have other files in each subject's folders (ex: M0,V1,V2,V2), it won't affect the pipeline_

If you have already run your data through DTIFIT and it is formatted in a different way, you can also create the above file structure using [**softlinks**](https://linuxhandbook.com/symbolic-link-linux/).

Information on how to run DTIFIT can be found [**here**](https://web.mit.edu/fsl_v5.0.10/fsl/doc/wiki/FDT(2f)UserGuide.html#DTIFIT).


### `-s`: path to subject text file 

This is the **full path** to a text file (.txt) with the subject IDs

**NOTE**: these should be the same name as the folders located in the DTIFIT folder `-d`.

An example is provided below, let's call it `subjectIDs_list.txt`

    subjectID_1
    subjectID_2
    ...
    ...
    ...
    subjectID_n



### `-i`: path to the demographics text file

This is the **full path**  to a tab-delimited text file, or a .csv with the subject information (demographics). This file will be merged to the final summary statistics derived from this protocol. 

Below is an example:

     
   |  subjectID    |   Age     | Diagnosis  |   Sex   |   ...   |
   | ------------- |:---------:|-----------:|:-------:|:-------:|
   |    USC_01     |    23     |      1     |    1    |   ...   |
   |    USC_02     |    45     |      1     |    2    |   ...   |
   |    USC_03     |    56     |      1     |    1    |   ...   | 
   |    USC_04     |    27     |      1     |    1    |   ...   |
   |    USC_05     |    21     |      1     |    1    |   ...   |
   |    USC_06     |    44     |      2     |    2    |   ...   |
   |    USC_07     |    35     |      1     |    1    |   ...   |
   |    USC_08     |    31     |      1     |    2    |   ...   |
   |    USC_09     |    50     |      1     |    1    |   ...   |
   |    USC_10     |    29     |      1     |    2    |   ...   |
   

:warning: **IMPORTANT NOTE**: Please make sure your subject column is named **subjectID**. :warning:


### `-r`: path to R binary

This pipeline makes use of R to merge the final tables together. Please make sure R is installed and provide the **full path** to the binary as such

Example:\
&nbsp;`/usr/local/R/bin/R`

<br>

## Example Usage

Using the example paths above, the wrapper would be run as such:

```
DIR=/Users/liz/ENIGMA 

${DIR}/ENIGMA_DTI_TBSS_pipeline.sh \
    -e ${DIR}/ENIGMA_DTI_TBSS \
    -o ${DIR}/my_ENIGMA_DTI_analysis/run_tbss \
    -d ${DIR}/my_ENIGMA_DTI_analysis/DTIFIT_folders \
    -s ${DIR}/my_ENIGMA_DTI_analysis/subjectIDs_list.txt \
    -i ${DIR}/my_ENIGMA_DTI_analysis/subject_demographics.txt \
    -r /usr/local/R/bin/R 
```


### `-q`: qsub system option (optional)

This flag is intended for SGE task systems. As noted above, with the `-q 1` flag, this script will complete tbss steps 1 & 2. Once successfully run, the user will be able to QC their data and move any subjects that haven't passed to another folder. By then running the same initial command, but this time with `-q 2`, the script will continue and finish the subsequent steps. 

Example run (pre-QC)

```
DIR=/Users/liz/ENIGMA 

${DIR}/ENIGMA_DTI_TBSS_pipeline.sh \
    -e ${DIR}/ENIGMA_DTI_TBSS \
    -o ${DIR}/my_ENIGMA_DTI_analysis/run_tbss \
    -d ${DIR}/my_ENIGMA_DTI_analysis/DTIFIT_folders \
    -s ${DIR}/my_ENIGMA_DTI_analysis/subjectIDs_list.txt \
    -i ${DIR}/my_ENIGMA_DTI_analysis/subject_demographics.txt \
    -r /usr/local/R/bin/R \
    -q 1
```


Example run (post-QC)
```
${DIR}/ENIGMA_DTI_TBSS_pipeline.sh \
    -e ${DIR}/ENIGMA_DTI_TBSS \
    -o ${DIR}/my_ENIGMA_DTI_analysis/run_tbss \
    -d ${DIR}/my_ENIGMA_DTI_analysis/DTIFIT_folders \
    -s ${DIR}/my_ENIGMA_DTI_analysis/subjectIDs_list.txt \
    -i ${DIR}/my_ENIGMA_DTI_analysis/subject_demographics.txt \
    -r /usr/local/R/bin/R \
    -q 2
```

Note the only part of the command that has changed is the `-q` flag option


<br>

#### That's it! Now you should have all of your subjects ROIs in one spreadsheet for each diffusivity measure with relevant covariates ready for association testing!

 ![picture](images/enigma_tbss.png)










 
