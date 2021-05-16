/**
 * ...
 * @author theck
 * 
 * Much of this code stolen from Xeio's TargetLowest addon
 */

//import com.GameInterface.CharacterCreation.CharacterCreation;
import com.GameInterface.Game.Character;
import com.GameInterface.Game.Raid;
import com.GameInterface.Game.Team;
import com.GameInterface.Game.TeamInterface;
import com.theck.ALIA.poddedPlayerEntry;
import com.theck.Utils.Debugger;
//import com.Utils.Signal;
import com.Utils.LDBFormat;
import gui.theck.podTargetsDisplay;
import mx.utils.Delegate;

class com.theck.ALIA.playerDebuffChecker
{
	// toggle debug messages
	static var debugMode:Boolean = false;
	
	static var DEATH_BUFFID:Number = 9212298;
	static var STATUS_PODDED:Number = 4;
	static var STATUS_DOOMED:Number = 3;
	static var STATUS_CLEAR:Number = 0;
	static var POLLING_INTERVAL:Number = 250;
	static var podded:Number = 7854429; // 7854429: "From Beneath You, It Devours", see npcStatusMonitor for more details
	static var podIncoming:Number = 8907521; // 8907521": "Inevitable Doom", curiously there's no buff (visible or invisible) for story mode?
	//static var podIncoming:Number = 9463770; // Consuming creep for bugtesting
	
	public var victimArray:Array;
	
	private var debuffPollingInterval:Number;
	private var forceChecking:Boolean;
	
	public var podDisplay:podTargetsDisplay;
	
	//public var DebuffStatusChanged:Signal;

	

	public function playerDebuffChecker(display:podTargetsDisplay) 
	{		
		podDisplay = display;
		
        //DebuffStatusChanged = new Signal();		
		
		victimArray = new Array();
	}
		
	public function StopCheckingDebuffs() {	
		
		DebugText("StopCheckingDebuffs()");
		clearInterval(debuffPollingInterval); 
		
	}
	
	private function StopForceChecking() {
		forceChecking = false;
	}
	
	public function MonitorRaidForPodDebuff():Void {
		DebugText("MonitorRaidForPodDebuff()");
		
		// clear any existing polling interval
		StopCheckingDebuffs();
		
		// set force-check flag, expire after 25 seconds
		forceChecking = true;
		setTimeout(Delegate.create(this, StopForceChecking), 25000);
		
		// start polling every 250 ms
		debuffPollingInterval = setInterval(Delegate.create(this, CheckForDebuffs), POLLING_INTERVAL);		
	}
	
	
	public function CheckForDebuffs() {
		//Debugger.DebugText("pDC.CheckForDebuffs()", debugMode);
		
		var raid:Raid = TeamInterface.GetClientRaidInfo();
		var team:Team = TeamInterface.GetClientTeamInfo();
		
		// check to see if we're in a raid
		if ( raid ) {
			
			// if so, check each team in the raid
			for ( var key:String in raid.m_Teams ) {
				
				CheckTeamForDebuffs( raid.m_Teams[key] );				
			}
		}
		// otherwise, just check our current team (only needed if 5 or fewer in instance, so likely only SM/E1)
		else if ( team ) {				
			CheckTeamForDebuffs( team );
		}
		// otherwise you're alone. Pretty sure you're getting podded, but just for completeness we'll check anyway
		else {
			CheckPlayerForDebuffs(Character.GetClientCharacter());
		}
	
		UpdatePodTargetsDisplay();
		
		// if there are no podded players and we've passed the force-check period, stop checking
		if ( victimArray.length == 0 && !forceChecking ) {
			StopCheckingDebuffs();
		}
		
		podDisplay.SetVisible( victimArray.length > 0 ? true : false );
		
		DebugText("CheckForDebuffs(): interval is " + debuffPollingInterval );
	}
	
	private function CheckTeamForDebuffs(team:Team) {
		//Debugger.DebugText("pDC.CheckTeamForDebuffs()", debugMode);
		
		for ( var i in team.m_TeamMembers ) {
				
			// grab one character
			var teamMember = team.m_TeamMembers[i];
			var char:Character = Character.GetCharacter( teamMember["m_CharacterId"] );
			
			CheckPlayerForDebuffs(char);
			
		}
	}
	
	private function CheckPlayerForDebuffs(char:Character) {
		//Debugger.DebugText("pDC.CheckPlayerForDebuffs()", debugMode);
		
		// make sure nothing fishy is going on
		if ( !char ) return;
		if ( char.GetName() == "" ) return; // (Xeio): Proxy check for character being out of range
		
		// remove character and exit if the character is dead
		if ( char.IsDead() || char.m_BuffList[DEATH_BUFFID] || char.m_InvisibleBuffList[DEATH_BUFFID] ) {
			RemovePlayerFromArray(char);
			return;
		}
		
		// now check for Doom and Pod buffs
		if ( char.m_BuffList[podIncoming] ) {
							
			var victim:poddedPlayerEntry = new poddedPlayerEntry( char, STATUS_DOOMED);
			AddVictimToArray(victim);
			
		}
		else if ( char.m_BuffList[podded] ) {
			
			var victim:poddedPlayerEntry = new poddedPlayerEntry( char, STATUS_PODDED);
			AddVictimToArray(victim);
		}
		else {
			RemovePlayerFromArray(char);
		}
		
/*		if ( debugMode ) {	
			DEBUG_PrintDebuffsOnPlayer( char );
		}*/

	}
	
	private function AddVictimToArray(victim:poddedPlayerEntry)
	{
		var foundInArray:Boolean = false;
		// check to see if the player is already in the array
		for ( var i in victimArray ) {
			var tmp:poddedPlayerEntry = victimArray[i];
			if ( tmp.GetName() == victim.GetName() ) {
				victimArray[i] = victim;
				foundInArray = true;
			}
		}
		if ( !foundInArray ) {
			victimArray.push(victim);
			
			//// debugging
			//var currentTime:Date = new Date();
			//Debugger.PrintText("pDC.AddVictimToArray: " + victim.GetName() + " " + currentTime.getSeconds() + "s and " + currentTime.getMilliseconds() + "s");
		}
	}
	
	private function RemovePlayerFromArray(char:Character)
	{
		for (var i in victimArray ) {
			var tmp:poddedPlayerEntry = victimArray[i];
			if ( tmp.GetName() == char.GetName() ) {
				victimArray.splice(Number(i), 1);
			}
		}
	}
	
	public function UpdatePodTargetsDisplay() {
		
		// sort array?
		podDisplay.ClearPlayerTextFields();
		
		DebugText("length of victimarray is " + victimArray.length );
		
		var j = 0;
		for ( var i in victimArray ) {
			DebugText("Victim array entry " + j + "is " + victimArray[j].char.GetName() + " with status " + victimArray[j].status);
			podDisplay.SetFieldText(podDisplay.playerList[j], victimArray[i].char.GetName());
			podDisplay.SetFieldColor(podDisplay.playerList[j], victimArray[i].status);
			j++;
		}
	}
	
	
	///// Debugging /////
		
	static function DebugText(text) {
		if (debugMode) Debugger.PrintText("pDC." + text);
	}
	
	public function DEBUG_PrintDebuffsOnPlayer(char:Character) {
		
		// verbose debugging - report all debuffs
		var buffString:String = " ";
		for ( var j in char.m_BuffList ) {
			buffString += LDBFormat.LDBGetText( 50210, Number(j) ) + " (" + j + "), ";
		}
		Debugger.DebugText("pDC.DEBUG_PrintDebuffsOnPlayer(): debuff list for " + char.GetName() + ": " + buffString, true );
		
		
		buffString = " ";
		for ( var j in char.m_InvisibleBuffList ) {
			buffString += LDBFormat.LDBGetText( 50210, Number(j) ) + " (" + j + "), ";
		}
		Debugger.DebugText("pDC.DEBUG_PrintDebuffsOnPlayer(): invisible debuff list for " + char.GetName() + ": " + buffString, true );
	}
	
	public function DEBUG_PrintDebuffsOnTeam() {
		var team:Team = TeamInterface.GetClientTeamInfo();
		for (var i in team.m_TeamMembers)
		{
			var teamMember = team.m_TeamMembers[i];
			var char:Character = Character.GetCharacter( teamMember["m_CharacterId"] );
			DEBUG_PrintDebuffsOnPlayer( char );
		}
	}
	
	public function DEBUG_PrintDebuffsOnRaid() {		
		var raid:Raid = TeamInterface.GetClientRaidInfo();
		var team:Team = TeamInterface.GetClientTeamInfo();
		// check to see if we're in a raid
		if ( raid ) {
			
			// if so, check each team in the raid
			for ( var key:String in raid.m_Teams ) {
				
				DEBUG_PrintDebuffsOnTeam( raid.m_Teams[key] );				
			}
		}
		// otherwise, just check our current team (only needed if 5 or fewer in instance, so likely only SM/E1)
		else if ( team ) {				
			DEBUG_PrintDebuffsOnTeam( team );
		}
		// otherwise you're alone. Pretty sure you're getting podded, but just for completeness we'll check anyway
		else {
			DEBUG_PrintDebuffsOnPlayer(Character.GetClientCharacter());
		}
	}
	
}