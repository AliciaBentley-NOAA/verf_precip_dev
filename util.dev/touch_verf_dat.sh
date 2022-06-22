#!/bin/sh
# 
# 'touch' the precip.$day files and vsdb files for FSS06H.
# 
# 'touch -c' would not create an empty file, if one does not already exist.

set -x

if [ $# -eq 0 ]; then  
  day=`date +%Y%m%d -d "1 day ago"`
else                  
  day=$1
fi

#
COMOUT=/lfs/h2/emc/ptmp/${USER}/verf.dat/v4.5.0/precip.
COMVSDB=/lfs/h2/emc/ptmp/${USER}/verf.dat/v4.5.0/vsdb

# 'touch' select files in precip.$day for daym14 - daym3. 
# For FSS06H, we need daym14-daym10 on line.  We are touching them as far
# back as daym14 to provide some safety margin - in case we need to make 
# re-runs a couple of days later.
#

daytouch=`date -d "$day - 14 days" +%Y%m%d`
daym3=`date -d "$day - 3 days" +%Y%m%d`

parmdir=/lfs/h2/emc/vpppg/noscrub/alicia.bentley/verf_precip.v4.5.0/parm.dev
# find out which models are being verified in FSS06H:
models=`grep '=1' $parmdir/verf_precip_fss_06h_config | sed 's/export run_//g' | sed 's/=1//g'`
# Add the non-FSS06H models whose files also need to be kept on line:
models=`echo $models`

while [ $daytouch -le $daym3 ]; do
  for model in `echo $models`
  do 
    cd $COMOUT$daytouch
    err=$?
    if [ $err -eq 0 ]; then
      touch -c ${model}_*
    fi
    cd $COMVSDB/$model
    if [ $err -eq 0 ]; then
      touch -c ${model}_${daytouch}.vsdb
    fi
  done
  daytouch=`date -d "$daytouch + 1 day" +%Y%m%d`
done

exit

