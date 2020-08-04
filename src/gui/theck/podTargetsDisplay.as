/**
 * ...
 * @author theck
 */

import flash.geom.Point;
import com.theck.Utils.Debugger;

class gui.theck.podTargetsDisplay
{
	// toggle debug messages
	static var debugMode:Boolean = false;
	
	static var statusColors:Array = new Array(0xFFFFFF, 0x008000, 0xA4A4A4, 0xFFC300 , 0xFF0000);
	
    public var clip:MovieClip;
    private var podHeader:TextField;
    public var playerList:Array;
	
	
	
	static var textSize:Number = 20;
	static var boxHeight:Number = textSize * 1.35;
	static var boxWidth:Number = textSize * 12;
	
	
	public function podTargetsDisplay(target:MovieClip) 
	{
		DebugText("pTD: constructor");
		clip = target.createEmptyMovieClip("podStatusDisplay", target.getNextHighestDepth());
        clip._x = Stage.width /  2;
        clip._y = Stage.height / 2;
		//clip.backgroundColor = 0x000000;
		
		podHeader = clip.createTextField("podHeader", clip.getNextHighestDepth(), 0, 0, boxWidth, boxHeight);
		
		playerList = new Array();
		
		for ( var i:Number = 0; i < 10; i ++ ) {
			
			playerList[i] = clip.createTextField("playerListEntry" + i, clip.getNextHighestDepth(), 0, boxHeight*(1+i), boxWidth, boxHeight);
			DebugText("pTD: playerList has " + playerList.length + " entries" )
		}
		
		InitializeAllTextFields();		
		SetFieldText(podHeader, "Pod Targets");
	}
	
	public function	InitializeAllTextFields() {
		InitializeTextField(podHeader);
		
		InitializeTextField(playerList[0]);
		for (  var i in playerList ) {
			InitializeTextField(playerList[i]);
		}
	}
	
	public function InitializeTextField(field:TextField) {	
		
        var textFormat:TextFormat = new TextFormat("_StandardFont", textSize,0xFFFFFF, true);
        textFormat.align = "center"	
		textFormat.underline = field._name == "podHeader" ? true : false;
		
        field.setNewTextFormat(textFormat);
        //field.autoSize = "center";
		field.background = true;
		field.backgroundColor = 0x000000;
		//field.border = true;
		
		SetFieldText(field, "");	
		DebugText("pTD: Initialized " + field._name);
	}
	
	public function SetFieldText(field:TextField, str:String) 
	{
		field.text = str;
	}
	public function SetFieldColor(field:TextField, status:Number)
	{
		field.textColor = statusColors[status];
	}
	
	
	private function SetFakeStatusText() {
		SetFieldText(podHeader, "Pod Header");
		for ( var i in playerList) {
			SetFieldText(playerList[i], "Podded Player " + i);
		}
		
		SetFieldColor(playerList[2], 4);
		SetFieldColor(playerList[5], 3);
	}
	
	public function SetGUIEdit(state:Boolean) {
		DebugText("pTD:SetGUIEdit() called with argument: " + state);
		ToggleBackground(state);
		SetVisible(state);
		EnableInteraction(state);
		if state {
			SetFakeStatusText();
		}
		else {
			SetFieldText(podHeader, "Pod Targets");
			ClearPlayerTextFields();
		}
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
		DebugText("GetPos: x: " + pos.x + "  y: " + pos.y);
		return pos;
	}
		
	public function SetVisible(flag:Boolean) {
		DebugText("npcStatusDisplay.SetVisible(): flag: " + flag);
		clip._visible = flag;
		podHeader._visible = flag;
		for ( var i:Number = 0; i < playerList.length; i++ ) {
			playerList[i]._visible = flag;
		}
	}
	
	public function ToggleBackground(flag:Boolean) {
		clip.background = flag;
		podHeader.background = flag;
		
		for ( var i:Number = 0; i < playerList.length; i++ ) {
			playerList[i].background = flag;
		}
	}

	public function EnableInteraction(state:Boolean) {
		clip.hitTestDisable = !state;
	}
	
	public function ClearPlayerTextFields() 
	{
		for ( var i in playerList ) {
			SetFieldText(playerList[i], "");
		}
	}
	
	
	
	static function DebugText(text) {
		if (debugMode) Debugger.PrintText(text);
	}
}