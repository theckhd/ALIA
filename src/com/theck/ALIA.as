/*
* ...
* @author theck
*/

import com.GameInterface.Game.Character;
import com.GameInterface.Playfield;
import com.Utils.ID32;
//import com.GameInterface.Targeting;
import com.GameInterface.UtilsBase;
import com.GameInterface.WaypointInterface;
import com.GameInterface.Game;
import com.Utils.Archive;
import com.theck.Utils.Common;
import com.theck.Utils.Debugger;


class com.theck.ALIA 
{
	static var inNYR10:Boolean;
	static var lurkerLocked:Boolean;
	private var m_player:Character;
	private var currentTarget:Character;
	private var lurker:Character;
	
	private var NYRE10_Shadow1:Boolean;
	private var NYRE10_PS1:Boolean;
	private var NYRE10_PS2:Boolean;
	private var NYRE10_PS3:Boolean;
	private var NYRE10_FR:Boolean;
	
	public function ALIA(){
	
	}

	public function Load(){
		com.GameInterface.UtilsBase.PrintChatText("ALIA loaded")
		WaypointInterface.SignalPlayfieldChanged.Connect(PlayfieldChanged, this);
		m_player = Character.GetClientCharacter();
		m_player.SignalOffensiveTargetChanged.Connect(TargetChanged, this)
		//Targeting.SignalTargetChanged.Connect(TargetChanged, this);
		PlayfieldChanged(m_player.GetPlayfieldID());
		lurkerLocked = false;
		
	}

	public function Unload(){
		WaypointInterface.SignalPlayfieldChanged.Disconnect(PlayfieldChanged, this);
		
		lurker.SignalStatChanged.Disconnect(LurkerStatChanged, this);
		lurker.SignalCharacterDied.Disconnect(ResetLurker, this);
		lurker.SignalCharacterDestructed.Disconnect(ResetLurker2, this);
	}
	
	public function Activate(config:Archive){
		com.GameInterface.UtilsBase.PrintChatText("ALIA activated")
	
	}

	public function Deactivate():Archive{
		var config = new Archive();
		return config
	}
	
	static function IsNYR10(zone)
	{
		inNYR10 = zone == 5715; // E10 is 5715, E5 is 5710
		return inNYR10;
	}
	
	public function PlayfieldChanged(zone)
	{
		if (IsNYR10(zone))
		{
			Debugger.PrintText("You have entered NYR");	
		}
	}
	
	public function TargetChanged(id:ID32)
	{	
		Debugger.PrintText("Target Changed to " + id);
		
		if (!lurkerLocked && !id.IsNull()) {
			
		currentTarget = Character.GetCharacter(id);
		Debugger.PrintText("Target Changed to " + currentTarget.GetName() );
			
			// this needs to be localized
			if (currentTarget.GetName() == "The Unutterable Lurker" && inNYR10) {
				Debugger.PrintText("Your Target is E10 Lurker!!");
				lurker = Character.GetCharacter(id);
				lurker.SignalStatChanged.Connect(LurkerStatChanged, this);
				lurker.SignalCharacterDied.Connect(ResetLurker, this);
				lurker.SignalCharacterDestructed.Connect(ResetLurker2, this);
				lurkerLocked = true;
				Debugger.PrintText("Lurker Locked!!")
				
				NYRE10_Shadow1 = true;
				NYRE10_PS1 = true;
				NYRE10_PS2 = true;
				NYRE10_PS3 = true;
				NYRE10_FR = true;
			}
		}
	}
	
	public function LurkerStatChanged(stat)
	{
		//Debugger.PrintText("Lurker's Stats Changed");
		
		// tested 6/5/2020: stat enum 1 is max health, stat enum 27 is current health
		var currentHP = lurker.GetStat(27, 1);
		
		// Shadow Incoming at 26369244 (75%)
		if (currentHP < 28000000 && NYRE10_Shadow1) {
			com.GameInterface.UtilsBase.PrintChatText("Shadow Incoming");
			Debugger.ShowFifo("Shadow Incoming");
			NYRE10_Shadow1 = false;
		}
		
		// First Personal Space at 23556525 (67%)
		else if (currentHP < 24500000 && NYRE10_PS1) {
			com.GameInterface.UtilsBase.PrintChatText("PS 1 incoming");
			Debugger.ShowFifo("PS 1 Incoming");
			NYRE10_PS1 = false;
		}
		
		// Second Personal Space at 15821546 (45%)
		else if (currentHP < 17000000 && NYRE10_PS1) {
			com.GameInterface.UtilsBase.PrintChatText("PS 2 incoming");
			Debugger.ShowFifo("PS 2 Incoming");
			NYRE10_PS2 = false;
		}
		
		// Third Personal Space at 8789478 (25%)
		else if (currentHP < 10000000 && NYRE10_PS1) {
			com.GameInterface.UtilsBase.PrintChatText("PS 3 incoming");
			Debugger.ShowFifo("PS 3 Incoming");
			NYRE10_PS3 = false;
		}
		
		// Final Resort at 1757950 (5%)
		else if (currentHP < 3000000 && NYRE10_FR) {
			com.GameInterface.UtilsBase.PrintChatText("Final Resort incoming");
			Debugger.ShowFifo("Final Resort Incoming");
			NYRE10_FR = false;
		}
	}
	
	public function ResetLurker()
	{
		Debugger.PrintText("Lurker died")
		lurker.SignalStatChanged.Disconnect(LurkerStatChanged, this);
		lurker.SignalCharacterDied.Disconnect(ResetLurker, this);
		lurker.SignalCharacterDestructed.Disconnect(ResetLurker2, this);
		lurkerLocked = false;
	}
	
	public function ResetLurker2()
	{
		Debugger.PrintText("Lurker destructed")
		Debugger.ShowFifo("Lurker destructed");
		lurker.SignalStatChanged.Disconnect(LurkerStatChanged, this);
		lurker.SignalCharacterDied.Disconnect(ResetLurker, this);
		lurker.SignalCharacterDestructed.Disconnect(ResetLurker2, this);
		lurkerLocked = false;		
	}
}