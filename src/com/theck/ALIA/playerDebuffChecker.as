/**
 * ...
 * @author theck
 * 
 * Much of this code stolen from Xeio's TargetLowest addon
 */

import com.GameInterface.Game.Character;
import com.GameInterface.Game.Raid;
import com.GameInterface.Game.Team;
import com.GameInterface.Game.TeamInterface;
import com.theck.Utils.Debugger;
import com.Utils.Signal;
import com.Utils.LDBFormat;
import mx.utils.Delegate;
import com.GameInterface.UtilsBase;

class com.theck.ALIA.playerDebuffChecker
{
	// toggle debug messages
	static var debugMode:Boolean = false;
	
	static var DEATH_BUFFID:Number = 9212298;
	static var STATUS_PODDED:Number = 4;
	static var STATUS_DOOMED:Number = 3;
	static var STATUS_CLEAR:Number = 0;
	static var podded:Number = 7854429; // 7854429: "From Beneath You, It Devours", see npcStatusMonitor for more details
	static var podIncoming:Number = 8907521; // 8907521": "Inevitable Doom", curiously there's no buff (visible or invisible) for story mode?
	public var currentVictim:Character;
	public var currentVictimStatus:Number;
	private var debuffPollingInterval:Number;
	
	public var DebuffStatusChanged:Signal;
	
	

	public function playerDebuffChecker() 
	{
		Debugger.DebugText("pDC.constructor", debugMode);
		
        DebuffStatusChanged = new Signal();		
	}
		
	public function StopCheckingDebuffs() {	
		
		Debugger.DebugText("pDC.StopCheckingDebuffs()", debugMode);
		clearInterval(debuffPollingInterval); 
		
	}
	
	public function MonitorRaidForPodDebuff():Void {
		Debugger.DebugText("pDC.MonitorRaidForPodDebuff()", debugMode);
		
		// clear any existing polling interval
		StopCheckingDebuffs()
		
		// run one check (this is likely to fail), but forces an update of currentVictim just in case
		CheckForDebuffs();
		
		// if we don't know who's doomed yet
		if !currentVictim {
			// start polling every 250 ms
			debuffPollingInterval = setInterval(Delegate.create(this, CheckForDebuffs), 250);
			
			// stop polling after 28s (3s cast + 25s travel time) to make sure we don't end up with multiple simultaneous polling intervals going
			// if ain't nobody podded after 25s, ain't nobody getting podded
			// this needs to be < 30s so that we don't accidentally clear the interval from subsequent pod casts
			setTimeout(Delegate.create(this, StopCheckingDebuffs), 28000); 
		}
	}
	
	
	public function CheckForDebuffs() {
		//Debugger.DebugText("pDC.CheckForDebuffs()", debugMode);
		currentVictim = undefined;
		
		var raid:Raid = TeamInterface.GetClientRaidInfo();
		var team:Team = TeamInterface.GetClientTeamInfo();;
		
		//Debugger.DebugText("pDC.CheckForDebuffs(): raid is " + raid, debugMode);
		//Debugger.DebugText("pDC.CheckForDebuffs(): team is " + team, debugMode);
		
		// check to see if we're in a raid
		if ( raid ) {
			Debugger.DebugText("pDC.CheckForDebuffs(): checking raid", debugMode);
			
			// if so, check each team in the raid
			for ( var key:String in raid.m_Teams ) {
				
				CheckTeamForDebuffs( raid.m_Teams[key] );				
			}
		}
		// otherwise, just check our current team (only needed if 5 or fewer in instance, so likely only SM/E1)
		else if ( team ) {		
			Debugger.DebugText("pDC.CheckForDebuffs(): checking team", debugMode);
		
			CheckTeamForDebuffs( team );
		}
		// otherwise you're alone. Pretty sure you're getting podded, but just for completeness we'll check anyway
		else {
			Debugger.DebugText("pDC.CheckForDebuffs(): checking self", debugMode);
			
			CheckPlayerForDebuffs(Character.GetClientCharacter());
		}
	
		// if we've found a person with the debuff, connect signals, disable interval, emit signal to update
		if ( currentVictim ) {
			Debugger.DebugText("pDC.CheckForDebuffs(): currentVictim is " + currentVictim.GetName(), debugMode);
			ConnectVictimSignals();
			StopCheckingDebuffs();
			//Debugger.DebugText("pDC.CheckForDebuffs(): interval is " + debuffPollingInterval + ", should be cleared?", debugMode );
			DebuffStatusChanged.Emit();
		}
		
		//Debugger.DebugText("pDC.CheckForDebuffs(): interval is " + debuffPollingInterval , debugMode );
	}
	
	private function CheckTeamForDebuffs(team:Team) {
		//Debugger.DebugText("pDC.CheckTeamForDebuffs()", debugMode);
		
		
		//Debugger.DebugText("pDC.CheckTeamForDebuffs(): team.m_TeamMembers.length is " + team.m_TeamMembers.length, debugMode);
		
		for ( var i in team.m_TeamMembers ) {
				
			// grab one character
			var teamMember = team.m_TeamMembers[i];
			var char:Character = Character.GetCharacter( teamMember["m_CharacterId"] );
			
			//Debugger.DebugText("pDC.CheckTeamForDebuffs(): checking " + char.GetName(), debugMode);
			
			CheckPlayerForDebuffs(char);
			
		}
	}
	
	private function CheckPlayerForDebuffs(char:Character) {
		//Debugger.DebugText("pDC.CheckPlayerForDebuffs()", debugMode);
		
		// make sure nothing fishy is going on
			if ( !char ) return;
			if ( char.GetName() == "" ) return; // (Xeio): Proxy check for character being out of range 
			if ( char.IsDead() ) return;
			if ( char.m_BuffList[DEATH_BUFFID] || char.m_InvisibleBuffList[DEATH_BUFFID] ) return;
			
			// now check for Doom and Pod buffs
			if ( char.m_BuffList[podIncoming] ) {
				
				currentVictim = char;
				currentVictimStatus = STATUS_DOOMED;
			}
			if ( char.m_BuffList[podded] ) {
				
				currentVictim = char;
				currentVictimStatus = STATUS_PODDED;
			}
			
/*			// verbose debugging - report all debuffs
			if ( debugMode ) {
				var buffString:String = " ";
				for ( var j in char.m_BuffList ) {
					buffString += LDBFormat.LDBGetText( 50210, Number(j) ) + " (" + j + "), ";
				}
				Debugger.DebugText("pDC.CheckPlayerForDebuffs(): debuff list for " + char.GetName() + ": " + buffString, debugMode );
				
				
				buffString = " ";
				for ( var j in char.m_InvisibleBuffList ) {
					buffString += LDBFormat.LDBGetText( 50210, Number(j) ) + " (" + j + "), ";
				}
				Debugger.DebugText("pDC.CheckPlayerForDebusffs(): invisible debuff list for " + char.GetName() + ": " + buffString, debugMode );
			}*/
	}
	
	private function ConnectVictimSignals() {
			currentVictim.SignalBuffAdded.Connect(VictimBuffAdded, this);
			currentVictim.SignalBuffRemoved.Connect(VictimBuffRemoved, this);
			//currentVictim.SignalInvisibleBuffAdded.Connect(VictimBuffAdded, this);
			//currentVictim.SignalInvisibleBuffUpdated.Connect(VictimBuffRemoved, this);
	}
	
	private function DisconnectVictimSignals() {
			currentVictim.SignalBuffAdded.Disconnect(VictimBuffAdded);
			currentVictim.SignalBuffRemoved.Disconnect(VictimBuffRemoved);
			//currentVictim.SignalInvisibleBuffAdded.Disconnect(VictimBuffAdded);
			//currentVictim.SignalInvisibleBuffUpdated.Disconnect(VictimBuffRemoved);		
	}
	
	public function VictimBuffAdded(buffId:Number) {
		Debugger.DebugText("pDC.VictimBuffAdded(): buffID " + buffId + " (" + LDBFormat.LDBGetText(50210, buffId) + ")", debugMode);
		
		if ( buffId == podIncoming ) {
			currentVictimStatus = STATUS_DOOMED;
			DebuffStatusChanged.Emit();
		}
		if ( buffId == podded ) {
			currentVictimStatus = STATUS_PODDED;
			DebuffStatusChanged.Emit();
		}		
	}
	
	public function VictimBuffRemoved(buffId:Number) {
		Debugger.DebugText("pDC.VictimBuffRemoved(): buffID " + buffId + " (" + LDBFormat.LDBGetText(50210, buffId) + ")", debugMode);
		
		if ( buffId == podded ) {
			currentVictimStatus = STATUS_CLEAR;
			DisconnectVictimSignals();
			currentVictim = undefined;
			DebuffStatusChanged.Emit();
		}		
	}
	
	
	public function GetVictimStatus():Number {
		//Debugger.DebugText("pDC.GetVictimStatus(): buffID", debugMode);
		
		return currentVictimStatus;
	}
	
	public function GetVictimName():String {
		//Debugger.DebugText("pDC.GetVictimName()", debugMode);
		
		return currentVictim.GetName();
	}
	
}