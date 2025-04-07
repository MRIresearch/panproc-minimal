FROM ubuntu:focal-20210416
MAINTAINER Chidi Ugonna<chidiugonna@arizona.edu>

ENV DEBIAN_FRONTEND noninteractive


##########################
# CREATE BIND and CUSTOM FOLDERS
###########################
RUN mkdir -p /xdisk /groups /opt/data /opt/bin /opt/tmp /opt/work /opt/input /opt/output /opt/config /opt/ohpc /cm/shared /cm/local &&\ 
    mkdir -p /input /output /work /subjects_dir /rental

##########################
# BASE PACKAGES and LOCALE
###########################

RUN apt update && \
    apt install -y nano \
	               apt-utils \
	               wget \
	               curl \
                   dc \
	               lsb-core \
                   unzip \
                   git \
                   locales

ENV TZ=America/Phoenix
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone
ENV LC_CTYPE="en_US.UTF-8"  
ENV LC_ALL="en_US.UTF-8"
ENV LANG="en_US.UTF-8"
ENV LANGUAGE=en_US.UTF-8
RUN echo "LC_ALL=en_US.UTF-8" >> /etc/environment
RUN echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen
RUN echo "LANG=en_US.UTF-8" > /etc/locale.conf
RUN locale-gen en_US.UTF-8
RUN export LC_ALL=en_US.UTF-8


############################
# MINICONDA and Python
############################
WORKDIR /opt/tmp
ENV MINICONDA_HOME=/opt/miniconda
ENV PATH=${MINICONDA_HOME}/bin:${PATH}

RUN wget https://repo.anaconda.com/miniconda/Miniconda3-py310_23.9.0-0-Linux-x86_64.sh && \
    chmod +x Miniconda3-py310_23.9.0-0-Linux-x86_64.sh && \
    /bin/bash ./Miniconda3-py310_23.9.0-0-Linux-x86_64.sh -b -p ${MINICONDA_HOME} -f && \
    conda install -y pip

#################################################################################
# FSL 6.0.7.16
#
# To install FSL versions < 6.0.6 then use fslinstaller_old.py or grab from cloud
#  wget https://fsl.fmrib.ox.ac.uk/fsldownloads/fslinstaller.py
#################################################################################
WORKDIR /opt/tmp
RUN apt  install -y  freeglut3 \
                        libfontconfig1 \
                        libxrender1

ENV FSLVER="6.0.7.16"
ENV FSLDIR=/opt/fsl

RUN wget https://fsl.fmrib.ox.ac.uk/fsldownloads/fslconda/releases/fslinstaller.py
RUN python /opt/tmp/fslinstaller.py -q -d $FSLDIR -V $FSLVER

#change from sh to bash in randomize_parallel
RUN  cp /opt/fsl/bin/randomise_parallel /opt/fsl/bin/old_randomise_parallel && \
     sed -i "s^bin/sh^bin/bash^g" /opt/fsl/bin/randomise_parallel

ENV LD_LIBRARY_PATH=$FSLDIR/lib:$LD_LIBRARY_PATH
ENV PATH=$FSLDIR/share/fsl/bin:$PATH
ENV FSLOUTPUTTYPE=NIFTI_GZ


###############################
# Install X11 libraries
#
###############################
RUN apt install -y libx11-dev \
                libxft2


##################################################
#  Issues faced with git clone
#
##################################################
RUN apt install ca-certificates && \
        update-ca-certificates

#########################
# MRTRIX 3.0.4
#########################
WORKDIR /opt
ENV PATH=/opt/mrtrix3/bin:$PATH

RUN apt install -y dc \
        libqt5opengl5-dev \
        libqt5svg5-dev \
        libtiff5-dev \
        git \
        g++ \
        libeigen3-dev \
        zlib1g-dev \
        libgl1-mesa-dev \
        libfftw3-dev \
        libpng-dev

RUN git clone https://github.com/MRtrix3/mrtrix3.git && \
    cd /opt/mrtrix3  && \
    git checkout 3.0.4 && \
    ./configure && \
    ./build


############################
# FREESURFER 7.3.2
###########################
WORKDIR /opt
ENV LD_LIBRARY_PATH=/opt/freesurfer/lib/qt/lib:/opt/freesurfer/mni/lib:${LD_LIBRARY_PATH}
ENV FSL_DIR=${FSLDIR}
RUN apt update && \
    apt  install -y  tcsh \
                        libxmu6 \
                        libglu1-mesa 


ENV FREESURFER_HOME=/opt/freesurfer
ENV FS_LICENSE=${FREESURFER_HOME}/license.txt
ENV PATH=$FREESURFER_HOME/bin:$FREESURFER_HOME/mni/bin:$FREESURFER_HOME/tktools:$PATH

RUN wget https://surfer.nmr.mgh.harvard.edu/pub/dist/freesurfer/7.3.2/freesurfer-linux-ubuntu20_amd64-7.3.2.tar.gz && \
    tar xz -f freesurfer-linux-ubuntu20_amd64-7.3.2.tar.gz && \
    rm /opt/freesurfer-linux-ubuntu20_amd64-7.3.2.tar.gz 

# create symbolic link as tkregister not provided in Freesurfer 7.1.1
RUN ln -s /opt/freesurfer/tktools/tkregister2.tcl /opt/freesurfer/tktools/tkregister.tcl && \
    ln -s /opt/freesurfer/bin/tkregister2 /opt/freesurfer/bin/tkregister

# Freesurfer 7.3.2 Patch
ENV FREESURFER=${FREESURFER_HOME}
RUN  wget https://surfer.nmr.mgh.harvard.edu/pub/dist/freesurfer/7.3.2-patch/mri_sclimbic/mri_sclimbic_seg && \
     mv mri_sclimbic_seg $FREESURFER/python/scripts/mri_sclimbic_seg && \
     chmod +x $FREESURFER/python/scripts/mri_sclimbic_seg && \
     wget https://surfer.nmr.mgh.harvard.edu/pub/dist/freesurfer/7.3.2-patch/segment_subregions/core.py && \
     mv core.py $FREESURFER/python/packages/freesurfer/subregions && \
     wget https://surfer.nmr.mgh.harvard.edu/pub/dist/freesurfer/7.3.2-patch/synthsr/mri_synthsr && \
     mv mri_synthsr $FREESURFER_HOME/python/scripts/mri_synthsr && \
     echo "PlaceMMPialSurf --mm_min_inside 50 --mm_max_inside 200 --mm_min_outside 10 --mm_max_outside 5" > /subjects_dir/global-expert-options.txt


# install correct mcr for freesurfer subregion segmentation
RUN fs_install_mcr R2019b



##########################
# cmake for ANTS install
#########################
RUN apt install -y libcurl4-openssl-dev \
                   libssl-dev

RUN cd /opt/tmp && \ 
    wget https://github.com/Kitware/CMake/releases/download/v3.18.1/cmake-3.18.1.tar.gz && \ 
    tar xz -f cmake-3.18.1.tar.gz && \ 
    rm cmake-3.18.1.tar.gz && \ 
    cd cmake-3.18.1 && \ 
    ./configure && \ 
    make && \ 
    make install && \ 
    ./bootstrap --prefix=/usr && \     
    make && \ 
    make install

####################################
# ANTS
###################################
RUN mkdir /opt/ANTScode && \ 
    cd /opt/ANTScode && \ 
    git clone https://github.com/ANTsX/ANTs.git && \ 
    cd ANTs && \ 
    git checkout -f tags/v2.5.0 && \ 
    mkdir /opt/ANTScode/bin && \ 
    cd /opt/ANTScode/bin && \ 
    cmake /opt/ANTScode/ANTs && \ 
    make  && \ 
    cd /opt/ANTScode/bin/ANTS-build && \ 
    make install && \ 
    ln -sf /usr/lib/ants/N4BiasFieldCorrection /usr/local/bin/

ENV ANTSPATH=/opt/ANTs/bin
ENV PATH=/opt/ANTScode/ANTs/Scripts:$ANTSPATH:$PATH
ENV ITK_GLOBAL_DEFAULT_NUMBER_OF_THREADS=4
ENV LD_LIBRARY_PATH=/opt/ANTs/lib:$LD_LIBRARY_PATH


############################################################################################
#
# HCP Workbench
# 
###########################################################################################

RUN cd /opt && \
    wget https://www.humanconnectome.org/storage/app/media/workbench/workbench-linux64-v1.5.0.zip && \
    unzip workbench-linux64-v1.5.0.zip && \
    rm workbench-linux64-v1.5.0.zip

ENV PATH=/opt/workbench/bin_linux64:$PATH


#############################
# Core Python Libraries
##############################
# make miniconda the first environment for python library consistency
ENV PATH=${MINICONDA_HOME}/bin:${PATH}
RUN pip install nipype==1.8.6 \
                nibabel==5.2.0 \
                numpy==1.26.3 \
                scipy==1.11.4 \ 
                pydicom==2.4.4 \
                pybids==0.16.4 \
                pandas==2.1.4 \
                nilearn==0.10.2 \
                nitransforms==23.0.1 \
                templateflow==23.1.0 \
                xnat==0.5.3 \
                matplotlib==3.8.1 \
                sdcflows==2.8.1 \
                mne[hdf5]==1.1.0 \
                vtk==9.3.0 \
                pyvista==0.43.4

###############################
# Install latest panpipelines
# 
################################
RUN pip install panpipelines==1.0.9

############################
# HOME DIRECTORY
###########################

# Replace 1000 with your user / group id
RUN export uid=1000 gid=1000 && \
    mkdir -p /home/aacazxnat && \
    mkdir -p /etc/sudoers.d && \
    echo "aacazxnat:x:${uid}:${gid}:aacazxnat,,,:/home/aacazxnat:/bin/bash" >> /etc/passwd && \
    echo "aacazxnat:x:${uid}:" >> /etc/group && \
    echo "aacazxnat ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/aacazxnat && \
    chmod 0440 /etc/sudoers.d/aacazxnat && \
    chown ${uid}:${gid} -R /home/aacazxnat

ENV HOME="/home/aacazxnat"
ENV USER=aacazxnat

RUN mkdir -p /home/aacazxnat/matlab

##################################
#  install itk and c3d
#
##################################

COPY ./src/itksnap-4.2.2-20241202-Linux-x86_64.tar.gz /
RUN mkdir /opt/itksnap &&\
    cd /opt/itksnap   &&\
    mv /itksnap-4.2.2-20241202-Linux-x86_64.tar.gz ./ &&\
    tar -zxvf itksnap-4.2.2-20241202-Linux-x86_64.tar.gz &&\
    rm itksnap-4.2.2-20241202-Linux-x86_64.tar.gz &&\
    cp -R itksnap-4.2.2-20241202-Linux-x86_64/* . &&\
    rm -R itksnap-4.2.2-20241202-Linux-x86_64 
ENV PATH=/opt/itksnap/bin:$PATH

COPY ./src/c3d-1.0.0-Linux-x86_64.tar.gz /
RUN mkdir /opt/c3dstable &&\
    cd /opt/c3dstable   &&\
    mv /c3d-1.0.0-Linux-x86_64.tar.gz ./ &&\
    tar -zxvf c3d-1.0.0-Linux-x86_64.tar.gz &&\
    rm c3d-1.0.0-Linux-x86_64.tar.gz &&\
    cp -R c3d-1.0.0-Linux-x86_64/* . &&\
    rm -R c3d-1.0.0-Linux-x86_64 
ENV PATH=/opt/c3dstable/bin:$PATH


COPY ./src/c3d-nightly-Linux-gcc64.tar.gz /
RUN mkdir /opt/c3dv142 &&\
    cd /opt/c3dv142   &&\
    mv /c3d-nightly-Linux-gcc64.tar.gz ./ &&\
    tar -zxvf c3d-nightly-Linux-gcc64.tar.gz &&\
    rm c3d-nightly-Linux-gcc64.tar.gz &&\
    cp -R c3d-1.4.2-Linux-gcc64/* . &&\
    rm -R c3d-1.4.2-Linux-gcc64

############################
# STARTUP and CLEANUP and CONFIG
###########################
COPY ./src/startup.sh /opt/bin
COPY ./src/license.txt ${FREESURFER_HOME}
COPY ./src/readme /opt/bin
COPY ./src/version /opt/bin 
COPY ./src/startup.m /home/aacazxnat/matlab/

ENV PATH=/opt/bin:$PATH

RUN rm -rf /tmp/*
RUN rm -rf /opt/tmp/*

ENV NVIDIA_VISIBLE_DEVICES=all


WORKDIR /opt/work
RUN ldconfig &&\
    chmod -R +x /opt/bin &&\
    rm -rf /tmp/* &&\
    rm -rf /opt/tmp/*
ENTRYPOINT ["/opt/bin/startup.sh"]



