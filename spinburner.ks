PARAMETER burnDelay is 0.

//set STEERINGMANAGER:MAXSTOPPINGTIME to 2.
//set STEERINGMANAGER:ROLLPID:KD to 4.
//set STEERINGMANAGER:PITCHPID:KD to 4.
//set STEERINGMANAGER:YAWPID:KD to 4.
//set STEERINGMANAGER:PITCHTS to 12.
//set STEERINGMANAGER:YAWTS to 12.
//set STEERINGMANAGER:ROLLTS to 12.
set spooltime to 3.
		
set g0 to constant():G0.
set dv to NEXTNODE:DELTAV:MAG.
set e  to CONSTANT():E.
clearscreen.
print "Steering".  
//SAS off.
//lock steering to NEXTNODE.

print "Waiting for node".  // line 5
set rt to NEXTNODE:ETA.    // remaining time
set goTime to 15 - burnDelay.
until rt <= (spooltime - burnDelay) {
    set rt to NEXTNODE:ETA.    // remaining time
	set maxwarp to 5.
	if rt < 50000   { set maxwarp to 4. }
	if rt < 5000   { set maxwarp to 3. }
	if rt < 500    { set maxwarp to 2. }
	if rt < 100     { set maxwarp to 1. }
	if rt < 60    { set maxwarp to 0. }
	if rt < goTime {
	   SET SHIP:CONTROL:FORE TO 1.
	   SET SHIP:CONTROL:ROLL TO 1.
    }	   

    print "    Remaining time:  " + (rt + burnDelay) at (0,5).  // line 6
    print "       Warp factor:  " + WARP at (0,6).  // line 7
    if WARP <> maxwarp {
        set WARP to maxwarp.
    }
}

SET SHIP:CONTROL:FORE TO 0.
SET SHIP:CONTROL:ROLL TO 0.
	   
STAGE.
set SHIP:CONTROL:PILOTMAINTHROTTLE to 1.
set bdv to 0.
set m0 to SHIP:MASS.
set MyISP to 0.



Until MyISP <> 0 {
	LIST ENGINES in MyEngines.
	for engine in MyEngines {
		if engine:typename() = "Engine" {
			if engine:ISP > 0 {
				set MyISP to engine:VISP.
			}
		}
	}
   print "Waiting for Engine Start." at (0,7).
}

clearscreen.
set delta to 0.
set lastdv to dv.
set ve to MyISP * g0.

Until bdv + 2 * delta >= dv {
   set mf to SHIP:MASS.
   set bdv to ve * LN(m0/mf).
   print "Target Dv:  " + dv at (0,7).
   print "Burned Dv:  " + bdv at (0,8).
   print "Engine ISP: " + MyISP at (0,9).
   set delta to dv - lastdv.
   set lastdv to dv.
}


set SHIP:CONTROL:PILOTMAINTHROTTLE to 0.
SET SHIP:CONTROL:NEUTRALIZE TO TRUE.
print "Done." at (0,10).
unlock all.

