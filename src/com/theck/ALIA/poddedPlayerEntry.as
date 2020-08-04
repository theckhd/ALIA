import com.GameInterface.Game.Character;
/**
 * ...
 * @author theck
 */
class com.theck.ALIA.poddedPlayerEntry
{
	public var char:Character;
	public var status:Number;
	
	public function poddedPlayerEntry(character:Character, statusNumber:Number) 
	{
		char = character;
		status = statusNumber;
	}
	
	public function GetChar():Character 
	{
		return char;
	}
	
	public function GetName():String 
	{
		return char.GetName();
	}
	
	public function GetStatus():Number
	{
		return status;
	}
	
}