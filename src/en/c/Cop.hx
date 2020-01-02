package en.c;

import mt.MLib;
import mt.deepnight.Lib;
import mt.deepnight.slb.*;
import mt.flash.Key;

class Cop extends en.Car {
	public static var ALL : Array<Cop> = [];
	var siren0			: BSprite;
	var siren1			: BSprite;
	var sirenOff		: Float;
	var alarm			: Bool;
	var trackCounter	: Int;

	public function new(x,y) {
		super(x,y);

		setSkin(1);
		weight = 30;
		alarm = false;
		speed*=0.7;
		trackCounter = 0;
		eatScore = 750;

		sirenOff = rnd(0,4);

		ALL.push(this);
		onActivate = null;

		siren0 = Assets.tiles.get("siren",0);
		spr.addChild(siren0);
		siren0.setCenter(0.5, 0.5);
		siren0.x = -1;
		siren0.y = -2;
		siren0.blendMode = ADD;

		siren1 = Assets.tiles.get("siren",1);
		spr.addChild(siren1);
		siren1.setCenter(0.5, 0.5);
		siren1.x = -1;
		siren1.y = 2;
		siren1.blendMode = ADD;

		lightsOn();

		if( Game.ME.pacman )
			setAlarm(true);
	}

	override function repop(x,y) {
		super.repop(x,y);

		var e = new en.c.Cop(x,y);
		if( !Game.ME.hero.cd.has("cherry") )
			e.setAlarm(true);
		call911();
	}

	override function unregister() {
		super.unregister();

		ALL.remove(this);
	}


	override function lightsOn(?a) {
		super.lightsOn(a);
		lights.alpha = 0.1;
	}
	override function updateCoords() {
		super.updateCoords();
	}

	public static function getAlarmedCount() {
		var n = 0;
		for(e in ALL)
			if( e.alarm )
				n++;
		return n;
	}

	public static function call911() {
		var patrols = ALL.filter( function(c) return !c.alarm );
		if( patrols.length>0 ) {
			var e = patrols[Std.random(patrols.length)];
			if( !e.cd.has("alarm") ) {
				if( Game.ME.pacman )
					Fx.ME.text(e, "WAKA WAKA in progress!");
				else
					Fx.ME.text(e, "Crime in progress!");
				e.setAlarm(true);
			}
		}
	}

	public static function onRobbery() {
		call911();
	}

	override function onRepeledBy(e,f) {
		super.onRepeledBy(e,f);

		if( e.isCar() ) {
			var e:Car = cast e;
			if( e.hasHeroDriver() && !alarm ) {
				if( !cd.has("alarm") ) {
					Fx.ME.text(this, "WTF?!");
					cd.set("wait", rnd(30,40));
					setAlarm(true);
				}
			}

			if( !e.hasHeroDriver() && !e.isCop() ) {
				if( alarm && !cd.hasSet("copCollide",20) )
					e.hit(3);
				cd.set("wait", rnd(10,20));
			}
		}
	}

	public function setAlarm(b) {
		if( b && cd.has("alarm") )
			return;

		if( b && !alarm ) {
			// Turn ON
			if( lights!=null )
				lights.alpha = 0.2;
			path = [];
			Fx.ME.alarm(this, 0x0080FF, 2);
			cd.set("shoot", Const.seconds(rnd(1.5,3)));
			trackCounter = Const.seconds(12);
		}
		if( !b && alarm ) {
			// Turn off
			anger = 0;
			if( lights!=null ) {
				lights.setFrame(0);
				lights.alpha = 0.1;
			}
			trackCounter = 0;
		}
		alarm = b;
	}

	function trackPlayer() {
		var h = Game.ME.hero;
		var pts = Game.ME.city.pf.getPath( {x:cx, y:cy}, {x:h.cx, y:h.cy} );
		path = pts.map( function(pt) return { cx:pt.x, cy:pt.y } );

		//for(pt in path)
			//Fx.ME.marker(pt.cx, pt.cy);

		cd.set("track", Const.seconds(2));
	}

	override function isCop() return true;

	override function update() {
		ai = !alarm;

		super.update();

		siren0.visible = siren1.visible = alarm;

		if( !alarm && !cd.has("alarm") && distSqr(Game.ME.hero)<=50*50 && getAlarmedCount()>1 ) {
			Fx.ME.text(this, "Suspect spotted!");
			setAlarm(true);
		}

		if( alarm ) {
			if( distSqr(Game.ME.hero)<=120*120 )
				trackCounter = MLib.max(trackCounter, Const.seconds(5));

			trackCounter--;
			if( trackCounter<=0 ) {
				Fx.ME.text(this, "Suspect lost");
				setAlarm(false);
			}
		}


		var h = Game.ME.hero;
		if( h.cd.has("cherry") && time%30==0 )
			Fx.ME.bleep(this, 0xB3FF00, 3, 1);


		if( !isBurning() ) {
			if( alarm && ( path.length==0 || !cd.has("track") ) )
				trackPlayer();

			if( alarm && !cd.has("wait") ) {
				var t = Game.ME.time;
				siren0.alpha = 0.3 + Math.cos(sirenOff + t*0.2)*0.2;
				siren1.alpha = 0.3 + Math.cos(sirenOff + 3.14+t*0.2)*0.2;

				if( path.length>0 ) {
					var next = path[0];
					var tx = (next.cx+0.5)*Const.GRID;
					var ty = (next.cy+0.5)*Const.GRID;
					if( Lib.distanceSqr(xx,yy, tx,ty)<=8*8 )
						path.shift();
					else {
						var a = Math.atan2(ty-yy, tx-xx);
						dx+=Math.cos(a)*speed;
						dy+=Math.sin(a)*speed;
					}
				}
			}

			// Shoot
			if( alarm && !cd.has("shoot") ) {
				if( Game.ME.pacman )
					cd.set("shoot", rnd(20,40));
				else
					cd.set("shoot", rnd(12,20));

				var h = Game.ME.hero;
				if( distSqr(h)<=70*70 ) {
					Assets.SBANK.gun01(1);
					new Bullet(this, h);
				}

			}
		}

		if( lights!=null && alarm && !cd.hasSet("lightSwitch",15) )
			lights.setFrame( lights.frame==0 ? 1 : 0 );

		if( alarm && time%2==0 && ( MLib.fabs(dx)>=0.005 || MLib.fabs(dy)>=0.005 ) )
			Fx.ME.trail(this, 0x0080FF);
	}
}
