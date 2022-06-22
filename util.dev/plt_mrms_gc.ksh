#!/bin/ksh 
set -x
# plot a 24h (12Z-12Z) total of gauge-corrected MRMS
#
day=$1

export GADDIR=/usrx/local/GrADS/2.0.2/lib
set -A mon jan feb mar apr may jun jul aug sep oct nov dec

# MRMS: GaugeCorr_QPE_01H_00.00_20160602-170000.grib2
DCOM=/dcom/us007003/ldmdata/obs/upperair/mrms/conus/GaugeCorr_QPE

daym1=`/nwprod/util/ush/finddate.sh $day d-1`
mm=`echo $daym1 | cut -c 5-6`
dd=`echo $daym1 | cut -c 7-8`
let mm=mm-1
mname=${mon[mm]}
yyyy=`echo $daym1 | cut -c 1-4`
date=${daym1}13
allthere=Y

while [ $date -le ${day}12 ]
do
  yyyymmdd=`echo $date | cut -c 1-8`
  hh=`echo $date | cut -c 9-10`
  mrmsfile=GaugeCorr_QPE_01H_00.00_${yyyymmdd}-${hh}0000.grib2
  cp $DCOM/$mrmsfile.gz .
  gunzip $mrmsfile
  err=$?
  if [ $err -ne 0 ]; then
    echo Problem copying or gunzip $mrmsfile
    allthere=N
  fi
  date=`/nwprod/util/exec/ndate +1 $date`
done

if [ $allthere = N ]; then exit; fi

cat > mrms_gc.ctl <<EOF1
dset ^GaugeCorr_QPE_01H_00.00_%y4%m2%d2-%h20000.grib2
index ^mrms_gc.idx
options template
undef 9.999E+20
title MRMS
* produced by g2ctl v0.1.0
* command line options: GaugeCorr_QPE_01H_00.00_20160602-170000.grib2
* griddef=1:0:(7000 x 3500):grid_template=0:winds(N/S): lat-lon grid:(7000 x 3500) units 1e-06 input WE:NS output WE:SN res 48 lat 54.995000 to 20.005001 by 0.010000 lon 230.004999 to 299.994997 by 0.010000 #points=24500000:winds(N/S)
dtype grib2
ydef 3500 linear 20.005001 0.01
xdef 7000 linear 230.004999 0.010000
tdef 24 linear 13Z${dd}${mname}${yyyy} 1hr
zdef 1 linear 1 1
vars 1
pcp   0,102,0   209,6,9 ** Precip Accum kg/m2
ENDVARS
EOF1

cat > pltgrads_mrms_gc.gs <<EOF2
'open mrms_gc.ctl'
'set parea 0.5 10.9 1. 7.7'
'set grads off'
'run /meso/save/Alicia.Bentley/utils/grads/gs/pcprgbset.gs'
'set mpdset mres'
'set gxout shaded'
'set lon 229 301'
'set lat 20 55.5' 
'set clevs  -0.01 0.1 2.0 5 10 15 20 25 35 50 75 100 125 150 175'
'set ccols 0 19 21 22 23 24 25 26 27 28 29 30 31 32 33 34'
'd sum(pcp,t=1,t=24)' 
'run /meso/save/Alicia.Bentley/utils/grads/gs/cbar.gs'
'draw title GC MRMS 24h pcp ending 12Z ${day}'
'printim mrms_gc.${day}12.24h.gif gif x480 y425 white'
'quit'
EOF2

gribmap -i mrms_gc.ctl

grads -blc "run pltgrads_mrms_gc.gs"
exit
