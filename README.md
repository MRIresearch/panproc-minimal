# panproc-minimal
Docker recipe for creating container to support PAN processing pipelines

## build/download instructions
Container can be built using the helper script `builddocker.sh` or directly as `docker build -t [image_name] ./` where `image_name` is your supplied name. The image `aacazxnat/panproc-minimal:[VER]` can also be pulled from docker hub as follows `docker pull aacazxnat/pancproc-minimal:0.1` for example.

# Additional notes
* Please register at FSL https://fsl.fmrib.ox.ac.uk/fsldownloads_registration for permission to download and use the FSL software which is bundled in this container.
* Please obtain a license from Freesurfer at https://fsl.fmrib.ox.ac.uk/fsldownloads_registration for a `license.txt` which you will need to place in the `src` folder if you decide to build your own image using this `Dockerfile` as a template.


## startup
When running the docker container normally or performing `singularity run`, the statup script /opt/bin/startup.sh is called which passes on commands to the container while performing some pre-run functions. Additional flags can be passed before the commands you want to run to change behavior in the container. Most importantly FSL and FREESURFER environments are sourced to enable full functionality of these tools but these applications make changes to the $PATH and $LD_LIBRARY_PATH environmental variables as well as setting other variables. To run the containr without sourcing these applications then pass in --xfsl and --xfree to bypass environment configuration by FSL and FREESURFER respectively. Also note that MRTRIX gui libraries are currently clashing with Freeview's libraries thus to run mrview use the --mrmode flag.

Example of running container without sourcing FSL or FREESURFER and invoking mrmode so that mrview can be opened.

```
docker run --rm -it aacazxnat/panproc-minimal:0.1 --xfsl --xfree --mrmode mrview

```
```
singularity run panproc-minimal.sif --xfsl --xfree --mrmode mrview

```

Options are shown below:

```
--log                  verbose log of what is happening during startup
--help                 show readme file
--version              show container version 
--workdir=WORKDIR      make WORKDIR inside the container the current directory
--home                 set the home directory within the container to /home/aacazxnat to circumvent use of OS $HOME
--xfsl                 Do not source FSL environment
--xfree                Do not source FREESURFER environment
--mrmode               Fix qt5 library conflict so that mrview can open
--pathpriority=PRIPATH Make PRIPATH the first path in $PRIPATH:$PATH
--libpriority=PRIPATH  Make PRIPATH the first path in $PRIPATH:$LD_LIBRARY_PATH
--retrieve=$TARGET     cp $TARGET (directory or file) to current directory (set using --workdir)
--sourcepre=$SOURCE    source $SOURCE before FSL and FREESURFER ($SOURCE is referenced inside container so use -v or -B to bind to OS location)
--sourcepre=$SOURCE    source $SOURCE after FSL and FREESURFER ($SOURCE is referenced inside container so use -v or -B to bind to OS location)
