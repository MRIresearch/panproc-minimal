#!/bin/bash
date=`date +%m/%d/%Y`
IMVER=0.1
CONTAINER="panproc-apps"

echo "${CONTAINER}" > ./src/version
echo "version ${IMVER}" >> ./src/version
echo "built on $date" >> ./src/version
echo "${CONTAINER} v${IMVER} build: ${date}" > ./src/readme

echo -e "\n\nContainer for running PAN apps associated with panpipelines:"\
        "\n------------------------------------------------------------------------------"\
        "\n\t* amico 2.1.0"\
        "\n\t* mne 1.1.0" >> ./src/readme

echo -e "\n\nReferences" \
        "\n-----------------" \
        "\n\t* Github: https://github.com/MRIresearch/panproc-apps" >> ./src/readme

docker build -t aacazxnat/${CONTAINER}:${IMVER} .
docker push aacazxnat/${CONTAINER}:${IMVER}
