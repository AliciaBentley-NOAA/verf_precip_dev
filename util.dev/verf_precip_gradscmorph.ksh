#!/bin/ksh
set -x

day=$1

set -A mon JAN FEB MAR APR MAY JUN JUL AUG SEP OCT NOV DEC
yyyy=`echo $day | cut -c 1-4`
mm=`echo $day | cut -c 5-6`
dd=`echo $day | cut -c 7-8`
mname=${mon[mm-1]}

export GADDIR=/usrx/local/GrADS/2.0.2/lib

cmfile=cmorph.${day}12.grb

cat > cmorph24.ctl <<EOF
dset  $cmfile
dtype grib 255
index cmorph.gribmap
title  cmorph24
undef  -9999.
tdef     1 linear 12z${dd}${mname}${yyyy} 1dy
xdef  1440 linear    0.125  0.25
ydef   480 linear  -59.875 0.25
zdef     1 linear 1 1
vars   1
p      0 61,1,0  daily precip (mm)
endvars
EOF

gribmap -i cmorph24.ctl

cat > grads.script <<EOF
'open cmorph24.ctl'
'set xsize 900 450'
'set parea 0.5 10.9 1. 7.7'
'set grads off'
'run $ZROOT/utils/grads/gs/pcprgbset.gs'
'set mpdset mres'
'set mproj scaled'
'set gxout grfill'
'set lat -63 63'
'set clevs  -0.01 0.1 5 10 15 20 25 30 35 50 75 100 125 150 175'
'set ccols 0 19 21 22 23 24 25 26 27 28 29 30 31 32 33 34'
*'set lat 0 60'
*'set lon -200 -50'
'd p'
'run $ZROOT/utils/grads/gs/cbar.gs'
'draw title 24h CMORPH pcp ending ${day}12'
'printim cmorph.${day}12.gif gif x900 y400 white'
'quit'
EOF

grads -blc "run grads.script" 
