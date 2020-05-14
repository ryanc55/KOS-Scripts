set STEERINGMANAGER:MAXSTOPPINGTIME to 6.
set STEERINGMANAGER:PITCHPID:KD to 2.
set STEERINGMANAGER:YAWPID:KD to 2.
set STEERINGMANAGER:PITCHTS to 12.
set STEERINGMANAGER:YAWTS to 12.
set spooltime to 1.
		
set g0 to constant():G0.
set dv to NEXTNODE:DELTAV:MAG.
set m0 to SHIP:MASS.
set e  to CONSTANT():E.
clearscreen.
print "Steering".  // line 4
//SAS off.
//lock steering to NEXTNODE.

print "Waiting for node".  // line 5
set rt to NEXTNODE:ETA.    // remaining time
until rt <= spooltime {
    set rt to NEXTNODE:ETA.    // remaining time
	set maxwarp to 5.
	if rt < 50000   { set maxwarp to 4. }
	if rt < 5000   { set maxwarp to 3. }
	if rt < 500    { set maxwarp to 2. }
	if rt < 100     { set maxwarp to 1. }
	if rt < 60    { set maxwarp to 0. }
	set WARP to maxwarp.

    print "    Remaining time:  " + rt at (0,5).  // line 6
    print "       Warp factor:  " + WARP at (0,6).  // line 7
    if WARP > maxwarp {
        set WARP to maxwarp.
    }
}
set bdv to 0.
set throttle to 1.

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

set throttle to 0.
print "Done." at (0,10).
unlock all.

