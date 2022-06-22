from pylab import *
from astropy.io import ascii
import matplotlib.pylab as plt 
import numpy as np
import sys
#Necessary to generate figs when not running an Xserver (e.g. via PBS)
plt.switch_backend('agg')
def rmse(arr1, arr2):
    return np.sqrt(((arr1 - arr2) ** 2).mean())
plt.xlabel('Daily gauge reports (mm/day)')
plt.ylabel('Analysis amt on gauge loc (mm/day)')
# range for both x/y axes are 0-120mm
plt.xlim((0,50))
plt.ylim((0,50))
vday=sys.argv[1]
DATDIR='/meso/save/Alicia.Bentley/verf.grid2gauge.dat/'
infile1=DATDIR+'g2g_ccpa_'+vday+'.dat'
infile2=DATDIR+'g2g_ccpax_'+vday+'.dat'
infile3=DATDIR+'g2g_ST4_'+vday+'.dat'
# plot diagonal line:
x = arange(0., 51., 1)
plt.plot(x,x,color='black',linestyle='dotted')
# make x/y scales equal (without the line below, python plot's y-scale tend
# to be smaller than its x-scale, to fit a 'landscape' page):
plt.gca().set_aspect('equal', adjustable='box')
#
tbl = ascii.read(infile1)
tbl.colnames  
plt.scatter(tbl['col4'], tbl['col5'],s=1,color='red') #'s' is size of dots
#
# draw regression line:
fit = plt.polyfit(tbl['col4'], tbl['col5'], deg=1)
plt.plot(x,fit[0] * x + fit[1], linewidth=2, color='red')
label1 = "CCPA: %6.2f"%rmse(tbl['col4'], tbl['col5'])
print(label1)
#print RMSE of RTMA: rmse(tbl['col4'], tbl['col5'])
print "fit0, fit1 of CCPA regression line:", fit[0], fit[1]
#
# Now do the same for the second dataset:
tbl = ascii.read(infile2)
tbl.colnames
plt.scatter(tbl['col4'], tbl['col5'],s=1,color='blue',alpha=0.2) #'s' is size of dots
fit = plt.polyfit(tbl['col4'], tbl['col5'], deg=1)
print rmse(tbl['col4'], tbl['col5'])
print "fit0, fit1 of CCPAX regression line:", fit[0], fit[1]
plt.plot(x,fit[0] * x + fit[1], linewidth=2, color='blue')
# label1 has '6.2f', label2 has '4.2f', so the two numbers would line
# up vertically.
label2 = "CCPAX: %4.2f"%rmse(tbl['col4'], tbl['col5'])
#
# Now do the same for the second dataset:
tbl = ascii.read(infile3)
tbl.colnames
plt.scatter(tbl['col4'], tbl['col5'],s=1,color='green',alpha=0.2) #'s' is size of dots
fit = plt.polyfit(tbl['col4'], tbl['col5'], deg=1)
print rmse(tbl['col4'], tbl['col5'])
print "fit0, fit1 of CCPAX regression line:", fit[0], fit[1]
plt.plot(x,fit[0] * x + fit[1], linewidth=2, color='green')
# label1 has '6.2f', label2 has '4.2f', so the two numbers would line
# up vertically.
label3 = "ST4: %9.2f"%rmse(tbl['col4'], tbl['col5'])
#
title('24h analyses vs daily gauges, valid 12Z '+vday)
fig1 = plt.figure(1)
fig1.text(0.25,0.85,"RMSE (mm/day):",color="black")
fig1.text(0.27,0.82,label1,color="red")
fig1.text(0.27,0.79,label2,color="blue")
fig1.text(0.27,0.76,label3,color="green")
plt.savefig("scat."+vday+".png")
# for cron jobs, do not plot on screen:
#plt.show()
