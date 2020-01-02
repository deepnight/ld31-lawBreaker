import flash.display.BlendMode;
import flash.display.Sprite;
import flash.display.Bitmap;
import flash.display.BitmapData;

import mt.MLib;
import mt.deepnight.Particle;
import mt.deepnight.Lib;
import mt.deepnight.Color;

import Const;

class Fx {
	public static var ME : Fx;

	var game			: Game;
	var pt0				: flash.geom.Point;
	var pool			: mt.deepnight.BitmapDataPool;

	public function new() {
		ME = this;
		game = Game.ME;
		pt0 = new flash.geom.Point(0,0);

		var tiles = Assets.tiles;
		pool = new mt.deepnight.BitmapDataPool();
		pool.addFromLib(tiles, ["smoke", "smallSmoke", "fire"]);
	}

	public function destroy() {
		Particle.clearAll();

		pool.destroy();
		pool = null;
	}

	public function register(p:Particle, ?b:BlendMode, ?bg=false) {
		game.buffer.dm.add(p, bg?Const.DP_BG_FX:Const.DP_FX);
		p.blendMode = b!=null ? b : BlendMode.ADD;
	}

	inline function rnd(min,max,?sign) { return Lib.rnd(min,max,sign); }
	inline function irnd(min,max,?sign) { return Lib.irnd(min,max,sign); }

	public function marker(cx:Int,cy:Int, ?col=0xFFFF00, ?short=false) {
		markerFree( (cx+0.5)*Const.GRID, (cy+0.5)*Const.GRID, col, short );
	}

	public function markerFree(x,y, ?col=0xFFFF00, ?short=false) {
		var p = new mt.deepnight.Particle(x,y);
		p.drawBox(1,1,col);
		p.filters = [
			new flash.filters.GlowFilter(col,0.6,4,4,4),
		];
		p.life = short?2 : 30;
		register(p, NORMAL);
	}


	public function bulletMiss(x,y) {
		var p = new mt.deepnight.Particle(x,y);
		p.drawBox(3,3, 0x95A2B0, rnd(0.4,0.7));
		p.ds = -0.03;
		p.frict = 0.9;
		p.groundY = y+rnd(0,2);
		p.filters = [ new flash.filters.BlurFilter(4,4) ];
		register(p,NORMAL);
	}


	public function animation(k:String, x,y, spd) {
		var s = Assets.tiles.getAndPlay(k, 1);
		s.setCenter(0.5,0.5);
		Game.ME.buffer.dm.add(s, Const.DP_FX);
		s.blendMode = ADD;
		s.a.setCurrentAnimSpeed(spd);
		s.setPos(x,y);
		s.a.killAfterPlay();
		return s;
	}


	public function lifeSmoke(e:Entity) {
		var p = new mt.deepnight.Particle(rnd(0,4,true), rnd(0,2,true));
		p.useBitmapData(pool.get("fire"), false);
		p.alpha = 0;
		p.da = 0.1;
		//p.dx = rnd(0,1,true);
		//p.dy = -rnd(0,1);
		p.frict = 0.8;
		//p.alpha = rnd(0.5, 0.7);
		p.life = rnd(10,20);
		p.rotation = -e.spr.rotation-rnd(10,20);
		e.spr.addChild(p);

		var p = new mt.deepnight.Particle(e.xx+rnd(0,2,true), e.yy+rnd(0,2,true));
		p.useBitmapData(pool.get("smallSmoke"), false);
		p.alpha = 0;
		p.da = rnd(0.1, 0.2);
		p.maxAlpha = 0.5;
		p.life = rnd(6,10);
		p.dy = -rnd(0.1, 0.3);
		p.rotation = rnd(0,360);
		p.scaleX = p.scaleY = 0.6;
		p.fadeOutSpeed = 0.02;
		register(p, NORMAL);
	}

	public function explosion(e:Entity, scale:Float) {
		for( i in 0...2 ) {
			var p = new mt.deepnight.Particle(e.xx+rnd(0,5,true)*scale, e.yy+rnd(0,5,true)*scale);
			p.useBitmapData(pool.get("smoke"), false);
			p.alpha = rnd(0.4, 0.6);
			p.life = rnd(30,60);
			p.dy = -rnd(0.1, 0.3);
			p.fadeOutSpeed = 0.02;
			p.rotation = rnd(0,360);
			p.scaleX = p.scaleY = rnd(1,1.5)*scale;
			p.ds = -rnd(0.005, 0.008);
			p.dr = rnd(0.2, 0.5,true);
			register(p, NORMAL);
		}

		var s = animation("explosion", e.xx, e.yy, 0.8);
		s.scale(scale);
		s.onFrameChange = function() {
			s.scaleX = s.scaleY+=0.1;
		}
		s.rotation = rnd(0, 360);

		var s = animation("explosion", e.xx+rnd(6,10,true), e.yy+rnd(6,10,true), 1);
		s.rotation = rnd(0, 360);
		s.scale(0.5*scale);

		var s = animation("explosion", e.xx+rnd(6,10,true), e.yy+rnd(6,10,true), 1);
		s.rotation = rnd(0, 360);
		s.scale(0.5*scale);

		for(i in 0...20) {
			var p = new mt.deepnight.Particle(e.xx+rnd(0,2,true), e.yy+rnd(0,2,true));
			p.drawBox(rnd(2,4),1, 0xFFFF80, rnd(0.3, 0.7));
			p.dx = rnd(0, 4, true);
			p.dy = -rnd(1,9);
			p.gy = rnd(0.05, 0.10);
			p.groundY = e.yy+rnd(0,4,true);
			p.frict = rnd(0.9, 0.95);
			p.life = rnd(10,30);
			p.onUpdate = function() {
				p.scaleX*=0.95;
				p.rotation = MLib.toDeg( Math.atan2(p.dy, p.dx) );
			}
			p.filters = [
				new flash.filters.GlowFilter(0xFF6C00,rnd(0.3,0.7), 4,4,4),
			];
			register(p,true);
		}
	}


	public function shoot(a:Entity, b:Entity) {
		var ang = Math.atan2(b.yy-a.yy, b.xx-a.xx) + rnd(0,0.03,true);
		var p = new mt.deepnight.Particle(a.xx+rnd(0,1,true), a.yy+rnd(0,1,true));
		p.drawBox(rnd(2,4), 1, 0xFFA600, 1);
		p.rotation = MLib.toDeg(ang);
		p.moveAng(ang, rnd(5,7));
		p.life = rnd(2,5);
		p.fadeOutSpeed = 0.2;
		p.filters = [ new flash.filters.GlowFilter(0xFF1A00,1, 4,4,3) ];
		register(p);
	}


	public function alarm(e:Entity, col:Int, ?n=1) {
		for(i in 0...n) {
			var p = new mt.deepnight.Particle(e.xx, e.yy);
			p.drawCircle(10,col, false);
			p.ds = 0.1;
			p.life = 5;
			p.delay = i*10;
			p.filters = [
				new flash.filters.GlowFilter(col, 0.8, 8,8,2),
			];
			register(p);
		}
	}

	public function bleep(e:Entity, col:Int, radius:Int, n:Int, ?slow=false) {
		for(i in 0...n) {
			var p = new mt.deepnight.Particle(e.xx, e.yy);
			p.drawCircle(radius,col, false);
			p.ds = 0.1;
			p.life = 5;
			p.delay = i*(slow?15:5);
			p.filters = [
				new flash.filters.GlowFilter(col, 0.8, 8,8,2),
			];
			register(p);
		}
	}

	public function pacmanEat(e:Entity) {
		var p = new mt.deepnight.Particle(e.xx, e.yy);
		p.drawCircle(4, 0xFFFF00, 0.3, false);
		p.ds = -0.1;
		p.life = 5;
		register(p, true);
	}

	public function pop(e:Entity, ?big=false, ?n=1) {
		for(i in 0...n) {
			var p = new mt.deepnight.Particle(e.xx, e.yy);
			p.drawCircle(big?12:3,0xFF8000, false);
			p.ds = 0.06;
			p.life = 6;
			p.delay = i*20;
			p.filters = [
				new flash.filters.GlowFilter(0x9654AB, 0.6, 8,8,3),
			];
			register(p);
		}
	}

	public function text(e:Entity, txt:String) {
		var p = new mt.deepnight.Particle(e.xx, e.yy);

		var tf = Assets.createField(txt, 0xFFFFFF, 10, "tiny");
		var bmp = Lib.flatten(tf, 8);
		var bd = bmp.bitmapData;
		bmp.bitmapData = null;
		bd.applyFilter(bd, bd.rect, pt0, new flash.filters.GlowFilter(0xFFFFFF,0.2, 8,8,2));
		p.useBitmapData(bd, true);
		p.onUpdate = function() {
			p.setPos(Std.int(e.xx), Std.int(e.yy-10));
		}
		p.life = 10 + txt.length*3;
		register(p);
	}


	public function flashBang(col:Int, alpha:Float, fadeSpeed:Float) {
		var bd = new flash.display.BitmapData(32,32, true, Color.addAlphaF(col,alpha));
		var bmp = new flash.display.Bitmap(bd);
		bmp.width = game.buffer.width;
		bmp.height = game.buffer.height;
		game.buffer.dm.add(bmp, Const.DP_FX);
		var p = game.createTinyProcess();
		p.onUpdate = function() {
			bmp.alpha-=fadeSpeed;
			if( bmp.alpha<=0 ) {
				bmp.parent.removeChild(bmp);
				bmp.bitmapData.dispose();
				bmp.bitmapData = null;
				bmp = null;
				p.destroy();
			}
		}
	}


	public function money(x,y, v:Int) {
		if( !game.pacman ) {
			var p = new mt.deepnight.Particle(x, y);
			p.drawCircle(6,0xFFBF00, 0.5, false);
			p.ds = -0.03;
			p.life = 2;
			p.filters = [
				new flash.filters.GlowFilter(0xFFBF00, 0.8, 8,8,2),
			];
			register(p, true);
		}

		var p = new mt.deepnight.Particle(x,y);
		p.maxAlpha =
			if( v>=500 ) 1
			else if( v>=500 ) 0.75;
			else 0.6;

		var tf = Assets.createField(Std.string(v), 0xFFFF00, 10, "tiny");
		var bmp = Lib.flatten(tf, 8);
		var bd = bmp.bitmapData;
		bmp.bitmapData = null;
		p.dy = -4;
		p.frict = 0.8;
		bd.applyFilter(bd, bd.rect, pt0, new flash.filters.GlowFilter(0xFF8000,0.5, 8,8,2));
		p.useBitmapData(bd, true);
		register(p, true);
	}


	public function trail(e:en.Car, col:Int) {
		var a = MLib.toRad(e.spr.rotation);
		var p = new mt.deepnight.Particle(e.xx, e.yy+1);
		p.drawBox(8,3, col, 0.1);
		p.rotation = e.spr.rotation;
		p.filters = [ new flash.filters.BlurFilter(4,4) ];
		p.fadeOutSpeed = 0.025;
		p.life = 10;
		register(p, true);
	}

	public function cherryTrail(e:en.Car) {
		var col = Color.makeColorHsl((game.time%30)/30, 1, 1);
		var a = MLib.toRad(e.spr.rotation);
		var p = new mt.deepnight.Particle(e.xx, e.yy+1);
		p.drawBox(8,3, col, 0.3);
		p.rotation = e.spr.rotation;
		p.filters = [ new flash.filters.BlurFilter(4,4) ];
		p.fadeOutSpeed = 0.025;
		p.life = 10;
		register(p, true);
	}

	public function sparks(x,y) {
		var p = new mt.deepnight.Particle(x+rnd(0,2,true), y+rnd(0,2,true));
		p.drawBox(1,1, 0xFFFF80, rnd(0.3, 0.7));
		p.dx = rnd(0, 0.5, true);
		p.dy = -rnd(0,1);
		p.gy = 0.1;
		p.groundY = y;
		p.frict = 0.9;
		p.life = rnd(10,30);
		p.filters = [
			new flash.filters.GlowFilter(0xFF6C00,rnd(0.3,0.7), 4,4,4),
		];
		register(p,true);
	}

	public function update() {
		Particle.update();
	}
}
