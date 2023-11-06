#!/bin/bash
date=`date +%m/%d/%Y`
IMVER=0.1
CONTAINER="panproc-minimal"

echo "${CONTAINER}" > ./src/version
echo "version ${IMVER}" >> ./src/version
echo "built on $date" >> ./src/version
echo "${CONTAINER} v${IMVER} build: ${date}" > ./src/readme

echo -e "\n\nContainer for PAN pipeline processing using CUDA Toolkit 9.1 with applications:"\
        "\n------------------------------------------------------------------------------"\
        "\n\t* FSL 6.0.7.4"\
        "\n\t* Mrtrix3 v3.0.4"\
        "\n\t* Freesurfer 7.1.1"\
        "\n\t* HCP Workbench (wb_view and wb_command) v1.5.0"\
        "\n\t* ANTS v2.5.0" >> ./src/readme

echo -e "\n\nAdditional Notes:"\
        "\n-----------------"\
        "\n\t* Run mrview as follows 'docker run aacazxnat/panproctools --libpriority=/opt/fsl/lib mrview' "\
        "because of qt library clash with freeview"  >> ./src/readme


echo -e "\n\nReferences" \
        "\n-----------------" \
        "\n\t* Github: https://github.com/MRIresearch/panproc-minimal" >> ./src/readme


docker build -t aacazxnat/${CONTAINER}:${IMVER} .
docker push aacazxnat/${CONTAINER}:${IMVER}
