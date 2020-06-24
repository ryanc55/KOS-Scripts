set landing_pos to LATLNG(0.6875,23.4358).
// 00°41′15″N, 23°26′00″E
set STEERINGMANAGER:MAXSTOPPINGTIME to 8.
set STEERINGMANAGER:PITCHPID:KD to .1.
set STEERINGMANAGER:YAWPID:KD to .1.
set STEERINGMANAGER:ROLLPID:KD to .5.
set STEERINGMANAGER:PITCHTS to 4.
set STEERINGMANAGER:YAWTS to 4.
set STEERINGMANAGER:ROLLTS to 4.
set STEERINGMANAGER:ROLLCONTROLANGLERANGE to 0.0000000001.
set engineisp to 440.
set spooltime to 1.5.   
set radarOffset to 4.97.	// The value of ship:ALTITUDE when landed (on gear)  //1.887 base 2.66 lander

set safetyfactor to 1.02.  // Safety factor for terrain changes.  Can be near 1 for vertical landings.  
set harddeck to 5000.

set e to constant():e.
set ve to engineisp * 9.80665.
set thrott to 0.
set GC to constant():G.
lock trueRadar to MAX(0.01,ship:altitude - landing_pos:terrainheight - radarOffset).
//lock trueRadar to ship:altitude - landing_pos:terrainheight - radarOffset.
lock g to constant:g * body:mass / body:radius^2.		// Surface Gravity (m/s^2)
// lock g to ship:sensors:grav:mag.   // Current Gravity
lock vertcomponent to abs(ship:verticalspeed) / ship:velocity:surface:MAG.
lock groundDist to trueRadar.
lock idealThrottle to stopDist / groundDist.
lock impactTime to trueRadar / max(0.01, -1 * ship:verticalspeed).
lock throttle to thrott.  // workaround for throttle bug when setting throttle directly
lock Pe to 2 * GC * body:mass * ( 1 / (body:radius) -   1 / (trueRadar+body:radius)).  // Potential energy per unit vessel mass
lock freeFallDv to (ship:velocity:surface:MAG) + (sqrt(Pe+ship:velocity:surface:MAG^2)-ship:velocity:surface:MAG).  
lock finalMass to ship:mass / (e^(freeFallDv / ve)).
lock maxDecel to MAX(0.001,(ship:availablethrust / ((ship:mass + finalMass)/2)) * vertcomponent - g).
lock stopDist to ship:verticalspeed^2 / (2 * maxDecel).
sas off.
rcs on.
brakes on.
set orbitalspeed to ship:groundspeed.  // fixme with right formula.

clearscreen.
clearvecdraws().

set LandingPositionVector to VECDRAW(V(0,0,0),landing_pos:position,RGB(0,.7,.7),"Landing Position",1.0,TRUE,.5).
set LandingPositionVector:vectorupdater to { return landing_pos:position.}.
set LandingPositionVector:startupdater to { return V(0,0,0).}.

set SurfaceVelocity to VECDRAW(V(0,0,0),ship:velocity:surface,RGB(0,0,.7),"Surface Velocity",1.0,TRUE,.5).
set SurfaceVelocity:vectorupdater to { return ship:velocity:surface.}.
set SurfaceVelocity:startupdater to { return V(0,0,0).}.

print "Turning to retrograde....".
lock steering to srfretrograde.
wait until vang(srfretrograde:FOREVECTOR, ship:facing:forevector) < 0.5.

clearscreen.
print "Phase 1..." at (0,1).  // constant velocity descent with hard deck offset.

set radarOffset to radarOffset + harddeck.

set burning to false.
set hdist to 0.
set hdistold to 0.

UNTIL (ship:groundspeed < 50 and (hdist > hdistold OR ship:verticalspeed > ship:groundspeed / -10)) OR ship:groundspeed < .1 {  //need a better test for misses
	set sPos to ship:body:position.
	set sVel to ship:velocity:surface.
	set angle_diff_h to VANG(-sPos, landing_pos:position - sPos).
	set hdistold to hdist.
	set hdist to (angle_diff_h/360)*2*(constant:pi)*sPos:mag.
	set maxhDecel to ship:availablethrust / ((ship:mass + finalMass)/2).
	set hstopdist to ship:groundspeed^2 / (2 * maxhDecel).
	set hthrott to MAX(.15,hstopdist / MAX(.001,hdist)).
	set hthrott to hthrott + (hthrott - .7).
	set hvector to -1 * hthrott * VCRS(sPos,VCRS(sVel,sPos)):normalized.
	set htime to ship:groundspeed / (hthrott * maxhDecel).
	set hspeed to VDOT(VCRS(ship:body:position,VCRS(sVel,ship:body:position)):normalized, sVel). //debug

    set idealvspeed to -1 * trueRadar / htime.
	set ig to -1 * g * (1 - ship:groundspeed / orbitalspeed).
	set fixvacc to MAX(0,(idealvspeed - ship:verticalspeed) - ig) / 2.
	if ship:groundspeed > 50 {
		set vthrott to min(0.4,fixvacc / (ship:availablethrust / ship:mass) / 2).
		set vvector to UP:vector * vthrott.
	}
	
	local V_side to VCRS(sVel,sPos):normalized.
	local V_per to VCRS(sPos,V_side):normalized.
	local T_vec to VCRS(sPos,VCRS(landing_pos:position,sPos)):normalized.
	local sdv to -1*VDOT(V_side,(T_vec*sVel:mag - V_per*sVel:mag)).
	if ship:groundspeed > 50 {
		set sthrott to MIN(.1,(sdv*mass)/(availablethrust)/htime*4).
		set svector to -1*VCRS(sVel,sPos):normalized * sthrott.
	}
    SET SteeringVec to hvector + vvector + svector.
	
	if burning {
		lock steering to SteeringVec:DIRECTION.
		set thrott to SteeringVec:MAG.
	} else if hthrott > .7 and htime > 0 {
		set burning to true.
	}
	
	PRINT "g: " + g at (0,7).
	PRINT "finalMass: " + finalMass at (0,14).
	Print "htime: " + htime at (0,9).
	Print "idealvspeed: " + idealvspeed at (0,18).
	PRINT "Ground Speed: " + ship:groundspeed at (0,16).
	PRINT "vthrott: " + vthrott + "                     " at (0,11).
    PRINT "hthrott: " + hthrott at (0,12).
	PRINT "sthrott: " + sthrott at (0,13).
	PRINT "Ground Dist:  " + groundDist at (0, 10).
	PRINT "throttle: " + SteeringVec:MAG at (0,8).
    PRINT "freefallDv: " + freeFallDv at (0,15).
	PRINT "hspeed: " + hspeed at (0,17).
	PRINT "fixvacc: " + fixvacc at (0,19).
//	PRINT "Current estimate : " + (htime + time - otime) at (0,20). 
//	PRINT "coordinate check:  " + VANG(vvector,hvector) at (0,21).
	wait 0.
}
set thrott to 0.
clearscreen.
lock steering to smoothRotate(srfretrograde).
print "Phase 2..." at (0,1).
when impactTime < 20 then {gear on.}
set radarOffset to radarOffset - harddeck.
wait until ship:verticalspeed < 0.
wait until vertcomponent > .5.
set burning to false.
UNTIL ship:verticalspeed > -0.01 {
	if burning {
		if idealThrottle > .8 {
			set thrott to idealThrottle * 1.1.
		}
		else if idealThrottle > .6 {
			set thrott to idealThrottle - ((.8 - idealThrottle) * 2).
		}
		else {  //shouldn't be needed.
			set thrott to 0.1.
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
	unlock steering.
	clearvecdraws().

FUNCTION smoothRotate {
    PARAMETER dir.
    LOCAL spd IS max(SHIP:ANGULARMOMENTUM:MAG/10,4).
    LOCAL curF IS SHIP:FACING:FOREVECTOR.
    LOCAL curR IS SHIP:FACING:TOPVECTOR.
    LOCAL rotR IS R(0,0,0).
    IF VANG(dir:FOREVECTOR,curF) < 90{SET rotR TO ANGLEAXIS(min(0.5,VANG(dir:TOPVECTOR,curR)/spd),VCRS(curR,dir:TOPVECTOR)).}
    RETURN LOOKDIRUP(ANGLEAXIS(min(2,VANG(dir:FOREVECTOR,curF)/spd),VCRS(curF,dir:FOREVECTOR))*curF,rotR*curR).
}

