import mt.deepnight.Buffer;
import mt.deepnight.Lib;
import mt.deepnight.Tweenie;
import mt.flash.Key;
import mt.MLib;


enum Phase {
	P_Intro;
	P_HowTo;
	P_Banks;
	P_Coins;
}

class Game extends mt.deepnight.FProcess { //}
	public static var ME : Game;

	public var buffer		: Buffer;
	public var fx			: Fx;
	public var city			: City;
	public var hero			: en.Hero;
	public var infos		: ui.Infos;
	public var money		: Int;
	public var highScores	: Array<Int>;
	public var phase		: Phase;
	public var phaseCounter	: Int;
	public var round		: Int;
	public var cm			: mt.deepnight.Cinematic;
	public var pacman		: Bool;

	public function new() {
		super();
		ME = this;
		money = 0;
		phaseCounter = 0;
		phase = P_Banks;
		pacman = false;
		round = 0;
		cm = new mt.deepnight.Cinematic(Const.FPS);

		Assets.init();

		var stage = flash.Lib.current.stage;
		stage.quality = flash.display.StageQuality.LOW;
		buffer = new Buffer(425,267, Const.UPSCALE, false, 0x0);
		buffer.drawQuality = flash.display.StageQuality.MEDIUM;
		buffer.setTexture( Buffer.makeScanline(Const.UPSCALE), 0.5, true );
		root.addChild(buffer.render);

		highScores = mt.deepnight.Lib.getCookie("lawBreaker", "hs", [0,0]);

		fx = new Fx();
		city = new City();
		infos = new ui.Infos();

		hero = new en.Hero();

		resetGame();
		infos.updateInfos();

		#if debug
		var c = new en.c.Helicopter(hero.cx, hero.cy-1);
		c.ai = false;
		addGouranga();
		addGouranga();
		#end

		//#if debug
		//setPhase(P_HowTo);
		//#else
		setPhase(P_Intro);
		//#end
	}

	override function onResize() {
		super.onResize();
		buffer.setScale(Const.UPSCALE);
	}

	public function setPhase(p:Phase) {
		phase = p;
		infos.updateInfos();
		phaseCounter = 0;
		switch( p ) {
			case P_Intro :
				var mask = new flash.display.Bitmap( new flash.display.BitmapData(buffer.width, buffer.height, true, alpha(0, 0.75)) );
				buffer.dm.add(mask, Const.DP_LOGO);

				var logo = Assets.tiles.get("logo");
				buffer.dm.add(logo, Const.DP_LOGO);
				logo.setCenter(0.5, 0.5);
				logo.x = Std.int(buffer.width*0.5);
				logo.y = 0;

				var tf1 = Assets.createField("A 48h game by Sébastien Bénard", 0xFFFFFF, 8, "def");
				buffer.dm.add(tf1, Const.DP_LOGO);
				tf1.x = Std.int( buffer.width*0.5 - tf1.textWidth*0.5 );
				tf1.y = 400;
				tf1.filters = [
					new flash.filters.GlowFilter(0x0,1, 2,2,4),
				];

				var tf2 = Assets.createField("deepnight.net", 0xFFFFFF, 10, "tiny");
				buffer.dm.add(tf2, Const.DP_LOGO);
				tf2.x = Std.int( buffer.width*0.5 - tf2.textWidth*0.5 );
				tf2.y = 400;
				tf2.filters = [
					new flash.filters.GlowFilter(0x0,1, 2,2,4),
				];

				var bt1 = Assets.createField("Normal mode (48h version)", 0xF7BB06, 8, "def");
				buffer.dm.add(bt1, Const.DP_LOGO);
				bt1.x = buffer.width;
				bt1.y = Std.int(buffer.height*0.5-15);
				bt1.filters = [
					new flash.filters.DropShadowFilter(1,90, 0xFFFF80,1, 0,0,1, 1,true),
					new flash.filters.DropShadowFilter(1,90, 0xA8225B,1, 0,0,1),
					new flash.filters.GlowFilter(0x701D63,1, 2,2,4),
				];

				var bt2 = Assets.createField("WAKA WAKA GTA mode", 0xF7BB06, 8, "def");
				buffer.dm.add(bt2, Const.DP_LOGO);
				bt2.x = buffer.width;
				bt2.y = Std.int(buffer.height*0.5+15);
				bt2.filters = [
					new flash.filters.DropShadowFilter(1,90, 0xFFFF80,1, 0,0,1, 1,true),
					new flash.filters.DropShadowFilter(1,90, 0xA8225B,1, 0,0,1),
					new flash.filters.GlowFilter(0x701D63,1, 2,2,4),
				];

				var arrow = new flash.display.Sprite();
				buffer.dm.add(arrow, Const.DP_LOGO);
				arrow.graphics.beginFill(0xFFFFFF);
				arrow.graphics.moveTo(0,-3);
				arrow.graphics.lineTo(5,0);
				arrow.graphics.lineTo(0,3);
				arrow.x = 191;

				function _clear() {
					logo.dispose();
					tf1.parent.removeChild(tf1);
					tf2.parent.removeChild(tf2);
					bt1.parent.removeChild(bt1);
					bt2.parent.removeChild(bt2);
					mask.bitmapData.dispose();
					mask.bitmapData = null;
					mask.parent.removeChild(mask);
					arrow.parent.removeChild(arrow);
				}

				//function _skip(_) cm.signal();

				function over1() {
					var m = buffer.getMouse();
					return m.bx>=bt1.x && m.bx<=bt1.x+bt1.width && m.by>=bt1.y-10 && m.by<=bt1.y+bt1.height+10;
				}

				function over2() {
					var m = buffer.getMouse();
					return m.bx>=bt2.x && m.bx<=bt2.x+bt2.width && m.by>=bt2.y-10 && m.by<=bt2.y+bt2.height+10;
				}

				function onMouseMove(_) {
					if( over1() ) {
						arrow.visible = true;
						arrow.y = bt1.y+11;
					}
					else if( over2() ) {
						arrow.visible = true;
						arrow.y = bt2.y+11;
					}
					else arrow.visible = false;
				}

				function clickMenu(_) {
					if( over1() ) {
						Assets.SBANK.coin03(1);
						tw.create(bt1.y, bt1.y-3, TLoopEaseOut, 400).pixel = true;
						tw.create(bt1.alpha, 0, 1500);
						tw.create(bt2.alpha, 0, 200);
						pacman = false;
						cm.signal();
						root.stage.removeEventListener(flash.events.MouseEvent.MOUSE_MOVE, onMouseMove);
						root.stage.removeEventListener(flash.events.MouseEvent.CLICK, clickMenu);
					}
					if( over2() ) {
						Assets.SBANK.coin03(1);
						tw.create(bt2.y, bt2.y-3, TLoopEaseOut, 400).pixel = true;
						tw.create(bt2.alpha, 0, 1500);
						tw.create(bt1.alpha, 0, 200);
						pacman = true;
						cm.signal();
						root.stage.removeEventListener(flash.events.MouseEvent.MOUSE_MOVE, onMouseMove);
						root.stage.removeEventListener(flash.events.MouseEvent.CLICK, clickMenu);
					}
				}

				function showMenu(_) {
					tw.create(logo.x, 50+logo.width*0.5, 100).onEnd = function() {
						Assets.SBANK.gun03().play(0.5, -0.5);
					}
					tw.create(bt1.x, 200, 200);
					tw.create(bt2.x, 200, 400);
					root.stage.removeEventListener(flash.events.MouseEvent.CLICK, showMenu);
					root.stage.addEventListener(flash.events.MouseEvent.CLICK, clickMenu);
					root.stage.addEventListener(flash.events.MouseEvent.MOUSE_MOVE, onMouseMove);
				}

				hero.cd.set("controls", 99999);
				var y = Std.int(buffer.height*0.5);

				function startMusic() {
					if( !Assets.music.isPlaying() )
						Assets.music.playLoop();
				}

				cm.create({
					380>>Assets.SBANK.explode01(1);
					1000>>startMusic();
					tw.create(logo.y, y, 400, TEaseIn).chain(y-8, TLoop, 150);
					root.stage.addEventListener(flash.events.MouseEvent.CLICK, showMenu);
					500;
					300>>Assets.SBANK.gun01(1);
					tw.create(tf1.y, 230, 300);
					200;
					300>>Assets.SBANK.gun01(1);
					tw.create(tf2.y, 245, 300);

					end;
					//root.stage.removeEventListener(flash.events.MouseEvent.CLICK, _skip);

					//tw.create(mask.alpha, 0);
					tw.create(logo.y, -400, 500);
					tw.create(logo.alpha, 0).onUpdate = function() {
						mask.alpha = logo.alpha;
					}
					tw.create(tf1.alpha, 0);
					tw.create(tf2.alpha, 0);
					1200;
					_clear();
					hero.cd.unset("controls");
					setPhase(P_HowTo);
				});



			case P_HowTo :
				phaseCounter = 1;

				fx.alarm(hero, 0x0080FF, 2);
				fx.text(hero, "Use ARROWS to move");
				delayer.add( function() {
					var c = en.c.SuperCar.ALL[0];
					fx.text(c, "Get in the car using SPACE");
					fx.alarm(c, 0xFE5301, 2);
				}, 2000);



			case P_Banks :
				round++;

				if( !pacman && round>=4 ) {
					destroy();
					new Outro();
					return;
				}

				// Monks
				if( round>=2 && en.Walker.ALL.length==0 )
					addGouranga();

				// Heli
				if( !pacman && round>=2 && en.c.Helicopter.ALL.length==0 ) {
					var pt = getFreeRandomSpot();
					new en.c.Helicopter(pt.cx, pt.cy);
				}

				// Tank
				if( !pacman && round>=3 && en.c.Tank.ALL.length==0 ) {
					var pt = getFreeRandomSpot();
					new en.c.Tank(pt.cx, pt.cy);
				}

				// Add cops
				var maxCops = pacman ? 2+round : round*2;
				if( en.c.Cop.ALL.length<maxCops )
					for(pt in city.getRandomSpots("spawn", maxCops-en.c.Cop.ALL.length, hero.cx, hero.cy, 8))
						new en.c.Cop(pt.cx, pt.cy);

				for( e in en.c.Cop.ALL )
					e.setAlarm(false);

				if( pacman )
					new ui.Notification('Level $round!');
				else
					new ui.Notification('Mission $round');

				if( !pacman ) {
					var i = 0;
					var banks = 4+round;
					for(pt in city.getRandomSpots("spawn", banks, hero.cx, hero.cy, 6)) {
						phaseCounter++;
						var e = new en.pl.Bank(pt.cx, pt.cy);
						delayer.add(function() fx.bleep(e,0xFF0000,10,4, true), 1000);
						i++;
					}
				}

				if( !pacman && en.pl.LoveHotel.ALL.length==0 ) {
					var pt = getFreeRandomSpot();
					new en.pl.LoveHotel(pt.cx, pt.cy);
				}

				// Bribes
				var n = (pacman?4:1);
				for(i in 0...n-en.pl.Bribe.ALL.length) {
					var pt = getFreeRandomSpot();
					new en.pl.Bribe(pt.cx, pt.cy);
				}

				if( pacman )
					repopPacmanCoins();


			case P_Coins :
				new ui.Notification('Mission $round completed!');
				for(i in 0...1) {
					var n = splashMoney();
					phaseCounter+=n;
				}
		}
	}


	function resetGame() {
		money = 0;
		round = 0;

		for(e in en.Car.ALL)
			e.destroy();

		for(e in en.Place.ALL)
			e.destroy();

		for(e in en.Walker.ALL)
			e.destroy();

		for(e in en.Item.ALL)
			e.destroy();

		for(pt in city.getRandomSpots("spawn", 12, hero.cx, hero.cy, 3))
			new en.c.CitizenCar(pt.cx, pt.cy);

		var pt = city.getSpots("start")[0];
		hero.setPosCase(pt.cx, pt.cy);
		hero.setLife(5);

		var c = new en.c.SuperCar(hero.cx, hero.cy-3);
		c.ai = false;

		infos.updateInfos();
	}

	public function onHeroDeath() {
		for(e in en.c.Cop.ALL)
			e.setAlarm(false);

		function notif(s) new ui.Notification(s);

		if( pacman) {
			cm.create({
				Fx.ME.flashBang(0xFF0000, 0.5, 0.01);
				notif("Game over!");
				2000;
				resetGame();
				setPhase(P_Intro);
				hero.spr.visible = true;
			});
		}
		else {
			cm.create({
				Fx.ME.flashBang(0xFF0000, 0.5, 0.01);
				notif("Killed!!");
				2000;
				Fx.ME.bleep(hero, 0x86FF00, 10, 3);
				Fx.ME.text(hero, "Healed!");
				hero.spr.visible = true;
				1500;
				gainMoney(hero, -10000);
			});
		}
	}


	public function getFreeRandomSpot() {
		var spots = city.getSpots("spawn").copy();
		while( spots.length>0 ) {
			var pt = spots.splice(Std.random(spots.length), 1)[0];

			if( Lib.distanceSqr(hero.cx, hero.cy, pt.cx, pt.cy)<=8*8 )
				continue;

			var empty = true;
			for(e in Entity.ALL)
				if( e.cx==pt.cx && e.cy==pt.cy ) {
					empty = false;
					break;
				}

			if( empty )
				return pt;
		}
		return null;
	}


	//public function onPlayerDeath() {
	//}

	public function decPhaseCounterIf(p:Phase) {
		if( phase!=p )
			return;

		phaseCounter--;
		if( phaseCounter<=0 )
			switch( phase ) {
				case P_Intro : setPhase(P_HowTo);
				case P_HowTo : setPhase(P_Banks);
				case P_Banks :
					if( pacman ) {
						gainMoney(hero, 50000);
						setPhase(P_Banks);
					}
					else
						setPhase(P_Coins);

				case P_Coins : setPhase(P_Banks);
			}
	}


	public function addGouranga() {
		var pt = getFreeRandomSpot();
		var last = null;
		for(i in 0...7) {
			var e = new en.Walker(pt.cx, pt.cy, last);
			last = e;
		}
	}


	public function repopPacmanCoins() {
		for(e in en.Item.ALL)
			e.destroy();

		var i = 0;
		phaseCounter = 0;
		var padding = MLib.max(0, 9-round);
		for(cx in padding...city.wid-padding)
			for(cy in padding...city.hei-padding) {
				if( city.isRoad(cx,cy) && (cx!=hero.cx || cy!=hero.cy) ) {
					delayer.add( function() {
						var it = new en.it.TinyCoin(cx,cy);
						fx.pop(it);
						phaseCounter++;
					}, i*2+rnd(0,5) );
					i++;
				}
			}
	}


	public function splashMoney() {
		var cx = irnd(4, city.wid-4);
		var cy = irnd(4, city.hei-4);
		var n = 0;
		for(dx in -3...4)
			for(dy in -3...4) {
				var cx = cx+dx;
				var cy = cy+dy;
				if( !city.hasCollision(cx,cy) ) {
					n++;
					delayer.add( function() {
						var e = if( Std.random(100)<30 )
							new en.it.Coin(cx,cy);
						else
							new en.it.TinyCoin(cx,cy);
						fx.pop(e);
					}, rnd(0, 500));
				}
			}
		return n;
	}

	public function gainMoney(e:Entity, v:Int, ?feedback=true) {
		money+=v;
		if( money<0 )
			money = 0;
		infos.updateInfos();
		if( feedback )
			fx.money(e.xx, e.yy, v);

		if( !pacman && money>=highScores[0] ) {
			highScores[0] = money;
			Lib.setCookie("lawBreaker", "hs", highScores);
		}

		if( pacman && money>=highScores[1] ) {
			highScores[1] = money;
			Lib.setCookie("lawBreaker", "hs", highScores);
		}
	}

	override function unregister() {
		super.unregister();

		for(e in Entity.ALL)
			e.destroy();
		Entity.gc();

		for(e in Bullet.ALL)
			e.destroy();
		Bullet.gc();

		city.destroy();
		city = null;

		fx.destroy();
		fx = null;

		cm.destroy();

		buffer.destroy();
		buffer = null;
	}

	override function update() {
		mt.flash.Key.update();

		super.update();

		for(e in Entity.ALL)
			e.update();
		Entity.gc();

		for(e in Bullet.ALL)
			e.update();
		Bullet.gc();

		// Test
		#if debug
		if( Key.isToggled(flash.ui.Keyboard.E) ) {
			destroy();
			new Outro();
			return;
		}

		if( Key.isToggled(flash.ui.Keyboard.K) )
			hero.hit(99);

		if( Key.isToggled(flash.ui.Keyboard.N) )
			setPhase(P_Banks);
		#end

		if( Key.isToggled(flash.ui.Keyboard.S) )
			mt.flash.Sfx.toggleMuteChannel(0);

		if( Key.isToggled(flash.ui.Keyboard.M) )
			mt.flash.Sfx.toggleMuteChannel(1);
	}

	override function render() {
		super.render();
		cm.update();
		Assets.tiles.updateChildren();
		fx.update();
		buffer.update();
	}
}
