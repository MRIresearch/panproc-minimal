# panproc-minimal
Docker recipe for creating container to support PAN processing pipelines

## build/download instructions
Container can be built using the helper script `builddocker.sh` or directly as `docker build -t [image_name] ./` where `image_name` is your supplied name. The image `aacazxnat/panproc-minimal:[VER]` can also be pulled from docker hub as follows `docker pull aacazxnat/pancproc-minimal:0.1` for example.

# Additional notes
* Please register at FSL https://fsl.fmrib.ox.ac.uk/fsldownloads_registration for permission to download and use the FSL software which is bundled in this container.
* Please obtain a license from Freesurfer at https://fsl.fmrib.ox.ac.uk/fsldownloads_registration for a `license.txt` which you will need to place in the `src` folder if you decide to build your own image using this `Dockerfile` as a template.


