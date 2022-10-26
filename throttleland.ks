@clobberbuiltins on.
set STEERINGMANAGER:MAXSTOPPINGTIME to 2.
set STEERINGMANAGER:PITCHPID:KD to .1.
set STEERINGMANAGER:YAWPID:KD to .1.
set STEERINGMANAGER:ROLLPID:KD to .5.
set STEERINGMANAGER:PITCHTS to 1.
set STEERINGMANAGER:YAWTS to 1.
set STEERINGMANAGER:ROLLTS to 1.
set STEERINGMANAGER:ROLLCONTROLANGLERANGE to 0.0000000001.
set radarOffset to 3.	// The value of ship:geoposition:position:MAG when landed (on gear)  //2.25 g8 3.68 rpod

LIST ENGINES in MyEngines.
for engine in MyEngines {
	if engine:ignition  {
			set spooltime to 0.3 + (choose 1 if engine:PressureFed else 2.8) / (3.0 / log10(max(1.1, sqrt(engine:DryMass * engine:PossibleThrustAt(0)^2)))).
			set engineisp to engine:VISP.
			set MyEngine to engine.
	}
}


clearscreen.
print "Turning to retrograde....".
lock steering to smoothRotate(srfretrograde).
wait until vang(srfretrograde:FOREVECTOR, ship:facing:forevector) < 0.8.

set safetyfactor to 1.05.  // Safety factor for terrain changes.  Can be near 1 for vertical landings.  
set thrott to 0.
set finalMass to ship:mass.
set e to constant():e.
set ve to engineisp * 9.80665.
set GC to constant():G.
lock trueRadar to MAX(0.01,ship:geoposition:position:MAG - radarOffset).
lock g to constant:g * body:mass / body:radius^2.		// Surface Gravity (m/s^2)
// lock g to ship:sensors:grav:mag.   // Current Gravity
lock vertcomponent to abs(ship:verticalspeed) / ship:velocity:surface:MAG.
lock maxDecel to MAX(0.001,(ship:availablethrust / ((ship:mass + finalMass)/2)) * vertcomponent - g) / safetyfactor.
lock stopDist to ship:verticalspeed^2 / (2 * maxDecel).
lock groundDist to trueRadar.
lock idealThrottle to stopDist / groundDist.
lock impactTime to trueRadar / max(0.01, -1 * ship:verticalspeed).
lock throttle to thrott.  // workaround for throttle bug when setting throttle directly
lock Pe to 2 * GC * body:mass * ( 1 / (body:radius) -   1 / (trueRadar+body:radius)).  // Potential energy per unit vessel mass
lock freeFallDv to (ship:velocity:surface:MAG) + (sqrt(Pe+ship:velocity:surface:MAG^2)-ship:velocity:surface:MAG).  
lock finalMass to ship:mass / (e^(freeFallDv / ve)).
//sas off.
rcs on.
brakes on.
set MyISP to 0.



clearscreen.
lock steering to SMOOTHROTATE (srfretrograde).
print "Phase 2 Only." at (0,1).
wait until ship:verticalspeed < -2.
wait until vertcomponent > .5.
set burning to false.
set desiredThrottle to .9.
UNTIL ship:verticalspeed > -0.01  {
	if burning {
		set thrott to desiredThrottle * idealThrottle - 2 * (desiredThrottle - idealThrottle).
		if MyISP > 0 {
			set engineisp to MyISP.
		}
	}
	else {
		set timeToBurn to (groundDist - (stopDist) / desiredThrottle) / abs(ship:verticalspeed).
		PRINT "Time to Burn: " + timeToBurn  at (0,8).
        if timeToBurn - spooltime < 8 {
			SET SHIP:CONTROL:FORE TO 1.
		}
		if timeToBurn < spooltime {
			SET SHIP:CONTROL:FORE TO 0.
			set thrott to idealThrottle.
			set burning to true.
			set burntime to time:seconds.
			Until MyISP > 0 {
				LIST ENGINES in MyEngines.
				for engine in MyEngines {
					if engine:typename() = "Engine" {
						if engine:ISP > 0 {
							set MyISP to engine:ISP.
							set currentEngine to engine.
						}
					}
				}
				print "Starting Engine.                        " at (0,7).
			}
		}
	}
	
	PRINT "g: " + g at (0,7).
	PRINT "finalMass: " + finalMass at (0,14).
	PRINT "vert component: = " + vertcomponent at (0,11).
	PRINT "maxdecel: " + maxdecel at (0,9).
    PRINT "Stop Dist: " + stopDist at (0,12).
	PRINT "Vertical Vel: " + ship:verticalspeed at (0,13).
	PRINT "Ground Dist:  " + groundDist at (0, 10).
    PRINT "freefallDv: " + freeFallDv at (0,15).
	PRINT "Ideal Throttle: " + idealThrottle at (0,16).	
	PRINT "ISP: " + MyISP at (0,17).
	PRINT "Spooltime: " + spooltime  at (0,18).

	
}


	print "Landing completed".
	set thrott to 0.
	set ship:control:pilotmainthrottle to 0.
	set SHIP:CONTROL:NEUTRALIZE to true.
    unlock throttle.
	unlock steering.
	set steering to UP.
	
FUNCTION realsmoothRotate {
    PARAMETER dir.
    LOCAL spd IS max(SHIP:ANGULARMOMENTUM:MAG/10,4).
    LOCAL curF IS SHIP:FACING:FOREVECTOR.
    LOCAL curR IS SHIP:FACING:TOPVECTOR.
    LOCAL rotR IS R(0,0,0).
    IF VANG(dir:FOREVECTOR,curF) < 90{SET rotR TO ANGLEAXIS(min(0.5,VANG(dir:TOPVECTOR,curR)/spd),VCRS(curR,dir:TOPVECTOR)).}
    RETURN LOOKDIRUP(ANGLEAXIS(min(2,VANG(dir:FOREVECTOR,curF)/spd),VCRS(curF,dir:FOREVECTOR))*curF,rotR*curR).
}

FUNCTION smoothRotate {
    PARAMETER dir.
    RETURN dir.
}