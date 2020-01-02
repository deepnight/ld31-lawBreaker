import mt.MLib;
import mt.deepnight.Lib;
import mt.deepnight.slb.*;

class Entity {
	public static var ALL		: Array<Entity> = [];
	public static var GC		: Array<Entity> = [];

	public var destroyAsked		: Bool;
	public var spr				: BSprite;
	public var cd				: mt.Cooldown;
	var time(get,null)			: Float;

	public var xx				: Float;
	public var yy				: Float;

	public var cx				: Int;
	public var cy				: Int;

	public var xr				: Float;
	public var yr				: Float;

	public var dx				: Float;
	public var dy				: Float;

	public var speed			: Float;
	public var frict			: Float;
	public var onActivate		: Null<Void->Void>;
	public var physics			: Bool;
	public var weight			: Float;
	public var repels			: Bool;
	public var life				: Int;
	public var maxLife			: Int;
	public var pixel			: Bool;

	public var hitCt			: Null<flash.geom.ColorTransform>;


	public function new() {
		ALL.push(this);
		destroyAsked = false;
		cd = new mt.Cooldown();
		physics = false;

		pixel = true;
		weight = 1;
		repels = true;
		cx = cy = 0;
		xr = yr = 0.5;
		dx = dy = 0;
		speed = 0.02;
		frict = 0.8;
		setLife(1);

		spr = new mt.deepnight.slb.BSprite(Assets.tiles, "heart");
		Game.ME.buffer.dm.add(spr, Const.DP_BG);
		spr.setCenter(0.5, 1);
		spr.x = spr.y = 100;
	}

	public function setLife(n) {
		maxLife = life = n;
	}

	inline function get_time() return Game.ME.time;

	function toString() {
		return Type.getClass(this)+'@$cx,$cy';
	}

	inline function rnd(min,max,?sign) return Lib.rnd(min,max,sign);
	inline function irnd(min,max,?sign) return Lib.irnd(min,max,sign);

	public static function hasAnyone(cx,cy, except:Entity) {
		return getAnyone(cx,cy,except);
	}

	public static function getAnyone(cx,cy, except:Entity) {
		for(e in ALL)
			if( e!=except && e.cx==cx && e.cy==cy )
				return e;
		return null;
	}


	public function hit(dmg:Int, ?silent=false) {
		var o = dmg>3 ? 40 : 5;
		hitCt = new flash.geom.ColorTransform(o,o,o,1);

		life-=dmg;
		if( life<=0 ) {
			life = 0;
			die();
		}
	}

	public function die() {
		destroy();
	}



	public function setPosCase(x,y) {
		cx = x;
		cy = y;
		xr = 0.5;
		yr = 0.5;
		updateCoords();
	}

	public function setPosFree(x:Float,y:Float) {
		cx = Std.int(x/Const.GRID);
		xr = (x-cx*Const.GRID)/Const.GRID;

		cy = Std.int(y/Const.GRID);
		yr = (y-cy*Const.GRID)/Const.GRID;
	}

	public inline function destroy() {
		if( !destroyAsked ) {
			destroyAsked = true;
			GC.push(this);
		}
	}

	public function distSqr(e:Entity) {
		return mt.deepnight.Lib.distanceSqr(xx,yy, e.xx,e.yy);
	}

	public function getClosestActivable() : Entity {
		var close = [];
		var d2 = Math.pow(Const.GRID*1, 2);
		for(e in Entity.ALL) {
			if( e!=this && e.onActivate!=null && distSqr(e)<=d2 )
				close.push(e);
		}

		if( close.length>0 ) {
			close.sort( function(a,b) {
				return Reflect.compare( distSqr(a)-a.life*0.5, distSqr(b)-b.life*0.5 );
			});
			return close[0];
		}
		else
			return null;
	}

	public function unregister() {
		ALL.remove(this);

		cd.destroy();
		cd = null;

		spr.dispose();
		spr = null;
	}

	public static function gc() {
		while( GC.length>0 )
			GC.pop().unregister();
	}


	public function updateCoords() {
		xx = (cx+xr)*Const.GRID;
		yy = (cy+yr)*Const.GRID;
		if( pixel ) {
			spr.x = Std.int(xx);
			spr.y = Std.int(yy);
		}
		else {
			spr.x = xx;
			spr.y = yy;
		}
	}


	function onCollideWall(ang:Float) {
		dx*=0.5;
		dy*=0.5;
	}

	function onRepeledBy(e:Entity, ratio:Float) {
	}

	public function isCar() return false;
	public function isCop() return false;


	public function update() {
		var city = Game.ME.city;
		cd.update();

		// Circular collisions
		if( repels )
			for(e in ALL) {
				if( e!=this && e.repels && MLib.fabs(e.cx-cx)<=1 && MLib.fabs(e.cy-cy)<=1 ) {
					var d2 = distSqr(e);
					if( d2<=4*4 ) {
						var a = Math.atan2(e.yy-yy, e.xx-xx);

						var pow = 0.05;
						var wr = e.weight/(e.weight+weight);
						if( e.weight-weight>=10 )
							wr = 1;
						else if( weight-e.weight>=10 )
							wr = 0;
						dx-=Math.cos(a)*pow*wr;
						dy-=Math.sin(a)*pow*wr;
						onRepeledBy(e, wr);

						wr = 1-wr;
						e.dx+=Math.cos(a)*pow*wr;
						e.dy+=Math.sin(a)*pow*wr;
						e.onRepeledBy(this, wr);
					}
				}
			}

		// X
		dx*=frict;
		xr+=dx;
		if( physics ) {
			if( city.hasCollision(cx-1,cy) && xr<0.1 ) {
				xr = 0.1;
				onCollideWall(3.14);
			}
			if( city.hasCollision(cx+1,cy) && xr>0.9 ) {
				xr = 0.9;
				onCollideWall(0);
			}
		}
		while( xr<0 ) { xr++; cx--; }
		while( xr>1 ) { xr--; cx++; }
		if( MLib.fabs(dx)<=0.0001 )
			dx = 0;

		// Y
		dy*=frict;
		yr+=dy;
		if( physics ) {
			if( city.hasCollision(cx,cy-1) && yr<0.1 ) {
				yr = 0.1;
				onCollideWall(-1.57);
			}
			if( city.hasCollision(cx,cy+1) && yr>0.7 ) {
				yr = 0.7;
				onCollideWall(1.57);
			}
		}
		while( yr<0 ) { yr++; cy--; }
		while( yr>1 ) { yr--; cy++; }
		if( MLib.fabs(dy)<=0.0001 )
			dy = 0;

		if( hitCt!=null ) {
			hitCt.redMultiplier*=0.8;
			hitCt.blueMultiplier = hitCt.greenMultiplier = hitCt.redMultiplier;
			if( hitCt.redMultiplier<=1 ) {
				hitCt = null;
				spr.transform.colorTransform = new flash.geom.ColorTransform();
			}
			else
				spr.transform.colorTransform = hitCt;
		}

		updateCoords();
	}
}