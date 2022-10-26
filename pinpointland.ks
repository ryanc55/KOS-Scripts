@clobberbuiltins on.
parameter LandLAT is 0.6875.
parameter LandLNG is 23.433.  //Tranquility Base Default
set landing_pos to LATLNG(LandLAT,LandLNG).  // N and E
set STEERINGMANAGER:MAXSTOPPINGTIME to 2.
set STEERINGMANAGER:PITCHPID:KD to 1.
set STEERINGMANAGER:YAWPID:KD to 1.
set STEERINGMANAGER:ROLLPID:KD to 1.
set radarOffset to 2.8.	// The value of ship:geoposition:position:MAG when landed (on gear)
set manualspooltime to 0.  // Set to 0 to auto-calculate.  YMMV
set desiredThrottle to .8.  //Leave some for steering
set minThrottle to .3.


SetEngine().
set orbitheight to ship:altitude.
set initialdescent to ship:verticalspeed.
set harddeck to 0.  //temporary for turn shape calculation
set targetHeight to orbitheight/10.  // Try to miss high and hover for best accuracy
set targetStop to 0.
set e to constant():e.
set ve to engineisp * 9.80665.
set thrott to 0.
set GC to constant():G.
lock trueRadar to MAX(0.01,ship:altitude - landing_pos:terrainheight - radarOffset - harddeck).
set g to constant:g * body:mass / body:radius^2.		// Surface Gravity (m/s^2)
lock orbitalspeed to sqrt(GC * body:mass / body:POSITION:MAG).
lock vertcomponent to abs(VDOT(SHIP:UP:VECTOR,ship:velocity:surface:normalized)).
lock groundDist to trueRadar.
lock idealThrottle to stopDist / groundDist.
lock impactTime to trueRadar / max(0.01, -1 * ship:verticalspeed).
lock throttle to thrott.  // workaround for throttle bug when setting throttle directly
lock Pe to 2 * GC * body:mass * ( 1 / (body:radius) -   1 / (ship:altitude - landing_pos:terrainheight - radarOffset+body:radius)).  // Potential energy per unit vessel mass
lock freeFallDv to (ship:velocity:surface:MAG) + (sqrt(Max(0,Pe+ship:velocity:surface:MAG^2))-ship:velocity:surface:MAG).  
lock finalMass to ship:mass / (e^(freeFallDv / ve)).
lock avgAcc to ship:availablethrust/((ship:mass + finalMass)/2).
lock avgTWR to avgAcc/g.
lock oberth to 1 - (ship:velocity:orbit:mag/orbitalspeed)^2.
lock turnPercent to ship:velocity:surface:mag/orbitalspeed.
lock maxvDecel to MAX(0.001,avgAcc * vertcomponent - (g * oberth)).
lock stagevDecel to MAX(0.001,avgAcc * max(.7,vertcomponent) - g ).
lock stopDist to ship:verticalspeed^2 / (2 * maxvDecel).
lock stageStopDist to ship:verticalspeed^2 / (2 * stagevDecel).
lock stageThrottle to stageStopDist / (ship:altitude - landing_pos:terrainheight - radarOffset).
lock shipacc to ship:availablethrust/ship:mass.
set turnShape to avgTWR*4.
lock harddeck to min(ship:altitude,orbitheight * turnPercent^turnShape + targetHeight * (1-turnPercent)).
set verticalkP to 1.   
set verticalkD to 0. //verticalkP / 3 Already enough damping in bell inertia.
set verticalkI to verticalkP / 30.
set steeringPID to PIDLOOP(verticalkP, verticalkI, verticalkD).
set steeringPID:MAXOUTPUT to .7.  //throttle
set steeringPID:MINOUTPUT to -.2.
set steeringPID:SETPOINT to 0.


sas off.
rcs on.
brakes on.

clearscreen.
clearvecdraws().

set LandingPositionVector to VECDRAW(V(0,0,0),landing_pos:position,RGB(0,.7,.7),"Landing Position",1.0,TRUE,.5).
set LandingPositionVector:vectorupdater to { return landing_pos:position.}.
set LandingPositionVector:startupdater to { return V(0,0,0).}.

set SurfaceVelocity to VECDRAW(V(0,0,0),ship:velocity:surface,RGB(0,0,.7),"Surface Velocity",1.0,TRUE,.5).
set SurfaceVelocity:vectorupdater to { return ship:velocity:surface.}.
set SurfaceVelocity:startupdater to { return V(0,0,0).}.


lock steering to srfretrograde.

clearscreen.
print "Phase 1..." at (0,1).  // constant velocity descent with hard deck offset.

set burning to false.
set hdistmin to 99999999999999999.
set hdist to 0.

UNTIL ((vertcomponent > .5 AND stageThrottle > desiredThrottle) OR (hdist - hdistmin) > 1000 OR ship:groundspeed < 5) {  
	
	set sPos to ship:body:position.
	set sVel to ship:velocity:surface.
	set angle_diff_h to VANG(-sPos, landing_pos:position - sPos).
	set hdist to (angle_diff_h/360)*2*(constant:pi)*sPos:mag.
	set hdistmin to min(hdist,hdistmin).
	set maxhDecel to MAX(0.0001,(ship:availablethrust) / ((ship:mass + finalMass)/2)).
	set hstopdist to ship:groundspeed^2 / (2 * maxhDecel).
	set hstopacc to ship:groundspeed^2 / (2 * hdist).
	set hthrott to MAX(0,hstopacc/shipacc).
	set hthrott to max(minThrottle,hthrott + 2 * (hthrott - desiredThrottle)).
	set hvector to -1 * hthrott * VCRS(sPos,VCRS(sVel,sPos)):normalized.
	set htime to ship:groundspeed / (hthrott * maxhDecel).
	set idealvspeed to min(initialdescent,-1 * trueRadar / htime).
	set inputthrott to ((idealvspeed - ship:verticalspeed) * 4 ) / (shipacc * htime).
	set vthrott to steeringPID:UPDATE(TIME:SECONDS,-1 * inputthrott).	
	set vthrott to vthrott + (g / shipacc * oberth).  //gravity drag
	set vvector to UP:vector * vthrott.
	set finalvSpeed to ship:verticalspeed + htime * (vthrott * shipacc - g * oberth).
	local V_side to VCRS(sVel,sPos):normalized.
	local V_per to VCRS(sPos,V_side):normalized.
	local T_vec to VCRS(sPos,VCRS(landing_pos:position,sPos)):normalized.
	local sdv to -1*VDOT(V_side,(T_vec*sVel:mag - V_per*sVel:mag)).
	if ship:groundspeed > 50 {
		set sthrott to MIN(.2,(sdv*mass)/(availablethrust)/htime*2).
		set svector to -1*VCRS(sVel,sPos):normalized * sthrott.
	} else {
		set svector to V(0,0,0).
	}
		SET SteeringVec to hvector + vvector + svector.

	if burning {
		lock steering to steering_dir(SteeringVec:DIRECTION).
		set thrott to SteeringVec:MAG.
	} else {
	    set orbitheight to ship:altitude.
		set initialdescent to ship:verticalspeed.
		if SteeringVec:MAG > .95 and htime > 0 {
			set burning to true.
			set initialdescent to ship:verticalspeed.
			steeringPID:RESET.
		}
	}
	
	print "hdist: " + hdist at (0,6).
	PRINT "ETA: " + (hdist-hstopdist)/ship:groundspeed at (0,7). 
	PRINT "throttle: " + SteeringVec:MAG at (0,8).
	Print "htime: " + htime at (0,9).
	print "vertcomponent: " + vertcomponent at (0,17).
	Print "idealvspeed: " + idealvspeed at (0,18).
	Print "vspeed: " + ship:verticalspeed at (0,19).
	PRINT "Ground Speed: " + ship:groundspeed at (0,16).
	PRINT "vthrott: " + vthrott + "                     " at (0,11).
    PRINT "hthrott: " + hthrott at (0,12).
	PRINT "sthrott: " + sthrott at (0,13).
	PRINT "Ground Dist:  " + groundDist at (0, 10).
    PRINT "freefallDv: " + freeFallDv at (0,15).
	PRINT "P : " + steeringPID:PTERM + "                                         " at (0,20).
	PRINT "I : " + steeringPID:ITERM + "                                         " at (0,21).
	PRINT "D : " + steeringPID:DTERM + "                                         " at (0,22).
	PRINT "stageThrottle: " + stageThrottle at (0,14).
	Print "avgTWR: " + avgTWR  at (0,23).

	wait 0.
}

clearscreen.
Print  "Gspeed: " + round(ship:groundspeed,1) + " stageT: " + round(stageThrottle,2) + " hdelta: " + round(hdist-hdistmin) at (0,2).
lock steering to srfretrograde.
print "Phase 2..." at (0,1).
when impactTime < 20 then {gear on.}
lock trueRadar to MAX(0.01,ship:geoposition:position:MAG - radarOffset).

if idealThrottle < (.75* desiredThrottle) {
	set burning to false.
	set thrott to 0.
	wait until ship:verticalspeed < 0.
	wait until vertcomponent > .5.
}

UNTIL ship:verticalspeed > -0.01 {
	if burning {
		if (idealThrottle < minThrottle) {
			set thrott to 0.
			set burning to false.
			lock steering to srfretrograde.
		} else {
			set retroThrott to max(minThrottle,idealThrottle + 2 * (idealThrottle - desiredThrottle )).		
			SET SteeringVec to srfretrograde:vector:NORMALIZED * retroThrott.
			if freeFallDv > (shipAcc*3) {
				Set availableSteering to 1 - retroThrott. //fixme cosine gains
			} else {
				set availableSteering to 0.
			}
			set FixVec to (landing_pos:POSITION:NORMALIZED - srfprograde:VECTOR:NORMALIZED) * 2.
			set FixVec to FixVec:NORMALIZED * Min(availableSteering,Min(.3,FixVec:MAG)).

//			PRINT "Correction: " + Round (FixvecMag,2) + " >> " + round(retroThrott,2)+ " >> " + round(FixVec:MAG,2) + "                                         " at (0,18).
			set SteeringVec to SteeringVec+FixVec.
			SET STEERING to steering_dir(SteeringVec:Direction).
			Set thrott to SteeringVec:MAG.
		}
	}
	else {
		set timeToBurn to (groundDist - stopDist)/abs(ship:verticalspeed).
		PRINT "Time to Burn: " + timeToBurn  at (0,8).
	   	IF timeToBurn < 15 {
		SET SHIP:CONTROL:FORE TO 1.  //ullage
		}
		if (idealThrottle > desiredThrottle OR (timeToBurn - spooltime) < (avgTWR / 2)) { 
			set thrott to idealThrottle.
			SET SHIP:CONTROL:FORE to 0.0.
			set burning to true.
		}
	}

	PRINT "g: " + g at (0,7).
	PRINT "finalMass: " + finalMass at (0,14).
	PRINT "vert component: = " + vertcomponent at (0,17).
	PRINT "maxvDecel: " + maxvDecel at (0,9).
    PRINT "Stop Dist: " + stopDist at (0,12).
	PRINT "Vertical Vel: " + ship:verticalspeed at (0,13).
	PRINT "Ground Dist:  " + groundDist at (0, 10).
	Print "Target Dist: " + hdist at (0,11).
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