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
	
	// From Beneath You It Devours timings
	static var FROM_BENEATH_COOLDOWN_FIRST:Number = 45000;
	static var FROM_BENEATH_COOLDOWN:Number = 32000; 
	static var FROM_BENEATH_SHADOW_LOCKOUT:Number = 48000;
	
	// Pure Filth timings
	static var PURE_FILTH_COOLDOWN:Number = 18000; // SM - E10
	
	static var PURE_FILTH_COOLDOWN_E17_LONG:Number = 22000; // E17 - first cast of pair
	static var PURE_FILTH_COOLDOWN_E17_SHORT:Number = 11000; // E17 - second cast of pair
	static var PURE_FILTH_COOLDOWN_E17_TEST_INTERVAL:Number = 15000; // E17 - minimum delay to trigger small cooldown
	
	// Shadow Out Of Time timings
	static var SHADOW_COOLDOWN_SM_FIRST:Number = 57000; // 57s smallest observed
	static var SHADOW_COOLDOWN_SM:Number = 33000; // 33s (confirmed, but cases of 27s and 30s observed)
	
	static var SHADOW_COOLDOWN_E1_FIRST:Number = 38000 // 38s (confirmed)
	static var SHADOW_COOLDOWN_E1:Number = 33000; // 33s (confirmed, but one case of 24s was observed)
	
	static var SHADOW_COOLDOWN_E5_FIRST:Number = 48000 // 48s (confirmed)
	static var SHADOW_COOLDOWN_E5:Number = 33000; // ???
	
	static var SHADOW_COOLDOWN_E10_FIRST:Number = 105000; // (confirmed-ish, 106s interval seen in video)
	static var SHADOW_COOLDOWN_E10:Number = 58000; // 58-60s (confirmed)
	
	static var SHADOW_COOLDOWN_E17_FIRST:Number = 116000; // 116s (confirmed)
	static var SHADOW_COOLDOWN_E17:Number = 60000; // 60s (comfirmed-ish - could be 65s?) 
	
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
		Debugger.DebugText("StartTrackingCasts()", debugMode);
		
		
		// start polling every 250 ms
		barUpdateInterval = setInterval(Delegate.create(this, UpdateCooldowns), POLLING_INTERVAL);		
	}
	
	public function StopTrackingCooldowns() 
	{	
		
		Debugger.DebugText("StopTrackingCasts()", debugMode);
		clearInterval(barUpdateInterval); 		
	}
	
	public function UpdateEncounterPhase( phase:Number ) 
	{
		Debugger.DebugText("UpdateEncounterPhase() called with phase = " + phase, debugMode);
		if ( phase > encounterPhase ) {
			encounterPhase = phase;
			
			if ( encounterPhase == 1 ) {
				Debugger.DebugText("UpdateEncounterPhase() - Phase 1 block", debugMode);
				// on entering phase 1, set cooldown to 45 seconds
				fromBeneathCooldownRemaining = FROM_BENEATH_COOLDOWN_FIRST;
				Debugger.DebugText("UpdateEncounterPhase() - fromBeneathCooldownRemaining is " + fromBeneathCooldownRemaining, debugMode);
				// sometimes lurker casts pure filth stealthily, just arbitrarily set cooldown here
				ResetPureFilthCooldown();
				// set Shadow to undefined so that we don't track it
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
				// clear last update time
				lastUpdateTime = undefined;
				barDisplay.SetVisible(false);
			}
			else if ( encounterPhase == 3 ) {
				Debugger.DebugText("UpdateEncounterPhase() - Phase 3 block", debugMode);
				// Reset shadow and pod
				firstShadowOfPhase3 = true;
				ResetShadowCooldown();
				ResetFromBeneathCooldown();
				// same stealth bug with entering phase 1
				ResetPureFilthCooldown();
				
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
	}
	
	public function ResetPureFilthCooldown() 
	{
		Debugger.DebugText("ResetPureFilthCooldown(): lurkerEliteLevel is " + lurkerEliteLevel, debugMode);
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
			
			// if the time difference is long enough, apply the short cooldown
			if ( timeDiff > PURE_FILTH_COOLDOWN_E17_TEST_INTERVAL ) { 
				pureFilthCooldownRemaining = PURE_FILTH_COOLDOWN_E17_SHORT;
			}
			// otherwise apply the long cooldown
			else {
				pureFilthCooldownRemaining = PURE_FILTH_COOLDOWN_E17_LONG; // TODO: add E17 mechanics here
			}
			
			// set the last cast time to now
			lastFilthCastTime = currentTime;
		}
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
		
		// in E17, Shadow also seems to delay pod by about 50 seconds
		if ( lurkerEliteLevel >= 17 ) {			
			fromBeneathCooldownRemaining = FROM_BENEATH_SHADOW_LOCKOUT;
			Debugger.DebugText("ResetShadowCooldown() - shadow lockout is " + FROM_BENEATH_SHADOW_LOCKOUT, debugMode);
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
		pureFilthCooldownRemaining = 0;
		lastUpdateTime = undefined;
		firstShadowOfPhase3 = false;
		Debugger.DebugText("ResetEncounter(): encounterPhase is now " + encounterPhase, debugMode);
	}
}