#!/bin/bash
#PBS -N send2rzdm
#PBS -o /lfs/h2/emc/ptmp/alicia.bentley/cron.out/verf_send2rzdm.out
#PBS -e /lfs/h2/emc/ptmp/alicia.bentley/cron.out/verf_send2rzdm.err
#PBS -l select=1:ncpus=10:mem=30GB
#PBS -q dev_transfer
#PBS -l walltime=00:15:00
#PBS -A VERF-DEV

set -x
. /usrx/local/prod/lmod/lmod/init/sh
set -x

# DATA, vday and domain are passed over from 
#  $script/exverf_precip_plotpcp.sh

cd $DATA
vyear=`echo $vday |cut -c1-4`
vyearmon=`echo $vday |cut -c1-6`

# Make sure RZDMDIR has been defined in the ecf script.  If not, exit without
# sending anything over.  
if [ "$RZDMDIR" = "" ]; then 
  echo  RZDMDIR has not been defined!  Exit.
fi

if [ $domain = conus ]; then
  # get 24h snowfall image from NOHRSC, rename it so it's more easily 
  #   identifiable. 
  # Not using the wget http://.../filename.png -O newname.png 
  #   option, because in that case, when a remote file does not exist, 
  #   there'll be a null newname.png - wipes out the blankplt.png we have
  #   copied to nohrsc_${vday}12_24h.png in ush/verf_precip_indexplot_conus.sh
  wget https://www.nohrsc.noaa.gov/snowfall/data/$vyearmon/sfav2_CONUS_24h_${vday}12.png 
  err=$?
  if [ $err -eq 0 ]; then
    mv sfav2_CONUS_24h_${vday}12.png nohrsc_${vday}12_24h.png
  fi

  ssh emcrzdm -l abentley "mkdir -p $RZDMDIR/$vyear/${vday}"
  scp *.gif *.png index.html abentley@emcrzdm:$RZDMDIR/$vyear/${vday}/.

  # Copy stage IV(st4-qpe) into a format that the new webpage can read!
  scp st4.*.24h.gif abentley@emcrzdm:$RZDMDIR/$vyear/${vday}/qpe.v${vday}12.024h.gif

  # copy over the GFS 24h forecast and the ST4 24h accum images to latest/
  # for the new daily comparisions web site head page.
  scp gfs.v*.024h.gif abentley@emcrzdm:$RZDMDIR/latest/model_latest.gif
  scp st4.*.24h.gif abentley@emcrzdm:$RZDMDIR/latest/anl_latest.gif

  # copy over the CCPA 24h total plot from Yan's directory.  
  # Note that this needs to be done AFTER the "scp *.gif" above - in 
  # ush/indexplot, we put in a dummy as a place holder for the real ccpa gif. 
  YANDIR=/home/www/emc/htdocs/gmb/yluo/ccpa/$vday
  ssh emcrzdm -l abentley \
    "cp $YANDIR/ccpa_${vday}12_24h.gif $RZDMDIR/$vyear/${vday}/."

  # Copy nohrsc into a format that the new webpage can read!
  scp nohrsc*24h.png abentley@emcrzdm:$RZDMDIR/$vyear/${vday}/nohrsc.v${vday}12.024h.gif

else 
  ssh emcrzdm -l abentley "mkdir -p $RZDMDIR/$vyear/${vday}.oconus"
  scp *.gif index.html abentley@emcrzdm:$RZDMDIR/$vyear/${vday}.oconus/.
  # Copy cmorph(qpe) into a format that the new webpage can read!
  scp cmorph.*.ak.gif abentley@emcrzdm:$RZDMDIR/$vyear/${vday}.oconus/qpe.v${vday}12.024h.AK.gif
  scp cmorph.*.hi.gif abentley@emcrzdm:$RZDMDIR/$vyear/${vday}.oconus/qpe.v${vday}12.024h.HI.gif
  scp cmorph.*.pr.gif abentley@emcrzdm:$RZDMDIR/$vyear/${vday}.oconus/qpe.v${vday}12.024h.PR.gif
fi 

if [ $cronmode = Y -a $debug = N ]; then
  cd ..
  rm -rf $DATA
fi

exit
