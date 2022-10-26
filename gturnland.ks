@clobberbuiltins on.
////Ship Tuning :  Fairly forgiving, but may need tweaking esp. radarOffset
set STEERINGMANAGER:MAXSTOPPINGTIME to 2.
set STEERINGMANAGER:PITCHPID:KD to 1.
set STEERINGMANAGER:YAWPID:KD to 1.
set STEERINGMANAGER:ROLLPID:KD to 1.
set radarOffset to 2.6.	// The value of ship:geoposition:position:MAG when landed (on gear)
set manualspooltime to 0.  // Set to 0 to auto-calculate.  YMMV
set desiredThrottle to .9. 
set minThrottle to .3.
set throttlekP to -10.   
set throttlekD to 0.
set throttlekI to throttlekP / 10.
set throttlePID to PIDLOOP(throttlekP, throttlekI, throttlekD).
set throttlePID:MAXOUTPUT to 1. 
set throttlePID:MINOUTPUT to minThrottle.
set throttlePID:SETPOINT to desiredThrottle.
set ullageTime to 10.  //Includes spool time
set landingSpeed to 6.  //   Dropping in reduces dust :-)
////Ship Tuning

SetEngine().
set e to constant():e.
set ve to engineisp * 9.80665.
set thrott to 0.
set GC to constant():G.
set g to constant:g * body:mass / body:radius^2.		// Surface Gravity (m/s^2)
lock orbitalspeed to sqrt(GC * body:mass / body:POSITION:MAG).
groundsim(1).
lock trueRadar to MAX(0.01,ship:altitude - landing_pos:terrainheight - radarOffset * 10).
lock vertcomponent to abs(VDOT(SHIP:UP:VECTOR,ship:velocity:surface:normalized)).
lock idealThrottle to stopDist / trueRadar.
lock impactTime to trueRadar / max(0.01, -1 * ship:verticalspeed).
lock throttle to thrott.  // workaround for throttle bug when setting throttle directly
lock Pe to 2 * GC * body:mass * ( 1 / (body:radius) -   1 / (ship:geoposition:position:MAG+body:radius)).  // Potential energy per unit vessel mass
lock freeFallDv to (ship:velocity:surface:MAG) + (sqrt(Max(0,Pe+ship:velocity:surface:MAG^2))-ship:velocity:surface:MAG).  
lock finalMass to ship:mass / (e^(freeFallDv / ve)).
lock avgAcc to ship:availablethrust/((ship:mass + finalMass)/2).
lock avgTWR to avgAcc/g.
lock oberth to 1 - (ship:velocity:orbit:mag/orbitalspeed)^2.
lock maxvDecel to MAX(0.001,avgAcc * vertcomponent - (g * oberth)).
lock stagevDecel to MAX(0.001,avgAcc * max(.7,vertcomponent) - g ).
lock stopDist to ship:verticalspeed^2 / (2 * maxvDecel).
lock shipacc to ship:availablethrust/ship:mass.

sas off.
rcs on.
brakes on.
clearscreen.
print "Turning to retrograde....".
lock steering to srfretrograde.
wait until vang(srfretrograde:FOREVECTOR, ship:facing:forevector) < 0.8.
when impactTime < 20 then {gear on.}

clearscreen.
print "Phase 1..." at (0,1).  
set burning to false.

UNTIL (burning AND (vertcomponent > .9 ) OR trueRadar < (10 * avgTWR)) {  


	if burning {
	  groundsim(1).
	  set thrott to throttlePID:UPDATE(TIME:SECONDS,totaly/trueRadar).	
	} else {
		groundsim(desiredThrottle).
		if ((totaly+spoolTime*(ship:velocity:surface:MAG*vertcomponent)) > trueRadar) {
			set thrott to desiredThrottle.
			set burning to true.
			SET SHIP:CONTROL:FORE to 0.
		} else {
			if ((totaly+ullageTime*(ship:velocity:surface:MAG*vertcomponent)) > trueRadar) {
				SET SHIP:CONTROL:FORE TO 1. 
			}
		}	
	}
	print "Y stop distance: " + totaly	at (0,7).
	print "Throttle: " + thrott + "                                         " at (0,8).
	print "vertcomponent: " + vertcomponent at (0,17).
	Print "vspeed: " + ship:verticalspeed at (0,19).
	PRINT "Ground Speed: " + ship:groundspeed at (0,16).
	PRINT "Ground Dist:  " + trueRadar at (0, 10).
    PRINT "freefallDv: " + freeFallDv at (0,15).
	PRINT "P : " + throttlePID:PTERM + "                                         " at (0,20).
	PRINT "I : " + throttlePID:ITERM + "                                         " at (0,21).
	PRINT "D : " + throttlePID:DTERM + "                                         " at (0,22).
}

clearscreen.

lock steering to srfretrograde.
print "Phase 2..." at (0,1).
lock trueRadar to MAX(0.01,ship:geoposition:position:MAG - radarOffset).


UNTIL ship:verticalspeed > -1  {
	if burning {
		if (idealThrottle < minThrottle) {
			set thrott to 0.
			set burning to false.
		} else {
			set thrott to max(minThrottle,idealThrottle + 2 * (idealThrottle - desiredThrottle )).	
		}
	}
	else {
		set timeToBurn to (trueRadar - stopDist)/abs(ship:verticalspeed).
		PRINT "Time to Burn: " + timeToBurn  at (0,8).
	   	IF timeToBurn < ullageTime {
		SET SHIP:CONTROL:FORE TO 1. 
		}
		if (idealThrottle > desiredThrottle OR (timeToBurn - spooltime) < (avgTWR / 2)) { 
			set thrott to idealThrottle.
			SET SHIP:CONTROL:FORE to 0.
			set burning to true.
		}
	}

	PRINT "g: " + g at (0,7).
	PRINT "finalMass: " + finalMass at (0,14).
	PRINT "vert component: = " + vertcomponent at (0,17).
	PRINT "maxvDecel: " + maxvDecel at (0,9).
    PRINT "Stop Dist: " + stopDist at (0,12).
	PRINT "Stop Time: " + totalt at (0,8).
	PRINT "Vertical Vel: " + ship:verticalspeed at (0,13).
	PRINT "Ground Dist:  " + trueRadar at (0, 10).
    PRINT "freefallDv: " + freeFallDv at (0,15).
	PRINT "Ideal Throttle: " + idealThrottle at (0,16).	
    wait 0.01.
}

	set thrott to 0.
	set ship:control:pilotmainthrottle to 0.
    lock steering to UP.

	wait until ship:STATUS = "LANDED" or ship:STATUS = "SPLASHED".
	
	print "Landing completed".

    unlock throttle.
	unlock steering.


function SetEngine {
	LIST ENGINES in MyEngines.
	for engine in MyEngines {
		if engine:ignition  {
				set engineisp to engine:VISP.
				if manualspooltime = 0 {
					set spooltime to 0.34 + (choose 1 if engine:PressureFed else 2.8) / (3.0 / log10(max(1.1, sqrt(engine:DryMass * engine:PossibleThrustAt(0)^2)))).
				}
				else {
					set spooltime to manualspooltime.
				}
				set MyEngine to engine.
		}
	}
}

function steering_dir {
    parameter dir.

    return LOOKDIRUP(dir:VECTOR, FACING:TOPVECTOR).
}

global function groundsim {
    parameter simthrottle is desiredThrottle.
	set totalt to 0.
	set totalx to 0.
	set totaly to 0.
	set dt to 2.
	set velvector to ship:velocity:surface.
	set vel to velvector:MAG.
	set simmassflow to MyEngine:MAXMASSFLOW/simthrottle.
	set done to false.
	set simshipmass to ship:mass.
	set psi to vang(velvector, -1*UP:VECTOR).
	set simshipacc to ship:availablethrust/ship:mass*simthrottle.
	
	until done {
		if (simshipacc * dt > vel) {
			set done to true.
			set dt to vel/simshipacc. 
		}
		set totalt to totalt + dt.
        set simshipmass1 to ship:mass - simmassflow * totalt.
		set simshipacc to (ship:availablethrust*simthrottle/((simshipmass+simshipmass1)/2)).
		set dvel to (simshipacc * dt) * (-1*velvector:NORMALIZED).		
		set velvector to velvector + dvel.
		set velvector to velvector + (-1*UP:VECTOR) * (g * (1-(vel/orbitalspeed)^2) *dt). //should be velocity:orbit
		set vel1 to velvector:MAG.
		set avgvel to (vel1+vel)/2.		
		set psi1 to vang(velvector, -1*UP:VECTOR).
		set dx to (sin(psi)+sin(psi1))*avgvel*dt/2.
		set dy to (cos(psi)+cos(psi1))*avgvel*dt/2.
		set totalx to totalx + dx.
		set totaly to totaly + dy.
		set psi to psi1.
		set simshipmass to simshipmass1.
		set vel to vel1.
		
		//print "psi: " + psi + " t: " + round(t,2) + " v: " + round(vel,2) + " t: " + round(t,2) + " y: " + round(totaly,2) + " simshipcurmass: " + round(simshipcurmass,5).
	}
   set landing_pos to body:geopositionof(body:geopositionof(ship:position):position +  totalx * vxcl(up:vector, velocity:surface):NORMALIZED).
}


