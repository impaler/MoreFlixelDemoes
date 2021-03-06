package states;
import addons.nape.FlxPhysSprite;
import addons.nape.FlxPhysState;
import com.eclecticdesignstudio.motion.Actuate;
import com.eclecticdesignstudio.motion.easing.Quad;
import nape.callbacks.CbEvent;
import nape.callbacks.CbType;
import nape.callbacks.InteractionCallback;
import nape.callbacks.InteractionListener;
import nape.callbacks.InteractionType;
import nape.geom.Vec2;
import nape.phys.Material;
import nme.Assets;
import nme.display.BitmapData;
import nme.display.Sprite;
import org.flixel.FlxG;
import org.flixel.FlxPoint;
import org.flixel.FlxSprite;
import org.flixel.FlxState;
import org.flixel.FlxU;

/**
 * @author TiagoLr ( ~~~ProG4mr~~~ )
 */

class Explosions extends FlxPhysState
{

	private var shooter:Shooter;
	public var buildingSprites:Array<FlxPhysSprite>;
	
	override public function create():Void 
	{	
		super.create();
		FlxG.mouse.show();
		
		// Sets gravity.
		FlxPhysState.space.gravity.setxy(0, 500);

		//createWalls( -2000, 0, 1640, FlxG.height);
		createWalls();
		createBuildings();
		//shooter = new Shooter();
		//add(shooter);
		
		FlxPhysState.space.listeners.add(new InteractionListener(CbEvent.BEGIN, 
													 InteractionType.COLLISION, 
													 Shooter.CB_BULLET,
													 CbType.ANY_BODY,
													 onBulletColides));
	}
	
	
	public function onBulletColides(clbk:InteractionCallback) 
	{
		if (shooter.getFirstAlive() != null) 
		{
			shooter.getFirstAlive().kill();
		}
	}
	
	private function createBuildings() 
	{
		buildingSprites = new Array<FlxPhysSprite>();
		createBuilding(Assets.getBitmapData("assets/building1.png"), 40, 380);
	}
	
	private function createBuilding(bitmapData:BitmapData, x:Int, y:Int) 
	{
		var spr:FlxPhysSprite;
		for (i in 0...bitmapData.width)
		{
			for (j in 0...bitmapData.height) 
			{
				var color = bitmapData.getPixel32(i, j);
				trace("alpha " + (color >>> 24));
				if ((color >>> 24) > 0) 
				{
					spr = new FlxPhysSprite(x + i * 10, y + j * 10);
					spr.makeGraphic(10, 10, color);
					spr.createRectangularBody();
					spr.setBodyMaterial(0.3);
					add(spr);
					buildingSprites.push(spr);
				}
			}
		}
	}
	
	override public function update():Void 
	{	
		super.update();
		
		if (FlxG.keys.justPressed("G"))
			disablePhysDebug(); // PhysState method to remove the debug graphics.
		if (FlxG.keys.justPressed("R"))
			FlxG.resetState();
		if (FlxG.mouse.justPressed()) 
		{
			
			Actuate.timer(0.3).onComplete(startBulletTime);
			
			createExplosion();
		}
	}
	
	private function startBulletTime() 
	{
		FlxG.timeScale = 0.2;
		Actuate.tween(FlxG, 1, { timeScale:1.0 } ).ease(Quad.easeIn).delay(1);
	}
	
	private function createExplosion() 
	{
		var explosion:Explosion = new Explosion(FlxG.mouse.x, FlxG.mouse.y, "assets/ExplosionWave.png", this); 
		add(explosion);
		
		var explosionFire:FlxSprite = new FlxSprite(FlxG.mouse.x, FlxG.mouse.y);
		explosionFire.loadGraphic("assets/ExplosionFire.png", true, false, 83, 83);
		var frames:Array<Int> = new Array<Int>();
		for (i in 0...43) frames.push(i);
		explosionFire.addAnimation("normal", frames, 30, true);
		add(explosionFire);
		explosionFire.play("normal");
		
		explosion.explosionFire = explosionFire; // For deleting purposes.
	}
	
	public function removeExplosion(explosion:Explosion)
	{
		remove(explosion);
		remove(explosion.explosionFire);
		explosion.explosionFire.destroy();
		explosion.destroy();
	}
	
}

import org.flixel.FlxSprite;
class Explosion extends FlxSprite
{
	static public inline var EXP_FORCE:Int = 1500;
	var parent:Explosions;
	var buildingSprites:Array<FlxPhysSprite>;
	public var explosionFire:FlxSprite;
	var trueX:Float;
	var trueY:Float;
	
	public function new(X:Float = 0, Y:Float = 0, SimpleGraphic:Dynamic = null, Parent:Explosions)
	{
		super(X, Y, SimpleGraphic);
		trueX = x;
		trueY = y;
		this.x -= width / 2;
		this.y -= height / 2;
		this.scale.x = 0.01;
		this.scale.y = 0.01;
		parent = Parent;
		buildingSprites = parent.buildingSprites.copy();
	}
	
	override public function update():Void 
	{
		super.update();
		this.scale.x *= 1 + FlxG.elapsed * 10;
		this.scale.y *= 1 + FlxG.elapsed * 10;
		
		if (this.width * scale.x >= 300) 
		{
			alpha -= 2 * FlxG.elapsed;
		}
		
		if (alpha <= 0)
		{
			parent.removeExplosion(this);
		}
		
		FlxG.log(" x " + x);
		
		for (i in buildingSprites)
		{
			var distance = FlxU.getDistance(new FlxPoint(i.x , i.y), new FlxPoint(trueX, trueY));
			if (distance < this.width * scale.x / 2) 
			{
				var impulse = EXP_FORCE / (distance * distance);
				i.body.applyImpulse(new Vec2((i.x - trueX) * impulse, (i.y - trueY) * impulse));
				buildingSprites.remove(i);
				//FlxG.log(" x " + (i.x - x) * impulse + " y " + (i.y - y) * impulse);
			}
		}
	}
}