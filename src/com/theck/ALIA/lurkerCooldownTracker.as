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
	static var FROM_BENEATH_COOLDOWN_FIRST_PHASE1:Number = 44000;
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
	static var SHADOW_COOLDOWN_SM_FIRST:Number = 45000; // (2021-05-21 recording)
	static var SHADOW_COOLDOWN_SM:Number = 41000; // (2021-01-08)
	
	static var SHADOW_COOLDOWN_E1_FIRST:Number = 38000 // ???
	static var SHADOW_COOLDOWN_E1:Number = 33000; // ???
	
	static var SHADOW_COOLDOWN_E5_FIRST:Number = 38000 // ???
	static var SHADOW_COOLDOWN_E5:Number = 33000; // ???
	
	static var SHADOW_COOLDOWN_E10_FIRST:Number = 60000; // (2020-11-05 E10)
	static var SHADOW_COOLDOWN_E10:Number = 90000; // 
	
	static var SHADOW_COOLDOWN_E17_FIRST:Number = 70000; // 70s
	static var SHADOW_COOLDOWN_E17:Number = 75000; // 75s (2021-01-06) (recording from 5/12/2021 seems to show 82s+?)
	
	static var SHADOW_FROM_BENEATH_LOCKOUT:Number = 22000; // Pod seems to lock out Shadow for 22 seconds or so
	
	private var shadow_cooldown_first:Number;
	private var shadow_cooldown:Number;	
	
	
	static var POLLING_INTERVAL:Number = 100;
	
	private var fromBeneathCooldownRemaining:Number; 
	private var pureFilthCooldownRemaining:Number; 
	private var shadowCooldownRemaining:Number;
		
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
		
		
		// start polling every 100 ms (set by POLLING_INTERVAL)
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
				fromBeneathCooldownRemaining = FROM_BENEATH_COOLDOWN_FIRST_PHASE1;
				
				// sometimes lurker casts pure filth stealthily, just arbitrarily set cooldown here
				pureFilthCooldownRemaining = ( lurkerEliteLevel >= 17 ? PURE_FILTH_COOLDOWN_E17_SHORT : PURE_FILTH_COOLDOWN );
				
				// set Shadow to undefined so that we don't track it
				// TODO: turn this into a phase 1 prediction algorithm?
				shadowCooldownRemaining = undefined;
				
				// show display and start updating
				barDisplay.SetVisible(true, encounterPhase);
				UpdateBars();
				StartTrackingCooldowns();
			}
			else if ( encounterPhase == 2 ) {
				Debugger.DebugText("UpdateEncounterPhase() - Phase 2 block", debugMode);
				
				// hide display and stop updating
				StopTrackingCooldowns();
				
				// clear last update time and show display
				lastUpdateTime = undefined;				
				barDisplay.SetVisible(false, encounterPhase);
			}
			else if ( encounterPhase == 3 ) {
				Debugger.DebugText("UpdateEncounterPhase() - Phase 3 block", debugMode);
				
				// Reset shadow and pod
				SetShadowCooldown(shadow_cooldown_first);
				SetFromBeneathCooldown( FROM_BENEATH_COOLDOWN );				
				
				// set cooldown for pure filth in phase 3 and clear the lastFilthCastTime
				SetPureFilthCooldown(PURE_FILTH_COOLDOWN_E17_PHASE3_INITIAL);
				lastFilthCastTime = undefined;
				
				// clear last update time
				lastUpdateTime = undefined;
				barDisplay.SetVisible(true, encounterPhase);
				
				// don't start tracking cooldowns - let ALIA dictate that based on lurker health changing - but do update the bar display once
				UpdateBars();
			}
			else if ( encounterPhase == 4 ) {
				Debugger.DebugText("UpdateEncounterPhase() - Phase 4 block", debugMode);
				// hide display and stop updating
				StopTrackingCooldowns();
				barDisplay.SetVisible(false, encounterPhase);
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
		if reduxAmount > (2 * POLLING_INTERVAL ) {
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
		if encounterPhase == 3 { barDisplay.UpdateShadowBar( shadowCooldownRemaining ) };
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
	
	private function SetFromBeneathCooldown(cd:Number)
	{
		Debugger.DebugText("SetFromBeneathCooldown(): cd set to " + cd , debugMode);
		fromBeneathCooldownRemaining = cd;
	}
	
	public function ResetFromBeneathCooldown() 
	{
		Debugger.DebugText("ResetFromBeneathCooldown()", debugMode);
		// this is only called when it's cast by Lurker, so it can be the default value. 
		SetFromBeneathCooldown( FROM_BENEATH_COOLDOWN );
		
		// Pod also seems to prevent Pure Filth from being cast for 9-10s
		Debugger.DebugText("ResetFromBeneathCooldown() - Filth lockout data, cooldown was " + pureFilthCooldownRemaining, debugMode);		
		SetPureFilthCooldown( Math.max(pureFilthCooldownRemaining, PURE_FILTH_FROM_BENEATH_LOCKOUT) );		
		Debugger.DebugText("ResetFromBeneathCooldown() - Filth lockout data, cooldown is now " + pureFilthCooldownRemaining, debugMode);
		
		// Pod ALSO also seems to prevent Shadow from being cast for ~22s
		Debugger.DebugText("ResetFromBeneathCooldown() - Shadow lockout data, cooldown was " + shadowCooldownRemaining, debugMode);		
		SetShadowCooldown( Math.max(shadowCooldownRemaining, SHADOW_FROM_BENEATH_LOCKOUT) );		
		Debugger.DebugText("ResetFromBeneathCooldown() - Shadow lockout data, cooldown is now " + shadowCooldownRemaining, debugMode);
	}
	
	
	private function SetPureFilthCooldown(cd:Number) {
		Debugger.DebugText("SetPureFilthCooldown(): cd set to " + cd , debugMode);
		pureFilthCooldownRemaining = cd;
	}
	
	public function ResetPureFilthCooldown() 
	{
		Debugger.DebugText("ResetPureFilthCooldown(): lurkerEliteLevel is " + lurkerEliteLevel, debugMode);
		
		// if we're not on E17, apply standard cooldown
		if lurkerEliteLevel < 17 {
			SetPureFilthCooldown(PURE_FILTH_COOLDOWN);
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
				SetPureFilthCooldown(PURE_FILTH_COOLDOWN_E17_SHORT);
				Debugger.DebugText("ResetPureFilthCooldown(): cooldown set to short (" + pureFilthCooldownRemaining + ")", debugMode );
			}
			// otherwise apply the long cooldown
			else {
				SetPureFilthCooldown(PURE_FILTH_COOLDOWN_E17_LONG); 
				Debugger.DebugText("ResetPureFilthCooldown(): cooldown set to long (" + pureFilthCooldownRemaining + ")", debugMode );
			}
			
			// set the last cast time to now
			lastFilthCastTime = currentTime;
			Debugger.DebugText("ResetPureFilthCooldown(): lastFilthCastTime set to " + currentTime, debugMode );
		}
	}

	private function SetShadowCooldown(cd:Number) {
		Debugger.DebugText("SetShadowCooldown(): cd set to " + cd , debugMode);
		shadowCooldownRemaining = cd;
	}
	
	public function ResetShadowCooldown() 
	{
		// only bother with this in phase 3
		if ( encounterPhase > 2 ) {
			
			// set cooldown - varies per difficulty (see SetLurkerEliteLevel())
			// Note: first Shadow cooldown in phase 3 now handled in UpdateEncounterPhase
			SetShadowCooldown( shadow_cooldown );
			Debugger.DebugText("ResetShadowCooldown() - 2+ shadow cooldown is " + shadow_cooldown, debugMode);
			
			
			// Shadow seems to lock out Pure Filth and Pod when cast			
			// The pod lockout appears to vary with difficulty (~25s on SM & E10, ~44s on E17, untested on E1/E5 yet)
			Debugger.DebugText("ResetShadowCooldown() - Pod lockout data, cooldown was " + fromBeneathCooldownRemaining, debugMode);			
			if ( lurkerEliteLevel >= 17 ) {
				SetFromBeneathCooldown(Math.max(fromBeneathCooldownRemaining, FROM_BENEATH_SHADOW_LOCKOUT_E17));
			}
			else {
				SetFromBeneathCooldown(Math.max(fromBeneathCooldownRemaining, FROM_BENEATH_SHADOW_LOCKOUT_E10));
			}			
			Debugger.DebugText("ResetShadowCooldown() - Pod lockout data, cooldown is now " + fromBeneathCooldownRemaining, debugMode);
			
			
			// the filth lockout appears to be ~25s on all difficulties
			Debugger.DebugText("ResetShadowCooldown() - Filth lockout data, cooldown was " + pureFilthCooldownRemaining, debugMode);			
			SetPureFilthCooldown( Math.max(pureFilthCooldownRemaining, PURE_FILTH_SHADOW_LOCKOUT));	
			Debugger.DebugText("ResetShadowCooldown() - Filth lockout data, cooldown is now " + pureFilthCooldownRemaining, debugMode);
		}		
		
		else {
			// Just throwing a debug line in here to make sure this is working
			Debugger.DebugText("ResetShadowCooldown() - shadow called in phase 1 or 2, nothing done", debugMode);
		}
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
		fromBeneathCooldownRemaining = 0;
		pureFilthCooldownRemaining = 0;
		lastUpdateTime = undefined;
		shadowCooldownRemaining = undefined;
		lastFilthCastTime = undefined;
		Debugger.DebugText("ResetEncounter(): encounterPhase is now " + encounterPhase, debugMode);
	}
}