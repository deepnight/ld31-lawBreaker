package en;

import mt.deepnight.Lib;
import mt.MLib;
import mt.deepnight.slb.*;

class Walker extends Entity {
	public static var ALL : Array<Walker> = [];
	static var COMBO = 0;
	static var COMBO_TIMER = 0.;

	public var leader			: Null<Walker>;
	var dir					: Int;

	public var lasts			: Array<{ cx:Int, cy:Int }>;
	public var tx				: Float;
	public var ty				: Float;
	//public var tcx				: Int;
	//public var tcy				: Int;

	public function new(x,y, ?lead:Walker) {
		super();

		leader = lead;
		ALL.push(this);
		dir = 1;

		lasts = [];
		setPosCase(x,y);
		physics = false;
		repels = false;
		speed = 0.01;
		tx = xx;
		ty = yy;

		Game.ME.buffer.dm.add(spr, Const.DP_PEDESTRIAN);
		spr.a.playAndLoop("gouranga");
		spr.a.unsync();
		spr.a.setGeneralSpeed(0.2);
		spr.setCenter(0.5, 0.5);

		updateCoords();
	}

	override function unregister() {
		super.unregister();
		ALL.remove(this);
	}

	override function updateCoords() {
		super.updateCoords();
		if( dx<-0.001 ) dir = -1;
		if( dx>0.001 ) dir = 1;
		spr.scaleX = MLib.fabs(spr.scaleX)*dir;
	}

	//function getSubPosition(dir:Int) {
		//return
			//if( dir==1 ) { xr:0.5, yr:0.75 }
			//else if( dir==3 ) { xr:0.5, yr:0.25 }
			//else if( dir==0 ) { xr:0.75, yr:0.5 }
			//else { xr:0.25, yr:0.5 }
	//}

	function visitedRecently(x,y) {
		for(pt in lasts)
			if( pt.cx==x && pt.cy==y )
				return true;
		return false;
	}

	override function update() {
		super.update();

		var h = Game.ME.hero;

		var boost = 1.;
		if( leader==null ) {
			if( Lib.distanceSqr(xx,yy, tx,ty)<=3*3 ) {
				var city = Game.ME.city;
				var nexts = [];
				if( !city.hasCollision(cx-1,cy) && !visitedRecently(cx-1,cy) ) nexts.push({ cx:cx-1, cy:cy });
				if( !city.hasCollision(cx+1,cy) && !visitedRecently(cx+1,cy) ) nexts.push({ cx:cx+1, cy:cy });
				if( !city.hasCollision(cx,cy-1) && !visitedRecently(cx,cy-1) ) nexts.push({ cx:cx, cy:cy-1 });
				if( !city.hasCollision(cx,cy+1) && !visitedRecently(cx,cy+1)  ) nexts.push({ cx:cx, cy:cy+1 });

				var pt = nexts[Std.random(nexts.length)];
				if( pt!=null ) {
					tx = ( pt.cx+rnd(0.2, 0.8) ) * Const.GRID;
					ty = ( pt.cy+rnd(0.1, 0.8) ) * Const.GRID;
					lasts.push({ cx:cx, cy:cy });
					while( lasts.length>5 )
						lasts.shift();
				}
				else {
					lasts = [];
				}
			}
		}
		else {
			tx = leader.xx;
			ty = leader.yy;

			if( Lib.distanceSqr(xx,yy, tx,ty)<=3*3 )
				cd.set("wait", rnd(1,6));

			if( Lib.distanceSqr(xx,yy, tx,ty)>8*8 )
				boost = 1.5;


			if( leader.destroyAsked )
				leader = null;
			lasts = [];
		}


		if( !cd.has("wait") ) {
			var a = Math.atan2(ty-yy, tx-xx);
			dx+=Math.cos(a)*speed*boost;
			dy+=Math.sin(a)*speed*boost;
		}

		if( !destroyAsked && !h.isWalking() && distSqr(h)<=5*5 && h.car.canLeave() ) {
			mt.flash.Sfx.playOne([ Assets.SBANK.gouranga0, Assets.SBANK.gouranga1, Assets.SBANK.gouranga2, Assets.SBANK.gouranga3 ]);
			var bmp = new flash.display.Bitmap( Assets.tiles.getBitmapData("blood") );
			bmp.x = xx-bmp.width*0.5;
			bmp.y = yy-bmp.height*0.5;
			bmp.scaleX = rnd(0.7, 1.1);
			bmp.scaleY = rnd(0.7, 1.1);
			bmp.alpha = rnd(0.7, 1);
			bmp.rotation = rnd(0,20,true);
			Game.ME.city.bg.bitmapData.draw(bmp, bmp.transform.matrix, bmp.transform.colorTransform);
			bmp.bitmapData.dispose();
			bmp.bitmapData = null;

			Game.ME.gainMoney(this,10);

			if( time-COMBO_TIMER<=#if debug 90 #else 15 #end )
				COMBO++;
			else
				COMBO = 0;
			if( COMBO>=6 )  {
				COMBO = 0;
				Fx.ME.flashBang(0xF38914, 0.5, 0.01);
				for(e in en.c.Cop.ALL) {
					e.cd.set("alarm", Const.seconds(5));
					e.setAlarm(false);
				}
				h.life = h.maxLife;
				Game.ME.gainMoney(this,5000);
				new ui.Notification("GOURANGA!!!");
			}

			COMBO_TIMER = time;
			destroy();
		}
	}
}

