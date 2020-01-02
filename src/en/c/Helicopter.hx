package en.c;

import mt.MLib;
import mt.deepnight.Lib;
import mt.deepnight.slb.*;
import mt.flash.Key;

class Helicopter extends en.Car {
	public static var ALL : Array<Helicopter> = [];

	//public static var ALL : Array<SuperCar> = [];
	public var dz			: Float;
	public var zz			: Float;
	var blades				: BSprite;
	var shadow				: BSprite;
	var spot				: BSprite;
	var target				: Null<{cx:Int, cy:Int}>;

	public function new(x,y) {
		super(x,y);

		ALL.push(this);
		dz = 0;
		zz = 0;
		setLife(15);
		speed*=0.3;
		frict = 0.95;
		setSkin(0);
		repels = false;
		//lightsOn(0.5);

		spr.set("heli");
		Game.ME.buffer.dm.add(side, Const.DP_SKY);
		side.set("heliSide");
		Game.ME.buffer.dm.add(spr, Const.DP_SKY);

		blades = Assets.tiles.get("heliBlades");
		blades.setCenter(0.5,0.5);
		Game.ME.buffer.dm.add(blades, Const.DP_SKY);
		blades.filters = [
			new flash.filters.BlurFilter(2,2)
		];

		spot = Assets.tiles.get("heliSpot");
		spot.setCenter(0.5,0.5);
		Game.ME.buffer.dm.add(spot, Const.DP_PEDESTRIAN);
		spot.blendMode = ADD;
		spot.alpha = 0.2;

		shadow = Assets.tiles.get("heliShadow");
		shadow.setCenter(0.5,0.5);
		Game.ME.buffer.dm.add(shadow, Const.DP_PEDESTRIAN);
		shadow.filters = [
			new flash.filters.BlurFilter(2,2)
		];

		updateCoords();
	}

	override function getPhysics() {
		return false;
	}


	override function updateCoords() {
		super.updateCoords();
		spr.y = Std.int(spr.y-zz);
		side.y = spr.y+1;
		if( blades!=null ) {
			blades.x = spr.x;
			blades.y = spr.y;

			shadow.x = spr.x;
			shadow.y = Std.int(yy);
			shadow.rotation = spr.rotation;
		}
	}

	override function canLeave() {
		return zz<=5 && !Game.ME.city.hasCollision(cx,cy);
	}

	override function die() {
		if( hasHeroDriver() ) {
			if( Game.ME.city.hasCollision(cx,cy) || zz>=6 ) {
				Game.ME.hero.leaveCar();
				Game.ME.hero.hit(99);
			}
		}

		super.die();
	}

	override function repop(x,y) {
		super.repop(x,y);
		new en.c.Helicopter(x,y);
	}


	override function unregister() {
		super.unregister();

		blades.dispose();
		blades = null;

		spot.dispose();
		spot = null;

		shadow.dispose();
		shadow = null;
		ALL.remove(this);
	}

	override function updateAI() {
		if( cd.has("heliIdle") ) {
			dx*=0.8;
			dy*=0.8;
		}
		else {
			if( target==null ) {
				var spots = Game.ME.city.getSpots("park").copy();
				spots.sort( function(a,b) return -Reflect.compare( Lib.distanceSqr(a.cx,a.cy, cx,cy), Lib.distanceSqr(b.cx,b.cy, cx,cy) ) );
				target = spots[Std.random(spots.length-5)];
			}

			if( target!=null ) {
				var tx = (target.cx+0.5)*Const.GRID;
				var ty = (target.cy+0.5)*Const.GRID;
				var a = Math.atan2(ty-yy, tx-xx);
				var s = speed;
				dx+=Math.cos(a)*s;
				dy+=Math.sin(a)*s;
				if( cx==target.cx && cy==target.cy ) {
					dx*=0.5;
					dy*=0.5;
					cd.set("heliIdle", Const.seconds(rnd(4,7)));
					target = null;
				}
			}
		}
	}


	override function update() {
		super.update();
		var city = Game.ME.city;

		if( ( city.hasCollision(cx,cy) || MLib.fabs(dx)>=0.002 || MLib.fabs(dy)>=0.002 ) ) {
			if( zz<=15 )
				dz+=0.10;
		}
		else if( !city.hasCollision(cx,cy) && zz>=2 )
			dz-=0.08;

		zz+=dz;
		dz*=0.8;

		blades.rotation += 50;
		while( blades.rotation>=360 )
			blades.rotation-=360;

		var tx = xx + Math.cos(ang)*(5+zz*1.5);
		var ty = yy + Math.sin(ang)*(5+zz*1.5);
		spot.x = tx;
		spot.y = ty;
		spot.setScale(0.3 + MLib.fmin(1, zz/20));

		if( hasHeroDriver() && !cd.has("fuel") ) {
			cd.set("fuel", Const.seconds(10));
			hit(1, true);
		}

		if( hasHeroDriver() && !cd.has("out") && !Game.ME.city.isValidCoord(cx,cy) ) {
			cd.set("out", Const.seconds(0.25));
			hit(1);
		}

		updateCoords();
	}
}
