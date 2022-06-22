#!/bin/sh 
#BSUB -J tar_prod_vsdb_for_tempest
#BSUB -o /gpfs/dell2/ptmp/Ying.Lin/cron.out/tarfortempest.%J
#BSUB -e /gpfs/dell2/ptmp/Ying.Lin/cron.out/tarfortempest.%J
#BSUB -n 1
#BSUB -q "dev_transfer"
#BSUB -W 0:25
#BSUB -R "rusage[mem=300]"
#BSUB -R "affinity[core]"
#BSUB -P VERF-T2O

set -x

# tar up the past $nback days' worth of prod VSDBs 
# and place it in hold45days.  Normally on $day, after ConUS VERFGEN jobs 
# (24h/03h) are run, we'd tar up 
#   1) ConUS prod/para VSDBs for $daym1, $daym2
#   2) OConUS VSDBs for $daym2
# 
# In the above case nback=2.  If we need to go back a few more days (say a 
# previous day's run of this job or the fetch job on lnx168 didn't complete 
# successfully) then change N to a larger value.
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
#

. ~/.bashrc
echo 'Actual output starts here'

date

nback=4
#nback=11

# For FSS06H:
nback1fss06=9
nback2fss06=11
#nback2fss06=15

NWPROD=/gpfs/dell1/nco/ops/nwprod
prdver=`grep verf_precip $NWPROD/versions/verf_precip.ver | awk -F'=' '{print $2}'`

configfile=verf_precip_fss_06h_config
prodfss06config=$NWPROD/verf_precip.${prdver}/parm/$configfile

prodfss06mods=`cat $prodfss06config | grep '=1' | awk '{print $2}' | sed 's/run_//' | sed 's/=1//'`

if [ $# -eq 0 ]; then
  today=`date -u +%Y%m%d`
else
  today=$1
fi

ARCHDIR=$NOSCRUB/hold45days
PRODDIR=/gpfs/dell1/nco/ops/com/verf/prod/vsdb/precip
nday=1

cd $PRODDIR

# 
while [ $nday -le $nback ];
do
  day=`date -d "$today - $nday day" +%Y%m%d`
  if [ $nday -eq 1 ]; then
    tar cvf $ARCHDIR/vsdb4tempest_prod.$today */*_${day}.vsdb
  else
    tar rvf $ARCHDIR/vsdb4tempest_prod.$today */*_${day}.vsdb
  fi
  let nday=$nday+1
done

# now deal with FSS06.  

nday=$nback1fss06

prodfss06tar=$ARCHDIR/vsdb4tempest_fss06_prod.$today

rm -f $prodfss06tar 

while [ $nday -le $nback2fss06 ];
do
  day=`date -d "$today - $nday day" +%Y%m%d`
  for mod in `echo $prodfss06mods`
  do
    if [ ! -e $prodfss06tar ]; then
      tar cvf $prodfss06tar ${mod}/${mod}_${day}.vsdb
    else
      tar rvf $prodfss06tar ${mod}/${mod}_${day}.vsdb
    fi
  done 

  let nday=$nday+1
done

cd $ARCHDIR
scp vsdb4tempest_*prod.$today wd22yl@vm-lnx-metviewdev-process1:~/wcoss.dropbox/.

date

exit
