package ui;

import mt.deepnight.slb.*;
import mt.MLib;

class Infos extends mt.deepnight.FProcess {
	public var money		: flash.text.TextField;
	public var high			: flash.text.TextField;
	var shields				: Array<BSprite>;
	var hearts				: Array<BSprite>;

	var m					: Float;

	public function new() {
		super(Game.ME);
		Game.ME.buffer.dm.add(root, Const.DP_INTERF);
		m = Game.ME.money;

		shields = [];
		hearts = [];

		money = Assets.createField("???", 0xFFFF00);
		root.addChild(money);
		money.width = 50;
		money.filters = [
			new flash.filters.GlowFilter(0x0,1, 2,2,4),
		];

		high = Assets.createField("???", 0x9BBBE1, 10, "tiny");
		root.addChild(high);
		high.width = 100;
		high.filters = [
			new flash.filters.GlowFilter(0x0,1, 2,2,4),
		];
	}

	public function updateInfos() {
		var g = Game.ME;

		for(s in hearts) s.dispose();
		hearts = [];
		for( i in 0...g.hero.life ) {
			var s = Assets.tiles.get("heart");
			root.addChild(s);
			hearts.push(s);
			s.setCenter(1,1);
			s.x = g.buffer.width-i*8;
			s.y = g.buffer.height-8;
		}

		for(s in shields) s.dispose();
		shields = [];
		var c = g.hero.car;
		if( c!=null ) {
			for( i in 0...MLib.min(20, c.life) ) {
				var s = Assets.tiles.get("shield");
				root.addChild(s);
				shields.push(s);
				s.setCenter(1,1);
				s.x = g.buffer.width-i*7;
				s.y = g.buffer.height;
			}
			if( c.life>20 )
				shields[shields.length-1].set("shieldPlus");
		}

		var moneyChange = Std.int(m)!=g.money;
		if( moneyChange ) {
			var a = tw.create(m, g.money, 300);
			a.onUpdateT = function(t) {
				money.text = "$"+Std.int(m);
				money.x = g.buffer.width-money.textWidth-5;
				money.y = Std.int( g.buffer.height-money.textHeight-16 + (t==1 ? 0 : Math.cos(time*0.6)*2) );
			}
		}
		else
			money.text = "$"+g.money;
		money.x = g.buffer.width-money.textWidth-5;
		money.y = Std.int( g.buffer.height-money.textHeight-16 );
		money.parent.addChild(money);

		high.visible = Game.ME.phase!=P_Intro;
		high.text = "Highscore: $"+Game.ME.highScores[Game.ME.pacman?1:0];
		high.y = Std.int(g.buffer.height-high.textHeight - 2 );
	}

	override function unregister() {
		super.unregister();

		for(s in shields) s.dispose();
		shields = null;

		high = null;
		money = null;
	}
}