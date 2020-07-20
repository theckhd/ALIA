/**
 * ...
 * @author theck
 */

 
import com.theck.Utils.Debugger;


class gui.theck.SimpleBar
{
	private var debugMode:Boolean = false;
	
	private var m_frame:MovieClip;
	private var m_parent:MovieClip;
	private var m_leftText:TextField;
	private var m_rightText:TextField;
	
	public function SimpleBar(name:String, parent:MovieClip, x:Number, y:Number, width:Number, inFontSize:Number) 
	{
		var fontSize:Number = inFontSize;
		if (fontSize == null || fontSize < 6)
		{
			fontSize = 14;
			Debugger.DebugText("Fontsize defaulted to " + fontSize, debugMode);
		}
		
		m_parent = parent;
		
		var textFormat:TextFormat = new TextFormat("_StandardFont", fontSize, 0xFFFFFF, true);
        textFormat.align = "center"
		m_leftText = clip.createTextField("m_leftText", clip.getNextHighestDepth(), 0, 0, 0, 0);
		m_rightText = clip.createTextField("m_rightText", clip.getNextHighestDepth(), 0, 0, 0, 0);
		
	}
	
	
	public function SetVisible(visible:Boolean):Void
	{
		m_frame._visible = visible;
	}
	
	public function GetVisible():Boolean
	{
		return m_frame._visible;
	}
	
	
		public function GetCoords():Object
	{
		var pt:Object = new Object();
		pt.x = m_frame._x;
		pt.y = m_frame._y;	
		return pt;
	}
	
	
		private function onDragPress():Void
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
	}
	
	public function Unload():Void
	{
		m_frame.removeMovieClip();
		m_frame = null;
	}
}