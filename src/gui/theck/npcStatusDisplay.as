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
	// status colors: White (running), Green (buffing), Gray (knocked down), Yellow (pod inc), Red (podded)
	static var statusColors:Array = new Array(0xFFFFFF, 0x008000, 0xA4A4A4, 0xFFC300 , 0xFF0000);
		
    public var clip:MovieClip;
    private var alexLetter:TextField;
    private var roseLetter:TextField;
    private var meiLetter:TextField;
    private var zuberiLetter:TextField;
	
	static var textSize:Number = 30;
	static var boxSize:Number = textSize*1.35;
	
	public function npcStatusDisplay(target:MovieClip) 
	{
		clip = target.createEmptyMovieClip("npcStatusDisplay", target.getNextHighestDepth());
        clip._x = Stage.width /  2;
        clip._y = Stage.height / 2;
		
		meiLetter = clip.createTextField("mei", clip.getNextHighestDepth(), 0, 0, boxSize, boxSize);
		roseLetter = clip.createTextField("rose", clip.getNextHighestDepth(), 0, boxSize, boxSize, boxSize);
        alexLetter = clip.createTextField("alex", clip.getNextHighestDepth(), 0, 2*boxSize, boxSize, boxSize);
		zuberiLetter = clip.createTextField("zuberi", clip.getNextHighestDepth(), 0, 3*boxSize, boxSize, boxSize);
		
		InitializeTextField(meiLetter);
		InitializeTextField(roseLetter);
		InitializeTextField(alexLetter);
		InitializeTextField(zuberiLetter);
	}
	
	
	
	public function InitializeTextField(field:TextField) {	
		
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
				//field._y += boxSize;
				break;
			case "alex":
				field.text = "A";
				//field._y += 2*(boxSize);
				break;
			case "zuberi":
				field.text = "Z";
				//field._y += 3*(boxSize);
				break;			
		}		
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
		UpdateField(meiLetter, meiStatus);
		UpdateField(roseLetter, roseStatus);
		UpdateField(alexLetter, alexStatus);
		UpdateField(zuberiLetter, zuberiStatus);		
    }
	
	private function UpdateField(field:TextField, status:Number) {
		//Debugger.DebugText("UpdateField()", debugMode);
		
		// sanitize input (sometimes npcs - alex in particular - aren't yet detected when this is called)
		//if ( status == undefined ) { status = 0 };
		
		// set text color according to status
		field.textColor = statusColors[status];		
	}
	
	public function setPos(pos:Point) {
		clip._x = pos.x;
		clip._y = pos.y;
	}
	
	public function getPos() {
		var pos:Point = new Point(clip._x, clip._y);
		Debugger.DebugText("getPos: x: " + pos.x + "  y: " + pos.y, debugMode);
		return pos;
	}
		
	public function setVisible(flag:Boolean) {
		clip._visible = flag;	
	}
	
	public function toggleBackground(flag:Boolean) {
		alexLetter.background = flag;
		roseLetter.background = flag;
		meiLetter.background = flag;
		zuberiLetter.background = flag;		
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
	}
	
	public function decayDisplay(decayTime) {
		Debugger.DebugText("decayText called", debugMode);
		Tweener.addTween(clip, {_alpha : 0, delay : 2, time : decayTime});	
	}
	
    //private function blinkField(field:TextField) {
		//Debugger.DebugText("blinkText called", debugMode);
		//
		//// clear any existing blinking effects first
        //clearInterval(field.blinkInterval);
        //field.transform.colorTransform = new ColorTransform();
		//
		//// Set up the color transform
        //var colorTransform:ColorTransform = field.transform.colorTransform;
        //colorTransform.rgb = 0xFFFFFF;
        //field.transform.colorTransform = colorTransform;
        //var increment = 20;		
        //field.blinkInterval = setInterval(Delegate.create(field,function(){
            //if (colorTransform.greenOffset >= 255) increment = -20;
            //if (colorTransform.greenOffset <= 0) increment = 20;
            //colorTransform.greenOffset += increment;
            //colorTransform.blueOffset += increment;
            //field.transform.colorTransform = colorTransform;
        //}), 50);
    //}
	
    //public function stopBlinkField(field:TextField) {
		//Debugger.DebugText("stopBlink called", debugMode);
        //clearInterval(field.blinkInterval);
        //field.transform.colorTransform = new ColorTransform();
    //}
	//
}