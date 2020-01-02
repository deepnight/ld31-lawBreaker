package en;

import mt.MLib;
import mt.deepnight.slb.*;

class Place extends Entity {
	public static var ALL : Array<Place> = [];

	public var charge		: Float;

	var icon				: BSprite;
	var base				: BSprite;
	var shine				: Float;

	var icx					: Float;
	var icy					: Float;

	private function new(x,y) {
		super();

		ALL.push(this);
		speed = 1;
		setPosCase(x,y);
		charge = 0;
		physics = false;
		repels = false;
		shine = 0;

		var city = Game.ME.city;
		icx = cx+0.5;
		icy = cy+0.5;
		var d = 0.8;
		if( city.hasCollision(cx-1,cy) ) icx-=d;
		else if( city.hasCollision(cx+1,cy) ) icx+=d;
		else if( city.hasCollision(cx,cy-1) ) icy-=d;
		else if( city.hasCollision(cx,cy+1) ) icy+=d;

		base = Assets.tiles.get("itemBase", 0);
		Game.ME.buffer.dm.add(base, Const.DP_ITEM);
		base.setCenter(0.5,0.5);

		icon = Assets.tiles.get("itemMoney");
		Game.ME.buffer.dm.add(icon, Const.DP_ITEM);
		icon.setCenter(0.5,0.5);

		spr.set("itemPickZone");
		spr.setCenter(0.5, 0.5);
		spr.blendMode = ADD;

		updateCoords();
	}

	override function unregister() {
		super.unregister();

		ALL.remove(this);

		icon.dispose();
		icon = null;

		base.dispose();
		base = null;
	}

	override function updateCoords() {
		super.updateCoords();
		if( base!=null ) {
			base.x = Std.int( icx * Const.GRID );
			base.y = Std.int( icy * Const.GRID );
			icon.x = base.x;
			icon.y = base.y;
		}
	}

	function onPick() {
		charge = 0;
		destroy();
	}


	override function update() {
		super.update();

		var h = Game.ME.hero;
		if( h.cx==cx && h.cy==cy && ( h.isWalking() || h.car.canLeave() ) )
			charge+=0.03*speed;
		else
			charge-=0.06;
		charge = MLib.fclamp(charge, 0, 1);
		base.setFrame( MLib.ceil(charge*(base.totalFrames()-1)) );
 		if( charge==1 )
			onPick();

		if( time%40==0 ) {
			cd.set("shine", 15);
			cd.onComplete("shine", function() icon.transform.colorTransform = new flash.geom.ColorTransform());
		}
		if( cd.has("shine") ) {
			var f = 1-cd.get("shine")/cd.getInitialValue("shine");
			var o = Math.sin(f*3.14)*255;
			var ct = new flash.geom.ColorTransform(1,1,1, 1, o,o,o);
			icon.transform.colorTransform = ct;
		}
	}
}