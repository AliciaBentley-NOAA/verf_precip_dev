#!/bin/ksh
# count the number of models precip.$day, and number of files for each model.
# Run this in the directory you're counting.  
#
# make a list of unique models: assuming that they are all in the format
# of $model_$yyyymmddhh_$hr1_$hr2.

wrkdir=/gpfs/dell2/stmp/Alicia.Bentley/getppt.compare
if [ ! -d $wrkdir ]; then
  mkdir -p $wrkdir
fi

# modlist is a temporary file
modlist=$wrkdir/modlist

# If the directory name is, say, /com/verf/prod/precip.20161115, 
# make the output list 'com_verf_precip_precip.20161115.list':
outfile=$wrkdir/`pwd | sed 's/\///' | sed 's/\//_/g'`.list

if [ -e $modlist ]; then rm -f $modlist; fi
if [ -e $outfile ]; then rm -f $outfile; fi

ls -1 | grep _.........._..._... | awk -F"_" '{print $1}' | sort -u > $modlist
nmod=`wc -l $modlist | awk '{print $1}'`
echo $nmod models in `pwd` >> $outfile
for model in `cat $modlist` 
do
  nfile=`ls -1 ${model}_*_*_* | wc -l`
  echo '  ' $model $nfile >> $outfile
done

exit
