/**
 * ...
 * @author theck
 */
import caurina.transitions.Tweener;
import flash.geom.Point;
import com.theck.Utils.Debugger;
//import flash.geom.ColorTransform;
//import mx.utils.Delegate;

class gui.theck.npcStatusDisplay
{
	// toggle debug messages
	static var debugMode = false;
	
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
	
	public function npcStatusDisplay(target:MovieClip) 
	{
		clip = target.createEmptyMovieClip("npcStatusDisplay", target.getNextHighestDepth());
        clip._x = Stage.width /  2;
        clip._y = Stage.height / 2;
		
		meiLetter = clip.createTextField("mei", clip.getNextHighestDepth(), 0, 0, boxSize, boxSize);
		roseLetter = clip.createTextField("rose", clip.getNextHighestDepth(), 0, boxSize, boxSize, boxSize);
        alexLetter = clip.createTextField("alex", clip.getNextHighestDepth(), 0, 2*boxSize, boxSize, boxSize);
		zuberiLetter = clip.createTextField("zuberi", clip.getNextHighestDepth(), 0, 3*boxSize, boxSize, boxSize);
		
		InitializeLetter(meiLetter);
		InitializeLetter(roseLetter);
		InitializeLetter(alexLetter);
		InitializeLetter(zuberiLetter);
		
		meiStatusText = clip.createTextField("meiStatus", clip.getNextHighestDepth(), boxSize, 0, statusTextWidth, boxSize);
		roseStatusText = clip.createTextField("roseStatus", clip.getNextHighestDepth(), boxSize, boxSize, statusTextWidth, boxSize);
		alexStatusText = clip.createTextField("alexStatus", clip.getNextHighestDepth(), boxSize, 2*boxSize, statusTextWidth, boxSize);
		zuberiStatusText = clip.createTextField("zuberiStatus", clip.getNextHighestDepth(), boxSize, 3*boxSize, statusTextWidth, boxSize);
		
		InitializeStatusText(meiStatusText);
		InitializeStatusText(roseStatusText);
		InitializeStatusText(alexStatusText);
		InitializeStatusText(zuberiStatusText);
	}
	
	
	
	public function InitializeLetter(field:TextField) {	
		
        var textFormat:TextFormat = new TextFormat("_StandardFont", textSize,0xFFFFFF, true);
        textFormat.align = "center"	
		
        field.setNewTextFormat(textFormat);
        //field.autoSize = "center";
		field.background = true;
		field.backgroundColor = 0x000000;
		//field.border = true;
		
		switch (field._name) {
			case "mei":
				field.text = "M";
				break;
			case "rose":
				field.text = "R";
				break;
			case "alex":
				field.text = "A";
				break;
			case "zuberi":
				field.text = "Z";
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
		
		//SetFakeStatusText();
	}
	
	private function SetFakeStatusText() {
		meiStatusText.text = "Doomed";
		roseStatusText.text = "Podded";
		alexStatusText.text = "OK";
		zuberiStatusText.text = "High";
	}
	
	public function EnableGUIEdit(state:Boolean)
	{
		// these first two should go in ALIA for saving settings
		//clip.onPress = Delegate.create(this, npcStartDrag);
		//clip.onRelease = Delegate.create(this, npcStopDrag);
		
		//UpdateText("100%");
		setVisible(true);
		toggleBackground(true);
		enableInteraction(true);
	}
	
	public function setGUIEdit(state:Boolean) {
		toggleBackground(state);
		enableInteraction(state);
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
		Tweener.removeTweens(clip);
		
		// update each text field with the appropriate status
		UpdateLetter(meiLetter, meiStatus);
		UpdateLetter(roseLetter, roseStatus);
		UpdateLetter(alexLetter, alexStatus);
		UpdateLetter(zuberiLetter, zuberiStatus);	
		UpdateStatusText(meiStatusText, meiStatus);
		UpdateStatusText(roseStatusText, roseStatus);
		UpdateStatusText(alexStatusText, alexStatus);
		UpdateStatusText(zuberiStatusText, zuberiStatus);	
    }
	
	private function UpdateLetter(field:TextField, status:Number) {
		//Debugger.DebugText("UpdateLetter()", debugMode);
		
		// sanitize input (sometimes npcs - alex in particular - aren't yet detected when this is called)
		//if ( status == undefined ) { status = 0 };
		
		// set text color according to status
		field.textColor = statusColors[status];		
	}
	
	private function UpdateStatusText(field:TextField, status:Number) {
		//Debugger.DebugText("UpdateLetter()", debugMode);
		
		// sanitize input (sometimes npcs - alex in particular - aren't yet detected when this is called)
		//if ( status == undefined ) { status = 0 };
		
		// set text color according to status
		field.textColor = statusColors[status];
		
		// sanitize this so that we don't spit out "undefined" after a GUIEdit
		if ( status == undefined ) { status = 0 };
		field.text = statusText[status];
	}
	
	public function setPos(pos:Point) {
		// sanitize inputs - this fixes a bug where someone changes screen resolution and suddenly the field is off the visible screen
		if pos.x > Stage.width { pos.x = Stage.width / 2; }
		if pos.y > Stage.height { pos.y = Stage.height / 2; }
		
		// set position
		clip._x = pos.x;
		clip._y = pos.y;
	}
	
	public function getPos() {
		var pos:Point = new Point(clip._x, clip._y);
		Debugger.DebugText("getPos: x: " + pos.x + "  y: " + pos.y, debugMode);
		return pos;
	}
		
	public function setVisible(flag:Boolean, zuberiFlag:Boolean) {
		clip._visible = flag;	
		if flag {
			if (arguments.length == 1) { 
				zuberiFlag = flag; 
				Debugger.DebugText("npcStatusDisplay.setVisible(): zuberiFlag defaulted to flag (" + flag + ")", debugMode);
			}
			showZuberi( zuberiFlag );
		}
	}
	
	public function toggleBackground(flag:Boolean) {
		alexLetter.background = flag;
		roseLetter.background = flag;
		meiLetter.background = flag;
		zuberiLetter.background = flag;		
		alexStatusText.background = flag;
		meiStatusText.background = flag;
		roseStatusText.background = flag;
		zuberiStatusText.background = flag;		
	}
	
	//public function setTextColor(color:Number) {
		//clip.textColor = color;
	//}
	
	public function enableInteraction(state:Boolean) {
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
	
	public function decayDisplay(decayTime) {
		Debugger.DebugText("decayText called", debugMode);
		Tweener.addTween(clip, {_alpha : 0, delay : 2, time : decayTime});	
	}
	
	public function showZuberi(flag:Boolean) {
		zuberiLetter._visible = flag;
		zuberiStatusText._visible = flag;
	}
}