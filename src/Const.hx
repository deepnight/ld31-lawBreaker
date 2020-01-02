class Const { //}
	public static var WID = Std.int(flash.Lib.current.stage.stageWidth);
	public static var HEI = Std.int(flash.Lib.current.stage.stageHeight);
	public static var UPSCALE = 2;
	public static var GRID = 13;
	public static var FPS = 30;
	public static function seconds(v:Float) return Std.int(v*FPS);

	private static var uniq = 0;
	public static var DP_BG = uniq++;
	public static var DP_ITEM = uniq++;
	public static var DP_BG_FX = uniq++;
	public static var DP_CARSIDE = uniq++;
	public static var DP_CAR = uniq++;
	public static var DP_PEDESTRIAN = uniq++;
	public static var DP_SKY = uniq++;
	public static var DP_FX = uniq++;
	public static var DP_INTERF = uniq++;
	public static var DP_LOGO = uniq++;
}
