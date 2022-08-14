/*
* ...
* @author theck
*/

//import com.GameInterface.Game.Raid;
//import com.GameInterface.Game.Team;
//import com.GameInterface.Game.TeamInterface;
//import com.GameInterface.UtilsBase;

import com.GameInterface.DistributedValue;
import com.GameInterface.Game.Character;
import com.GameInterface.Game.Dynel;
import gui.theck.SimpleBar;
//import com.GameInterface.Utils;
import com.GameInterface.VicinitySystem;
import com.Utils.ID32;
import com.Utils.Archive;
import com.Utils.LDBFormat;
import com.Utils.GlobalSignal;
//import com.Utils.Signal;
import com.theck.ALIA.lurkerCooldownTracker;
import com.theck.ALIA.playerDebuffChecker;
import com.theck.Utils.Common;
import com.theck.Utils.Debugger;
import com.theck.ALIA.npcStatusMonitor;
import gui.theck.TextFieldController;
import gui.theck.npcStatusDisplay;
import gui.theck.lurkerBarDsiplay;
import gui.theck.podTargetsDisplay;
import gui.theck.SimpleCounter;
import mx.utils.Delegate;
import flash.geom.Point;


class com.theck.ALIA.ALIA 
{
	// Version
	static var version:String = "1.1.0";
	
	// toggle debug messages and enable addon outisde of NYR
	static var debugMode:Boolean = false;
	static var debugAlwaysInNY:Boolean = false;
	
	// basic settings and text strings
	static var stringLurker:String = LDBFormat.LDBGetText(51000, 32030);
	static var stringShadowOutOfTime:String = LDBFormat.LDBGetText(50210, 8934410); //"Shadow Out Of Time";
	static var stringPersonalSpace:String = LDBFormat.LDBGetText(50210, 8934415); //"Personal Space";
	static var stringFinalResort:String = LDBFormat.LDBGetText(50210, 7963851); //"Final Resort";
	static var stringFromBeneath:String = LDBFormat.LDBGetText(50210, 8934432); //"From Beneath You, It Devours"
	static var stringPureFilth:String = LDBFormat.LDBGetText(50210, 7854359); // "Pure Filth"
	static var stringDownfall:String = LDBFormat.LDBGetText(50210, 7958970); //"Downfall", also 7958971
	static var alex112:Number = 32302;
	static var mei112:Number = 32301;
	static var rose112:Number = 32299;
	static var zuberi112:Number = 32303;
	static var bird112_SM:Number = 37266; // The two in SM parking garage are 32407 
	static var bird112_E1:Number = 32452;
	static var bird112_E5:Number = 37258;
	static var bird112_E10:Number = 35482; // same on E10 & E17.
	//static var bird112_E17:Number = 37297; // Guess, other possibilites: 37298, 37299
	static var hulk112_E5:Number = 37333; 
	static var hulk112_E10:Number = 35899; 
	static var hulk112_E17:Number = 38370; 
	static var textDecayTime:Number = 10;
	static var nowColor:Number = 0xFF0000;
	
	// lockout timers
	static var LOCKOUT_PURE_FILTH:Number = 4000; // cast time of Pure Filth + 1 s wiggle room
	static var LOCKOUT_SHADOW:Number = 10000; // cast time + 2 s wiggle room
	static var LOCKOUT_PERSONAL:Number = 7000; // cast time + 2 s wiggle room
	static var LOCKOUT_FROM_BENEATH:Number = 4000; // cast time of From Beneath + 1s wiggle room
	
	static var LURKERCASTBAR_INTERVAL = 50;
	
	// These aren't needed right now, just here for reference. Values from live (post-patch)
	//static var lurkerMaxHealthSM = 3262582;
	//static var lurkerMaxHealthE1 = 3262582;
	//static var lurkerMaxHealthE5 = 10905556;
	static var lurkerMaxHealthE1  =  3262582;
	static var lurkerMaxHealthE5  = 11140440;
	
	static var lurkerMaxHealthE10 = 43199824; // checked 7 / 19 open beta, re-checked 9/30. Pre-patch value was 35158992
	
	//static var lurkerMaxHealthE17 = 77213848; // checked 9/30

	
	// character variables
	public var m_player:Character;
	private var lurker:Character;
	private var alex:npcStatusMonitor;
	private var rose:npcStatusMonitor;
	private var mei:npcStatusMonitor;
	private var zuberi:npcStatusMonitor;
	private var currentBird:Character;
	private var currentHulk:Character;
	
	// GUI stuff
	private var m_swfRoot:MovieClip;
    private var AnnounceText:TextField;
	private var w_pos:flash.geom.Point;
	private var h_pos:flash.geom.Point;
	private var n_pos:flash.geom.Point;
	private var p_pos:flash.geom.Point;
	private var b_pos:flash.geom.Point;
	private var t_pos:flash.geom.Point;
	private var cb_pos:flash.geom.Point;
	private var warningController:TextFieldController;
	private var healthController:TextFieldController;
	private var updateHealthDisplay:Boolean;
	private var npcDisplay:npcStatusDisplay;
	private var playerDebuffController:playerDebuffChecker;
	private var lurkerCastBar:SimpleBar;
	private var lurkerCastName:String;
	private var lurkerCastBarUpdateInterval:Number;
	private var lurkerCastInProgress:Boolean;
	private var guiEditThrottle:Boolean = true;
	private var podDisplay:podTargetsDisplay;
	private var barDisplay:lurkerBarDsiplay;
	private var cooldownTracker:lurkerCooldownTracker;
	private var countdownTimer:SimpleCounter;
	
	// logic flags and accumulators
	private var ann_SB1_Soon:Boolean;
	private var ann_SB1_Now:Boolean;
	private var ann_PS1_Soon:Boolean;
	private var ann_PS1_Now:Boolean;
	private var ann_PS2_Soon:Boolean;
	private var ann_PS2_Now:Boolean;
	private var ann_PS3_Soon:Boolean;
	private var ann_PS3_Now:Boolean;
	private var ann_FR_Soon:Boolean;
	private var ann_FR_Now:Boolean;
	private var announceSettingsBool:Boolean;
	private var personalNowSoundAlreadyPlaying:Boolean = false;
	private var personalSoonSoundAlreadyPlaying:Boolean = false;
	private var fromBeneathSoundAlreadyPlaying:Boolean = false;
	private var loadFinished = false;
	private var encounterPhase:Number;
	private var numBirds:Number;
	private var numHulks:Number;
	private var numShadows:Number;
	private var numDownfalls:Number;
	private var shadowThrottleFlag:Boolean = true;
	private var personalThrottleFlag:Boolean = true;
	private var fromBeneathThrottleFlag:Boolean = true;
	private var pureFilthThrottleFlag:Boolean = true;
	private var downfallThrottleFlag:Boolean = true;
	private var lurkerEliteLevel:Number  = 0;

	
	// percentages
	static var pct_SB1_Now:Number = 0.75;
	static var pct_PS1_Now:Number = 0.67;
	static var pct_PS2_Now:Number = 0.45;
	static var pct_PS3_Now:Number = 0.25;
	static var pct_FR_Now:Number  = 0.05;
	private var pct_warning:DistributedValue;
	
	// other options
	private var showZuberi:DistributedValue;
	private var ignorePoddedNPCs:DistributedValue;
	private var personalSound:DistributedValue;
	private var fromBeneathSound:DistributedValue;
	private var showSlashCommands:DistributedValue;
	private var showNPCNames:DistributedValue;
	private var showShadowBar:DistributedValue;
	private var showCastBar:DistributedValue;
	private var playHulkWarningSound:DistributedValue;
	private var debuggingHack:DistributedValue;

	//////////////////////////////
	////// Addon Management //////
	//////////////////////////////
	
	public function ALIA(swfRoot:MovieClip) {
        m_swfRoot = swfRoot;
		
		// create options
		CreateOptions();
    }

	public function Load() {
		com.GameInterface.UtilsBase.PrintChatText("ALIA v" + version + ": A Lurker Is Loaded");
		DebugText("Debug mode enabled");
		
		// grab character
		m_player = Character.GetClientCharacter();
		
		//create text field, connect to GuiEdit
		CreateGuiElements();
		GlobalSignal.SignalSetGUIEditMode.Connect(GuiEdit, this);
		
		// connect options to SettingsChanged function
		ConnectOptionsSignals();
		
		// announce settings flag
		announceSettingsBool = true;
		setTimeout(Delegate.create(this, SetLoadFinishedFlag), 5000);
	}

	public function Unload() {		
		DebugText("Unload()");
		
		// disconnect all signals
		ResetLurker();
		
		DisconnectOptionsSignals();
	}
	
	public function Activate(config:Archive) {
		DebugText("Activate()");
				
		// set options
		ActivateOptions(config);
		
		// Initialize vicinity signal and update visibility
		Initialize();
		
		// Announce any relevant settings the first time Activate() is called within NYR
		AnnounceSettings();
	}

	public function Deactivate():Archive {
		DebugText("Deactivate()");
		
		// save the current position in the config
		var config = new Archive();
		
		config = DeactivateOptions();
		
		return config
	}
	
	private function IsNYR10() {
		var zone = m_player.GetPlayfieldID();
		return ( debugAlwaysInNY || zone == 5715); // E10 & E17 are 5715
	}
	
	private function IsNYR() {
		var zone = m_player.GetPlayfieldID();
		return ( debugAlwaysInNY || IsNYR10() || zone == 5710); // SM, E1, and E5 are all 5710
	}
	
	private function SetLoadFinishedFlag() {
		loadFinished = true;
	}
		
	public function Initialize() {	
		DebugText("Initialize(): encounterPhase = " + encounterPhase );
		
		// if in NYR, do some things
		if (IsNYR())
		{	
			// connect NPC detection signals
			ConnectVicinitySignals();
			
			// connect to CharacterAlive signal (for resetting lurker upon wipes)
			ConnectCharacterAliveSignal();
			ConnectCharacterInCombatSignal();
			
			// initialize accumulators just in case
			ResetAccumulators();
			
			// The cinematic after a kill causes a Deactivate() / Activate() -> Initialize() sequence. 
			// If this was just after a kill, do some cleanup 
			if encounterPhase == 4 
			{
				// keep NPC display hidden
				npcDisplay.SetVisible(false);
				npcDisplay.ResetAlpha();
			}
			// otherwise we just zoned in or wiped, so prepare for the next attempt
			else 
			{	
				ResetEncounterState();
				
				// reset GUI element visibility
				npcDisplay.ResetAlpha();
				npcDisplay.SetVisible( IsNYR(), encounterPhase, ShowZuberi() ); 
				healthController.ResetAlpha();
				SplashWarningText();
			}
		}
		// if we're not in NYR do some cleanup
		else
		{
			// disconnect all signals
			DisconnectVicinitySignals();
			DisconnectCharacterAliveSignal();
			DisconnectCharacterInCombatSignal();
			ResetLurker();
			
			// NPC Status Display element visibility
			npcDisplay.SetVisible( IsNYR(), encounterPhase, ShowZuberi() ); 
			
			// reset health display (so it doesn't read "Dead" if we killed it in a previous run)
			healthController.UpdateText("100%");
		}
		
		// update visibility & blink state of text fields no matter what zone we're in
		warningController.SetVisible( IsNYR() );
		warningController.StopBlink();		
		healthController.SetVisible( IsNYR() ); 		
	}
	
	//////////////////////////////
	////// Options Handling //////
	//////////////////////////////
	
	private function CreateOptions() {		
		
		// create options (note: each is a DistributedValue, need to access w/ SetValue() / GetValue() in code
		// the argument here is the string used to adjust the variable via chat window
		pct_warning = DistributedValue.Create("alia_warnpct");
		showZuberi = DistributedValue.Create("alia_zuberi");
		personalSound = DistributedValue.Create("alia_ps_sound");
		fromBeneathSound = DistributedValue.Create("alia_pod_sound");
		showNPCNames = DistributedValue.Create("alia_shownames");
		showShadowBar = DistributedValue.Create("alia_shadowbar");
		showCastBar = DistributedValue.Create("alia_castbar");
		playHulkWarningSound = DistributedValue.Create("alia_hulk_sound");
		
		// new options get added above this line
		showSlashCommands = DistributedValue.Create("alia_options");
		debuggingHack = DistributedValue.Create("alia_debug");
	}
	
	private function ConnectOptionsSignals() {
		
		// connect option change signals to SettingsChanged
		pct_warning.SignalChanged.Connect(SettingsChanged, this);
		showZuberi.SignalChanged.Connect(SettingsChanged, this);
		personalSound.SignalChanged.Connect(SettingsChanged, this);
		fromBeneathSound.SignalChanged.Connect(SettingsChanged, this);
		showNPCNames.SignalChanged.Connect(SettingsChanged, this);
		showShadowBar.SignalChanged.Connect(SettingsChanged, this);
		showCastBar.SignalChanged.Connect(SettingsChanged, this);
		playHulkWarningSound.SignalChanged.Connect(SettingsChanged, this);
		
		// new options get added above this line
		showSlashCommands.SignalChanged.Connect(AnnounceSlashCommands, this);
		debuggingHack.SignalChanged.Connect(DebuggingHack, this);
	}
	
	private function DisconnectOptionsSignals() {
		
		// disconnect option change signals 	
		pct_warning.SignalChanged.Disconnect(SettingsChanged, this);
		showZuberi.SignalChanged.Disconnect(SettingsChanged, this);
		personalSound.SignalChanged.Disconnect(SettingsChanged, this);
		fromBeneathSound.SignalChanged.Disconnect(SettingsChanged, this);
		showNPCNames.SignalChanged.Disconnect(SettingsChanged, this);
		showShadowBar.SignalChanged.Disconnect(SettingsChanged, this);
		showCastBar.SignalChanged.Disconnect(SettingsChanged, this);
		playHulkWarningSound.SignalChanged.Disconnect(SettingsChanged, this);
		
		// new options get added above this line
		showSlashCommands.SignalChanged.Disconnect(AnnounceSlashCommands, this);
		debuggingHack.SignalChanged.Disconnect(DebuggingHack, this);
	}
	
	private function ActivateOptions(config:Archive) {
		
		// Move text to desired position
		w_pos = config.FindEntry("alia_warnPosition", new Point(600, 600));		
		warningController.SetPos(w_pos);
		
		h_pos = config.FindEntry("alia_healthPosition", new Point(600, 500));
		healthController.SetPos(h_pos);
		
		n_pos = config.FindEntry("alia_npcPosition", new Point(600, 400));
		npcDisplay.SetPos(n_pos);
		
		p_pos = config.FindEntry("alia_podPosition", new Point(1100, 600));
		podDisplay.SetPos(p_pos);
		
		b_pos = config.FindEntry("alia_barPosition", new Point(1100, 600));
		barDisplay.SetPos(b_pos);
		
		t_pos = config.FindEntry("alia_timerPosition", new Point(700, 600));
		countdownTimer.SetPos(t_pos);
		
		cb_pos = config.FindEntry("alia_castBarPosition", new Point(500, 500));
		lurkerCastBar.SetPos(cb_pos);
		
		// set options
		// the arguments here are the names of the settings within Config (not the slash command strings)
		pct_warning.SetValue(config.FindEntry("alia_pct_warning", 3));
		showZuberi.SetValue( config.FindEntry("alia_showZuberi", false));
		personalSound.SetValue( config.FindEntry("alia_personalSound", true));
		fromBeneathSound.SetValue( config.FindEntry("alia_fromBeneathSound", true));
		showNPCNames.SetValue( config.FindEntry("alia_showNPCNames", true));
		showShadowBar.SetValue( config.FindEntry("alia_shadowbar", false) );
		showCastBar.SetValue( config.FindEntry("alia_castbar", true) );
		playHulkWarningSound.SetValue( config.FindEntry("alia_hulk_sound", false) );
		
		// any options that need to be passed to other classes need to be handled here
		barDisplay.EnableShadowBar( showShadowBar.GetValue() );
		
		// new options get added above this line
		debuggingHack.SetValue( false );
		showSlashCommands.SetValue( false );
	}
	
	private function DeactivateOptions():Archive {
		
		// save the current position in the config
		var config = new Archive();
		config.AddEntry("alia_warnPosition", w_pos);
		config.AddEntry("alia_healthPosition", h_pos);
		config.AddEntry("alia_npcPosition", n_pos);
		config.AddEntry("alia_podPosition", p_pos);
		config.AddEntry("alia_barPosition", b_pos);
		config.AddEntry("alia_timerPosition", t_pos);
		config.AddEntry("alia_castBarPosition", cb_pos);
		
		// save options
		// the arguments here are the names of the settings within Config (not the slash command strings)
		config.AddEntry("alia_pct_warning", pct_warning.GetValue());
		config.AddEntry("alia_showZuberi", showZuberi.GetValue());
		config.AddEntry("alia_personalSound", personalSound.GetValue());
		config.AddEntry("alia_fromBeneathSound", fromBeneathSound.GetValue());
		config.AddEntry("alia_hulk_sound", playHulkWarningSound.GetValue());
		config.AddEntry("alia_showNPCNames", showNPCNames.GetValue());
		config.AddEntry("alia_shadowbar", showShadowBar.GetValue());
		config.AddEntry("alia_castbar", showCastBar.GetValue());
		
		return config
	}
	
	private function SettingsChanged(dv:DistributedValue) {
		
		DebugText("SettingsChanged()");
        DebugText("SettingsChanged: dv.GetName() is " + dv.GetName());
        DebugText("SettingsChanged: dv.GetValue() is " + dv.GetValue());
		
		announceSettingsBool = true;
		
		// switch off of the settings name (defined in ALIA constructor)
		switch (dv.GetName()) {
		case "alia_warnpct":
			pct_warning = dv;
			break;
		case "alia_zuberi":
			showZuberi = dv;
			npcDisplay.SetVisible( IsNYR(), encounterPhase, ShowZuberi() );
			break;
		case "alia_ps_sound":
			personalSound = dv;
			if (loadFinished && personalSound.GetValue() ) { PlayPersonalSpaceNowWarningSound(); };
			break;
		case "alia_pod_sound":
			fromBeneathSound = dv;
			if ( loadFinished && fromBeneathSound.GetValue() ) { PlayFromBeneathWarningSound(); };
			break;
		case "alia_shownames":
			showNPCNames = dv;
			npcDisplay.ChangeLetterMode(showNPCNames.GetValue());
			GuiEdit();
			break;
		case "alia_shadowbar":
			showShadowBar = dv;
			barDisplay.EnableShadowBar( showShadowBar.GetValue() );
			GuiEdit();
			break;
		case "alia_castbar":
			showCastBar = dv;
			lurkerCastBar.SetVisible( showCastBar.GetValue() );
			GuiEdit();
			break;
		case "alia_hulk_sound":
			playHulkWarningSound = dv;			
			if ( loadFinished && fromBeneathSound.GetValue() ) { PlayHulkWarningSound(); };
			break;
		}
		
		AnnounceSettings(loadFinished);
	}
	
	public function AnnounceSettings(override:Boolean) {
		if ( debugMode || override || ( announceSettingsBool && IsNYR() ) )  {
			com.GameInterface.UtilsBase.PrintChatText("ALIA v" + version + ":" + ( IsNYR() ? " NYR Detected." : "" ) + " Warning setting is " + pct_warning.GetValue() + '%, Zuberi is ' + ( showZuberi.GetValue() ? "shown" : "hidden" ) + ". Sound alert for Personal Space " + ( personalSound.GetValue() ? "enabled" : "disabled" ) + ". Sound alert for Pod cast " + ( fromBeneathSound.GetValue() ? "enabled" : "disabled" ) + ". Sound alert for Hulks (phase 3) is " + ( playHulkWarningSound.GetValue() ? "enabled" : "disabled" ) + ". NPC names are " + ( showNPCNames.GetValue() ? "shown" : "abbreviated" ) + ". Lurker cast bar is " + ( showCastBar.GetValue() ? "enabled" : "disabled" ) + ". Experimental Shadow bar is " + ( showShadowBar.GetValue() ? "enabled" : "disabled" ) + "." );
			com.GameInterface.UtilsBase.PrintChatText("ALIA: Type \"/option alia_options true\" to see slash commands.");
			announceSettingsBool = false; // only resets on Load() or SettingsChanged()
		}
		
	}
	
	public function AnnounceSlashCommands(dv:DistributedValue):Void {
		if dv.GetValue() {
			com.GameInterface.UtilsBase.PrintChatText("ALIA: \"/setoption alia_warnpct #\" will change the warning threshold to #%.");
			com.GameInterface.UtilsBase.PrintChatText("ALIA: \"/setoption alia_zuberi (true/false)\" will toggle Zuberi display.");
			com.GameInterface.UtilsBase.PrintChatText("ALIA: \"/setoption alia_shownames (true/false)\" will toggle full NPC names.");
			com.GameInterface.UtilsBase.PrintChatText("ALIA: \"/setoption alia_ps_sound (true/false)\" will enable Personal Space warning sound.");
			com.GameInterface.UtilsBase.PrintChatText("ALIA: \"/setoption alia_pod_sound (true/false)\" will enable From Beneath You It Devours warning sound.");
			com.GameInterface.UtilsBase.PrintChatText("ALIA: \"/setoption alia_hulk_sound (true/false)\" will enable warning sounds for hulks in phase 3.");
			com.GameInterface.UtilsBase.PrintChatText("ALIA: \"/setoption alia_castbar (true/false)\" will enable the lurker cast bar.");
			com.GameInterface.UtilsBase.PrintChatText("ALIA: \"/setoption alia_shadowbar (true/false)\" will enable an experimental Shadow from Beyond timer bar.");
			
		}
		dv.SetValue(false);
	}
	
	private function DebuggingHack():Void {
		// stupid hack for debugging purposes only
		SummonDrone();
		if ( debugMode && debuggingHack.GetValue() ){ 
			
			
			PlayHulkWarningSound();
			//PlayPersonalSpaceSoonWarningSound();
			
			
			//barDisplay.UpdateFromBeneathBar(0.9, 20400);
			//setTimeout(Delegate.create(this, PlayPersonalSpaceNowWarningSound), 5000);	
		
			//DebugText("lurker ghosting is " + lurker.IsGhosting() );
			//var pos = m_player.GetPosition();
			//DebugText("x=" + pos.x + ", y=" + pos.y + ", z=" + pos.z);
			
			//countdownTimer.StopCounting();
			//countdownTimer.SetTime(0, 35, 0);
			//countdownTimer.StartCounting();
			
			//UtilsBase.PrintChatText(LDBFormat.LDBGetText(50210, 9463770));
			//playerDebuffController.DEBUG_PrintDebuffsOnRaid();
			
			// do not put code below this line
		}
		
		debuggingHack.SetValue( false );
	}
	
	/////////////////////////////
	////// Encounter Logic //////
	/////////////////////////////
	
	public function ResetAnnounceFlags() {
		// only enable announcements if the lurker is below the threshold (crash/reloadui protection)
		var pct = lurker.GetStat(27, 1) / lurker.GetStat(1, 1);
		if ( pct > pct_SB1_Now ) {	
			ann_SB1_Soon = true;
			ann_SB1_Now = true;
		}
		if (pct > pct_PS1_Now ) {
			ann_PS1_Soon = true;
			ann_PS1_Now = true;
		}
		if ( pct > pct_PS2_Now ) {
			ann_PS2_Soon = true;
			ann_PS2_Now = true;
		}
		if ( pct > pct_PS3_Now ) {
			ann_PS3_Soon = true;
			ann_PS3_Now = true;
		}
		ann_FR_Soon = true;
		ann_FR_Now = true;
	}
	
	public function ResetUpdateHealthDisplayFlag() { updateHealthDisplay = true; }
	
	public function ResetAccumulators() {
		DebugText("ResetAccumulators()");
			numBirds = 0;
			numHulks = 0;
			numShadows = 0;
			numDownfalls = 0;
	}
	
	public function ResetEncounterState() {
		DebugText("ResetEncounterState()");
		SetEncounterState( 0, "ResetEncounterState()");
	}
	
	public function GetLurkerEliteLevel( lurker112:Number, lurkerMaxHealth:Number ):Number {
		
		var elevel:Number = 0; // default to story mode
		
		// test against 112 value (see DetectNPCs comment block below)
		switch ( lurker112 ) {
			case 35448:
			case 35449:
				elevel = 10;
				break;
			case 37256:
			case 37255:
				elevel = 5;
				break;
			case 32433:
			case 32030:
				elevel = 1;
				break;
			case 37265:
			case 37263:
				elevel = 0;
				break;
			default:
				elevel = 0;
				DebugText("Lurker 112 unknown, default to story mode");
				break;
		}
		// E17 has the same 112 value as E10, need to check health to differentiate
		if ( elevel == 10 && lurkerMaxHealth > lurkerMaxHealthE10 ) {
			elevel = 17;
		}
		DebugText("GetLurkerEliteLevel(): Lurker found to be elevel = " + elevel + " (dynel112: " + lurker112 + ", max health: " + lurkerMaxHealth + ")");
		Debugger.PrintText("GetLurkerEliteLevel(): Lurker found to be elevel = " + elevel + " (dynel112: " + lurker112 + ", max health: " + lurkerMaxHealth + ")");
		return elevel;
	}
	
	public function DetectNPCs(dynelId:ID32):Void {
		//DebugText("DetectNPCs()");
		
		/* Notes: 
		// dynelID and dynel.GetID() match, and give type:spawnid (e.g. 50000:12345). spawnid seems to be generated anew each time something is spawned
		// GetType() and m_Type are 50000 for all characters (players, hostile and friendly npcs, etc)
		// GetNameTagCategory() seems to return 5 for NPCs (hostile or friendly), but 6 for lurker (probably "boss")
		// GetName() gives the name
		// GetStat(112) gives the unique character ID, which is what we want to grab
		// Useful 112s:  Eldritch Guardian (bird) is 37266, (hulk) is 37333
		// 112s pulled from E1 intro: Alex is 32302, Mei Ling is 32301, Rose is 32299, Zuberi 32303
		// 112s for lurker:
		//	SM: 37265 (first spawn), 37263 (after wipe)
		//	E1: 32433 (first spawn), 32030 (after wipe)
		//	E5: 37256 (first pull), 37255 (after wipe)
		// 	E10: 35448 (First pull), 35449 (after wipe)
		*/
		
		// bail if this isn't a character
		if dynelId.GetType() != 50000 {return; }
		
		var dynel:Dynel = Dynel.GetDynel(dynelId);
		var dynel112:Number = dynel.GetStat(112);
		
		//if ( debugMode && ( dynel.GetName() == "Eldritch Guardian" || dynel.GetName() == "Zero-Point Titan" ) ) {
			//DebugText("Detected " + dynel.GetName() + " with id " + dynel.GetStat(112));
		//}
		
		/* Debugging stuff
		DebugText("Dynel Id: " + dynelId);
		DebugText("Dynel GetName(): " + dynel.GetName());
		DebugText("Dynel Stat 112: " + dynel.GetStat(112));
		DebugText("Dynel GetID(): " + dynel.GetID());
		DebugText("Dynel Interaction type: " + ProjectUtilsBase.GetInteractionType(dynelId));
		DebugText("Dynel m_Type: " + dynelId.m_Type);
		DebugText("Dynel GetType(): " + dynelId.GetType());
		DebugText("Dynel NameTagCategory: " + dynel.GetNametagCategory());
		*/
		
		// check for lurker first
		if ( !lurker && dynel.GetName() == stringLurker ) {
			DebugText("DetectNPCs(): Lurker hooked")
			
			// store lurker variable
			lurker = Character.GetCharacter(dynel.GetID());
			
			// Connect to lurker-specific signals
			ConnectLurkerSignals();
			
			// set flags for announcements to true
			ResetAnnounceFlags();
			
			// enable health display updating
			updateHealthDisplay = true;
			
			// attempt to set difficulty level
			lurkerEliteLevel = GetLurkerEliteLevel(dynel112, lurker.GetStat(1, 1) );
			cooldownTracker.SetLurkerEliteLevel(lurkerEliteLevel);
		}
		
		// attempt to grab helpful NPCs only under certain conditions (to try and avoid entrance grab)
		// if we know we're past phase 1, or we're in combat, check for Alex/Rose/Mei
		else if ( encounterPhase > 1 || m_player.IsInCombat() ) {
			
			if ( !alex && ( dynel112 == alex112 ) ) {
				alex = new npcStatusMonitor(Character.GetCharacter(dynel.GetID()));
				alex.StatusChanged.Connect(UpdateNPCStatusDisplay, this);
				UpdateNPCStatusDisplay();
				AdvanceEncounterState(3, alex.char.GetName()); // for crash recovery
				DebugText("DetectNPCs(): Alex hooked");
			}
			else if ( !rose && ( dynel112 == rose112 ) ) {			
				rose = new npcStatusMonitor(Character.GetCharacter(dynel.GetID()));
				rose.StatusChanged.Connect(UpdateNPCStatusDisplay, this);
				UpdateNPCStatusDisplay();
				AdvanceEncounterState(3, rose.char.GetName()); // for crash recovery
				DebugText("DetectNPCs(): Rose hooked");
			}
			else if ( !mei && ( dynel112 == mei112 ) ) {
				mei = new npcStatusMonitor(Character.GetCharacter(dynel.GetID()));
				mei.StatusChanged.Connect(UpdateNPCStatusDisplay, this);
				UpdateNPCStatusDisplay();
				AdvanceEncounterState(3, mei.char.GetName()); // for crash recovery
				DebugText("DetectNPCs(): Mei hooked");
			}
		}
		// Zuberi ONLY shows up in phase 3, so we can check for him freely and use him as a phase 3 test/update for crashes/reloadui
		if ( !zuberi && ( dynel112 == zuberi112 ) ) {
			zuberi = new npcStatusMonitor(Character.GetCharacter(dynel.GetID()));
			zuberi.StatusChanged.Connect(UpdateNPCStatusDisplay, this);
			UpdateNPCStatusDisplay();
			AdvanceEncounterState(3, zuberi.char.GetName());
			DebugText("DetectNPCs(): Zuberi hooked");	
		}
		
		// Hulks only show up in phase 2 & 3, use them for encounter state detection
		if ( dynel112 == hulk112_E5 || dynel112 == hulk112_E10 || dynel112 == hulk112_E17 ) {
			DebugText("DetectNPCs(): Detected " + dynel.GetName() + " #" + ( numHulks + 1 ) + ", id: " + dynel112 );	
			
			// grab hulk and store until dead
			currentHulk = Character.GetCharacter(dynel.GetID());
			currentHulk.SignalCharacterDied.Connect(HulkDied, this);
			
			// encounter state logic - detecting a hulk means at least phase 2
			AdvanceEncounterState(2, "detecting a Hulk");
			
			if ( numHulks > 4 || encounterPhase > 2 ) && playHulkWarningSound.GetValue() {
				
				// play sound for MBio
				PlayHulkWarningSound();
			}
		}
		
		// Birds only show up in phase 2, use them for encounter state detection. Each difficulty has a different id, because why the hell not.
		if ( dynel112 == bird112_SM || dynel112 == bird112_E1 || dynel112 == bird112_E5 || dynel112 == bird112_E10 ) {
			DebugText("DetectNPCs(): Detected " + dynel.GetName() + " #" + ( numBirds +1 ) + ", id: " + dynel112 );	
			
			// grab bird and store until dead
			currentBird = Character.GetCharacter(dynel.GetID());
			currentBird.SignalCharacterDied.Connect(BirdDied, this);
			currentBird.SignalCommandStarted.Connect(BirdCasting, this);
			
			// encounter state logic - detecting a hulk means at least phase 2
			AdvanceEncounterState(2, "detecting a Bird");
			
			// update bird/downfall display - add 1 since we only count the birds once they die
			npcDisplay.UpdateBirdNumber( numBirds + 1 );	
			npcDisplay.UpdateDownfallNumber( numDownfalls );
		}
		
		// unhook this function if we have all the NPCs 
		if ( alex && rose && mei && zuberi && lurker ) { 
			DisconnectVicinitySignals(); 
		}
	}
	
	private function AdvanceEncounterState( state:Number, debugText:String ) {
		if state > encounterPhase {
			DebugText("encounterPhase advanced from " + encounterPhase + " to " + state + " by " + debugText);
			
			// set encounter state variable 
			encounterPhase = state;
			
			// update npcStatusDisplay visibility in phases 1-4
			npcDisplay.SetVisibilityByPhase( encounterPhase, ShowZuberi() );
			
			// push this to the cooldown tracker
			cooldownTracker.UpdateEncounterPhase(encounterPhase);
			
			// if we've just started the encounter
			if state == 1 {
				// hide pod display at beginning of phase 1 (it should automatically show/hide itself afterwards)
				podDisplay.SetVisible(false);
				
				//start countdown timer
				countdownTimer.SetTime(10,00,00);
				countdownTimer.StartCounting();
			}
			
			// if we've moved to phase 3
			if state == 3 {
				//force an update status on the NPCs
				UpdateNPCStatusDisplay();
			}
		}
	}
	
	private function SetEncounterState( state:Number, debugText:String ) {
		DebugText("encounterPhase set from " + encounterPhase + " to " + state + " by " + debugText);
		// set encounter state variable 
		encounterPhase = state;
	}
	
	private function GetHealthPercent(char:Character):Number {
		// tested 6/5/2020: stat enum 1 is max health, stat enum 27 is current health
		var pct = char.GetStat(27, 1) / char.GetStat(1, 1);
		return pct;
	}
	
	public function LurkerStatChanged(stat)	{
		//DebugText("Lurker's Stats Changed",debugMode);
		
		if (stat == 27) {
		
			// get lurker's health percent (decimal form)
			var pct = GetHealthPercent(lurker);
			
			// throttle display updates to every 200 ms
			if (updateHealthDisplay && !isNaN(pct) ) {
			
				healthController.UpdateText( Math.round(pct * 1000) / 10 + "%");
				
				updateHealthDisplay = false;
				setTimeout(Delegate.create(this, ResetUpdateHealthDisplayFlag), 200 );
			}
			if ( encounterPhase < 1 && pct < 0.9999999995 ) { 
				AdvanceEncounterState(1, "lurker health below 99.99999995%");
			}
			
			// Shadow Incoming at 75%
			if ( ann_SB1_Soon && pct < ( pct_SB1_Now + pct_warning.GetValue() / 100 ) ) 
			{
				UpdateWarning("Shadow Soon (75%)");
				ann_SB1_Soon = false;
			}
			else if ( ann_SB1_Now && pct < pct_SB1_Now ) 
			{
				UpdateWarningWithBlink("Shadow Now! (75%)"); 
				ann_SB1_Now = false;
			}
			
			// First Personal Space at 67%
			// Limit to phase 3 b/c it's possible to push lurker past 67% + pct_warning in phase 1 and have annoying messages during phase 2.
			if ( ann_PS1_Soon && ( encounterPhase > 2 ) && IsNYR10() && pct < ( pct_PS1_Now + pct_warning.GetValue() / 100 ) ) 
			{
				UpdateWarning("Personal Space Soon (67%)");
				if (Boolean(personalSound.GetValue())) { PlayPersonalSpaceSoonWarningSound(); }
				ann_PS1_Soon = false;
			}
			else if ( ann_PS1_Now && ( encounterPhase > 2 ) && IsNYR10() && pct < pct_PS1_Now ) 
			{
				UpdateWarningWithBlink("Personal Space Now! (67%)"); 
				if (Boolean(personalSound.GetValue())) { PlayPersonalSpaceNowWarningSound(); }
				ann_PS1_Now = false;
			}
			
			// Second Personal Space at 15821546 (45%)
			else if ( ann_PS2_Soon && IsNYR10() && pct < ( pct_PS2_Now + pct_warning.GetValue() / 100 ) ) 
			{
				UpdateWarning("Personal Space Soon (45%)");
				if (Boolean(personalSound.GetValue())) { PlayPersonalSpaceSoonWarningSound(); }
				ann_PS2_Soon = false;
			}
			else if ( ann_PS2_Now && IsNYR10() && pct < pct_PS2_Now ) 
			{
				UpdateWarningWithBlink("Personal Space Now! (45%)"); 
				if (Boolean(personalSound.GetValue())) { PlayPersonalSpaceNowWarningSound(); }
				ann_PS2_Now = false;
			}
			
			// Third Personal Space at 8789478 (25%)
			else if ( ann_PS3_Soon && IsNYR10() && pct < ( pct_PS3_Now + pct_warning.GetValue() / 100 ) ) 
			{
				UpdateWarning("Personal Space Soon (25%)");
				if (Boolean(personalSound.GetValue())) { PlayPersonalSpaceSoonWarningSound(); }
				ann_PS3_Soon = false;		
			}
			else if (ann_PS3_Now && IsNYR10() && pct < pct_PS3_Now ) 
			{
				UpdateWarningWithBlink("Personal Space 3 Now! (25%)");
				if (Boolean(personalSound.GetValue())) { PlayPersonalSpaceNowWarningSound(); }
				ann_PS3_Now = false;
			}
				
			// Final Resort at 1757950 (5%) -  this seems to happen between 2.5% and 3% on Story Mode, but who cares about story mode anyway
			if (ann_FR_Soon && pct < ( (lurkerEliteLevel == 0 ? pct_FR_Now / 2 : pct_FR_Now ) + pct_warning.GetValue() / 100 ) ) 
			{
				UpdateWarning("Final Resort Soon (" + (lurkerEliteLevel == 0 ? "2.5" : "5" ) + "%)");
				ann_FR_Soon = false;				
			}
			else if (ann_FR_Now && pct < (lurkerEliteLevel == 0 ? pct_FR_Now / 2 : pct_FR_Now ) ) 
			{
				UpdateWarningWithBlink("Final Resort Now! (" + (lurkerEliteLevel == 0 ? "2.5" : "5" ) + "%)"); 
				if (Boolean(personalSound.GetValue())) { PlayPersonalSpaceNowWarningSound(); }
				ann_FR_Now = false;			
			}
		}
		// stat 1050 is Lurker's "interactable" or "targetable" stat. Changes to 5 at beginning of phase 2. Changes to 3 when lurker becomes active at beginning of phase 3.
		else if ( stat == 1050 ) {
			var statval:Number = lurker.GetStat(stat, 1);
			DebugText("LurkerStatChanged(): stat 1050 changed to " + statval );
			// start tracking cooldowns again as soon as lurker becomes targetable in phase 3
			if ( statval == 3 ) {
				DebugText("LurkerStatChanged(): Lurker became active in phase 3");
				AdvanceEncounterState(3, "lurker became active in phase 3");
				DebugText("LurkerStatChanged(): cooldownTracker.StartTrackingCooldowns() called");
				cooldownTracker.StartTrackingCooldowns();
			}
			else if ( statval == 5 ) {
				AdvanceEncounterState(2, "Lurker became inactive");
			}
		}
		else {
			DebugText("LurkerStatChanged(): stat = " + stat + ", amt = " + lurker.GetStat(stat, 1) );
		}
	}
	
	public function LurkerCasting(spell) {
		DebugText("Lurker is casting " + spell);
		
		// Several of these calls need to be throttled because reticle-targetting can cause this signal to be triggered multiple times in one cast
		if showCastBar.GetValue() {
			lurkerCastName = spell;
			StartLurkerCastBar(); //todo throttle?
		}
		
		// Shadow out of Time
		if ( ( spell == stringShadowOutOfTime ) && shadowThrottleFlag )
		{	
			numShadows++;
			DebugText("numShadows = " + numShadows );
			shadowThrottleFlag = false;
			
			// reset cooldown tracker
			cooldownTracker.ResetShadowCooldown();
			
			// encounter phase logic - set to phase 2 (primarily crash detection)
			AdvanceEncounterState(2, "a Shadow cast");
			
			// reset throttle flag after 10 seconds (cast is only 8 seconds)
			setTimeout(Delegate.create(this, ResetShadowThrottleFlag), LOCKOUT_SHADOW);
			
			// only decay warning text on the first shadow
			if numShadows < 2 {
				warningController.DecayText(3);
			}
		}
		
		// Personal Space
		else if (spell == stringPersonalSpace && personalThrottleFlag)
		{
			//if ( GetHealthPercent(lurker) < 0.68 ) {
				
				// decay warning text when PS is cast
				warningController.DecayText(3);	
			//}
			
			// reset throttle flag after 7 seconds (cast is only 5 seconds)
			setTimeout(Delegate.create(this, ResetPersonalThrottleFlag), LOCKOUT_PERSONAL);
		}
		
		// Final Resort
		else if (spell == stringFinalResort && personalThrottleFlag)
		{
			// decay warning text and stop blinking effect when FR cast
			warningController.DecayText(3);
			warningController.StopBlink();
			warningController.SetTextColor(nowColor);
			
			// reset throttle flag after 7 seconds (cast is only 5 seconds)
			setTimeout(Delegate.create(this, ResetPersonalThrottleFlag), LOCKOUT_PERSONAL);
		}
		
		// From Beneath You It Devours (pod)
		else if ( (spell == stringFromBeneath ) && fromBeneathThrottleFlag )
		{
			fromBeneathThrottleFlag = false;
			
			// play a warning sound for pod casts (audible cue for cleansers)
			if (Boolean(fromBeneathSound.GetValue())) { PlayFromBeneathWarningSound(); }
			
			// enable player debuff monitoring
			playerDebuffController.MonitorRaidForPodDebuff();
						
			// reset cooldown tracker
			cooldownTracker.ResetFromBeneathCooldown();
			
			// reset throttle flag after 4 seconds (cast is only 3 seconds)
			setTimeout(Delegate.create(this, ResetFromBeneathThrottleFlag), LOCKOUT_FROM_BENEATH);
		}
		
		// Pure Filth
		else if ( (spell == stringPureFilth ) && pureFilthThrottleFlag )
		{
			pureFilthThrottleFlag = false;
			
			//reset cooldown tracker
			cooldownTracker.ResetPureFilthCooldown();
			
			// reset throttle flag after 4 seconds (cast is only 3 seconds)
			setTimeout(Delegate.create(this, ResetPureFilthThrottleFlag), LOCKOUT_PURE_FILTH);
			
			//// Debugging
			//playerDebuffController.DEBUG_PrintDebuffsOnRaid(); // TODO: DELETE this whole section
			//setTimeout(Delegate.create(this, playerDebuffController.DEBUG_PrintDebuffsOnRaid), 10000);
		}
	}
	
	public function BirdCasting(spell) {
		DebugText("Bird is casting " + spell );
		// DebugText("stringDownfall is " + stringDownfall);
		
		// throttling to prevent multi-triggers
		if ( ( spell == stringDownfall ) && downfallThrottleFlag )
		{
			numDownfalls++;
			downfallThrottleFlag = false;
			// reset throttle flag after 5 econds (cast is only 2 seconds)
			setTimeout(Delegate.create(this, ResetDownfallThrottleFlag), 5000);
			
			// update display
			if encounterPhase < 3 {
				DebugText("numDownfalls is " + numDownfalls );
				npcDisplay.UpdateDownfallNumber( numDownfalls );
			}
		}
	}

	private function StartLurkerCastBar() {
		DebugText("SLCB entered")
		lurkerCastBar.SetVisible(true);
		//lurkerCastBar.Update(lurker.GetCommandProgress(), "", lurkerCastName);
		DebugText("interval: " + lurkerCastBarUpdateInterval);
		if (!lurkerCastBarUpdateInterval ) {
			lurkerCastBarUpdateInterval = setInterval(Delegate.create(this, UpdateLurkerCastBar), LURKERCASTBAR_INTERVAL);
		}
	}
	
	private function UpdateLurkerCastBar() {
		lurkerCastBar.Update(lurker.GetCommandProgress(), "", "");
		lurkerCastBar.SetCenterText(lurkerCastName);
		
		//DebugText("ULC: bool: " + lurkerCastInProgress + "; progress: " + lurker.GetCommandProgress());
		
		if ( lurker.GetCommandProgress() > 0.2 && ! lurkerCastInProgress ) { lurkerCastInProgress = true };
		
		if ( lurker.GetCommandProgress() == 0 ||lurker.GetCommandProgress() == 1 || ! lurker.GetCommandProgress() ) && lurkerCastInProgress {
			lurkerCastBar.SetVisible(false);
			lurkerCastInProgress = false;
			DebugText("ULC.end bool: " + lurkerCastInProgress + "; progress: " + lurker.GetCommandProgress());
			clearInterval(lurkerCastBarUpdateInterval);
			lurkerCastBarUpdateInterval = undefined;
		}
	}
	
	private function ResetShadowThrottleFlag() { shadowThrottleFlag = true; }
	
	private function ResetPersonalThrottleFlag() { personalThrottleFlag = true; }
	
	private function ResetFromBeneathThrottleFlag() { fromBeneathThrottleFlag = true; }
	
	private function ResetPureFilthThrottleFlag() { pureFilthThrottleFlag = true; }
	
	private function ResetDownfallThrottleFlag() { downfallThrottleFlag = true; }
	
	////////////////////////////////
	////// Signal Connections //////
	////////////////////////////////
	
	public function LurkerDied() {
		
		healthController.UpdateText("Dead");
		healthController.DecayText(5);
		
		// disconnect lurker signals
		DisconnectLurkerSignals();
		lurker = undefined; // probably not needed
		
		// decay any remaining message, also stop blinking
		warningController.DecayText(3);
		warningController.StopBlink();
		npcDisplay.DecayDisplay(3);
		
		// stop any debuff polling interval
		playerDebuffController.StopCheckingDebuffs();
		
		// set encounterPhase to 4 to signify death
		AdvanceEncounterState( 4, "LurkerDied()");
		countdownTimer.StopCounting();
	}
	
	public function ResetLurker() {
		DebugText("ResetLurker(): Signals disconnected, lurker unlocked")
		
		// Disconnect all of the lurker-specific signals
		DisconnectLurkerSignals();
		
		// re-enable Vicinity Signals
		setTimeout(Delegate.create(this, ConnectVicinitySignals), 3000 );
		
		// decay any remaining message, also stop blinking
		warningController.DecayText(3);
		warningController.StopBlink();
		
		// stop any debuff polling interval
		playerDebuffController.StopCheckingDebuffs();
		
		// stop the cooldown Tracker if it's running
		cooldownTracker.StopTrackingCooldowns();
		cooldownTracker.ResetEncounter();
		// TODO: reset the timers too
		
		// reset accumulators / encounter state variable
		ResetAccumulators();
		ResetEncounterState();
		currentBird = undefined;
		currentHulk = undefined;
		countdownTimer.StopCounting();
	}
	
	public function ConnectLurkerSignals() {	
		DebugText("ConnectLurkerSignals()");
		
		// Connect to statchanged signal
		lurker.SignalStatChanged.Connect(LurkerStatChanged, this);
		lurker.SignalCommandStarted.Connect(LurkerCasting, this);
		
		// Connect death/wipe signals to a function that resets signal connections 
		lurker.SignalCharacterDied.Connect(LurkerDied, this);
		lurker.SignalCharacterDestructed.Connect(ResetLurker, this);	
	}
	
	public function DisconnectLurkerSignals() {
		
		// Disconnect all of the lurker-specific signals
		lurker.SignalStatChanged.Disconnect(LurkerStatChanged, this);	
		lurker.SignalCommandStarted.Disconnect(LurkerCasting, this);
		lurker.SignalCharacterDied.Disconnect(LurkerDied, this);
		lurker.SignalCharacterDestructed.Disconnect(ResetLurker, this);	
	}
	
	public function ConnectCharacterAliveSignal() {
		m_player.SignalCharacterAlive.Connect(ResetLurker, this);
	}
	
	public function DisconnectCharacterAliveSignal() {
		m_player.SignalCharacterAlive.Disconnect(ResetLurker, this);
	}
	
	public function ConnectCharacterInCombatSignal() {
		m_player.SignalToggleCombat.Connect(PlayerEntersCombat, this);
	}
	public function DisconnectCharacterInCombatSignal() {
		m_player.SignalToggleCombat.Disconnect(PlayerEntersCombat, this);
	}
	
	private function PlayerEntersCombat() {
		DebugText("SignalToggleCombat fired");
		var pos = m_player.GetPosition();
		if ( encounterPhase < 1 && lurker ) {
			AdvanceEncounterState(1, "player entered combat after detecting lurker");
		}
		else if (  encounterPhase < 1 && ( pos.z < 560 ) ) {
			AdvanceEncounterState(1, "player entered combat in appropriate proximity");
		}
	}
	
	public function HulkDied() {
		
		// disconnect signals
		currentHulk.SignalCharacterDied.Disconnect(HulkDied, this);
		currentHulk = undefined; // probably not needed
		
		// increment Hulk Counter
		numHulks++;	
	}
	
	public function BirdDied() {
		
		// disconnect signals
		currentBird.SignalCharacterDied.Disconnect(BirdDied, this);
		currentBird.SignalCommandStarted.Disconnect(BirdCasting, this);
		currentBird = undefined; // probably not needed
		
		// increment Bird Counter
		numBirds++;	
		
		// reset downfall counter
		numDownfalls = 0;
	}
	
	public function ConnectVicinitySignals() {
		DebugText("ConnectVicinitySignal()");
		
		VicinitySystem.SignalDynelEnterVicinity.Connect(DetectNPCs, this);
		m_player.SignalOffensiveTargetChanged.Connect(DetectNPCs, this);
		m_player.SignalDefensiveTargetChanged.Connect(DetectNPCs, this);
		
		// reset all of the character variables
		alex = undefined;
		rose = undefined;
		mei = undefined;
		zuberi = undefined;
		lurker = undefined;
		
		UpdateNPCStatusDisplay();
		
	}
	
	public function DisconnectVicinitySignals()	{
		DebugText("DisconnectVicinitySignal()");
		
		VicinitySystem.SignalDynelEnterVicinity.Disconnect(DetectNPCs, this);
		m_player.SignalOffensiveTargetChanged.Disconnect(DetectNPCs, this);
		m_player.SignalDefensiveTargetChanged.Disconnect(DetectNPCs, this);
		
	}
	
/*	// TODO: Comment once finished testing
	public function ConnectTestSignals() {
		
		m_player.SignalCharacterAlive.Connect(PrintSignalCharacterAlive, this);// "SignalCharacterAlive");
		m_player.SignalCharacterDied.Connect(PrintSignalCharacterDied, this);// "SignalCharacterDied");
		m_player.SignalCharacterRevived.Connect(PrintSignalCharacterRevived, this);// "SignalCharacterRevived");
		m_player.SignalCharacterTeleported.Connect(PrintSignalCharacterTeleported, this);// "SignalCharacterTeleported");
		m_player.SignalCharacterDestructed.Connect(PrintSignalCharacterDestructed, this);// "SignalCharacterDestructed");
		m_player.SignalToggleCombat.Connect(PrintSignalToggleCombat, this);// "SignalToggleCombat");
		//m_player.SignalClientCharacterAlive.Connect(SignalPrinter, "SignalClientCharacterAlive");
		//m_player.SignalCharacterDestructed.Connect(SignalPrinter, "SignalCharacterDestructed");
		
	}*/
	
	///////////////////////
	//////  Sounds  ///////
	///////////////////////
	
	public function PlayPersonalSpaceSoonWarningSound() {
		// breaking target and retargeting the boss can generate the signal multiple times,
		// so we have to throttle the sound playing
		if ( !personalSoonSoundAlreadyPlaying ) {
			// throttle sound 
			personalSoonSoundAlreadyPlaying = true;
			// create beep pattern
			PlayMobilePhoneTone6();
			setTimeout(Delegate.create(this, PlayMobilePhoneTone7), 300 );
			setTimeout(Delegate.create(this, PlayMobilePhoneTone8), 600 );
			setTimeout(Delegate.create(this, PlayMobilePhoneTone9), 900 );
			//for ( var i:Number = 0; i < 5; i ++ )
			//{
				//setTimeout(Delegate.create(this, PlaySingleBeep), i*900);
			//}
			// unthrottle after 5 seconds
			setTimeout(Delegate.create(this, ResetPersonalSpaceSoonWarningSoundFlag), 5000 );
		}		
	}
	
	public function ResetPersonalSpaceSoonWarningSoundFlag() {
		personalSoonSoundAlreadyPlaying = false;
	}
	
	public function PlayPersonalSpaceNowWarningSound() {
		// breaking target and retargeting the boss can generate the signal multiple times,
		// so we have to throttle the sound playing
		if ( !personalNowSoundAlreadyPlaying ) {
			// throttle sound 
			personalNowSoundAlreadyPlaying = true;
			// create beep pattern
			for ( var i:Number = 0; i < 25; i ++ )
			{
				setTimeout(Delegate.create(this, PlaySingleBeep), i*200);
			}
			// unthrottle after 5 seconds
			setTimeout(Delegate.create(this, ResetPersonalSpaceNowWarningSoundFlag), 5000 );
		}		
	}
	
	public function ResetPersonalSpaceNowWarningSoundFlag() {
		personalNowSoundAlreadyPlaying = false;
	}
	
	public function PlayFromBeneathWarningSound() {
		// breaking target and retargeting the boss can generate the signal multiple times,
		// so we have to throttle the sound playing
		if ( !fromBeneathSoundAlreadyPlaying ) {
			// throttle sound 
			fromBeneathSoundAlreadyPlaying = true;
			// create beep pattern
			for ( var i:Number = 0; i < 4; i ++ )
			{
				setTimeout(Delegate.create(this, PlaySingleMobilePositive), i*900);
			}
			// unthrottle after 5 seconds
			setTimeout(Delegate.create(this, ResetFromBeneathWarningSoundFlag), 5000 );
		}
	}
	
	public function PlayHulkWarningSound() {
		//PlaySingleMobileNegative();
		for ( var i:Number = 0; i < 5; i ++ )
		{
			setTimeout(Delegate.create(this, PlaySingleMobileNegative), i*300);
		}
		//setTimeout(Delegate.create(this, PlaySingleMobileNegative), 400);
		//setTimeout(Delegate.create(this, PlaySingleMobileNegative), 800);
		//setTimeout(Delegate.create(this, PlaySingleMobileNegative), 1500);
		//setTimeout(Delegate.create(this, PlaySingleMobileNegative), 1000);
	}
	
	public function ResetFromBeneathWarningSoundFlag() {
		fromBeneathSoundAlreadyPlaying = false;
	}
	
	public function PlaySingleBeep() {
		com.GameInterface.Game.Character.GetClientCharacter().AddEffectPackage("sound_fxpackage_beep_single.xml");
	}
	
	public function PlaySingleMobilePositive() {
		com.GameInterface.Game.Character.GetClientCharacter().AddEffectPackage("sound_fx_package_mobile_positive_feedback.xml");
	}
	
	public function PlaySingleMobileNegative() {
		com.GameInterface.Game.Character.GetClientCharacter().AddEffectPackage("sound_fx_package_mobile_negative_feedback.xml");
	}
	
	public function PlayMobilePhoneTone6() {
		com.GameInterface.Game.Character.GetClientCharacter().AddEffectPackage("sound_fx_package_mobile_phone_button_6.xml");
	}
	public function PlayMobilePhoneTone7() {
		com.GameInterface.Game.Character.GetClientCharacter().AddEffectPackage("sound_fx_package_mobile_phone_button_7.xml");
	}
	public function PlayMobilePhoneTone8() {
		com.GameInterface.Game.Character.GetClientCharacter().AddEffectPackage("sound_fx_package_mobile_phone_button_8.xml");
	}
	public function PlayMobilePhoneTone9() {
		com.GameInterface.Game.Character.GetClientCharacter().AddEffectPackage("sound_fx_package_mobile_phone_button_9.xml");
	}
	
	public function PlayChainsawSound() {		
		com.GameInterface.Game.Character.GetClientCharacter().AddEffectPackage("sound_fxpackage_GUI_item_equip_chainsaw.xml");
	}
	
	public function PlayWhipSound() {		
		com.GameInterface.Game.Character.GetClientCharacter().AddEffectPackage("sound_fxpackage_GUI_item_equip_whip.xml");
	}
	
	public function SummonDrone() {
		com.GameInterface.Game.Character.GetClientCharacter().AddEffectPackage("fxpackage_gameplay_generic_auctionhouse_deliverydrone.xml");
	}
	
	///////////////////////
	////// GUI stuff //////
	///////////////////////
	
	public function CreateGuiElements() {
		DebugText("CreateGuiElements()");
		
		// if a warning field doesn't already exist, create one
		if !warningController {
			warningController = new TextFieldController(m_swfRoot, "warningText");
			DebugText("Warning Controller created");
		}
		
		// if pct health display doesn't already exist, create one
		if !healthController {
			healthController = new TextFieldController(m_swfRoot, "healthText");
			DebugText("% Health Controller created");
		}
		
		// if the NPC display doesn't already exist, create one
		if !npcDisplay {
			npcDisplay = new npcStatusDisplay(m_swfRoot, showNPCNames.GetValue());
			DebugText("NPC Status Display created");
		}
		
		// if the pod target display doesn't exist, create it
		if !podDisplay {
			podDisplay = new podTargetsDisplay(m_swfRoot);
			DebugText("Pod Target Display created");
		}
		
		// if the debuff checker doesn't exist, create one
		if !playerDebuffController {
			playerDebuffController = new playerDebuffChecker(podDisplay);
			//playerDebuffController.DebuffStatusChanged.Connect(UpdatePodText, this);
			DebugText("Player Debuff Checker created");
		}
		
		// if the lurker bar display doesn't already exist, create one
		if ( !barDisplay ) {
			barDisplay = new lurkerBarDsiplay(m_swfRoot);
			DebugText("Bar Display created");
		}
		
		// if the cooldown tracker doesn't exist, create it
		if ( !cooldownTracker ) {
			cooldownTracker = new lurkerCooldownTracker(barDisplay);
			DebugText("Cooldown Tracker created");
		}
		
		// if the countdown timer doesn't exist, create it
		if ( !countdownTimer ) {
			countdownTimer = new SimpleCounter("ALIA", m_swfRoot, 30);
			countdownTimer.SetTime(10, 0, 0);
			DebugText("Countdown Timer created");
		}
		
		// if the lurker cast bar doesn't exist, create it
		if ( !lurkerCastBar ) {
			lurkerCastBar = new SimpleBar("lurkerCastSimpleBar", m_swfRoot, 600, 600, 280, 16);
			DebugText("Lurker Cast Bar created");
		}
		
		// Set default text
        warningController.UpdateText("A Lurker Is Announced");
		warningController.DecayText(textDecayTime);
		healthController.UpdateText("100%");
		
		// Call a GuiEdit to update visibility and such
        GuiEdit();
    }
	
	public function DestroyGUIElements() {
		DebugText("DestroyGUIElements()");
		
		warningController = undefined;
		healthController = undefined;
		npcDisplay = undefined;		
		playerDebuffController = undefined;
		podDisplay = undefined;
	}
	
	private function UpdateWarning(text:String)	{
		// print text to chat, stop any existing blink effects, and update the text field
		//com.GameInterface.UtilsBase.PrintChatText(text);
		warningController.StopBlink();
		warningController.UpdateText(text);
	}
	
	private function UpdateWarningWithDecay(text:String) {
		// print text to chat, update the text field, schedule decay
		//com.GameInterface.UtilsBase.PrintChatText(text);
		warningController.UpdateText(text);		
		warningController.DecayText(textDecayTime);
	}
	
	private function UpdateWarningWithBlink(text:String) {
		// print text to chat, set color to red, update the text field, start blinking
		//com.GameInterface.UtilsBase.PrintChatText(text);
		warningController.SetTextColor( nowColor );
		warningController.UpdateText(text);
		warningController.BlinkText();
	}
    
	private function UpdateNPCStatusDisplay() {
		//DebugText("UpdateNPCStatusDisplay(): m: " + mei.GetStatus() + " r: " + rose.GetStatus() + " a: " + alex.GetStatus() + " z: " + zuberi.GetStatus() );
		npcDisplay.UpdateAll(mei.GetStatus(), rose.GetStatus(), alex.GetStatus(), zuberi.GetStatus());
	}
	
    //private function UpdatePodText() {
		//npcDisplay.UpdatePodStatus(playerDebuffController.GetVictimName(), playerDebuffController.GetVictimStatus() );
	//}
	
	public function WarningStartDrag() {
		DebugText("WarningStartDrag called");
        warningController.clip.startDrag();
    }

    public function WarningStopDrag() {
		DebugText("WarningStopDrag called");
        warningController.clip.stopDrag();
		
		// grab position for config storage on Deactivate()
        w_pos = Common.getOnScreen(warningController.clip); 
		
		DebugText("WarningStopDrag: x: " + w_pos.x + "  y: " + w_pos.y);
    }
	
    public function PctHealthStartDrag() {
		DebugText("PctHealthStartDrag called");
        healthController.clip.startDrag();
    }

    public function PctHealthStopDrag() {
		DebugText("PctHealthStopDrag called");
        healthController.clip.stopDrag();
		
		// grab position for config storage on Deactivate()
        h_pos = Common.getOnScreen(healthController.clip); 
		
		DebugText("PctHealthStopDrag: x: " + h_pos.x + "  y: " + h_pos.y);
    }
	
    public function NpcStartDrag() {
		DebugText("NpcStartDrag called");
        npcDisplay.clip.startDrag();
    }

    public function NpcStopDrag() {
		DebugText("NpcStopDrag called");
        npcDisplay.clip.stopDrag();
		
		// grab position for config storage on Deactivate()
        n_pos = Common.getOnScreen(npcDisplay.clip); 
		
		DebugText("NpcStopDrag: x: " + n_pos.x + "  y: " + n_pos.y);
    }
	
    public function PodStartDrag() {
		DebugText("podStartDrag called");
        podDisplay.clip.startDrag();
    }

    public function PodStopDrag() {
		DebugText("podStopDrag called");
        podDisplay.clip.stopDrag();
		
		// grab position for config storage on Deactivate()
        p_pos = Common.getOnScreen(podDisplay.clip); 
		
		DebugText("podStopDrag: x: " + p_pos.x + "  y: " + p_pos.y);
    }
	
    public function BarStartDrag() {
		DebugText("BarStartDrag called");
        barDisplay.clip.startDrag();
    }

    public function BarStopDrag() {
		DebugText("BarStopDrag called");
        barDisplay.clip.stopDrag();
		
		// grab position for config storage on Deactivate()
        b_pos = Common.getOnScreen(barDisplay.clip); 
		
		DebugText("barStopDrag: x: " + b_pos.x + "  y: " + b_pos.y);
    }
	
    public function TimerStartDrag() {
		DebugText("TimerStartDrag called");
        countdownTimer.clip.startDrag();
    }

    public function TimerStopDrag() {
		DebugText("TimerStopDrag called");
        countdownTimer.clip.stopDrag();
		
		// grab position for config storage on Deactivate()
        t_pos = Common.getOnScreen(countdownTimer.clip); 
		
		DebugText("TimerStopDrag: x: " + t_pos.x + "  y: " + t_pos.y);
    }
	
    public function CastBarStartDrag() {
		DebugText("CastBarStartDrag called");
        lurkerCastBar.m_frame.startDrag();
    }

    public function CastBarStopDrag() {
		DebugText("CastBarStopDrag called");
        lurkerCastBar.m_frame.stopDrag();
		
		// grab position for config storage on Deactivate()
        cb_pos = Common.getOnScreen(lurkerCastBar.m_frame); 
		
		DebugText("CastBarStopDrag: x: " + cb_pos.x + "  y: " + cb_pos.y);
    }
	
	
    public function ShowZuberi():Boolean {
		if ( Boolean(showZuberi.GetValue()) || lurkerEliteLevel > 10 ) 
		{
			return true; 
		}
		else 
		{ 
			return false;
		}
	}
	
	public function SplashWarningText() {
		warningController.UpdateText("A Lurker Is Announced");
		warningController.DecayText(textDecayTime);
	}
	
	public function GuiEdit(state:Boolean) {
		DebugText("GuiEdit: state " + state );
		warningController.SetVisible(IsNYR());
		warningController.EnableInteraction(false);
		healthController.SetVisible(IsNYR()); 
		podDisplay.SetVisible(IsNYR());
		barDisplay.SetVisible(IsNYR());
		countdownTimer.SetVisible(IsNYR());
		lurkerCastBar.SetVisible(IsNYR());
		
		//only editable in NYR
		if IsNYR() 
		{
			if (state) {
				DebugText("GuiEdit: true case executed");
				warningController.clip.onPress = Delegate.create(this, WarningStartDrag);
				warningController.clip.onRelease = Delegate.create(this, WarningStopDrag);
				warningController.UpdateText("~~~~~ Move Me!! ~~~~~");
				warningController.SetVisible(true);
				warningController.SetGUIEdit(true);
				warningController.StopBlink(); // probably unnecessary?
				
				healthController.clip.onPress = Delegate.create(this, PctHealthStartDrag);
				healthController.clip.onRelease = Delegate.create(this, PctHealthStopDrag);
				healthController.UpdateText("100%");
				healthController.SetVisible(true);
				healthController.SetGUIEdit(true);
				
				npcDisplay.SetGUIEdit(true);
				npcDisplay.clip.onPress = Delegate.create(this, NpcStartDrag);
				npcDisplay.clip.onRelease = Delegate.create(this, NpcStopDrag);
				
				podDisplay.SetGUIEdit(true);
				podDisplay.clip.onPress = Delegate.create(this, PodStartDrag);
				podDisplay.clip.onRelease = Delegate.create(this, PodStopDrag);
				
				barDisplay.SetGUIEdit(true);
				barDisplay.clip.onPress = Delegate.create(this, BarStartDrag);
				//barDisplay.fromBeneathBar.onP
				barDisplay.clip.onRelease = Delegate.create(this, BarStopDrag);
				
				countdownTimer.SetGUIEdit(true);
				countdownTimer.clip.onPress = Delegate.create(this, TimerStartDrag);
				countdownTimer.clip.onRelease = Delegate.create(this, TimerStopDrag);
				
				lurkerCastBar.SetVisible(true);
				lurkerCastBar.ShowDragText(true);
				lurkerCastBar.m_frame.onPress = Delegate.create(this, CastBarStartDrag);
				lurkerCastBar.m_frame.onRelease = Delegate.create(this, CastBarStopDrag);
				
				
				// set throttle variable - this prevents extra spam when the game calls GuiEdit event with false argument, which it seems to like to do ALL THE DAMN TIME
				guiEditThrottle = true;
			} 
			else if guiEditThrottle {
				DebugText("GuiEdit: false case executed");
				warningController.clip.stopDrag();
				warningController.clip.onPress = undefined;
				warningController.clip.onRelease = undefined;
				SplashWarningText();
				warningController.SetGUIEdit(false);
				warningController.StopBlink(); // probably unnecessary?
				
				healthController.clip.stopDrag();
				healthController.clip.onPress = undefined;
				healthController.clip.onRelease = undefined;
				healthController.SetGUIEdit(false);
				
				npcDisplay.clip.stopDrag();
				npcDisplay.clip.onPress = undefined;
				npcDisplay.clip.onRelease = undefined;
				npcDisplay.SetGUIEdit(false);
				npcDisplay.SetVisible(IsNYR(), encounterPhase, ShowZuberi() );
				
				podDisplay.clip.stopDrag();
				podDisplay.clip.onPress = undefined;
				podDisplay.clip.onRelease = undefined;
				podDisplay.SetGUIEdit(false);
				podDisplay.SetVisible( IsNYR(), encounterPhase);
				
				barDisplay.clip.stopDrag();
				barDisplay.clip.onPress = undefined;
				barDisplay.clip.onRelease = undefined;
				barDisplay.SetGUIEdit(false);
				barDisplay.SetVisible(IsNYR(), encounterPhase);
				
				countdownTimer.clip.stopDrag();
				countdownTimer.clip.onPress = undefined;
				countdownTimer.clip.onRelease = undefined;
				countdownTimer.SetGUIEdit(false);
				countdownTimer.SetVisible(IsNYR());
				
				lurkerCastBar.ShowDragText(false);
				lurkerCastBar.m_frame.onPress = undefined;
				lurkerCastBar.m_frame.onRelease = undefined;
				lurkerCastBar.SetVisible(false);
				
				// set throttle variable
				guiEditThrottle = false;
				setTimeout(Delegate.create(this, ResetGuiEditThrottle), 100);
			}
		}
    }
	
	private function ResetGuiEditThrottle() {
		guiEditThrottle = true;
	}
	
	///////////////////////
	////// Debugging //////
	///////////////////////
	
	static function DebugText(text) {
		if (debugMode) Debugger.PrintText(text);
	}
	
	//private function PrintSignalCharacterAlive() {
		//Debugger.PrintText("SignalCharacterAlive");
	//}
	//
	//private function PrintSignalCharacterDied() {
		//Debugger.PrintText("SignalCharacterDied");
	//}
	//
	//private function PrintSignalCharacterRevived() {
		//Debugger.PrintText("SignalCharacterRevived");
	//}
	//
	//private function PrintSignalCharacterTeleported() {
		//Debugger.PrintText("SignalCharacterTeleported");
	//}
	//
	//private function PrintSignalToggleCombat() {
		//Debugger.PrintText("SignalToggleCombat");
	//}
	//
	//private function PrintSignalCharacterDestructed() {
		//Debugger.PrintText("SignalCharacterDestructed");
	//}
}
