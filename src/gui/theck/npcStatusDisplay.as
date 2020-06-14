/**
 * ...
 * @author theck
 */
import caurina.transitions.Tweener;
import flash.geom.Point;
import com.theck.Utils.Debugger;
import flash.geom.ColorTransform;
import mx.utils.Delegate;

class gui.theck.npcStatusDisplay
{
	// toggle debug messages
	static var debugMode = false;
	// status colors: White (running), Green (buffing), Gray? (knocked down), Yellow (pod inc), Red (podded)
	static var statusColors:Array = new Array(0xFFFFFF, 0x008000, 0xC0C0C0, 0xFFC300 , 0xFF0000);
		
    public var clip:MovieClip;
    private var alexText:TextField;
    private var roseText:TextField;
    private var meiText:TextField;
    private var zuberiText:TextField;
	
	static var textSize:Number = 30;
	static var boxSize:Number = textSize*1.35;
	
	public function npcStatusDisplay(target:MovieClip) 
	{
		clip = target.createEmptyMovieClip("npcStatusDisplay", target.getNextHighestDepth());
        clip._x = Stage.width /  2;
        clip._y = Stage.height / 2;
		
		meiText = clip.createTextField("mei", clip.getNextHighestDepth(), 0, 0, boxSize, boxSize);
		roseText = clip.createTextField("rose", clip.getNextHighestDepth(), 0, boxSize, boxSize, boxSize);
        alexText = clip.createTextField("alex", clip.getNextHighestDepth(), 0, 2*boxSize, boxSize, boxSize);
		zuberiText = clip.createTextField("zuberi", clip.getNextHighestDepth(), 0, 3*boxSize, boxSize, boxSize);
		
		InitializeTextField(meiText);
		InitializeTextField(roseText);
		InitializeTextField(alexText);
		InitializeTextField(zuberiText);
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
	}
	
	public function UpdateAll(meiStatus:Number, roseStatus:Number, alexStatus:Number, zuberiStatus:Number) {
		//Debugger.DebugText("UpdateAll()", debugMode);
		
		// reappear if we've decayed this
		Tweener.removeTweens(clip);
		
		// update each text field with the appropriate status
		UpdateField(meiText, meiStatus);
		UpdateField(roseText, roseStatus);
		UpdateField(alexText, alexStatus);
		UpdateField(zuberiText, zuberiStatus);		
    }
	
	private function UpdateField(field:TextField, status:Number) {
		//Debugger.DebugText("UpdateField()", debugMode);
		
		//stopBlinkField(field);
		field.textColor = statusColors[status];
		//if (status > 3) {blinkField( field) };
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
		alexText.background = flag;
		roseText.background = flag;
		meiText.background = flag;
		zuberiText.background = flag;		
	}
	
	public function setTextColor(color:Number) {
		clip.textColor = color;
	}
	public function enableInteraction(state:Boolean) {
		clip.hitTestDisable = !state;
		alexText.hitTestDisable = !state;
		meiText.hitTestDisable = !state;
		roseText.hitTestDisable = !state;
		zuberiText.hitTestDisable = !state;
	}
	
	public function decayDisplay(decayTime) {
		Debugger.DebugText("decayText called", debugMode);
		Tweener.addTween(clip, {_alpha : 0, delay : 2, time : decayTime});	
        //setTimeout(Delegate.create(this, stopBlink), decayTime*1000 + 500);
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