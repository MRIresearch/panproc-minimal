#!/bin/bash
date=`date +%m/%d/%Y`
IMVER=0.3
CONTAINER="panproc-minimal"

echo "${CONTAINER}" > ./src/version
echo "version ${IMVER}" >> ./src/version
echo "built on $date" >> ./src/version
echo "${CONTAINER} v${IMVER} build: ${date}" > ./src/readme

echo -e "\n\nContainer for PAN pipeline with applications:"\
        "\n------------------------------------------------------------------------------"\
        "\n\t* FSL 6.0.7.16"\
        "\n\t* Mrtrix3 v3.0.4"\
        "\n\t* Freesurfer 7.3.2 with known issues patched (See Additional Notes)"\
        "\n\t* ANTS v2.5.0"\
        "\n\t* ITKSnap v4.2.2"\
        "\n\t* HCP Workbench (wb_view and wb_command) v1.5.0" >> ./src/readme


echo -e "\n\nAdditional Notes:"\
        "\n-----------------"\
        "\n\t* Run all GUI-based apps e.g mrview, fsl, freeview, fsleyes with LD_LIBRARY_PATH={empty string}' "\
        "\n\t  because of library clashes"\
        "\n\t* Freesurfer 7.3.2 has required patches applied for known issues. If performing Pial surface placement "\
        "\n\t  with FLAIR images then obtain global-expert-options.txt from within folder at /subjects_dir">> ./src/readme


echo -e "\n\nReferences" \
        "\n-----------------" \
        "\n\t* Github: https://github.com/MRIresearch/panproc-minimal" >> ./src/readme


docker build -t aacazxnat/${CONTAINER}:${IMVER} .
docker push aacazxnat/${CONTAINER}:${IMVER}
