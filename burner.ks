//set STEERINGMANAGER:MAXSTOPPINGTIME to 6.
//set STEERINGMANAGER:PITCHPID:KD to 2.
//set STEERINGMANAGER:YAWPID:KD to 2.
//set STEERINGMANAGER:PITCHTS to 12.
//set STEERINGMANAGER:YAWTS to 12.
set spooltime to 1.
		
set g0 to constant():G0.
set dv to NEXTNODE:DELTAV:MAG.
set e  to CONSTANT():E.
clearscreen.
print "Steering".  
//SAS off.
//lock steering to NEXTNODE.
set m0 to 0.
print "Waiting for node".  
set rt to NEXTNODE:ETA.    // remaining time
until rt <= spooltime {
    set rt to NEXTNODE:ETA.    // remaining time
	set maxwarp to 5.
	if rt < 50000   { set maxwarp to 4. }
	if rt < 5000   { set maxwarp to 3. }
	if rt < 500    { set maxwarp to 2. }
	if rt < 100     { set maxwarp to 1. }
	if rt < 60    { set maxwarp to 0. }
	if rt < 6 {
	   if m0 = 0 {
			SET SHIP:CONTROL:FORE TO 1.
			set m0 to SHIP:MASS.
	   }
    }	   

    set WARP to maxwarp.
    print "    Remaining time:  " + rt at (0,5).  
    print "       Warp factor:  " + WARP at (0,6).  
}
SET SHIP:CONTROL:FORE TO 0.
set SHIP:CONTROL:PILOTMAINTHROTTLE to 1.
set bdv to 0.
Until bdv >= dv {
  set MyISP to 0.
  LIST ENGINES in MyEngines.
  for engine in MyEngines {
	if engine:typename() = "Engine" {
		if engine:ISP > 0 {
			set MyISP to engine:ISP.
		}
	}
  }

  if MyISP > 0 {
   set ve to MyISP * g0.
   set mf to SHIP:MASS.
   set bdv to ve * LN(m0/mf).
   print "Target Dv:  " + dv at (0,7).
   print "Burned Dv:  " + bdv at (0,8).
   print "Engine ISP: " + MyISP at (0,9).
   } else {
   print "Waiting for Engine Start." at (0,7).
   }
}

set SHIP:CONTROL:PILOTMAINTHROTTLE to 0.
print "Done." at (0,10).
unlock all.

