#!/bin/ksh
set -x

day=$1

export GADDIR=/usrx/local/GrADS/2.0.2/lib

cat > cpc_glb.ctl <<EOF
dset cpcfile.$day
options  little_endian 
title global daily analysis 
xdef 1440 linear  00.1250 0.250
ydef 720  linear -89.875 0.250
undef -999.0
zdef 1 linear 1 1
tdef 9999 linear 01jan2007 1dy
vars 2
p        1  00 the grid analysis (0.1mm/day)
nstn     1  00 number of gauge 
ENDVARS
EOF

cat > grads.script <<EOF
'open cpc_glb.ctl'
'set xsize 900 450'
'set parea 0.5 10.9 1. 7.7'
'set grads off'
'run $ZROOT/utils/grads/gs/pcprgbset.gs'
'set mpdset mres'
'set mproj scaled'
'set gxout grfill'
*'set lat -63 63'
'set clevs  -0.01 0.1 2.0 5 10 15 20 25 35 50 75 100 125 150 175'
'set ccols 0 19 21 22 23 24 25 26 27 28 29 30 31 32 33 34'
*'set lat 0 60'
*'set lon -200 -50'
'd p*0.1'
'run $ZROOT/utils/grads/gs/cbar.gs'
'draw title 24h CPC unifd anl ending ${day}12'
'printim cpcuni_glb.${day}12.gif gif x900 y400 white'
'quit'
EOF

grads -blc "run grads.script" 
