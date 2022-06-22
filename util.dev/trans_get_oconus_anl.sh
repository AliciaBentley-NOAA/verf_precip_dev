#!/bin/ksh

set -x

# GET CMORPH
if [ $# -eq 0 ]; then   
  vday=`date -u +%Y%m%d -d "1 day ago"`
else        
  vday=$1
fi          

vdaym1=`date -d "$vday - 1 day" +%Y%m%d`

#vday=20220620    #date to verify and make plots for (usually 2 days ago, and vday appears in verfgen/plot/send2rzdm)
#vdaym1=20220619  #day before date to make plots for (usually 3 days ago)

COMOUT=/lfs/h2/emc/ptmp/${USER}/verf.dat/v4.5.0/precip

# In routine verification done by cron jobs on devwcoss, this script is the
# one that "bsub < $VERF/ecf/jverf_precip_verfgen_24h.oconus.ecf". When the
# OCoNUS verification jobs are initiated manually and without bsub, 
# This script is called by the OconUS run of 
#  $script/exverf_precip_verfgen_24h.sh.ecf

# Get CMORPH precip files.  There is some duplication here: each day we're
# getting 8 3-hr segments covering $vdaym1, and the 8 3-hr segments 
# covering $vday, in order to get the 24h accumulation ending at 12Z $vday.
# We do this duplicate wget so that if one day's data is late, it might only
# affect that day's OConUS verification.
#
#cmsite=ftp.cpc.ncep.noaa.gov/precip/global_CMORPH/3-hourly_025deg
# CMORPH does not come out until 19:55 UTC the following day
# Working on oconus before 4pm requires setting vday and vdaym1 to day-2 above
cmsite=ftp.cpc.ncep.noaa.gov/precip/CMORPH_V0.x/RAW/0.25deg-3HLY

yyyy1=`echo $vdaym1 | cut -c 1-4`
yyyymm1=`echo $vdaym1 | cut -c 1-6`
yyyy2=`echo $vday | cut -c 1-4`
yyyymm2=`echo $vday | cut -c 1-6`

cmfile1=CMORPH_V0.x_RAW_0.25deg-3HLY_${vdaym1}
cmfile2=CMORPH_V0.x_RAW_0.25deg-3HLY_${vday}

cd $COMOUT.$vdaym1
wget ftp://$cmsite/$yyyy1/$yyyymm1/$cmfile1.gz
err1=$?
cd $COMOUT.$vday
wget ftp://$cmsite/$yyyy2/$yyyymm2/$cmfile2.gz
err2=$?

# 2016/8/10: starting from QPE.151.2016081012.24h, AKQPE are now in /dcom.
# For the purpose of bsub, ssume the file is always there. 
err3=0

# submit the OConUS VERFGEN job if this job is run w/o argument and if
# wget for all analyses files are successful.

# 2013/11/26 AKQPE is too often not made over the weekends (and not re-made
# days afterwards. So we'll run the OConUS analysis if either AKQPE or CMORPH
# is available.  
# 
## if [ $# = 0 -a $err1 = 0 -a $err2 = 0 -a $err3 = 0 ]; then
if [[ ($# = 0) && (($err1 = 0 && $err2 = 0) || $err3 = 0 ) ]]; then
  echo Got into the part where you bsub ecf/dev/jverf_precip_verfgen_24h.oconus.ecf
  qsub /lfs/h2/emc/vpppg/noscrub/${USER}/verf_precip.v4.5.0/ecf/dev/jverf_precip_verfgen_24h.oconus.ecf > /lfs/h2/emc/ptmp/${USER}/cron.out/qsub.verfgen24.oconus.out 2>&1
fi 

exit
