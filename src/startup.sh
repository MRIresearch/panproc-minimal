#!/bin/bash
########################################################## 
#  Start-up script for singularity images
##########################################################
###########################
# Helper Functions
##########################
# opts_GetOpt1() is copied from HCPpipelines - https://raw.githubusercontent.com/Washington-University/HCPpipelines/master/global/scripts/opts.shlib
opts_GetOpt1() {
    sopt="$1"
    shift 1
    for fn in "$@" ; do
    if [ `echo $fn | grep -- "^${sopt}=" | wc -w` -gt 0 ] ; then
        echo "$fn" | sed "s/^${sopt}=//"
        return 0
    fi
    done
}

opts_findcommand() {
  POS=0
  for fn in "$@" ; do
  if [[ "${fn}" == *"--"* ]] 
  then
    POS=$((POS + 1))
  else
    echo $POS
    return 0
  fi
  done
  echo $POS
}

opts_findflag() {
  POS=0
  sopt="$1"
  shift 1
  for fn in "$@" ; do
  if [[ "${fn}" == *"${sopt}"* ]] 
  then
    echo $POS
    return 0
  else 
    POS=$((POS + 1))
  fi
  done
  echo $POS
}

opts_DefaultOpt() {
    echo $1
}

opts_CheckFlag() {
    sopt="$1"
    shift 1
    for fn in "$@" ; do
    if [ `echo $fn | grep -- "^${sopt}=" | wc -w` -gt 0 ] ; then
        return 1
    fi
    done
    return 0
}

opts_CheckFlagBasic() {
    sopt="$1"
    shift 1
    for fn in "$@" ; do
    if [ `echo $fn | grep -- "^${sopt}" | wc -w` -gt 0 ] ; then
        return 1
    fi
    done
    return 0
}

###########################################################
SHIFT=0
#################################
# if no flag passed then print out version and help
if [ -z ${1+x} ]
then
   VERSION="True"
   HELP="True"
fi

# where does command begin
POS=`opts_findcommand $@`

################################
# Log
flag="--log"
default=0
opts_CheckFlagBasic $flag $@
FlagExists=`echo $?`
if [ $FlagExists -eq 1 ] 
then
   PARAMPOS=`opts_findflag $flag $@`
   if  [ $PARAMPOS -le $POS ] 
   then 
       LOG=`opts_DefaultOpt $LOG 1`
   else
       LOG=`opts_DefaultOpt $LOG $default`
   fi
else
# flag wasn't passed - what do you want to do?
LOG=`opts_DefaultOpt $LOG $default`
fi

###########################################################
# Processing starts
IMAGE=$(head -1 /opt/bin/version*)
MSG="Starting Singularity image: $IMAGE" 
if [ $LOG -eq 1 ]; then echo -e $MSG; fi

################################
# Version 
flag="--version"
default="False"
opts_CheckFlagBasic $flag $@
FlagExists=`echo $?`
if [ $FlagExists -eq 1 ]
then  
  PARAMPOS=`opts_findflag $flag $@`
  if  [ $PARAMPOS -le $POS ] 
  then
     opts_CheckFlag $flag $@
     FlagExists=`echo $?`
     if [ $FlagExists -eq 1 ] 
     then 
         VERSION=`opts_GetOpt1 $flag $@`
     else
        # flag passed but without = sign; decide what to do next
         VERSION=`opts_DefaultOpt $VERSION True`
     fi
  else
    VERSION=`opts_DefaultOpt $VERSION $default`
  fi
else
# flag wasn't passed - what do you want to do?
VERSION=`opts_DefaultOpt $VERSION $default`
fi

#################################
# Help
flag="--help"
default="False"
opts_CheckFlagBasic $flag $@
FlagExists=`echo $?`
if [ $FlagExists -eq 1 ]
then
  PARAMPOS=`opts_findflag $flag $@`
  if  [ $PARAMPOS -le $POS ]   
  then
    opts_CheckFlag $flag $@
    FlagExists=`echo $?`
    if [ $FlagExists -eq 1 ]
    then 
      HELP=`opts_GetOpt1 $flag $@`
    else
      # flag passed but without = sign; decide what to do next
      HELP=`opts_DefaultOpt $HELP True`
    fi
  else
     HELP=`opts_DefaultOpt $HELP $default`
  fi
else
# flag wasn't passed - what do you want to do?
HELP=`opts_DefaultOpt $HELP $default`
fi


#################################
# workdir
flag="--workdir"
default="/tmp"
opts_CheckFlagBasic $flag $@
FlagExists=`echo $?`
if [ $FlagExists -eq 1 ]
then
  PARAMPOS=`opts_findflag $flag $@`
  if  [ $PARAMPOS -le $POS ]   
  then
      opts_CheckFlag $flag $@
      FlagExists=`echo $?`
      if [ $FlagExists -eq 1 ]
      then 
         WORKDIR=`opts_GetOpt1 $flag $@`
         if [ ! -d $WORKDIR ]
          then
           MSG="--workdir $WORKDIR doesn't exist - using $default instead"
           if [ $LOG -eq 1 ]; then echo -e $MSG; fi
           WORKDIR=`opts_DefaultOpt $WORKDIR $default`
         fi
      else
        # flag passed but without = sign; decide what to do next
         WORKDIR=`opts_DefaultOpt $WORKDIR $default`
      fi
  else
   WORKDIR=`opts_DefaultOpt $WORKDIR $default`
  fi
else
# flag wasn't passed - pass on default
WORKDIR=`opts_DefaultOpt $WORKDIR $default`
fi

######################
# Home
flag="--home"
default="/home/aacazxnat"
opts_CheckFlagBasic $flag $@
FlagExists=`echo $?`
if [ $FlagExists -eq 1 ]
then
  PARAMPOS=`opts_findflag $flag $@`
  if  [ $PARAMPOS -le $POS ]   
  then
      opts_CheckFlag $flag $@
      FlagExists=`echo $?`
      if [ $FlagExists -eq 1 ]
      then 
         HOMEDIR=`opts_GetOpt1 $flag $@`
         if [ ! -d $HOMEDIR ]
          then
           MSG="--home $HOMEDIR doesn't exist - using $default instead"
           if [ $LOG -eq 1 ]; then echo -e $MSG; fi
           HOMEDIR=`opts_DefaultOpt $HOMEDIR $default`
         fi
      else
        # flag passed but without = sign; decide what to do next
         HOMEDIR=`opts_DefaultOpt $HOMEDIR $default`
      fi
  else
   HOMEDIR=`opts_DefaultOpt $HOMEDIR $default`
  fi
else
# flag wasn't passed - use singularity default HOME
MSG="Singularity has implicitly set HOME to $HOME"
if [ $LOG -eq 1 ]; then echo -e $MSG; fi
HOMEDIR=$HOME
fi

################################
# do not source fsl
flag="--xfsl"
default="False"
opts_CheckFlagBasic $flag $@
FlagExists=`echo $?`
if [ $FlagExists -eq 1 ]
then  
  PARAMPOS=`opts_findflag $flag $@`
  if  [ $PARAMPOS -le $POS ] 
  then
     opts_CheckFlag $flag $@
     FlagExists=`echo $?`
     if [ $FlagExists -eq 1 ] 
     then 
         XFSL=`opts_GetOpt1 $flag $@`
     else
        # flag passed but without = sign; decide what to do next
         XFSL=`opts_DefaultOpt $XFSL True`
     fi
  else
    XFSL=`opts_DefaultOpt $XFSL $default`
  fi
else
# flag wasn't passed - what do you want to do?
XFSL=`opts_DefaultOpt $XFSL $default`
fi

################################
# do not source freesurfer
flag="--xfree"
default="False"
opts_CheckFlagBasic $flag $@
FlagExists=`echo $?`
if [ $FlagExists -eq 1 ]
then  
  PARAMPOS=`opts_findflag $flag $@`
  if  [ $PARAMPOS -le $POS ] 
  then
     opts_CheckFlag $flag $@
     FlagExists=`echo $?`
     if [ $FlagExists -eq 1 ] 
     then 
        XFREE=`opts_GetOpt1 $flag $@`
     else
        # flag passed but without = sign; decide what to do next
        XFREE=`opts_DefaultOpt $XFREE True`
     fi
  else
    XFREE=`opts_DefaultOpt $XFREE $default`
  fi
else
# flag wasn't passed - what do you want to do?
XFREE=`opts_DefaultOpt $XFREE $default`
fi

################################
# quick fix for libpriority of mrview
flag="--mrmode"
default="False"
opts_CheckFlagBasic $flag $@
FlagExists=`echo $?`
if [ $FlagExists -eq 1 ]
then  
  PARAMPOS=`opts_findflag $flag $@`
  if  [ $PARAMPOS -le $POS ] 
  then
     opts_CheckFlag $flag $@
     FlagExists=`echo $?`
     if [ $FlagExists -eq 1 ] 
     then 
        MRMODE=`opts_GetOpt1 $flag $@`
     else
        # flag passed but without = sign; decide what to do next
        MRMODE=`opts_DefaultOpt $MRMODE True`
     fi
  else
    MRMODE=`opts_DefaultOpt $MRMODE $default`
  fi
else
# flag wasn't passed - what do you want to do?
MRMODE=`opts_DefaultOpt $MRMODE $default`
fi

#################################
# Path Priority 
flag="--pathpriority"
default=""
PATHPRIORITYPASSED="False"
opts_CheckFlagBasic $flag $@
FlagExists=`echo $?`
if [ $FlagExists -eq 1 ]
then
  PARAMPOS=`opts_findflag $flag $@`
  if  [ $PARAMPOS -le $POS ]   
  then
      opts_CheckFlag $flag $@
      FlagExists=`echo $?`
      if [ $FlagExists -eq 1 ]
      then 
         PATHPRIORITY=`opts_GetOpt1 $flag $@`
         PATHPRIORITYPASSED="True" 
         MSG="--pathpriority parsed"
         if [ $LOG -eq 1 ]; then echo -e $MSG; fi
         if [ ! -d $PATHPRIORITY ]
         then
           MSG="--priority $PATHPRIORITY doesn't exist - path may not be found"
           if [ $LOG -eq 1 ]; then echo -e $MSG; fi
         fi
      else
         # flag passed but without = sign; ignore
         MSG="--pathpriority needs an included path"
         if [ $LOG -eq 1 ]; then echo -e $MSG; fi
      fi
   fi
#else
# flag wasn't passed - ignore
fi

####################################################################
# Lib Priority 
flag="--libpriority"
default=""
LIBPRIORITYPASSED="False"
opts_CheckFlagBasic $flag $@
FlagExists=`echo $?`
if [ $FlagExists -eq 1 ]
then
  PARAMPOS=`opts_findflag $flag $@`
  if  [ $PARAMPOS -le $POS ]   
  then
      opts_CheckFlag $flag $@
      FlagExists=`echo $?`
      if [ $FlagExists -eq 1 ]
      then 
         LIBPRIORITY=`opts_GetOpt1 $flag $@`
         LIBPRIORITYPASSED="True" 
         MSG="--libpriority parsed"
         if [ $LOG -eq 1 ]; then echo -e $MSG; fi
         if [ ! -d $LIBPRIORITY ]
         then
           MSG="--libpriority $LIBPRIORITY doesn't exist - path may not be found"
           if [ $LOG -eq 1 ]; then echo -e $MSG; fi
         fi
      else
         # flag passed but without = sign; ignore
         MSG="--libpriority needs an included path"
         if [ $LOG -eq 1 ]; then echo -e $MSG; fi
      fi
   fi
#else
# flag wasn't passed - ignore
fi


#################################
# Retrieve 
flag="--retrieve"
default=""
cpcommand=""
RETRIEVEPASSED="False"
opts_CheckFlagBasic $flag $@
FlagExists=`echo $?`
if [ $FlagExists -eq 1 ]
then
  PARAMPOS=`opts_findflag $flag $@`
  if  [ $PARAMPOS -le $POS ]   
  then
      opts_CheckFlag $flag $@
      FlagExists=`echo $?`
      if [ $FlagExists -eq 1 ]
      then 
         RETRIEVE=`opts_GetOpt1 $flag $@`
         if [ ! -f $RETRIEVE ]
         then
            MSG="$RETRIEVE not accessible as a file"
            if [ $LOG -eq 1 ]; then echo -e $MSG; fi
            if [ -d $RETRIEVE ]
            then
               MSG="$RETRIEVE is accessible as a directory"
               if [ $LOG -eq 1 ]; then echo -e $MSG; fi
               RETRIEVEPASSED="True"
               cpcommand="cp -R "
            fi
         else
            RETRIEVEPASSED="True"
            cpcommand="cp "
         fi
      else
         # flag passed but without = sign; ignore
         MSG="--retrieve needs an included path"
         if [ $LOG -eq 1 ]; then echo -e $MSG; fi
      fi
    fi
#else
# flag wasn't passed - ignore
fi

#################################
# SourcePre
flag="--sourcepre"
default=""
SOURCEPREPASSED="False"
opts_CheckFlagBasic $flag $@
FlagExists=`echo $?`
if [ $FlagExists -eq 1 ]
then
  PARAMPOS=`opts_findflag $flag $@`
  if  [ $PARAMPOS -le $POS ]   
  then  
      opts_CheckFlag $flag $@
      FlagExists=`echo $?`
      if [ $FlagExists -eq 1 ]
      then 
         SOURCEPRE=`opts_GetOpt1 $flag $@`
         if [ ! -f $SOURCEPRE ]
         then
            MSG="$SOURCEPRE not accessible as a file"
            if [ $LOG -eq 1 ]; then echo -e $MSG; fi
         else
            SOURCEPREPASSED="True"
         fi
      else
         # flag passed but without = sign; ignore
         MSG="--retrieve needs an included path"
         if [ $LOG -eq 1 ]; then echo -e $MSG; fi
      fi
    
  fi
#else
# flag wasn't passed - ignore
fi

#################################
# SourcePost
flag="--sourcepost"
default=""
SOURCEPOSTPASSED="False"
opts_CheckFlagBasic $flag $@
FlagExists=`echo $?`
if [ $FlagExists -eq 1 ]
then
  PARAMPOS=`opts_findflag $flag $@`
  if  [ $PARAMPOS -le $POS ]   
  then  
      opts_CheckFlag $flag $@
      FlagExists=`echo $?`
      if [ $FlagExists -eq 1 ]
      then 
         SOURCEPOST=`opts_GetOpt1 $flag $@`
         if [ ! -f $SOURCEPOST ]
         then
            MSG="$SOURCEPOST not accessible as a file"
            if [ $LOG -eq 1 ]; then echo -e $MSG; fi
         else
            SOURCEPOSTPASSED="True"
         fi
      else
         # flag passed but without = sign; ignore
         MSG="--retrieve needs an included path"
         if [ $LOG -eq 1 ]; then echo -e $MSG; fi
      fi
    
  fi
#else
# flag wasn't passed - ignore
fi


######################################
# act on flags

# --workdir
MSG="Navigating to $WORKDIR"
if [ $LOG -eq 1 ]; then echo -e $MSG; fi
cd $WORKDIR

# --home
MSG="Setting HOME directory to $HOMEDIR"
if [ $LOG -eq 1 ]; then echo -e $MSG; fi
export HOME=$HOMEDIR


# --retrieve 
if [ $RETRIEVEPASSED = "True" ]
then
   MSG="copying $RETRIEVE to $PWD - you may need to use --homedir to provide an accessible current directory"
   if [ $LOG -eq 1 ]; then echo -e $MSG; fi
   $cpcommand $RETRIEVE $PWD
fi

# --version
if [ $VERSION = "True" ]
then
    more /opt/bin/version* 
fi

# --help
if [ $HELP = "True" ]
then
   more /opt/bin/readme*
fi

# --sourcepre
if [ $SOURCEPREPASSED = "True" ]
then
   MSG="Sourcing $SOURCEPRE"
   if [ $LOG -eq 1 ]; then echo -e $MSG; fi
   . $SOURCEPRE
fi

if [ -f  $FREESURFER_HOME/SetUpFreeSurfer.sh ] && [ $XFREE = "False" ]
then 
    . $FREESURFER_HOME/SetUpFreeSurfer.sh
fi

if [ -f  $FSLDIR/etc/fslconf/fsl.sh ] && [ $XFSL = "False" ]
then 
    . $FSLDIR/etc/fslconf/fsl.sh
fi

# Make MINICONDA first 
export PATH=${MINICONDA_HOME}/bin:${PATH}

# --sourcepre
if [ $SOURCEPOSTPASSED = "True" ]
then
   MSG="Sourcing $SOURCEPOST"
   if [ $LOG -eq 1 ]; then echo -e $MSG; fi
   . $SOURCEPOST
fi


# --pathpriority
if [ $PATHPRIORITYPASSED = "True" ]
then
   export PATH=$PATHPRIORITY:$PATH
   MSG="Current PATH shown below:\n$PATH"
   if [ $LOG -eq 1 ]; then echo -e $MSG; fi
fi

# --libpriority
if [ $LIBPRIORITYPASSED = "True" ]
then
   export LD_LIBRARY_PATH=$LIBPRIORITY:$LD_LIBRARY_PATH
   MSG="Current LD_LIBRARY_PATH shown below:\n$LD_LIBRARY_PATH"
   if [ $LOG -eq 1 ]; then echo -e $MSG; fi
fi

# --libpriority
if [ $MRMODE = "True" ]
then
   MRVIEWLIB=/opt/fsl/lib
   export LD_LIBRARY_PATH=${MRVIEWLIB}:$LD_LIBRARY_PATH
   MSG="MRMODE invoked by prioritizing ${MRVIEWLIB}. Current LD_LIBRARY_PATH shown below:\n$LD_LIBRARY_PATH"
   if [ $LOG -eq 1 ]; then echo -e $MSG; fi
fi


if [ $POS -gt 0 ]
then
   shift $POS
fi

############################################
# Run trailing command by passing on to shell
$*
