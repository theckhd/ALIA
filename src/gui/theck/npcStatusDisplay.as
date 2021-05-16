/**
 * ...
 * @author theck
 */
import caurina.transitions.Tweener;
import flash.geom.Point;
import com.theck.Utils.Debugger;

class gui.theck.npcStatusDisplay
{
	// toggle debug messages
	static var debugMode:Boolean = false;
	
	// status colors: White (running), Green (buffing), Gray (incapacitated), Yellow (pod inc), Red (podded)
	static var statusColors:Array = new Array(0xFFFFFF, 0x008000, 0xA4A4A4, 0xFFC300 , 0xFF0000);
	static var statusText:Array = new Array("", "", "", "Doomed" , "Podded");
		
    public var clip:MovieClip;
	
    private var alexLetter:TextField;
    private var roseLetter:TextField;
    private var meiLetter:TextField;
    private var zuberiLetter:TextField;
	
    private var alexStatusText:TextField;
    private var roseStatusText:TextField;
    private var meiStatusText:TextField;
    private var zuberiStatusText:TextField;
	
	
	static var textSize:Number = 30;
	static var boxSize:Number = textSize * 1.35;
	static var statusTextWidth:Number = textSize * 4;
	static var letterWidthMultiplier:Number = 2.35;
	
	private var letterWidth:Number = boxSize;
	private var letterOffset:Number = 0;
	
	private var showFullNPCNames:Boolean;
	
	public function npcStatusDisplay(target:MovieClip, fullNPCs:Boolean) 
	{
		clip = target.createEmptyMovieClip("npcStatusDisplay", target.getNextHighestDepth());
        clip._x = Stage.width /  2;
        clip._y = Stage.height / 2;
		
		showFullNPCNames = fullNPCs;
		
		if showFullNPCNames {
			letterWidth = textSize * letterWidthMultiplier;
			letterOffset = textSize * ( -1 );
		}
		
		meiLetter = clip.createTextField("mei", clip.getNextHighestDepth(), letterOffset, 0, letterWidth, boxSize);
		roseLetter = clip.createTextField("rose", clip.getNextHighestDepth(), letterOffset, boxSize, letterWidth, boxSize);
        alexLetter = clip.createTextField("alex", clip.getNextHighestDepth(), letterOffset, 2*boxSize, letterWidth, boxSize);
		zuberiLetter = clip.createTextField("zuberi", clip.getNextHighestDepth(), letterOffset, 3*boxSize, letterWidth, boxSize);
		
		InitializeLetter(meiLetter, showFullNPCNames);
		InitializeLetter(roseLetter, showFullNPCNames);
		InitializeLetter(alexLetter, showFullNPCNames);
		InitializeLetter(zuberiLetter, showFullNPCNames);
		
		meiStatusText = clip.createTextField("meiStatus", clip.getNextHighestDepth(), boxSize, 0, statusTextWidth, boxSize);
		roseStatusText = clip.createTextField("roseStatus", clip.getNextHighestDepth(), boxSize, boxSize, statusTextWidth, boxSize);
		alexStatusText = clip.createTextField("alexStatus", clip.getNextHighestDepth(), boxSize, 2*boxSize, statusTextWidth, boxSize);
		zuberiStatusText = clip.createTextField("zuberiStatus", clip.getNextHighestDepth(), boxSize, 3*boxSize, statusTextWidth, boxSize);
		
		InitializeStatusText(meiStatusText);
		InitializeStatusText(roseStatusText);
		InitializeStatusText(alexStatusText);
		InitializeStatusText(zuberiStatusText);
	}
	
	public function ChangeLetterMode(newState:Boolean) {
		
		if ( showFullNPCNames && !newState ) {
			// set letterOffset to 0 and letterWidth to boxSize
			letterOffset = 0;
			letterWidth = boxSize;
		}
		else if ( !showFullNPCNames && newState ) {
			// set letterOffset & letterWidth
			letterOffset = textSize * ( -1 );
			letterWidth = textSize * letterWidthMultiplier;
		}
		
		showFullNPCNames = newState;
		
		// set all x values to letterOffset
		meiLetter._x = letterOffset;
		roseLetter._x = letterOffset;
		alexLetter._x = letterOffset;
		zuberiLetter._x = letterOffset;
		
		// set all width values to letterWidth
		meiLetter._width = letterWidth;
		roseLetter._width = letterWidth;
		alexLetter._width = letterWidth;
		zuberiLetter._width = letterWidth;
				
		// reinitialize text
		InitializeAllLetters(newState);
	}
	
	public function InitializeAllLetters(fullNPCs:Boolean) {
		InitializeLetter(meiLetter, fullNPCs);
		InitializeLetter(roseLetter, fullNPCs);
		InitializeLetter(alexLetter, fullNPCs);
		InitializeLetter(zuberiLetter, fullNPCs);
	}
	
	public function InitializeLetter(field:TextField, fullNPCs:Boolean) {	
		
        var textFormat:TextFormat = new TextFormat("_StandardFont", textSize,0xFFFFFF, true);
        textFormat.align = "center"	
		
        field.setNewTextFormat(textFormat);
        //field.autoSize = "center";
		field.background = true;
		field.backgroundColor = 0x000000;
		//field.border = true;
		
		SetLetterText(field, fullNPCs);	
	}
	
	private function SetLetterText(field:TextField, fullNPCs:Boolean) {
		switch (field._name) {
			case "mei":
				field.text = ( fullNPCs ? "Mei" : "M" );
				break;
			case "rose":
				field.text = ( fullNPCs ? "Rose" : "R" );
				break;
			case "alex":
				field.text = ( fullNPCs ? "Alex" : "A" );
				break;
			case "zuberi":
				field.text = ( fullNPCs ? "Zub" : "Z" );
				break;
		}	
		
	}
	
	public function InitializeStatusText(field:TextField) {
		var textFormat:TextFormat = new TextFormat("_StandardFont", textSize,0xFFFFFF, true);
        textFormat.align = "left"	
		
        field.setNewTextFormat(textFormat);
        //field.autoSize = "left";
		field.background = true;
		field.backgroundColor = 0x000000;
		//field.border = true;
	}
	
	private function SetFakeStatusText() {
		meiStatusText.text = "Doomed";
		roseStatusText.text = "Podded";
		alexStatusText.text = "OK";
		zuberiStatusText.text = "High";
	}
		
	public function SetGUIEdit(state:Boolean) {
		Debugger.DebugText("NPCSD:SetGUIEdit() called with argument: " + state, debugMode);
		ToggleBackground(state);
		EnableInteraction(state);
		if state {
			UpdateAll(0, 0, 0, 0);
			SetFakeStatusText();
		}
		else {
			UpdateAll(undefined, undefined, undefined, undefined);
		}
	}
	
	public function UpdateAll(meiStatus:Number, roseStatus:Number, alexStatus:Number, zuberiStatus:Number) {
		//Debugger.DebugText("UpdateAll()", debugMode);
		
		// reappear if we've decayed this
		//ResetAlpha();
		
		// update each text field with the appropriate status
		UpdateLetter(meiLetter, meiStatus);
		UpdateLetter(roseLetter, roseStatus);
		UpdateLetter(alexLetter, alexStatus);
		UpdateLetter(zuberiLetter, zuberiStatus);	
		UpdateStatusText(meiStatusText, meiStatus);
		UpdateStatusText(roseStatusText, roseStatus);
		UpdateStatusText(alexStatusText, alexStatus);
		UpdateStatusText(zuberiStatusText, zuberiStatus);	
		
		//// debugging
		//var currentTime:Date = new Date();
		//if (meiStatus == 3 ) { Debugger.PrintText("nSD.UpdateAll: Mei " + " " + currentTime.getSeconds() + "s or " + currentTime.getMilliseconds() + "ms"); };
		//if (roseStatus == 3 ) { Debugger.PrintText("nSD.UpdateAll: Rose " + " " + currentTime.getSeconds() + "s or " + currentTime.getMilliseconds() + "ms"); };
		//if (alexStatus == 3 ) { Debugger.PrintText("nSD.UpdateAll: Alex " + " " + currentTime.getSeconds() + "s or " + currentTime.getMilliseconds() + "ms"); };
		//if (zuberiStatus == 3 ) { Debugger.PrintText("nSD.UpdateAll: Zuberi " + " " + currentTime.getSeconds() + "s or " + currentTime.getMilliseconds() + "ms"); };
    }
	
	private function UpdateLetter(field:TextField, status:Number) {
		//Debugger.DebugText("UpdateLetter()", debugMode);
		
		// set text color according to status
		field.textColor = statusColors[status];		
	}
	
	private function UpdateStatusText(field:TextField, status:Number) {
		//Debugger.DebugText("UpdateLetter()", debugMode);
		
		// set text color according to status
		field.textColor = statusColors[status];
		
		// sanitize this so that we don't spit out "undefined" after a GUIEdit
		if ( status == undefined ) { status = 0 };
		field.text = statusText[status];
	}
	
	public function SetPos(pos:Point) {
		// sanitize inputs - this fixes a bug where someone changes screen resolution and suddenly the field is off the visible screen
		if ( pos.x > Stage.width || pos.x < 0 ) { pos.x = Stage.width / 2; }
		if ( pos.y > Stage.height || pos.y < 0 ) { pos.y = Stage.height / 2; }
		
		// set position
		clip._x = pos.x;
		clip._y = pos.y;
	}
	
	public function GetPos() {
		var pos:Point = new Point(clip._x, clip._y);
		Debugger.DebugText("GetPos: x: " + pos.x + "  y: " + pos.y, debugMode);
		return pos;
	}
		
	public function SetVisible(flag:Boolean, phase:Number, zuberiFlag:Boolean) {
		Debugger.DebugText("npcStatusDisplay.SetVisible(): flag: " + flag + ", phase: " + phase + ", zuberiFlag: " + zuberiFlag, debugMode);
		clip._visible = flag;
		if flag {
			SetVisibilityByPhase( phase, zuberiFlag );
		}
		else {
			HideAllStatus();
		}
	}
	
	public function SetVisibilityByPhase( phase:Number, zuberiFlag:Boolean ) {
		Debugger.DebugText("npcStatusDisplay.SetVisibilityByPhase(): phase: " + phase + ", zuberiFlag: " + zuberiFlag, debugMode);
		// if phase isn't specified default to 0
		if (arguments.length == 0) {
			phase = 0;
			Debugger.DebugText("npcStatusDisplay.SetVisibilityByPhase(): phase defaulted to 0", debugMode);
		}
		// if zuberi isn't specified default to true
		if (arguments.length == 1) {
			zuberiFlag = true;
			Debugger.DebugText("npcStatusDisplay.SetVisibilityByPhase(): zuberiFlag defaulted to true", debugMode);
		}
		
		// reset alpha on everything (in case we've killed this before and decayed the text at the end)
		//ResetAlpha();
		
		// if we haven't started yet, show everything
		if phase < 1 
		{
			ShowMeiStatus(true);
			ShowRoseStatus(true);
			ShowAlexStatus(true);
			ShowZuberiStatus(zuberiFlag);			
		}
		
		// phase 1: hide all, pods will appear automatically when needed
		else if phase < 2 
		{
			HideAllStatus();
		}
		// in phase 2 mei is used for counting birds and rose ise for counting downfalls
		else if phase == 2 
		{
			ShowMeiStatus(true);
			ShowRoseStatus(true);	
			meiLetter.text = ( showFullNPCNames ? "Bird" : "B" );
			roseLetter.text = ( showFullNPCNames ? "DF" : "D" );
			UpdateBirdNumber( 0 );
			UpdateDownfallNumber( 0 );
			meiLetter.textColor = statusColors[ 0 ];
			meiStatusText.textColor = statusColors[ 0 ];
			roseLetter.textColor = statusColors[ 0 ];
			roseStatusText.textColor = statusColors[ 0 ];
			
			// alex and zuberi are not used, hide
			ShowAlexStatus(false);
			ShowZuberiStatus(false);
		}
		// in phase 3, use default settings
		else if phase < 4 
		{
			//ShowPodStatus(false);
			ShowMeiStatus(true);
			ShowRoseStatus(true);
			ShowAlexStatus(true);
			ShowZuberiStatus(zuberiFlag);
			
			// reset text fields to phase 3 values
			SetLetterText(meiLetter, showFullNPCNames);
			SetLetterText(roseLetter, showFullNPCNames);
			meiStatusText.text = "";
			roseStatusText.text = "";
		}
		else if phase >= 4 
		{			
			// reset text fields to phase 0 values
			SetLetterText(meiLetter, showFullNPCNames);
			SetLetterText(roseLetter, showFullNPCNames);
			meiStatusText.text = "";
			roseStatusText.text = "";
		}
	}
	
	public function UpdateBirdNumber( num:Number ) { meiStatusText.text = String(num); }
	
	public function UpdateDownfallNumber( num:Number ) { roseStatusText.text = String(num); }
	
	public function ToggleBackground(flag:Boolean) {
		alexLetter.background = flag;
		roseLetter.background = flag;
		meiLetter.background = flag;
		zuberiLetter.background = flag;		
		alexStatusText.background = flag;
		meiStatusText.background = flag;
		roseStatusText.background = flag;
		zuberiStatusText.background = flag;	
	}

	public function EnableInteraction(state:Boolean) {
		clip.hitTestDisable = !state;
		alexLetter.hitTestDisable = !state;
		meiLetter.hitTestDisable = !state;
		roseLetter.hitTestDisable = !state;
		zuberiLetter.hitTestDisable = !state;
		alexStatusText.hitTestDisable = !state;
		meiStatusText.hitTestDisable = !state;
		roseStatusText.hitTestDisable = !state;
		zuberiStatusText.hitTestDisable = !state;
	}
	
	public function DecayDisplay(decayTime) {
		Debugger.DebugText("NPSCSD: DecayDisplay()", debugMode);
		Debugger.DebugText("NPSCSD: DecayDisplay(): meiLetter._alpha = " + meiLetter._alpha, debugMode);
		Tweener.addTween(meiLetter, {_alpha : 0, delay : 2, time : decayTime});
		Tweener.addTween(meiStatusText, {_alpha : 0, delay : 2, time : decayTime});
		Tweener.addTween(roseLetter, {_alpha : 0, delay : 2, time : decayTime});
		Tweener.addTween(roseStatusText, {_alpha : 0, delay : 2, time : decayTime});
		Tweener.addTween(alexLetter, {_alpha : 0, delay : 2, time : decayTime});
		Tweener.addTween(alexStatusText, {_alpha : 0, delay : 2, time : decayTime});
		Tweener.addTween(zuberiLetter, {_alpha : 0, delay : 2, time : decayTime});
		Tweener.addTween(zuberiStatusText, {_alpha : 0, delay : 2, time : decayTime});
	}
	
	public function ResetAlpha() {
		Debugger.DebugText("NPSCSD: ResetAlpha()", debugMode);
		Debugger.DebugText("NPSCSD: ResetAlpha(): meiLetter._alpha = " + meiLetter._alpha, debugMode);
		meiLetter._alpha = 100;
		meiStatusText._alpha = 100;
		roseLetter._alpha = 100;
		roseStatusText._alpha = 100;
		alexLetter._alpha = 100;
		alexStatusText._alpha = 100;
		zuberiLetter._alpha = 100;
		zuberiStatusText._alpha = 100;
		Debugger.DebugText("NPSCSD: ResetAlpha(): meiLetter._alpha = " + meiLetter._alpha, debugMode);
	}
		
	public function ShowMeiStatus(flag:Boolean) {
		meiLetter._visible = flag;
		meiStatusText._visible = flag;
	}
	
	public function ShowRoseStatus(flag:Boolean) {
		roseLetter._visible = flag;
		roseStatusText._visible = flag;
	}
	
	public function ShowAlexStatus(flag:Boolean) {
		alexLetter._visible = flag;
		alexStatusText._visible = flag;
	}
	
	public function ShowZuberiStatus(flag:Boolean) {
		zuberiLetter._visible = flag;
		zuberiStatusText._visible = flag;
	}
	
	public function HideAllStatus() {
		Debugger.DebugText("NPSCSD: HIdeAllStatus()", debugMode);
		ShowMeiStatus(false);
		ShowRoseStatus(false);
		ShowAlexStatus(false);
		ShowZuberiStatus(false);
	}
}