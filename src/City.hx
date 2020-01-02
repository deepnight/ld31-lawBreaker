import mt.MLib;
import mt.deepnight.slb.*;
import mt.deepnight.Lib;
import mt.deepnight.Color;
import flash.display.Sprite;
import flash.display.Bitmap;
import flash.display.BitmapData;

class CityCell {
	public var collides		: Bool;
	public var isRoad		: Bool;
	public function new() {
		collides = false;
		isRoad = false;
	}
}

class City extends mt.deepnight.FProcess {
	public var wid			: Int;
	public var hei			: Int;

	public var map			: Array<Array<CityCell>>;
	public var spots		: Map<String, Array<{cx:Int, cy:Int}>>;
	public var pf			: mt.deepnight.PathFinder;

	public var bg			: Bitmap;

	public var trafficLights: Array<{ /*spr:BSprite,*/ cx:Int, cy:Int, state:Int, timer:Int }>;

	public function new() {
		super(Game.ME);
		spots = new Map();
		trafficLights = [];

		var source = Assets.tiles.getBitmapData("map");
		wid = Std.int(source.width);
		hei = Std.int(source.height);

		pf = new mt.deepnight.PathFinder(wid,hei);

		map = [];
		for(cx in 0...wid) {
			map[cx] = [];
			for( cy in 0...hei ) {
				map[cx][cy] = new CityCell();
			}
		}

		for(cx in 0...wid)
			for( cy in 0...hei ) {
				var p = source.getPixel(cx,cy);
				switch( p ) {
					case 0x0 :
						map[cx][cy].isRoad = true;

					case 0x006500 :
						addSpot("park", cx,cy);

					case 0xFFFFFF :
						map[cx][cy].collides = true;

					case 0xFF00FF:
						map[cx][cy].collides = true;
						addSpot("rstar", cx,cy);

					case 0x00FF00 :
						addSpot("start", cx,cy);
						map[cx][cy].isRoad = true;

					case 0xFF0000 :
						addSpot("debug", cx,cy);
						map[cx][cy].isRoad = true;
				}
				if( isRoad(cx,cy) )
					addSpot("road", cx,cy);
			}

		for(cx in 0...wid)
			for( cy in 0...hei ) {
				if( hasCollision(cx,cy) )
					pf.setCollision(cx,cy);

				if( !isRoad(cx,cy) )
					continue;

				var roads =
					( isRoad(cx-1, cy)?1:0 ) +
					( isRoad(cx+1, cy)?1:0 ) +
					( isRoad(cx, cy-1)?1:0 ) +
					( isRoad(cx, cy+1)?1:0 );
				if( roads>2 ) {
					addSpot("crossRoad", cx,cy);
					trafficLights.push({ /*spr:null,*/ cx:cx, cy:cy, state:0, timer:Std.random(30) });
				}
				else
					addSpot("spawn", cx,cy);
			}

		source.dispose();

		bg = new flash.display.Bitmap( new flash.display.BitmapData(wid*Const.GRID, hei*Const.GRID, false, 0x0) );
		Game.ME.buffer.dm.add(bg, Const.DP_BG);

		redraw();
	}

	public function getRandomSpots(k:String, n:Int, avoidX:Int, avoidY:Int, minDist=4) {
		var spots = getSpots(k).copy();
		var existing = [ {cx:avoidX, cy:avoidY} ];
		var d2 = minDist*minDist;
		var a = [];
		while( n>0 ) {
			var pt = spots.splice(Std.random(spots.length),1)[0];
			if( pt==null ) {
				#if debug
				trace("failed "+k+" x"+n);
				#end
				break;
			}
			var close = false;
			for( e in existing )
				if( Lib.distanceSqr(pt.cx, pt.cy, e.cx, e.cy)<=d2 ) {
					close = true;
					break;
				}

			if( !close ) {
				existing.push(pt);
				a.push(pt);
				n--;
			}
		}

		existing = null;
		return a;
	}

	public inline function isValidCoord(cx,cy) {
		return cx>=0 && cx<wid && cy>=0 && cy<hei;
	}

	public function hasCollisionPixel(x:Float,y:Float) {
		return hasCollision(Std.int(x/Const.GRID), Std.int(y/Const.GRID));
	}

	public function hasCollision(cx,cy) {
		return getCell(cx,cy).collides;
	}

	public function isRoad(cx,cy) {
		return getCell(cx,cy).isRoad;
	}

	public function getCell(cx,cy) {
		if( isValidCoord(cx,cy) )
			return map[cx][cy];
		else {
			var c = new CityCell();
			c.collides = true;
			c.isRoad = false;
			return c;
		}
	}

	public function addSpot(k,cx,cy) {
		if( !spots.exists(k) )
			spots.set(k, []);
		spots.get(k).push({ cx:cx, cy:cy });
	}

	public function getSpots(k) {
		return spots.exists(k) ? spots.get(k) : [];
	}

	public function hasSpot(k, cx,cy) {
		for(pt in getSpots(k))
			if( pt.cx==cx && pt.cy==cy )
				return true;
		return false;
	}

	public function redraw() {
		var tiles = Assets.tiles;
		var bd = bg.bitmapData;
		bd.fillRect( bd.rect, 0 );

		var rbd = new flash.display.BitmapData(bd.width, bd.height, true, 0x0);
		var lbd = rbd.clone();
		var inner = rbd.clone();
		var bbd = rbd.clone();
		var specials = rbd.clone();

		//for( t in trafficLights ) {
			//if( t.spr!=null )
				//t.spr.destroy();
			//var s = tiles.get("trafficH");
			//Game.ME.buffer.dm.add(s, Const.DP_BG);
			//s.x = t.cx*Const.GRID;
			//s.y = t.cy*Const.GRID;
			//s.setPivotCoord(13,13);
			//s.blendMode = ADD;
			//t.spr = s;
		//}

		for(cx in 0...wid)
			for( cy in 0...hei ) {
				var x = cx*Const.GRID;
				var y = cy*Const.GRID;
				if( hasCollision(cx,cy) ) {
					if( hasCollision(cx,cy+1) )
						tiles.drawIntoBitmapRandom(inner, x,y, "road");
					else {
						if( hasCollision(cx,cy-1) ) {
							tiles.drawIntoBitmapRandom(bd, x,y, "road");
							tiles.drawIntoBitmapRandom(inner, x,y-5, "road");
							tiles.drawIntoBitmapRandom(bbd, x,y, "buildingFront");
						}
						else {
							tiles.drawIntoBitmapRandom(bd, x,y, "grass");
							tiles.drawIntoBitmapRandom(specials, x,y-2, "buildingSolo");
						}
					}
					//else
						//bd.fillRect( new flash.geom.Rectangle(cx*Const.GRID, cy*Const.GRID, Const.GRID, Const.GRID), alpha(0x934E2D) );
				}

				if( isRoad(cx,cy) )
					tiles.drawIntoBitmapRandom(rbd, x,y, "road");

				if( isRoad(cx,cy) ) {
					//if( Std.random(100)<40 ) {
						//if( hasCollision(cx,cy-1) )
							//tiles.drawIntoBitmap(lbd, x+Const.GRID*0.5, y-1, "light", 0.5,0.5);
						//if( hasCollision(cx,cy+1) )
							//tiles.drawIntoBitmap(lbd, x,y-Const.GRID*0.4, "light", 0.5, 0.5);
					//}

					var n =
						( isRoad(cx-1, cy)?1:0 ) +
						( isRoad(cx+1, cy)?1:0 ) +
						( isRoad(cx, cy-1)?1:0 ) +
						( isRoad(cx, cy+1)?1:0 );
					if( n<=2 ) {
						if( isRoad(cx,cy-1) )
							tiles.drawIntoBitmap(rbd, x,y, "roadLine", 0);

						if( isRoad(cx,cy+1) )
							tiles.drawIntoBitmap(rbd, x,y, "roadLine", 2);

						if( isRoad(cx+1,cy) )
							tiles.drawIntoBitmap(rbd, x,y, "roadLine", 1);

						if( isRoad(cx-1,cy) )
							tiles.drawIntoBitmap(rbd, x,y, "roadLine", 3);
					}
					else {
						if( isRoad(cx,cy-1) )
							tiles.drawIntoBitmap(rbd, x,y, "roadStop", 0);

						if( isRoad(cx,cy+1) )
							tiles.drawIntoBitmap(rbd, x,y, "roadStop", 2);

						if( isRoad(cx+1,cy) )
							tiles.drawIntoBitmap(rbd, x,y, "roadStop", 1);

						if( isRoad(cx-1,cy) )
							tiles.drawIntoBitmap(rbd, x,y, "roadStop", 3);
					}
				}
			}

		for(pt in getSpots("park"))
			tiles.drawIntoBitmapRandom(bd, pt.cx*Const.GRID, pt.cy*Const.GRID, "grass");


		var border = 0x81574B;
		var col = 0x653932;
		inner.applyFilter(inner, inner.rect, pt0, Color.getColorizeFilter(col, 1,0));
		inner.applyFilter(inner, inner.rect, pt0, new flash.filters.GlowFilter(0x0,0.5, 4,4,2, 1,true));
		inner.applyFilter(inner, inner.rect, pt0, new flash.filters.DropShadowFilter(2, 90, 0x0,0.1, 0,0,1, 1,true));
		inner.applyFilter(inner, inner.rect, pt0, new flash.filters.GlowFilter(border,1, 2,2,8, 1,true));
		//inner.applyFilter(inner, inner.rect, pt0, new flash.filters.DropShadowFilter(4, -90, 0x2f323c,1, 0,0,1, 1,true));
		//inner.draw(bbd, flash.display.BlendMode.ERASE);

		bbd.applyFilter(bbd, bbd.rect, pt0, new flash.filters.DropShadowFilter(1,-90, Color.brightnessInt(border,0.1),1, 0,0,1) );
		bbd.applyFilter(bbd, bbd.rect, pt0, new flash.filters.DropShadowFilter(1,-90, 0x0,0.2, 4,8,1) );

		inner.copyPixels(bbd, bbd.rect, new flash.geom.Point(0,0), true);
		inner.applyFilter(inner, inner.rect, pt0, new flash.filters.GlowFilter(0x0, 0.3, 2,2,4));
		inner.applyFilter(inner, inner.rect, pt0, new flash.filters.DropShadowFilter(6, -30, 0x0,0.3, 0,0,1));

		//var c = 0x596279;
		//bbd.applyFilter(bbd, bbd.rect, pt0, Color.getColorizeFilter(c, 1, 0));
		//bbd.applyFilter(bbd, bbd.rect, pt0, new flash.filters.GlowFilter(0xffffff,0.05, 2,2,8, 1,true));
		//bbd.applyFilter(bbd, bbd.rect, pt0, new flash.filters.DropShadowFilter(2, 90, Color.darken(c,0.2),1, 0,0,1) );
		//bbd.applyFilter(bbd, bbd.rect, pt0, new flash.filters.DropShadowFilter(1, 90, Color.darken(c,0.25),1, 0,0,1) );
		//bbd.applyFilter(bbd, bbd.rect, pt0, new flash.filters.GlowFilter(Color.darken(c,0.4),1, 2,2,8));
		//bbd.applyFilter(bbd, bbd.rect, pt0, new flash.filters.GlowFilter(0x0,0.2, 16,16,1, 1,true));
		//bbd.applyFilter(bbd, bbd.rect, pt0, new flash.filters.DropShadowFilter(6, 0, 0x0,0.1, 0,0,1) );

		rbd.applyFilter(rbd, rbd.rect, pt0, new flash.filters.GlowFilter(0x0,0.2, 8,8,1, 1,true));
		rbd.applyFilter(rbd, rbd.rect, pt0, new flash.filters.GlowFilter(0xFFFFFF,0.09, 4,4,15, 1,true));
		//rbd.applyFilter(rbd, rbd.rect, pt0, new flash.filters.DropShadowFilter(3, 60, 0x0,0.1, 4,4,1, 1,true) );

		bd.copyPixels(rbd, rbd.rect, pt0, true);
		bd.copyPixels(inner, inner.rect, pt0, true);
		bd.copyPixels(specials, specials.rect, pt0 , true);
		bd.draw(lbd, flash.display.BlendMode.ADD);

		var bmp = new flash.display.Bitmap( tiles.getBitmapData("rstar") );
		for(pt in getSpots("rstar")) {
			bmp.x = pt.cx*Const.GRID;
			bmp.y = pt.cy*Const.GRID-7;
			bmp.alpha = 0.4;
			bd.draw(bmp, bmp.transform.matrix, bmp.transform.colorTransform, flash.display.BlendMode.OVERLAY);
		}

		bmp.bitmapData.dispose();
		bmp.bitmapData = null;


		var dark = tiles.getBitmapData("dark");
		var m = new flash.geom.Matrix();
		m.scale(bd.width/dark.width, bd.height/dark.height);
		bd.draw(dark, m);
		dark.dispose();

		specials.dispose();
		inner.dispose();
		lbd.dispose();
		rbd.dispose();
		bbd.dispose();
	}


	public function getTrafficLight(cx,cy) {
		for(t in trafficLights)
			if( t.cx==cx && t.cy==cy )
				return t;
		return null;
	}


	override function unregister() {
		super.unregister();

		pf.destroy();
		pf = null;

		map = null;

		bg.bitmapData.dispose();
		bg.bitmapData = null;

		spots = null;
	}


	override function update() {
		super.update();

		for(pt in trafficLights) {
			pt.timer--;
			if( pt.timer<=0 ) {
				pt.state++;
				if( pt.state>3 )
					pt.state = 0;
				pt.timer = pt.state==1 || pt.state==3 ? 10 : 120;
				//pt.spr.set( switch( pt.state ) {
					//case 0 : "trafficH";
					//case 2 : "trafficV";
					//default : "trafficNone";
				//});

				//if( !hasCollision(pt.cx-1, pt.cy) )
					//Fx.ME.marker(pt.cx-1, pt.cy, pt.state==0?0x00FF00:0xFF0000);
//
				//if( !hasCollision(pt.cx+1, pt.cy) )
					//Fx.ME.marker(pt.cx+1, pt.cy, pt.state==0?0x00FF00:0xFF0000);
//
				//if( !hasCollision(pt.cx, pt.cy-1) )
					//Fx.ME.marker(pt.cx, pt.cy-1, pt.state==2?0x00FF00:0xFF0000);
//
				//if( !hasCollision(pt.cx, pt.cy+1) )
					//Fx.ME.marker(pt.cx, pt.cy+1, pt.state==2?0x00FF00:0xFF0000);
			}
		}
	}
}

