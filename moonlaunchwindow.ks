//Parking orbit solver for above lunar plane launches.
//Thanks and credit to PLAD for the spreadsheet this is based off.

CLEARSCREEN.
//lat long of launch
set launchLat to SHIP:GEOPOSITION:LAT. 
set launchLong to SHIP:GEOPOSITION:LNG.

//LAN delta launch to orbit due to Earth spin and launch profile.  Measure on a test launch of your vessel. ~6 from mid lattitudes due east launch.  0 for mechjeb ascent guidance.
set LANgrowth to 0. 

set moon to body("Moon").
set eartharth to body("Earth").
set earthSiderealRot to Earth:ROTATIONPERIOD.
set earthDegDay to 360*(86400/earthSiderealRot).
set moonIncl to moon:ORBIT:INCLINATION.
set moonLAN to moon:ORBIT:LAN.
set moonArgP to moon:ORBIT:ARGUMENTOFPERIAPSIS.
set moonEcc to moon:ORBIT:ECCENTRICITY.
set moonSMA to moon:ORBIT:SEMIMAJORAXIS.
set moonMDA to constant:RadtoDeg * 0.2299708307.  //0.2303657634 without Principia

set minTravelTime to 3. 

set timeNow to TIME:seconds/86400.


set iterations to 1.
until iterations < 1 {

set moonArrival to minTravelTime + 1. 
set moonTA to BODY("Moon"):ORBIT:TRUEANOMALY + moonMDA*moonArrival.
set moonNTA to MOD(moonTA+360 ,360).
set radius to (moonSMA*(1-moonEcc^2))/(1+moonEcc*COS(moonNTA)).
set xCoord to radius*(COS(moonLAN)*COS(moonArgP+moonNTA)-SIN(moonLAN)*SIN(moonArgP+moonNTA)*COS(moonIncl)).
set yCoord to radius*(SIN(moonLAN)*COS(moonArgP+moonNTA)+COS(moonLAN)*SIN(moonArgP+moonNTA)*COS(moonIncl)).
set zCoord to radius*(SIN(moonArgP+moonNTA)*SIN(moonIncl)).
set moonAngle to MOD((ARCTAN2(yCoord,xCoord))+360,360).
set moonLat to ARCSIN(zCoord/radius).

set launchAngle to moonAngle - ARCCOS(moonLat/launchLat).  //TODO: give user choice of these two windows.
//set launchAngle to moonAngle + ARCCOS(moonLat/launchLat).
set targetLAN to MOD(launchAngle+270,360).
set earthRotArrival to MOD(BODY("Earth"):ROTATIONANGLE+(moonArrival*earthDegDay)+360,360).
set absLaunchSiteLong to MOD(earthRotArrival+launchLong+LANgrowth+360,360).
set daysSinceLaunchAngle to ((absLaunchSiteLong-launchAngle)/(360/earthSiderealRot))/86400.

if daysSinceLaunchAngle < 0 {
	set travelTime to daysSinceLaunchAngle+((minTravelTime+1)*(earthSiderealRot/86400)).
	} else {
	set travelTime to daysSinceLaunchAngle+(minTravelTime*(earthSiderealRot/86400)).
}

set launchTime to moonArrival-travelTime.
set timeNow to launchTime.
set iterations to iterations - 1.
}

print "Launching to Lunar intercept plane." at (0,4).
print "Target LAN: " + HMSText(targetLAN) at (0,5).
set launchTime to launchTime * 86400 + TIME:seconds.
set tminus to 1.
until tminus < 0 {

set maxwarp to 5.
if tminus < 50000   { set maxwarp to 4. }
if tminus < 5000   { set maxwarp to 3. }
if tminus < 500    { set maxwarp to 2. }
if tminus < 50     { set maxwarp to 1. }
if tminus < 5    { set maxwarp to 0. }
print "Time Warp:  " + WARP at (0,5).  
set WARP to maxwarp.

set tminus to launchTime - TIME:seconds.
print "T-minus " + floor(tminus) + " seconds." at (0,6).
wait 0.2.
}
print "Liftoff!" at (0,8).

STAGE.

function HMSText {
	parameter n.
	
	set H to floor(n).
	set n to (n - H) * 60.
	set M to floor(n).
	set n to n - M.
	set S to floor(n * 60).
	return H + char(176) + M + "'" + S + char(34).
	
}