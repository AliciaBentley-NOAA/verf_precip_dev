#!/bin/ksh
set -x
today=`date +%Y%m%d`
vday=`/nwprod/util/ush/finddate.sh $today d-8`
wrkdir=/stmpp1/Alicia.Bentley/python.ccpax
if [ -d $wrkdir ]; then
  rm -f $wrkdir/*
else
  mkdir -p $wrkdir
fi
cd $wrkdir
python $HOMEverf_precip/util.dev/python/anl_vs_gauge_scatter.py $vday
# delete the line below when the above works in cron jobs.  
mv scat.$vday.png /meso/save/Alicia.Bentley/verf.grid2gauge.dat
exit
