// Edit this block to suit your craft.
set STEERINGMANAGER:MAXSTOPPINGTIME to 4.
set STEERINGMANAGER:PITCHPID:KD to 1.
set STEERINGMANAGER:YAWPID:KD to 1.
set STEERINGMANAGER:ROLLPID:KD to 1.
set STEERINGMANAGER:PITCHTS to 2.
set STEERINGMANAGER:YAWTS to 2.
set STEERINGMANAGER:ROLLTS to 2.
set engineisp to 315.
set spooltime to 1.   
set radarOffset to 1.68.	// The value of ship:geoposition:position:MAG when landed (on gear)  //2.25 g8 3.68 rpod
set safetyfactor to 1.02.  // Safety factor for terrain changes.  Can be near 1 for vertical landings.  

set finalMass to ship:mass.
set e to constant():e.
set ve to engineisp * 9.80665.
set thrott to 0.
set GC to constant():G.
lock trueRadar to MAX(0.01,ship:geoposition:position:MAG - radarOffset).
lock g to constant:g * body:mass / body:radius^2.		// Surface Gravity (m/s^2)
// lock g to ship:sensors:grav:mag.   // Current Gravity
lock vertcomponent to abs(ship:verticalspeed) / ship:velocity:surface:MAG.
lock maxDecel to MAX(0.001,(ship:availablethrust / ((ship:mass + finalMass)/2)) * vertcomponent - g).
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
when impactTime < 20 then {gear on.}

clearscreen.
print "Turning to retrograde....".
//lock steering to smoothRotate(srfretrograde).
//wait until vang(srfretrograde:FOREVECTOR, ship:facing:forevector) < 0.8.

clearscreen.
print "Phase 1..." at (0,1).  // Ballistic descent with hard deck at 5000m

set thrott to 1.
set harddeck to ship:geoposition:terrainheight + 5000.

UNTIL TRUE {  //ship:velocity:surface:MAG < freeFallDv / 4

	set deckdist to altitude - harddeck.
	set braketime to ship:velocity:surface:MAG / (ship:availablethrust / ((ship:mass + finalMass)/2)).
	set descentspeed to -1 * deckdist / braketime.
    set correction to max(0,descentspeed - ship:verticalspeed) / 10.
    SET SteeringVec to -1 * (ship:velocity:surface):NORMALIZED + UP:FOREVECTOR * correction.
    lock steering to SMOOTHROTATE(SteeringVec:DIRECTION).
	PRINT "g: " + g at (0,7).
	PRINT "finalMass: " + finalMass at (0,14).
	PRINT "vert component: = " + vertcomponent at (0,11).
	PRINT "maxdecel: " + maxdecel at (0,9).
    PRINT "Target Vel: " + descentspeed at (0,12).
	PRINT "Vertical Vel: " + ship:verticalspeed at (0,13).
	PRINT "Ground Dist:  " + groundDist at (0, 10).
	PRINT "Correction: " + correction  at (0,8).
    PRINT "freefallDv: " + freeFallDv at (0,15).
	wait 0.5.
}
set thrott to 0.

clearscreen.
//lock steering to SMOOTHROTATE (srfretrograde).
print "Phase 2..." at (0,1).
wait until ship:verticalspeed < 0.
wait until vertcomponent > .5.
set burning to false.
UNTIL ship:verticalspeed > -0.01 {
	if burning {
		if idealThrottle > .9 {
			set thrott to idealThrottle * 1.1.
		}
		else if idealThrottle > .5 {
			set thrott to idealThrottle / 1.1.
		}
		else {  //shouldn't be needed.
			set thrott to 0.
			set burning to false.
		}
	}
	else {
		set timeToBurn to (groundDist - stopDist)/abs(ship:verticalspeed).
		PRINT "Time to Burn: " + timeToBurn  at (0,8).
	   	IF timeToBurn < 15 {
		SET SHIP:CONTROL:FORE TO 1.  //ullage
		}
		if timeToBurn - spooltime < 1 {
			set thrott to idealThrottle.
			SET SHIP:CONTROL:FORE to 0.0.
			set burning to true.
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
    wait 0.01.
}

	print "Landing completed".
	set thrott to 0.
	set ship:control:pilotmainthrottle to 0.
    unlock throttle.
//	unlock steering.

FUNCTION smoothRotate {
    PARAMETER dir.
    LOCAL spd IS max(SHIP:ANGULARMOMENTUM:MAG/10,4).
    LOCAL curF IS SHIP:FACING:FOREVECTOR.
    LOCAL curR IS SHIP:FACING:TOPVECTOR.
    LOCAL rotR IS R(0,0,0).
    IF VANG(dir:FOREVECTOR,curF) < 90{SET rotR TO ANGLEAXIS(min(0.5,VANG(dir:TOPVECTOR,curR)/spd),VCRS(curR,dir:TOPVECTOR)).}
    RETURN LOOKDIRUP(ANGLEAXIS(min(2,VANG(dir:FOREVECTOR,curF)/spd),VCRS(curF,dir:FOREVECTOR))*curF,rotR*curR).
}