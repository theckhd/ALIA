/**
 * ...
 * @author theck
 * 
 * Much of this adapted from BooBars
 */

 
import com.theck.Utils.Debugger;
import flash.geom.Matrix;
//import caurina.transitions.Tweener;
import com.Utils.Text;

class gui.theck.SimpleBar
{
	private var debugMode:Boolean = false;
	
	private var m_frame:MovieClip;
	private var m_bar:MovieClip;
	private var m_scaleFrame:MovieClip;
	private var m_scaleWidth:Number;
	private var m_leftText:TextField;
	private var m_rightText:TextField;	
	private var m_parent:MovieClip;
	public var barHeight:Number;
	
	
	private static var m_radius:Number = 4;
	
	public function SimpleBar(name:String, parent:MovieClip, x:Number, y:Number, width:Number, inFontSize:Number, colors:Array) 
	{
		var fontSize:Number = inFontSize;
		if (fontSize == null || fontSize < 6) {
			fontSize = 14;
			Debugger.DebugText("Fontsize defaulted to " + fontSize, debugMode);
		}
		if ( colors == null ) {
			colors = [0x2E2E2E, 0x585858];  // Grey
		}
		
		m_parent = parent;
		m_frame = m_parent.createEmptyMovieClip(name + "CastBarFrame", m_parent.getNextHighestDepth());
		m_scaleFrame = m_frame.createEmptyMovieClip(name + "ScaleFrame", m_frame.getNextHighestDepth());
		
		m_frame._x = x;
		m_frame._y = y;
		
		var textFormat:TextFormat = new TextFormat("_StandardFont", fontSize, 0xFFFFFF, true);
        textFormat.align = "center"
		
		var extents:Object = Text.GetTextExtent("TEST", textFormat, m_frame);
		var height:Number = extents.height + extents.height * 0.05 + 4;
		barHeight = Math.ceil(height);
		
		Debugger.DebugText("SimpleBar: height = " + height, debugMode);
		
		m_bar = CreateBar( name + "Bar", width, height, colors);
		m_leftText = m_frame.createTextField(name + "_leftText", m_frame.getNextHighestDepth(), 0, m_frame._height / 2 - extents.height / 2, 40, extents.height);
		m_rightText = m_frame.createTextField(name + "_rightText", m_frame.getNextHighestDepth(), m_frame._width - 40, m_frame._height / 2 - extents.height / 2, 40, extents.height);
		m_leftText.setNewTextFormat(textFormat);
		m_rightText.setNewTextFormat(textFormat);
		m_leftText.background = false;
		m_rightText.background = false;
		
		//do this after CreateBar
		m_scaleWidth = m_scaleFrame._width;
		
		DrawFilledRoundedRectangle(m_frame, 0x000000, 2, 0x000000, 50, 0, 0, width, height);
		
	}
	
	
	public function SetVisible(visible:Boolean):Void { m_frame._visible = visible; }
	
	public function GetVisible():Boolean { return m_frame._visible;	}
	
	
	public function GetCoords():Object
	{
		var pt:Object = new Object();
		pt.x = m_frame._x;
		pt.y = m_frame._y;
		return pt;
	}
	
	
/*	private function onDragPress():Void
	{
		m_frame.startDrag();
		m_dragging = true;
	}
	
	private function onDragRelease():Void
	{
		if (m_dragging == true)
		{
			m_frame.stopDrag();
			m_dragging = false;
		}
	}*/
	
	public function Unload():Void
	{
		m_frame.removeMovieClip();
		m_frame = null;
	}
	
	public function Update(pct:Number, leftString:String, rightString:String):Void
	{
		Debugger.DebugText("SimpleBar: pct is " + pct, debugMode);
		if ( pct == null ) {
			Debugger.DebugText("SimpleBar: pct is " + pct, debugMode);
			SetVisible(false);
			m_scaleFrame._width = m_scaleWidth;
		}		
		else {
			SetVisible(true);
			Debugger.DebugText("SimpleBar: leftString is " + leftString, debugMode);
			Debugger.DebugText("SimpleBar: rightString is " + rightString, debugMode);
			// update strings if provided
			if ( leftString != null ) {
				m_leftText.text = leftString;
			}
			if ( rightString != null ) {
				m_rightText.text = rightString;
			}
			
			if ( pct > 1 ) { pct = 1 };
			
			// update percentage bar
			//Debugger.DebugText("SimpleBar: pct is " + pct, debugMode);
			//Debugger.DebugText("SimpleBar: m_scaleFrame._width is " + m_scaleFrame._width, debugMode);
			//Debugger.DebugText("SimpleBar: m_scaleWidth is " + m_scaleWidth, debugMode);
			m_scaleFrame._width = ( m_scaleWidth * pct );
		}
	}
	
	// Functions shamelessly stolen from BooBars and adapted for my nefarious purposes
	
	private function CreateBar(name:String, width:Number, height:Number, colours:Array):MovieClip
	{
		var bar:MovieClip = m_scaleFrame.createEmptyMovieClip(name, m_scaleFrame.getNextHighestDepth());
		DrawGradientFilledRoundedRectangle(bar, 0x000000, 0, colours, 0, 0, width, height);
		return bar;
	}
	
	private function DrawGradientFilledRoundedRectangle(mc:MovieClip, lineColour:Number, lineWidth:Number, fillColours:Array, x:Number, y:Number, width:Number, height:Number):Void
	{
		var alphas:Array = [100, 100];
		var ratios:Array = [0, 245];
		var matrix:Matrix = new Matrix();
		var colors:Array = [0x2E2E2E, 0x1C1C1C];
		
		matrix.createGradientBox(width, height, 90 / 180 * Math.PI, 0, 0);
		mc.lineStyle(lineWidth, lineColour, 100, true, "none", "square", "round");
		if (ColourArrayValid(fillColours) != true)
		{
			mc.beginGradientFill("linear", colors, alphas, ratios, matrix);
		}
		else
		{
			mc.beginGradientFill("linear", fillColours, alphas, ratios, matrix);
		}

		mc.moveTo(x + m_radius, y);
		mc.lineTo(x + (width-m_radius), y);
		mc.curveTo(x + width, y, x + width, y + m_radius);
		mc.lineTo(x + width, y + (height - m_radius));
		mc.curveTo(x + width, y + height, x + (width - m_radius), y + height);
		mc.lineTo(x + m_radius, y + height);
		mc.curveTo(x, y + height, x, y + (height - m_radius));
		mc.lineTo(x, y + m_radius);
		mc.curveTo(x, y, x + m_radius, y);
		mc.endFill();
	}
	
	private function DrawFilledRoundedRectangle(mc:MovieClip, lineColour:Number, lineWidth:Number, fillColour:Number, fillAlpha:Number, x:Number, y:Number, width:Number, height:Number):Void
	{
		mc.lineStyle(lineWidth, lineColour, 100, true, "none", "square", "round");
		mc.beginFill(fillColour, fillAlpha);
		mc.moveTo(x + m_radius, y);
		mc.lineTo(x + (width-m_radius), y);
		mc.curveTo(x + width, y, x + width, y + m_radius);
		mc.lineTo(x + width, y + (height - m_radius));
		mc.curveTo(x + width, y + height, x + (width - m_radius), y + height);
		mc.lineTo(x + m_radius, y + height);
		mc.curveTo(x, y + height, x, y + (height - m_radius));
		mc.lineTo(x, y + m_radius);
		mc.curveTo(x, y, x + m_radius, y);
		mc.endFill();
	}
	
	private function ColourArrayValid(inColours:Array):Boolean
	{
		if (inColours == null)
		{
			Debugger.DebugText("colours null", debugMode);
			return false;
		}
		
		if ((inColours instanceof Array) != true)
		{
			Debugger.DebugText("colours not array", debugMode);
			return false;
		}
		
		if (inColours.length != 2)
		{
			Debugger.DebugText("colours not 2 long", debugMode);
			return false;
		}
		
		if (inColours[0] == null || inColours[1] == null)
		{
			Debugger.DebugText("colours contents null", debugMode);
			return false;
		}
		
		if (typeof(inColours[0]) != "number" || typeof(inColours[1]) != "number")
		{
			Debugger.DebugText("colours not number " + typeof(inColours[0]), debugMode);
			return false;
		}
		
		if (inColours[0] < 0 || inColours[0] > 0xFFFFFF)
		{
			Debugger.DebugText("colour 0 invalid number " + inColours[0], debugMode);
			return false;
		}
		
		if (inColours[1] < 0 || inColours[1] > 0xFFFFFF)
		{
			Debugger.DebugText("colour 1 invalid number " + inColours[1], debugMode);
			return false;
		}
		
		return true;
	}
	
}