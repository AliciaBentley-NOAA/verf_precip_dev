#!/bin/sh
#BSUB -J jverf_trans_send2rzdm
#BSUB -o /gpfs/dell2/ptmp/Alicia.Bentley/cron.out/verf.send2rzdm.%J
#BSUB -e /gpfs/dell2/ptmp/Alicia.Bentley/cron.out/verf.send2rzdm.%J
#BSUB -n 1
#BSUB -q "dev_transfer"
#BSUB -W 0:05
#BSUB -R "rusage[mem=300]"
#BSUB -R "affinity[core]"
#BSUB -P VERF-T2O

set -x

# DATA, vday and domain are passed over from 
#  $script/exverf_precip_plotpcp.sh.ecf

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

  ssh emcrzdm -l wd22yl "mkdir -p $RZDMDIR/$vyear/${vday}"
  scp *.gif *.png index.html wd22yl@emcrzdm:$RZDMDIR/$vyear/${vday}/.

  # copy over the GFS 24h forecast and the ST4 24h accum images to latest/
  # for the new daily comparisions web site head page.
  scp gfs.v*.024h.gif wd22yl@emcrzdm:$RZDMDIR/latest/model_latest.gif
  scp st4.*.24h.gif wd22yl@emcrzdm:$RZDMDIR/latest/anl_latest.gif
  # copy over the CCPA 24h total plot from Yan's directory.  
  # Note that this needs to be done AFTER the "scp *.gif" above - in 
  # ush/indexplot, we put in a dummy as a place holder for the real ccpa gif. 
  YANDIR=/home/www/emc/htdocs/gmb/yluo/ccpa/$vday
  ssh emcrzdm -l wd22yl \
    "cp $YANDIR/ccpa_${vday}12_24h.gif $RZDMDIR/$vyear/${vday}/."
else 
  ssh emcrzdm -l wd22yl "mkdir -p $RZDMDIR/$vyear/${vday}.oconus"
  scp *.gif index.html wd22yl@emcrzdm:$RZDMDIR/$vyear/${vday}.oconus/.
fi 

if [ $cronmode = Y -a $debug = N ]; then
  cd ..
  rm -rf $DATA
fi

exit
