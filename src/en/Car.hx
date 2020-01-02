package en;

import mt.MLib;
import mt.deepnight.Lib;
import mt.deepnight.slb.*;
import mt.flash.Key;

class Car extends Entity {
	public static var ALL : Array<Car> = [];

	public var ang			: Float;

	public var side			: BSprite;
	public var lights		: Null<BSprite>;

	public var ai			: Bool;
	public var path			: Array<{ cx:Int, cy:Int }>;
	public var driveAng		: Float;
	var anger				: Int;
	var explosionScale		: Float;
	var eatScore			: Int;

	private function new(x,y) {
		super();

		ALL.push(this);
		explosionScale = 0.3;
		eatScore = 50;
		ai = true;
		ang = 0;
		driveAng = 0;
		path = [];
		weight = 20;
		frict = 0.9;
		speed = 0.017;
		setLife(10);

		side = new mt.deepnight.slb.BSprite(Assets.tiles, "carSide");
		Game.ME.buffer.dm.add(side, Const.DP_CARSIDE);
		side.setCenter(0.5,0.5);

		spr.set("car");
		spr.setCenter(0.5,0.5);
		Game.ME.buffer.dm.add(spr, Const.DP_CAR);

		onActivate = function() {
			if( canLeave() && !Game.ME.hero.destroyAsked )
				Game.ME.hero.grabCar(this);
		}

		setPosCase(x,y);
		setSkin(2);
	}

	override function isCar() return true;

	public function lightsOn(?alpha=0.2) {
		lightsOff();

		lights = new mt.deepnight.slb.BSprite(Assets.tiles, "halo");
		Game.ME.buffer.dm.add(lights, Const.DP_FX);
		lights.setCenter(0.5, 0.5);
		lights.visible = false;
		lights.alpha = alpha;
		lights.blendMode = ADD;
	}

	public function lightsOff() {
		if( lights!=null ) {
			lights.dispose();
			lights = null;
		}
	}

	override function hit(d, ?silent) {
		super.hit(d,silent);

		if( hasHeroDriver() ) {
			if( !silent )
				mt.flash.Sfx.playOne([ Assets.SBANK.carHit01, Assets.SBANK.carHit02 ]);
			Game.ME.infos.updateInfos();
		}
	}


	function repop(x,y) {
	}

	override function die() {
		Fx.ME.explosion(this, explosionScale);
		Assets.SBANK.explode01(1);
		repels = false;
		physics = false;

		if( hasHeroDriver() )
			Game.ME.hero.leaveCar();

		if( !destroyAsked ) {
			var spots = Game.ME.city.getSpots("spawn").copy();
			while( spots.length>0 ) {
				var pt = spots.splice(Std.random(spots.length),1)[0];
				if( Lib.distanceSqr(cx,cy, pt.cx, pt.cy)>=6*6 ) {
					var conflict = false;
					for(e in en.Car.ALL)
						if( e.cx==pt.cx && e.cy==pt.cy ) {
							conflict = true;
							break;
						}
					if( !conflict ) {
						repop(pt.cx,pt.cy);
						break;
					}
				}
			}
		}

		super.die();
	}


	override function unregister() {
		if( hasHeroDriver() )
			Game.ME.hero.leaveCar();

		super.unregister();

		ALL.remove(this);
		lightsOff();

		side.dispose();
		side = null;
	}


	override function updateCoords() {
		super.updateCoords();

		side.x = spr.x;
		side.y = spr.y+1;

		spr.rotation = MLib.round(MLib.toDeg(ang)/10)*10;
		side.rotation = spr.rotation;

		if( lights!=null ) {
			lights.x = xx;
			lights.y = yy;
			lights.visible = true;
		}
	}

	function chooseNewDirection() {
		var city = Game.ME.city;
		var spots = [];
		var angs = [ driveAng, driveAng+1.57, driveAng-1.57 ];
		for(a in angs) {
			var x = cx;
			var y = cy;
			while( city.isRoad(x,y) ) {
				x+=MLib.round( Math.cos(a) );
				y+=MLib.round( Math.sin(a) );
			}
			x-=MLib.round( Math.cos(a) );
			y-=MLib.round( Math.sin(a) );
			if( ( x!=cx || y!=cy ) )
				spots.push({ cx:x, cy:y });
		}

		if( spots.length==0 ) {
			Fx.ME.marker(cx,cy, 0xFF0000);
			trace(this+" is lost! "+driveAng);
		}
		else {
			var pt = spots[ Std.random(spots.length) ];
			path = mt.deepnight.Bresenham.getThinLine(cx,cy, pt.cx,pt.cy).map( function(p) return { cx:p.x, cy:p.y } );
			if( path[0].cx!=cx || path[0].cy!=cy )
				path.reverse();
		}
	}

	function getDrivingPosition(a:Float) {
		return
			if( a==0 ) { xr:0.5, yr:0.75 }
			else if( a==3.14 ) { xr:0.5, yr:0.25 }
			else if( a==-1.57 ) { xr:0.75, yr:0.5 }
			else { xr:0.25, yr:0.5 }
	}

	public function hasHeroDriver() {
		return Game.ME.hero.car==this;
	}

	function getOtherCars(x,y) {
		for(e in ALL)
			if( e!=this && e.cx==x && e.cy==y )
				return e;
		return null;
	}

	public function setSkin(id) {
		spr.setFrame(id);
		side.setFrame(id);
	}

	override function onRepeledBy(e,f) {
		super.onRepeledBy(e,f);
		cd.set("controls", 3);
		cd.set("rotation", 10);


		if( e.isCar() ) {
			var e : Car = cast e;
			//if( ( hasHeroDriver() || e.hasHeroDriver() ) && !cd.has("collideHit") ) {
				//cd.set("collideHit", rnd(3,8));
				//hit(1);
			//}
			anger+=2;
			if( ( !ai || !e.ai ) && !cd.hasSet("repelSparks",5) )
				for(i in 0...5)
					Fx.ME.sparks(xx, yy);
		}
	}

	override function onCollideWall(a:Float) {
		//if( hasHeroDriver() && !cd.has("collideHit") ) {
			//cd.set("collideHit", rnd(3,8));
			//hit(1);
		//}

		Fx.ME.sparks(xx+Math.cos(a)*2, yy+Math.sin(a)*2);
		dx*=0.9;
		dy*=0.9;
	}


	public function isBurning() {
		return life/maxLife<=0.33;
	}

	function getPhysics() {
		return !ai;
	}

	public function canLeave() {
		return true;
	}

	function updateAI() {
		// Get new destination
		if( path.length==0 )
			chooseNewDirection();

		var isAngry = anger>=50;

		// Move to next
		if( path.length>0 && ( !cd.has("wait") || isAngry ) ) {
			var next = path[0];

			if( next.cx<cx ) driveAng = 3.14;
			else if( next.cx>cx ) driveAng = 0;
			else if( next.cy<cy ) driveAng = -1.57;
			else if( next.cy>cy ) driveAng = 1.57;

			var e = getOtherCars(next.cx, next.cy);
			if( e!=null && !isAngry && MLib.fabs(Lib.angularSubstractionRad(ang, e.ang))<=1.6 && distSqr(e)<=10*10 )
				cd.set("wait", rnd(3,6));
			else {
				var t = Game.ME.city.getTrafficLight(next.cx, next.cy);
				var tlStop = false;
				if( t!=null ) {
					if( t.state!=0 && driveAng==0 && xr>0.5 )
						tlStop = true;

					if( t.state!=0 && driveAng==3.14 && xr<0.5 )
						tlStop = true;

					if( t.state!=2 && driveAng==-1.57 && yr<0.5 )
						tlStop = true;

					if( t.state!=2 && driveAng==1.57 && yr>0.5 )
						tlStop = true;
				}

				if( tlStop ) {
					// Stopped at traffic light
					cd.set("wait", rnd(3,7));
					anger--;
				}
				else {
					var p = getDrivingPosition(driveAng);
					var tx = next.cx+p.xr;
					var ty = next.cy+p.yr;
					var a = Math.atan2( ty - (cy+yr), tx - (cx+xr) );
					dx += Math.cos(a)*speed*0.3;
					dy += Math.sin(a)*speed*0.3;
					//if( !cd.has("rotation") )
						//ang += Lib.angularSubstractionRad(a,ang)*0.15;
					//else
						//ang += Lib.angularSubstractionRad(a,ang)*0.03;

					// Next point reached
					if( Lib.distanceSqr(cx+xr,cy+yr, tx, ty)<=0.5*0.5 ) {
						path.shift();
						// Change plan (cross roads)
						if( path.length>0 && Std.random(100)<100 && !cd.hasSet("newDir", 120) ) {
							var next = path[0];
							var city = Game.ME.city;
							if( next.cx!=cx && ( city.isRoad(cx,cy-1) || city.isRoad(cx,cy+1) ) )
								chooseNewDirection();
							else if( next.cy!=cy && ( city.isRoad(cx-1,cy) || city.isRoad(cx+1,cy) ) )
								chooseNewDirection();
						}
					}
					anger--;
				}
			}

		}
	}

	override function update() {
		physics = getPhysics();

		// Driver AI
		if( ai )
			updateAI();

		if( cd.has("wait") ) {
			dx*=0.7;
			dy*=0.7;
			anger++;
		}

		if( Game.ME.city.hasCollision(cx,cy) )
			anger+=5;

		anger = MLib.clamp(anger, 0, 50);

		var h = Game.ME.hero;
		if( !hasHeroDriver() && !h.isWalking() && h.cd.has("cherry") ) {
			if( distSqr(h)<=12*12 ) {
				hit(99);
				Game.ME.delayer.add( function() {
					Game.ME.gainMoney(this, eatScore);
				}, 250);
			}
		}

		if( hasHeroDriver() && !cd.has("controls") ) {
			// In car controls
			if( Key.isDown(Key.LEFT) )
				dx-=speed;
			if( Key.isDown(Key.RIGHT) )
				dx+=speed;
			if( !Key.isDown(Key.LEFT) && !Key.isDown(Key.RIGHT) )
				dx*=0.9;

			if( Key.isDown(Key.UP) )
				dy-=speed;
			if( Key.isDown(Key.DOWN) )
				dy+=speed;
			if( !Key.isDown(Key.UP) && !Key.isDown(Key.DOWN) )
				dy*=0.9;

			var hero = Game.ME.hero;
			hero.setPosFree(xx, yy);
		}

		if( MLib.fabs(dx)>=0.001 || MLib.fabs(dy)>=0.001 ) {
			var a = Math.atan2(dy, dx);
			if( !cd.has("rotation") )
				ang += Lib.angularSubstractionRad(a,ang)*0.6;
			else
				ang += Lib.angularSubstractionRad(a,ang)*0.03;
		}

		if( isBurning() ) {
			ai = false;
			if( !cd.hasSet("burning", Const.seconds(3)) )
				hit(1);

			if( time%5==0 )
				Fx.ME.lifeSmoke(this);
		}

		super.update();


		if( hasHeroDriver() ) {
			var s = Math.sqrt( dx*dx + dy*dy );
			var max = speed*9;
			//Assets.setEngine(s/max);
		}


		while( ang>=3.14 ) ang-=6.28;
		while( ang<=-3.14 ) ang+=6.28;
	}
}