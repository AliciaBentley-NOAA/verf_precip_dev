#!/bin/ksh 
#BSUB -J tar_vsdb_for_tempest
#BSUB -o /gpfs/dell2/ptmp/Alicia.Bentley/cron.out/tarfortempest.%J
#BSUB -e /gpfs/dell2/ptmp/Alicia.Bentley/cron.out/tarfortempest.%J
#BSUB -n 1
#BSUB -q "dev_transfer"
#BSUB -W 1:25
#BSUB -R "rusage[mem=300]"
#BSUB -R "affinity[core]"
#BSUB -P VERF-T2O

set -x

# tar up the past $nback days' worth of para VSDBs (ConUS, OConUS) 
# and place it in hold45days.  Normally on $day, after ConUS VERFGEN jobs 
# (24h/03h) are run, we'd tar up 
#   1) ConUS para VSDBs for $daym1, $daym2
#   2) OConUS VSDBs for $daym2
# Then: 
#  
# In the above case nback=2.  If we need to go back a few more days (say a 
# previous day's run of this job or the fetch job on lnx168 didn't complete 
# successfully) then change N to a larger value.
#
# Later that morning the dailychk.vsdb job lnx168 will untar the vsdb tar ball
# left in the 'wcoss.dropbox' on linux machine into 
# /export-4/tempest/wd22yl/vsdb (before doing the daily check)
#
# We are using this script instead of rsync because at the time of this script's
# creation (1 Aug 2013), NCEP model production had recently (25 Jul)
# transitioned from CCS to WCOSS, and we don't want to have the past 40 days' 
# WCOSS VSDBs overwrite the pre-25 Jul data on the tempest VSDB repository.
#
# 2013/8/2: This morning I scheduled this job to run at 10:00 UTC on devwcoss,
#   but the nam_20130731.vsdb file didn't have the 3-hourly vsdbs yet.  
#   The file on devwcoss:/com/.../vsdb/precip has a 'last touched' time of
#   11:29 UTC.  Schedule this job to run at 13:00 UTC instead, and set nback=3,
#   rather than nback=2, so we have two chances to get the up-to-date vsdbs.  
# 
# 2016/5/18-20
# Tar up prod and verf with FSS06H updates from $todaym9 to $todaymX.  
# use prod/parm and para/parm.dev.wcoss's verf_precip_fss_06h_config to 
# determine which files need to be included (otherwise there'd be too many
# non-FSS06H models included in the tar files.
#
# 2017/07/14: separate out processing for prod vsdb and dev vsdb, run this
#   job on prodwcoss - the 5-9 Jul devwcoss outage left large holes in 
#   devwcoss prod data that were never filled. 

. ~/.bashrc
echo 'Actual output starts here'

date

nback=4
#nback=11

# For FSS06H:
nback1fss06=9
nback2fss06=11
#nback2fss06=15

configfile=verf_precip_fss_06h_config
parafss06config=$NOSCRUB/verif_precip/parm.dev/$configfile
parafss06mods=`cat $parafss06config | grep '=1' | awk '{print $2}' | sed 's/run_//' | sed 's/=1//'`

if [ $# -eq 0 ]; then
  today=`date -u +%Y%m%d`
else
  today=$1
fi

triggertempest=Y
if [ $# -eq 2 ]; then
  arg2=$2
  if [ $arg2 = notrigger ]; then
    triggertempest=N
  fi
fi

ARCHDIR=$NOSCRUB/hold45days
VERFDAT=/gpfs/dell2/ptmp/Alicia.Bentley/verf.dat
PARADIR=$VERFDAT/vsdb
OCONUSDIR=$VERFDAT/vsdb.oconus
nday=1

while [ $nday -le $nback ];
do
  day=`date -d "$today - $nday day" +%Y%m%d`
  if [ $nday -eq 1 ]; then
    cd $PARADIR
    tar cvf $ARCHDIR/vsdb4tempest_para.$today */*_${day}.vsdb
  else
    cd $PARADIR
    tar rvf $ARCHDIR/vsdb4tempest_para.$today */*_${day}.vsdb
    cd $OCONUSDIR
    tar rvf $ARCHDIR/vsdb4tempest_oconus.$today */*_${day}.vsdb
  fi
  let nday=$nday+1
done

# now deal with FSS06.  

nday=$nback1fss06

parafss06tar=$ARCHDIR/vsdb4tempest_fss06_para.$today

rm -f $parafss06tar

while [ $nday -le $nback2fss06 ];
do
  day=`date -d "$today - $nday day" +%Y%m%d`

  cd $PARADIR
  for mod in `echo $parafss06mods`
  do
    if [ ! -e $parafss06tar ]; then
      tar cvf $parafss06tar ${mod}/${mod}_${day}.vsdb
    else
      tar rvf $parafss06tar ${mod}/${mod}_${day}.vsdb
    fi
  done 

  let nday=$nday+1
done

cd $ARCHDIR
scp vsdb4tempest_*para.$today wd22yl@vm-lnx-metviewdev-process1:~/wcoss.dropbox/.
scp vsdb4tempest_*oconus.$today wd22yl@vm-lnx-metviewdev-process1:~/wcoss.dropbox/.

# triggers dailychk.vsdb job on tempest (which in turn triggers 
# scorescript.para, also on tempest).  This takes a good long while to run. 
# If we're making manual re-runs and want to skip this step, run this job
# script with the argument 'notrigger', followed by yyyymmdd (normally today):
if [ $triggertempest = Y ]; then
  ssh wd22yl@vm-lnx-metviewdev-process1 "~/crons/dailychk.vsdb > &! ~/crons/output/chk_vsdb.out"
fi

date

exit
