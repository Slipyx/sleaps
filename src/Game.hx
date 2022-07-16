package;

class Game extends hxd.App {
	public static var ME(default, null): Game;
	var appRoot: Layers;
	public var root: Layers;
	// layer that gets moved with camera
	public var scroller: Layers;
	// static ui layer
	public var uiRoot: Layers;

	public var window(get, null): hxd.Window;
	inline function get_window() return hxd.Window.getInstance();

	// timing
	// fixed update tmod accumulator
	var fixedAccum = 0.0;
	public var tmod(default, null): Float;
	public var fixedTmod(get, null): Float;
	inline function get_fixedTmod() return G.FPS / G.FIXED_FPS;
	// frame count
	public var ftime(default, null): Float;
	// seconds count
	public var stime(get, never): Float;
	inline function get_stime() return ftime / G.FPS;
	public var fixedAlpha(default, null): Float;

	// scene relative world mouse position
	public var mouseX(default, null): Float;
	public var mouseY(default, null): Float;
	// screen relative mouse pos
	public var scrMouseX(default, null): Float;
	public var scrMouseY(default, null): Float;

	// cam world pixel location
	public var camLocation: Point;

	public var defaultTile(default, null): Tile;
	var blurFilter: h2d.filter.Blur;
	var crtShader: CrtShader;

	// blah
	var level: Level;
	var tf: h2d.Text;
	var ogCursorBMP: hxd.BitmapData;
	//var scCursor: hxd.Cursor;

	public function new() {
		super();
		ME = this;
		ftime = 0;
		tmod = 1;
	}

	override function init() {
		super.init();
		trace( ':: Game.init ::' );

		G.rand = new lib.Rand( Std.random( 0x7fffffff ) );
		#if hl hl.Gc.enable( true ); #end

		hxd.Timer.smoothFactor = 0.4;
		engine.backgroundColor = 0xFF101020;

		engine.fullScreen = false;
		window.vsync = true;
		hxd.Timer.wantedFPS = G.FPS;

		// app root layer and filters
		appRoot = new Layers( s2d );
		blurFilter = new h2d.filter.Blur( 2, 1, 1, 0 );
		crtShader = new CrtShader();
		s2d.filter = new h2d.filter.Shader( crtShader );
		appRoot.filter = blurFilter;
		// game root layer
		root = new Layers();
		appRoot.add( root, G.LAYER_BG );
		// game scroller layer
		scroller = new Layers();
		root.add( scroller, G.LAYER_BG );
		//scroller.filter = new h2d.filter.Nothing();
		// ui root layer
		uiRoot = new Layers();
		root.add( uiRoot, G.LAYER_UI );
		//uiRoot.filter = new h2d.filter.Nothing();

		// cursor
		ogCursorBMP = Res.cursor.toBitmap();
		// callback to set native cursor to custom scaled one (doesnt work everywhere)
		hxd.System.setCursor = function(cur:hxd.Cursor) {
			var sccbm = new hxd.BitmapData( ogCursorBMP.width*G.SCALE, ogCursorBMP.height*G.SCALE );
			try {
			sccbm.drawScaled( 0, 0, sccbm.width, sccbm.height,
				ogCursorBMP, 0, 0, ogCursorBMP.width, ogCursorBMP.height, None, false );
			hxd.System.setNativeCursor( Custom(
				new hxd.Cursor.CustomCursor( [G.SCALE > 1 ? sccbm : ogCursorBMP], 0, 0, 0 )) );
			} catch ( e ) {
				trace( e.message );
			}
		}

		// event callbacks
		window.addEventTarget( onEvent );
		window.addResizeEvent( onResize );
		window.onClose = onClose;
		onResize();

		// debug text
		var fnt = Res.font1.toFont();
		tf = new h2d.Text( fnt );
		tf.filter = new h2d.filter.Outline( 0.5 );
		tf.setScale(2);
		tf.x = tf.y = 1;
		s2d.add( tf );
		tf.text = 'hello there world!';

		defaultTile = Tile.fromColor( 0xffff00ff, 8, 8 );
		defaultTile.setCenterRatio();
		camLocation = new Point( 0, 0 );

		// initial level
		level = new Level();

		hxd.Timer.skip();
	}

	override function onResize() {
		super.onResize();
		var b = int((G.SCALE-1) * 0.5);
		blurFilter.radius = b;
		crtShader.size.x = window.width;
		crtShader.size.y = window.height;
		crtShader.scale = G.SCALE;
		//appRoot.filter = null;
		// update scaled cursor
		hxd.System.setCursor( Default );
		trace( 'onResize: ${window.width} x ${window.height}, SCALE: ${G.SCALE}, blur: $b' );
	}

	override function loadAssets( onDone: Void -> Void ) {
		trace( ':: Game.loadAssets ::' );
		#if usePak
			//new hxd.fmt.pak.Loader( s2d, onDone );
			onDone();
		#else
			onDone();
		#end
	}

	var lastwinsz = [0,0];
	function onEvent( e: hxd.Event ) {
		if ( e.kind == EKeyDown ) {
			switch ( e.keyCode ) {
				case Key.F: {
					// toggle fullscreen
					// remember last windowed size to revert to
					if ( engine.fullScreen == false ) {
						lastwinsz[0] = window.width;
						lastwinsz[1] = window.height;
					}
					engine.fullScreen = !engine.fullScreen;
					if ( engine.fullScreen == false )
						window.resize( lastwinsz[0], lastwinsz[1] );
				}
			}
		}
	}

	var tfup: Float = 0;
	function fixedUpdate() {
		level.onFixedUpdate();

		tfup += fixedTmod;
		if ( tfup > 3 ) {
			tf.text = 'FPS: ${int(hxd.Timer.fps())} DC: ${engine.drawCalls}\n'+
			#if hl
				'VM: ${int(hl.Gc.stats().currentMemory/1048576.0)}MB\n'+
			#end
				'GPU: ${int(engine.mem.stats().totalMemory/1048576.0)}MB';

			var p: actors.Player =null;
			for(a in level.allActors(actors.Player)){p=cast a;break;}
			if ( p != null )
				tf.text += '\np:${p.cellLocation},${p.cellRatio}\nv:${p.velocity}\nlf:${int(p.life)}';
			
			tfup = 0;
		}
	}

	override function update( dt: Float ) {
		super.update( dt );

		tmod = hxd.Timer.tmod;
		ftime += tmod;

		// preupdate
		level.onPreUpdate();
		// update
		level.onUpdate();
		// fixed
		fixedAccum += tmod;
		while ( fixedAccum >= fixedTmod ) {
			fixedUpdate();
			fixedAccum -= fixedTmod;
		}
		fixedAlpha = fixedAccum / fixedTmod;
		// post
		level.onPostUpdate();

		// cam
		var wnd = window;
		var gScale = G.SCALE;

		// update cam
		//camLocation.x += 0.05 * tmod;

		// post update apply cam
		var camW: Int = M.ceil( wnd.width / gScale );
		var camH: Int = M.ceil( wnd.height / gScale );
		scroller.x = -camLocation.x + camW * 0.5;
		scroller.y = -camLocation.y + camH * 0.5;
		scroller.x *= gScale;
		scroller.y *= gScale;
		scroller.x = M.round( scroller.x );
		scroller.y = M.round( scroller.y );

		// update world mouse pos
		mouseX = (wnd.mouseX / gScale) - scroller.x / gScale;
		mouseY = (wnd.mouseY / gScale) - scroller.y / gScale;
		// screen mouse (scn)
		scrMouseX = (wnd.mouseX / gScale);
		scrMouseY = (wnd.mouseY / gScale);

		// sort actors by y pos
		scroller.ysort( G.LAYER_MAIN );
		// update layer scaling
		scroller.setScale( gScale );
		uiRoot.setScale( gScale );
	}

	override function render( e: h3d.Engine ) {
		/*engine.pushTarget( rt );
		engine.clear( 0xFF202040, 1 );
		scn2d.render( e );
		scnUI.render( e );
		engine.popTarget();*/

		s3d.render( e );
		s2d.render( e );
	}

	function onClose(): Bool {
		trace( 'FIN' );
		level.destroy();
		return true;
	}

	static function main() {
		trace( 'welcome!' );

		try {
			#if usePak
				Res.initPak();
			#elseif js
				Res.initEmbed();
			#else
				Res.initLocal();
			#end
		} catch ( e ) {
			trace( e );
		}

		new Game();
	}
}

interface IUpdater {
	function onPreUpdate(): Void;
	function onUpdate(): Void;
	function onFixedUpdate(): Void;
	function onPostUpdate(): Void;
}
