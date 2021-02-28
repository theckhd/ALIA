/**
 * ...
 * @author theck
 */

import gui.theck.lurkerBarDsiplay;
import com.theck.Utils.Debugger;
import mx.utils.Delegate;

class com.theck.ALIA.lurkerCooldownTracker
{
	
	private var debugMode:Boolean = false;
	
	private var encounterPhase:Number;
	private var lurkerEliteLevel:Number;
	
	// Timing variables - parentheticals indicate recording in which this timing was observed
	
	// From Beneath You It Devours timings
	static var FROM_BENEATH_COOLDOWN_FIRST:Number = 44000;
	static var FROM_BENEATH_COOLDOWN:Number = 33500; // 33s minimum observed on various difficulties
	static var FROM_BENEATH_SHADOW_LOCKOUT_E17:Number = 44000; // (2021-01-06 E17) Shadow locks out Pod, observed in multiple difficulties
	static var FROM_BENEATH_SHADOW_LOCKOUT_E10:Number = 24500; // (2020-11-05 E10)
	
	// Pure Filth timings
	static var PURE_FILTH_COOLDOWN:Number = 18000; // SM - E10
	
	static var PURE_FILTH_COOLDOWN_E17_LONG:Number = 20000; // E17 - first cast of pair
	static var PURE_FILTH_COOLDOWN_E17_SHORT:Number = 10000; // E17 - second cast of pair
	static var PURE_FILTH_COOLDOWN_E17_TEST_INTERVAL:Number = 15000; // E17 - minimum delay to trigger small cooldown
	static var PURE_FILTH_COOLDOWN_E17_PHASE3_INITIAL:Number = 5000; // first cast after phase 3 starts
	static var PURE_FILTH_SHADOW_LOCKOUT:Number = 24500; // Shadow locks out Pure Filth, observed in multiple difficulties
	static var PURE_FILTH_FROM_BENEATH_LOCKOUT:Number = 9500; // Pod locks out Pure Filth by 9-10s as well, observed in multiple difficulties
	
	// Shadow Out Of Time timings 
	static var SHADOW_COOLDOWN_SM_FIRST:Number = 54000; // (2021-01-08)
	static var SHADOW_COOLDOWN_SM:Number = 41000; // (2021-01-08)
	
	static var SHADOW_COOLDOWN_E1_FIRST:Number = 38000 // ???
	static var SHADOW_COOLDOWN_E1:Number = 33000; // ???
	
	static var SHADOW_COOLDOWN_E5_FIRST:Number = 38000 // ???
	static var SHADOW_COOLDOWN_E5:Number = 33000; // ???
	
	static var SHADOW_COOLDOWN_E10_FIRST:Number = 60000; // (2020-11-05 E10)
	static var SHADOW_COOLDOWN_E10:Number = 90000; // 
	
	static var SHADOW_COOLDOWN_E17_FIRST:Number = 70000; // 70s
	static var SHADOW_COOLDOWN_E17:Number = 75000; // 75s (2021-01-06) 
	
	static var SHADOW_FROM_BENEATH_LOCKOUT:Number = 22000; // Pod seems to lock out Shadow for 22 seconds or so
	
	private var shadow_cooldown_first:Number;
	private var shadow_cooldown:Number;	
	
	
	static var POLLING_INTERVAL:Number = 100;
	
	private var fromBeneathCooldownRemaining:Number; 
	private var pureFilthCooldownRemaining:Number; 
	private var shadowCooldownRemaining:Number;
	
	private var firstShadowOfPhase3:Boolean = false;
	
	private var barUpdateInterval:Number;
	
	private var lastUpdateTime:Date;
	private var lastFilthCastTime:Date;
	
	public var barDisplay:lurkerBarDsiplay;
	
	public function lurkerCooldownTracker(display:lurkerBarDsiplay) 
	{
		Debugger.DebugText("lurkerCooldownTracker constructor", debugMode);
		barDisplay = display;
		encounterPhase = 0;
		lurkerEliteLevel = 0;
	}
	
	public function StartTrackingCooldowns():Void {
		
		// clear any existing polling interval
		StopTrackingCooldowns();
		Debugger.DebugText("StartTrackingCooldowns()", debugMode);
		
		
		// start polling every 250 ms
		barUpdateInterval = setInterval(Delegate.create(this, UpdateCooldowns), POLLING_INTERVAL);		
	}
	
	public function StopTrackingCooldowns() 
	{	
		
		Debugger.DebugText("StopTrackingCooldowns()", debugMode);
		clearInterval(barUpdateInterval); 		
	}
	
	public function UpdateEncounterPhase( phase:Number ) 
	{
		Debugger.DebugText("UpdateEncounterPhase() called with phase = " + phase + " and encounterPhase = " + encounterPhase, debugMode);
		if ( phase > encounterPhase ) {
			encounterPhase = phase;
			
			if ( encounterPhase == 1 ) {
				Debugger.DebugText("UpdateEncounterPhase() - Phase 1 block", debugMode);
				
				// on entering phase 1, set cooldown to 45 seconds
				fromBeneathCooldownRemaining = FROM_BENEATH_COOLDOWN_FIRST;
				Debugger.DebugText("UpdateEncounterPhase() - fromBeneathCooldownRemaining set to " + fromBeneathCooldownRemaining, debugMode);
				
				// sometimes lurker casts pure filth stealthily, just arbitrarily set cooldown here
				pureFilthCooldownRemaining = ( lurkerEliteLevel >= 17 ? PURE_FILTH_COOLDOWN_E17_SHORT : PURE_FILTH_COOLDOWN );
				Debugger.DebugText("UpdateEncounterPhase() - pureFilthCooldownRemaining set to " + pureFilthCooldownRemaining, debugMode);
				
				// set Shadow to undefined so that we don't track it
				// TODO: turn this into a phase 1 prediction algorithm?
				shadowCooldownRemaining = undefined;
				
				// show display and start updating
				barDisplay.SetVisible(true);
				UpdateBars();
				StartTrackingCooldowns();
			}
			else if ( encounterPhase == 2 ) {
				Debugger.DebugText("UpdateEncounterPhase() - Phase 2 block", debugMode);
				
				// hide display and stop updating
				StopTrackingCooldowns();
				
				// clear last update time and show display
				lastUpdateTime = undefined;				
				barDisplay.SetVisible(false);
			}
			else if ( encounterPhase == 3 ) {
				Debugger.DebugText("UpdateEncounterPhase() - Phase 3 block", debugMode);
				
				// Reset shadow and pod
				firstShadowOfPhase3 = true;
				ResetShadowCooldown();
				ResetFromBeneathCooldown();
				
				// set cooldown for pure filth in phase 3
				SetInitialPureFilthCooldownPhase3();
				
				// clear last update time
				lastUpdateTime = undefined;
				barDisplay.SetVisible(true);
				
				// don't start tracking cooldowns - let ALIA dictate that based on lurker health changing - but do update the bar display once
				UpdateBars();
			}
			else if ( encounterPhase == 4 ) {
				Debugger.DebugText("UpdateEncounterPhase() - Phase 4 block", debugMode);
				// hide display and stop updating
				StopTrackingCooldowns();
				barDisplay.SetVisible(false);
			}
		}
	}
	
	private function UpdateCooldowns() 
	{
		//Debugger.DebugText("UpdateCooldowns()", debugMode);
		
		var currentTime:Date = new Date();
		
		if !lastUpdateTime { lastUpdateTime = currentTime; }
		
		var reduxAmount:Number;
		
		reduxAmount = currentTime.getTime() - lastUpdateTime.getTime();
		if reduxAmount > 250 {
			Debugger.DebugText("UpdateCooldowns(): anomalous reduxAmount is " + reduxAmount, debugMode);
		}
		
		fromBeneathCooldownRemaining = ReduceCooldownRemaining( fromBeneathCooldownRemaining, reduxAmount );
		pureFilthCooldownRemaining = ReduceCooldownRemaining( pureFilthCooldownRemaining, reduxAmount );
		shadowCooldownRemaining = ReduceCooldownRemaining( shadowCooldownRemaining, reduxAmount );
		
		UpdateBars();
		lastUpdateTime = currentTime;
		
	}
	
	public function UpdateBars() 
	{		
		barDisplay.UpdateFromBeneathBar( fromBeneathCooldownRemaining );
		barDisplay.UpdatePureFilthBar( pureFilthCooldownRemaining );
		barDisplay.UpdateShadowBar( shadowCooldownRemaining );
	}
	
	private function ReduceCooldownRemaining(cdr:Number, amount:Number) 
	{
		
		// if the cooldown hasn't been started yet, skip
		if ( cdr == undefined ) {
			return undefined;
		}
		
		var newCD = cdr
		
		// decrement cooldown
		newCD -= amount;
		
		// cap at zero
		if newCD < 0 {
			newCD = 0;
		}
		
		return newCD;
	}
	
	public function ResetFromBeneathCooldown() 
	{
		Debugger.DebugText("ResetFromBeneathCooldown()", debugMode);
		// this is only called when it's cast by Lurker, so it can be the default value. 
		fromBeneathCooldownRemaining = FROM_BENEATH_COOLDOWN;
		
		// Pod also seems to prevent Pure Filth from being cast for 9-10s
		Debugger.DebugText("ResetFromBeneathCooldown() - Filth lockout data, cooldown was " + pureFilthCooldownRemaining, debugMode);
		
		pureFilthCooldownRemaining = Math.max(pureFilthCooldownRemaining, PURE_FILTH_FROM_BENEATH_LOCKOUT);
		
		Debugger.DebugText("ResetFromBeneathCooldown() - Filth lockout data, cooldown is now " + pureFilthCooldownRemaining, debugMode);
		
		// Pod ALSO also seems to prevent Shadow from being cast for ~22s
		Debugger.DebugText("ResetFromBeneathCooldown() - Shadow lockout data, cooldown was " + shadowCooldownRemaining, debugMode);
		
		shadowCooldownRemaining = Math.max(shadowCooldownRemaining, SHADOW_FROM_BENEATH_LOCKOUT);
		
		Debugger.DebugText("ResetFromBeneathCooldown() - Shadow lockout data, cooldown is now " + shadowCooldownRemaining, debugMode);
	}
	
	public function ResetPureFilthCooldown() 
	{
		Debugger.DebugText("ResetPureFilthCooldown(): lurkerEliteLevel is " + lurkerEliteLevel, debugMode);
		
		// if we're not on E17, apply standard cooldown
		if lurkerEliteLevel < 17 {
			pureFilthCooldownRemaining = PURE_FILTH_COOLDOWN;
			Debugger.DebugText("ResetPureFilthCooldown(): cooldown set to standard value", debugMode );
		}
		else {			
			// E17 casts come in pairs, but it seems like the game tracks the time since the last pure filth cast
			// to determine whether to apply the "short" (10s) or "long" (20s) version of the cooldown.
			// I've observed cases where the interval is 23s / 16s / 12s (because the second PF was delayed by Personal Space, 
			// suggesting that if it's been >15s since the last pure filth, it will apply the short cooldown
			
			// grab the current time
			var currentTime:Date = new Date();
			var timeDiff:Number;
			
			// if we don't have a last filth cast time, assume it's the first of a pair and set timeDiff > interval so that it invokes the short cooldown
			if ( !lastFilthCastTime ) {
				timeDiff = PURE_FILTH_COOLDOWN_E17_TEST_INTERVAL + 5000;
				Debugger.DebugText("ResetPureFilthCooldown(): lastFilthCastTime undefined, setting timeDiff to default: " + timeDiff, debugMode );
			}
			// otherwise calculate the time difference
			else {
				timeDiff = currentTime.getTime() - lastFilthCastTime.getTime();
				Debugger.DebugText("ResetPureFilthCooldown(): timeDiff is " + timeDiff, debugMode );
			}		
						
			// if the time difference is long enough, apply the short cooldown
			if ( timeDiff > PURE_FILTH_COOLDOWN_E17_TEST_INTERVAL ) { 
				pureFilthCooldownRemaining = PURE_FILTH_COOLDOWN_E17_SHORT;
				Debugger.DebugText("ResetPureFilthCooldown(): cooldown set to short (" + pureFilthCooldownRemaining + ")", debugMode );
			}
			// otherwise apply the long cooldown
			else {
				pureFilthCooldownRemaining = PURE_FILTH_COOLDOWN_E17_LONG; 
				Debugger.DebugText("ResetPureFilthCooldown(): cooldown set to long (" + pureFilthCooldownRemaining + ")", debugMode );
			}
			
			// set the last cast time to now
			lastFilthCastTime = currentTime;
			Debugger.DebugText("ResetPureFilthCooldown(): lastFilthCastTime set to " + currentTime, debugMode );
		}
		
/*		// old code, delete later. or not. I'm not your dad.
		if lurkerEliteLevel < 17 {
			pureFilthCooldownRemaining = PURE_FILTH_COOLDOWN;
		}
		else {
			// E17 casts come in pairs, but it seems like the game tracks the time since the last pure filth cast
			// to determine whether to apply the "short" (11s) or "long" (22s) version of the cooldown.
			// I've observed cases where the interval is 23s / 16s / 12s (because the second PF was delayed by Personal Space, 
			// suggesting that if it's been >15s since the last pure filth, it will apply the short cooldown
			
			var currentTime:Date = new Date();
			var timeDiff:Number;
			
			// if we don't have a last filth cast time, assume it's the first of a pair and set timeDiff > interval
			if ( !lastFilthCastTime ) {
				timeDiff = PURE_FILTH_COOLDOWN_E17_TEST_INTERVAL + 1;
			}
			// otherwise calculate the time difference
			else {
				timeDiff = currentTime.getTime() - lastFilthCastTime.getTime();
			}
			
			// if the time difference is less than the cast time (plus a little wiggle room for latency/etc.), ignore. 
			// this is needed b/c every time you re-target the boss with the reticle, the game generates another "casting" call
			if ( timeDiff > PURE_FILTH_CAST_TIME + 500 ) {
				
				// if the time difference is long enough, apply the short cooldown
				if ( timeDiff > PURE_FILTH_COOLDOWN_E17_TEST_INTERVAL ) { 
					pureFilthCooldownRemaining = PURE_FILTH_COOLDOWN_E17_SHORT;
				}
				// otherwise apply the long cooldown
				else {
					pureFilthCooldownRemaining = PURE_FILTH_COOLDOWN_E17_LONG; 
				}
			}
			
			// set the last cast time to now
			lastFilthCastTime = currentTime;
		}*/
	}
	
	public function SetInitialPureFilthCooldownPhase3()
	{
		// this just sets the cooldown to 5 seconds at the beginning of phase 3 and clears the "last cast" time so we get the short cooldown
		pureFilthCooldownRemaining = PURE_FILTH_COOLDOWN_E17_PHASE3_INITIAL;
		lastFilthCastTime = undefined;
	}
	
	public function ResetShadowCooldown() 
	{
		// This one varies per difficulty (see SetLurkerEliteLevel()) and based on whether it's the first cast in phase 3 or not
		if ( firstShadowOfPhase3 ) {
			shadowCooldownRemaining = shadow_cooldown_first;
			firstShadowOfPhase3 = false;
			Debugger.DebugText("ResetShadowCooldown() - first shadow cooldown is " + shadow_cooldown_first, debugMode);
		}
		else {
			shadowCooldownRemaining = shadow_cooldown;
			Debugger.DebugText("ResetShadowCooldown() - 2+ shadow cooldown is " + shadow_cooldown, debugMode);
		}
		
		// Shadow seems to lock out Pure Filth and Pod when cast
		
		// The pod lockout appears to vary with difficulty (~25s on SM & E10, ~44s on E17, untested on E1/E5 yet)
		Debugger.DebugText("ResetShadowCooldown() - Pod lockout data, cooldown was " + fromBeneathCooldownRemaining, debugMode);
		
		if ( lurkerEliteLevel >= 17 ) {
			fromBeneathCooldownRemaining = Math.max(fromBeneathCooldownRemaining, FROM_BENEATH_SHADOW_LOCKOUT_E17);
		}
		else {
			fromBeneathCooldownRemaining = Math.max(fromBeneathCooldownRemaining, FROM_BENEATH_SHADOW_LOCKOUT_E10);
		}
		
		Debugger.DebugText("ResetShadowCooldown() - Pod lockout data, cooldown is now " + fromBeneathCooldownRemaining, debugMode);
		
		// the filth lockout appears to be ~25s on all difficulties
		Debugger.DebugText("ResetShadowCooldown() - Filth lockout data, cooldown was " + pureFilthCooldownRemaining, debugMode);
		
		pureFilthCooldownRemaining = Math.max(pureFilthCooldownRemaining, PURE_FILTH_SHADOW_LOCKOUT);
		
		Debugger.DebugText("ResetShadowCooldown() - Filth lockout data, cooldown is now " + pureFilthCooldownRemaining, debugMode);
		
		
	}
	
	public function SetLurkerEliteLevel(diff:Number) 
	{

		lurkerEliteLevel = diff;
		Debugger.DebugText("SetLurkerEliteLevel(): elite level is " + lurkerEliteLevel, debugMode);
		
		// set cooldowns based on elite level
		switch ( lurkerEliteLevel ) {
			
			case 17:
				shadow_cooldown = SHADOW_COOLDOWN_E17;
				shadow_cooldown_first = SHADOW_COOLDOWN_E17_FIRST;
				break;
			case 10:
				shadow_cooldown = SHADOW_COOLDOWN_E10;
				shadow_cooldown_first = SHADOW_COOLDOWN_E10_FIRST;
				break;
			case 5:
				shadow_cooldown = SHADOW_COOLDOWN_E5;
				shadow_cooldown_first = SHADOW_COOLDOWN_E5_FIRST;
				break;
			case 1:
				shadow_cooldown = SHADOW_COOLDOWN_E1;
				shadow_cooldown_first = SHADOW_COOLDOWN_E1_FIRST;
				break;
			case 0:
				shadow_cooldown = SHADOW_COOLDOWN_SM;
				shadow_cooldown_first = SHADOW_COOLDOWN_SM_FIRST;
				break;
			default:
				Debugger.DebugText("ALIA.lurkerCooldownTracker.SetLurkerEliteLevel(): Lurker Elite Level undefined. This should never happen. Tell Theck immediately!", true);
				break; // this is what the addon will do if this happens, too!
		}
	}
	
	public function ResetEncounter()
	{
		encounterPhase = 0;
		pureFilthCooldownRemaining = 0;
		lastUpdateTime = undefined;
		firstShadowOfPhase3 = false;
		fromBeneathCooldownRemaining = 0;
		pureFilthCooldownRemaining = 0;
		//ResetFromBeneathCooldown();
		//ResetPureFilthCooldown();
		shadowCooldownRemaining = undefined;
		lastFilthCastTime = undefined;
		Debugger.DebugText("ResetEncounter(): encounterPhase is now " + encounterPhase, debugMode);
	}
}