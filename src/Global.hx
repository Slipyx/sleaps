package;

class Global {
	// uniform best fit integer scale based on scene dims
	public static var SCALE(get, never): Int;
	static inline function get_SCALE() {
		return int(M.max( 1, M.min(
			M.floor( Game.ME.window.width / G.SCNW ),
			M.floor( Game.ME.window.height / G.SCNH ) ) ));
	}

	// FPS
	public static final FPS = 60;
	public static final FIXED_FPS = 30;

	// virtual scene dims
	public static final SCNW = 320;
	public static final SCNH = 180;

	// layers
	static var _li = 0;
	public static final LAYER_BG = _li++;
	public static final LAYER_BG_FX = _li++;
	public static final LAYER_MAIN = _li++;
	public static final LAYER_FG = _li++;
	public static final LAYER_FG_FX = _li++;
	public static final LAYER_TOP = _li++;
	public static final LAYER_UI = _li++;

	// random
	public static var rand: Rand;
}
