package en;

import mt.flash.Key;
import mt.MLib;
import mt.deepnight.slb.*;
import mt.deepnight.Lib;

class Hero extends Entity {
	public var car			: Null<en.Car>;
	var dir					: Int;
	var shadow				: BSprite;

	public function new() {
		super();

		dir = 1;
		setLife(5);
		speed = 0.08;
		frict = 0.5;
		weight = 1;
		physics = true;
		Game.ME.buffer.dm.add(spr, Const.DP_PEDESTRIAN);

		shadow = Assets.tiles.get("shadow");
		shadow.setCenter(0,1);
		Game.ME.buffer.dm.add(shadow, Const.DP_BG);

		spr.a.setGeneralSpeed(0.3);
		spr.a.registerStateAnim("guyWalk", 1, function() return MLib.fabs(dx)>=0.0005 || MLib.fabs(dy)>=0.0005);
		spr.a.registerStateAnim("guyIdle", 0);
		spr.a.applyStateAnims();
	}

	override function die() {
		if( car!=null )
			leaveCar();

		Fx.ME.explosion(this, 0.5);
		Assets.SBANK.death02(1);
		setLife(5);
		spr.visible = false;

		var pt = Game.ME.city.getSpots("start")[0];
		setPosCase(pt.cx, pt.cy);

		cd.set("controls", Const.seconds(2));

		Game.ME.onHeroDeath();
	}


	override function unregister() {
		super.unregister();

		Assets.setEngine();
		shadow.dispose();
		shadow = null;
	}


	override function hit(d,?silent) {
		super.hit(d,silent);
		Game.ME.infos.updateInfos();
		if( !silent )
			mt.flash.Sfx.playOne([ Assets.SBANK.hit01, Assets.SBANK.hit02, Assets.SBANK.hit03, ]);
	}

	public function grabCar(c:en.Car) {
		repels = false;
		car = c;
		car.ai = false;
		car.path = [];
		spr.visible = false;
		dx = dy = 0;
		Fx.ME.bleep(car, 0xFF0000, 5, 2);
		Game.ME.infos.updateInfos();
		Game.ME.decPhaseCounterIf(P_HowTo);
	}

	public function leaveCar() {
		repels = true;
		dx = dy = 0;

		Assets.setEngine();

		var city = Game.ME.city;
		var x = car.xx;
		var y = car.yy;
		for( a in [1.57, -1.57, 3.14, 0] ) {
			a+=car.ang;
			if( !city.hasCollisionPixel(x+Math.cos(a)*4, y+Math.sin(a)*4) ) {
				setPosFree( x+Math.cos(a)*4, y+Math.sin(a)*4 );
				break;
			}
		}

		spr.visible = true;
		car = null;
		Game.ME.infos.updateInfos();
	}

	public inline function isWalking() return car==null;


	override function updateCoords() {
		super.updateCoords();
		if( dx<-0.001 ) dir = -1;
		if( dx>0.001 ) dir = 1;
		spr.scaleX = MLib.fabs(spr.scaleX)*dir;
		if( shadow!=null ) {
			shadow.x = spr.x;
			shadow.y = spr.y;
			shadow.visible = spr.visible;
		}
	}


	override function update() {
		if( !cd.has("controls") ) {
			if( isWalking() ) {
				// Walk controls
				if( Key.isDown(Key.LEFT) )
					dx-=speed;

				if( Key.isDown(Key.RIGHT) )
					dx+=speed;

				if( Key.isDown(Key.UP) )
					dy-=speed;

				if( Key.isDown(Key.DOWN) )
					dy+=speed;

				if( Key.isDown(Key.SPACE) && !cd.has("activate") ) {
					var e = getClosestActivable();
					if( e!=null ) {
						cd.set("activate", 6);
						e.onActivate();
					}
				}
			}
			else {
				if( Key.isDown(Key.SPACE) && !cd.has("activate") ) {
					if( car.canLeave() ) {
						cd.set("activate", 6);
						leaveCar();
					}
					else {
						Fx.ME.text(this, "You need to land!");
					}
				}
			}
		}

		if( !isWalking() )
			if( time%2==0 && ( MLib.fabs(car.dx)>=0.001 || MLib.fabs(car.dy)>=0.001 ) && car.canLeave() )
				if( cd.has("cherry") )
					Fx.ME.cherryTrail(car);
				else
					Fx.ME.trail(car, 0xFF1A00);

		super.update();
	}
}