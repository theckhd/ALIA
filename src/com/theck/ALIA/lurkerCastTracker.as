import gui.theck.lurkerBarDsiplay;
/**
 * ...
 * @author theck
 */
class com.theck.ALIA.lurkerCastTracker
{
	
	private var debugMode:Boolean = false;
	
	private var encounterPhase:Number;
	
	static var fromBeneathCooldown:Number = 33; //45s for first one
	static var pureFilthCooldown:Number = 15; // wild guess
	static var shadowFromBeyondCooldown:Number = 60; // no idea
	static var POLLING_INTERVAL:Number = 250;
	
	private var barUpdateInterval:Number;
	
	public var barDisplay:lurkerBarDsiplay;
	
	public function lurkerCastTracker(display:lurkerBarDsiplay) 
	{
		barDisplay = display;
	}
	
}