FROM ubuntu:focal-20210416
MAINTAINER Chidi Ugonna<chidiugonna@arizona.edu>

ENV DEBIAN_FRONTEND noninteractive


##########################
# CREATE BIND and CUSTOM FOLDERS
###########################
RUN mkdir -p /xdisk /groups /opt/ohpc /rental 
RUN mkdir /pandata /panbin /pantmp /panwork /paninput /panoutput /panconfig 

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
WORKDIR /pantmp
ENV MINICONDA_HOME=/opt/miniconda
ENV PATH=${MINICONDA_HOME}/bin:${PATH}

RUN wget https://repo.anaconda.com/miniconda/Miniconda3-py310_23.9.0-0-Linux-x86_64.sh && \
    chmod +x Miniconda3-py310_23.9.0-0-Linux-x86_64.sh && \
    /bin/bash ./Miniconda3-py310_23.9.0-0-Linux-x86_64.sh -b -p ${MINICONDA_HOME} -f && \
    conda install -y pip


##################################################
#  Issues faced with git clone
#
##################################################
RUN apt install ca-certificates && \
        update-ca-certificates


#######################################
# Amico envionment
#######################################

COPY ./src/activateConda.sh /panbin

RUN chmod +x /panbin/activateConda.sh && \
    /opt/miniconda/bin/conda create -y -n amico python=3.10 && \
    /opt/miniconda/bin/conda init bash

RUN . /panbin/activateConda.sh  && \
    conda activate amico && \
    pip install dmri-amico==2.1.0 &&\
    conda activate

#######################################
# mne envionment
#######################################

RUN chmod +x /panbin/activateConda.sh && \
    /opt/miniconda/bin/conda create -y -n mne python=3.10 && \
    /opt/miniconda/bin/conda init bash

RUN . /panbin/activateConda.sh  && \
    conda activate mne && \
    pip install mne[hdf5]==1.1.0 &&\
    conda activate



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
COPY ./src/readme /panbin
COPY ./src/version /panbin 
COPY ./src/startup.m /home/aacazxnat/matlab/
COPY ./src/startup.sh /panbin
ENV PATH=/panbin:$PATH

RUN rm -rf /tmp/* &&\
    rm -rf /pantmp/*

ENV NVIDIA_VISIBLE_DEVICES=all

RUN ldconfig
WORKDIR /work
RUN chmod -R +x /panbin
ENTRYPOINT ["/panbin/startup.sh"]



