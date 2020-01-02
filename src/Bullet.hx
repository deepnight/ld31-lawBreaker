import mt.deepnight.slb.*;
import mt.MLib;
import mt.deepnight.Lib;

class Bullet {
	public static var ALL		: Array<Bullet> = [];
	public static var GC		: Array<Bullet> = [];

	public var spr			: BSprite;

	public var xx			: Float;
	public var yy			: Float;
	public var life			: Int;
	public var dx			: Float;
	public var dy			: Float;

	var destroyAsked		: Bool;

	public function new(from:Entity, to:Entity) {
		ALL.push(this);
		xx = from.xx;
		yy = from.yy;
		life = Lib.irnd(10,20);

		var a = Math.atan2(to.yy-from.yy, to.xx-from.xx);
		var s = Lib.rnd(6,7);
		dx = Math.cos(a)*s;
		dy = Math.sin(a)*s;

		spr = Assets.tiles.get("bullet");
		Game.ME.buffer.dm.add(spr, Const.DP_FX);
		spr.rotation = MLib.toDeg(a);
		spr.setCenter(0.5, 0.5);
		spr.blendMode = ADD;
	}

	public function destroy() {
		if( !destroyAsked ) {
			GC.push(this);
			destroyAsked = true;
		}
	}

	public static function gc() {
		while( GC.length>0 )
			GC.pop().unregister();
	}

	public function unregister() {
		ALL.remove(this);

		spr.dispose();
		spr = null;
	}

	public function update() {
		xx+=dx;
		yy+=dy;

		spr.x = xx;
		spr.y = yy;

		var h = Game.ME.hero;
		if( Lib.distanceSqr(xx,yy, h.xx,h.yy)<=3*3 ) {
			destroy();
			if( h.car!=null )
				h.car.hit(1);
			else if( h.spr.visible )
				h.hit(1);
		}

		life--;
		if( life<=0 ) {
			Fx.ME.bulletMiss(xx,yy);
			destroy();
		}
	}
}