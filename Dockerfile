FROM ubuntu:focal-20210416
MAINTAINER Chidi Ugonna<chidiugonna@arizona.edu>

ENV DEBIAN_FRONTEND noninteractive


##########################
# CREATE BIND and CUSTOM FOLDERS
###########################
RUN mkdir -p /xdisk /groups /opt/data /opt/bin /opt/tmp /opt/work /opt/input /opt/output /opt/config /opt/ohpc /cm/shared /cm/local

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
# CUDA 9.1
############################
WORKDIR /opt/tmp
ENV LD_LIBRARY_PATH=/usr/local/cuda/lib64:/usr/lib:$LD_LIBRARY_PATH
RUN wget https://developer.nvidia.com/compute/cuda/9.1/Prod/local_installers/cuda_9.1.85_387.26_linux && \
    mkdir -p nvidia_installers && \
    chmod +x cuda_9.1.85_387.26_linux && \
    ./cuda_9.1.85_387.26_linux -extract=`pwd`/nvidia_installers && \
    rm cuda_9.1.85_387.26_linux && \
    cd nvidia_installers && \
    ./cuda*.run --tar mxvf && \
    cp InstallUtils.pm /usr/lib/x86_64-linux-gnu/perl-base  && \
    rm cuda-samples* && \
    rm NVIDIA-Linux* && \
    ./cuda-linux.9.1.85-23083092.run -noprompt && \
    wget https://developer.nvidia.com/compute/cuda/9.1/Prod/patches/1/cuda_9.1.85.1_linux && \
    chmod +x cuda_9.1.85.1_linux && \
    ./cuda_9.1.85.1_linux --silent -accept-eula && \
    wget https://developer.nvidia.com/compute/cuda/9.1/Prod/patches/2/cuda_9.1.85.2_linux && \
    chmod +x cuda_9.1.85.2_linux && \
    ./cuda_9.1.85.2_linux --silent -accept-eula && \
    wget https://developer.nvidia.com/compute/cuda/9.1/Prod/patches/3/cuda_9.1.85.3_linux && \
    chmod +x cuda_9.1.85.3_linux && \
    ./cuda_9.1.85.3_linux --silent -accept-eula && \
    cd .. && \
    rm -R nvidia_installers

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
# FSL 6.0.7.4
#
# To install FSL versions < 6.0.6 then use fslinstaller_old.py or grab from cloud
#  wget https://fsl.fmrib.ox.ac.uk/fsldownloads/fslinstaller.py
#################################################################################
WORKDIR /opt/tmp
RUN apt  install -y  freeglut3 \
                        libfontconfig1 \
                        libxrender1

ENV FSLVER="6.0.7.4"
ENV FSLDIR=/opt/fsl

COPY ./src/fslinstaller.py /opt/tmp
RUN python fslinstaller.py -q -d $FSLDIR -V 6.0.7.4

#change from sh to bash in randomize_parallel
RUN  cp /opt/fsl/bin/randomise_parallel /opt/fsl/bin/old_randomise_parallel && \
     sed -i "s^bin/sh^bin/bash^g" /opt/fsl/bin/randomise_parallel

ENV LD_LIBRARY_PATH=$FSLDIR/lib:$LD_LIBRARY_PATH
ENV FSLOUTPUTTYPE=NIFTI_GZ

##########################################################################################
#install probtrackx2 for CUDA 9.1 - note that the commented link below for FSL 5.* versions
# #wget http://users.fmrib.ox.ac.uk/~moisesf/Probtrackx_GPU/CUDA_9.1/probtrackx2_gpu.zip
#the link that is used below is for FSL 6.* versions.
#################################################################

RUN mkdir -p /opt/tmp/probtrackx && \
    cd /opt/tmp/probtrackx && \
    wget http://users.fmrib.ox.ac.uk/~moisesf/Probtrackx_GPU/FSL_6/CUDA_9.1/probtrackx2_gpu.zip && \
    unzip probtrackx2_gpu.zip && \
    rm -f probtrackx2_gpu.zip && \
    mv probtrackx2_gpu $FSLDIR/bin


###########################################################################################
#install bedpostx for CUDA 9.1 - note that the commented link is for FSL 5.* versions
# #wget http://users.fmrib.ox.ac.uk/~moisesf/Bedpostx_GPU/CUDA_9.1/bedpostx_gpu.zip
#the link that is used below is for FSL 6.* versions.
#########################################################################################

RUN mkdir -p /opt/tmp/bedpost && \
    cd /opt/tmp/bedpost && \
    wget http://users.fmrib.ox.ac.uk/~moisesf/Bedpostx_GPU/FSL_6/CUDA_9.1/bedpostx_gpu.zip && \
    unzip bedpostx_gpu.zip && \
    rm -f bedpostx_gpu.zip && \
    cp /opt/tmp/bedpost/bin/* $FSLDIR/bin && \ 
    cp /opt/tmp/bedpost/lib/* $FSLDIR/lib && \
    sed -i 's\#!/bin/sh\#!/bin/bash\g' $FSLDIR/bin/bedpostx_postproc_gpu.sh

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

ENV LD_LIBRARY_PATH=/usr/lib/x86_64-linux-gnu:${LD_LIBRARY_PATH}
RUN git clone https://github.com/MRtrix3/mrtrix3.git && \
    cd /opt/mrtrix3  && \
    git checkout 3.0.4 && \
    ./configure && \
    ./build


############################
# FREESURFER 7.1.1
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

RUN wget https://surfer.nmr.mgh.harvard.edu/pub/dist/freesurfer/7.1.1/freesurfer-linux-centos6_x86_64-7.1.1.tar.gz && \
    tar xz -f freesurfer-linux-centos6_x86_64-7.1.1.tar.gz && \
    rm /opt/freesurfer-linux-centos6_x86_64-7.1.1.tar.gz 

# create symbolic link as tkregister not provided in Freesurfer 7.1.1
RUN ln -s /opt/freesurfer/tktools/tkregister2.tcl /opt/freesurfer/tktools/tkregister.tcl && \
    ln -s /opt/freesurfer/bin/tkregister2 /opt/freesurfer/bin/tkregister

# install matlab runtime for freesurfer subnucleic segmentation of hippocampus
RUN fs_install_mcr R2014b



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
# make miniconda the first environment for pythin library consistency
ENV PATH=${MINICONDA_HOME}/bin:${PATH}
RUN pip install nipype==1.8.6 \
                nibabel==5.1.0 \
                numpy==1.26.1 \
                scipy==1.11.3 \ 
                pydicom==2.4.3 \
                pybids==0.16.3 \
                pandas==2.1.2 \
                nilearn==0.10.2 \
                nitransforms==23.0.1 \
                templateflow==23.1.0 \
                xnat==0.5.2 \
                matplotlib==3.8.1


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

###############################
# LAST UPDATES
# 
################################
# updates to container go here
ENV PATH=${PATH}:$FSLDIR/bin

RUN ldconfig
WORKDIR /opt/work
RUN chmod -R +x /opt/bin
ENTRYPOINT ["/opt/bin/startup.sh"]



