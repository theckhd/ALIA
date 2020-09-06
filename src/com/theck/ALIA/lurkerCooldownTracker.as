/**
 * ...
 * @author theck
 */

import gui.theck.lurkerBarDsiplay;
import com.theck.Utils.Debugger;
import mx.utils.Delegate;

class com.theck.ALIA.lurkerCooldownTracker
{
	
	private var debugMode:Boolean = true;
	
	private var encounterPhase:Number;
	private var lurkerDifficulty:Number;
	
	static var FROM_BENEATH_INITIAL_COOLDOWN:Number = 45000;
	static var FROM_BENEATH_COOLDOWN:Number = 32000; 
	static var PURE_FILTH_COOLDOWN:Number = 18000; // wild guess
	static var SHADOW_FROM_BEYOND_COOLDOWN:Number = 48000; // 48s on E5
	static var SHADOW_FROM_BEYOND_EXTRA:Number = 12000; // 60s on E10+
	static var POLLING_INTERVAL:Number = 100;
	
	private var fromBeneathCooldownRemaining:Number; 
	private var pureFilthCooldownRemaining:Number; 
	private var shadowFromBeyondCooldownRemaining:Number;
	
	private var barUpdateInterval:Number;
	
	private var lastUpdateTime:Date;
	
	public var barDisplay:lurkerBarDsiplay;
	
	public function lurkerCooldownTracker(display:lurkerBarDsiplay) 
	{
		Debugger.DebugText("lurkerCooldownTracker constructor", debugMode);
		barDisplay = display;
		encounterPhase = 0;
		lurkerDifficulty = 0;
	}
	
	public function StartTrackingCooldowns():Void {
		Debugger.DebugText("StartTrackingCasts()", debugMode);
		
		// clear any existing polling interval
		StopTrackingCooldowns();
		
		
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
				// on entering phase 1, set cooldown to 45 seconds
				fromBeneathCooldownRemaining = FROM_BENEATH_INITIAL_COOLDOWN;
				// set Shadow to undefined so that we don't track it
				shadowFromBeyondCooldownRemaining = undefined;
				
				// show display and start updating
				barDisplay.SetVisible(true);
				StartTrackingCooldowns();
			}
			else if ( encounterPhase == 2 ) {
				// hide display and stop updating
				StopTrackingCooldowns();
				lastUpdateTime = undefined;
				barDisplay.SetVisible(false);
			}
			else if ( encounterPhase == 3 ) {
				// Reset shadow and pod
				ResetShadowCooldown();
				ResetFromBeneathCooldown();
				pureFilthCooldownRemaining = 0;
				lastUpdateTime = undefined;
				barDisplay.SetVisible(true);
				// don't start tracking cooldowns - let ALIA dictate that based on lurker health changing - but do update the bar display once
				UpdateBars();
			}
			else if ( encounterPhase == 4 ) {
				// hide display and stop updating
				StopTrackingCooldowns();
				barDisplay.SetVisible(false);
			}
		}
	}
	
	private function UpdateCooldowns() 
	{
		Debugger.DebugText("UpdateCooldowns()", debugMode);
		
		var currentTime:Date = new Date();
		
		if !lastUpdateTime { lastUpdateTime = currentTime; }
		
		var reduxAmount:Number;
		
		reduxAmount = currentTime.getTime() - lastUpdateTime.getTime();
		//Debugger.DebugText("UpdateCooldowns(): reduxAmount is " + reduxAmount, debugMode);
		
		fromBeneathCooldownRemaining = ReduceCooldownRemaining( fromBeneathCooldownRemaining, reduxAmount );
		pureFilthCooldownRemaining = ReduceCooldownRemaining( pureFilthCooldownRemaining, reduxAmount );
		shadowFromBeyondCooldownRemaining = ReduceCooldownRemaining( shadowFromBeyondCooldownRemaining, reduxAmount );
		
		UpdateBars();
		lastUpdateTime = currentTime;
		
	}
	
	public function UpdateBars() 
	{		
		barDisplay.UpdateFromBeneathBar( fromBeneathCooldownRemaining );
		barDisplay.UpdatePureFilthBar( pureFilthCooldownRemaining );
		barDisplay.UpdateShadowBar( shadowFromBeyondCooldownRemaining );
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
		// this is only called when it's cast by Lurker, so it can be the default value. 
		fromBeneathCooldownRemaining = FROM_BENEATH_COOLDOWN;
	}
	
	public function ResetPureFilthCooldown() 
	{
		if lurkerDifficulty < 17 {
			pureFilthCooldownRemaining = PURE_FILTH_COOLDOWN;
		}
		else {
			pureFilthCooldownRemaining = PURE_FILTH_COOLDOWN; // TODO: add E17 mechanics here
		}
	}
	
	public function ResetShadowCooldown() 
	{
		// adjust for difficulty
		shadowFromBeyondCooldownRemaining = SHADOW_FROM_BEYOND_COOLDOWN + ( lurkerDifficulty > 5 ? SHADOW_FROM_BEYOND_EXTRA : 0 );
	}
	
	public function SetLurkerDifficulty(diff:Number) 
	{
		lurkerDifficulty = diff;
	}
	
	public function ResetEncounterPhase()
	{
		encounterPhase = 0;
		pureFilthCooldownRemaining = 0;		
	}
}