package;

class Player extends Actor {
	var frames: Array<Tile>;
	var fi: Float;

	var g: h2d.Graphics;
	var g2: h2d.Graphics;
	// current, target forward dir
	var cfwd: Point;
	var tfwd: Point;
	var tps = 5; // 5
	var afps = 6; // 6

	public function new() {
		super();

		for ( a in level.allActors( ) ) {
			trace( '${$type(a)}, ${a.tag}' );
		}

		trace( 'New player! ${location}' );
		cfwd = new Point(1,0);
		tfwd = new Point(1,0);

		spr.tile = Res.pchar.toTile();
		//spr.t = Tile.autoCut( Res.char.toBitmap(), 16, 16 ).main;
		//be.t.setCenterRatio();
		frames = new Array<Tile>();
		for ( y in 0...4 )
			for ( x in 0...4 ) {
				frames.push( spr.tile.sub( x*16,y*32,16,32, -8,-24 ) );
			}
		fi = 0;

		friction = 0.72;
		// snap cam to spawn
		game.camLocation.x = spr.x;
		game.camLocation.y = spr.y;

		// bounds
		g = new h2d.Graphics( spr );
		g.lineStyle( 0.5, 0x00ff00, 1 );
		g.drawRect( -8 , -8, 16, 16 );
		g.lineStyle( 0.5, 0xff0000, 1 );
		g.drawCircle( 0, 0, radius );
		// cur fwd dir
		g2 = new h2d.Graphics( spr );
		g2.beginFill( 0x0000ff );
		g2.drawRect( radius, -1, 8, 2 );
		g2.endFill();
		trace( 'Player init!' );
	}

	override function onPreStepX() {
		super.onPreStepX();
		var curcol = level.getCollision( cellLocation.x, cellLocation.y );
		var cx = cellLocation.x;
		var cy = cellLocation.y;

		// right blocked
		if ( cellRatio.x > 0.55 ) {
			var rightcol = level.getCollision( cx+1, cy );
			if ( rightcol == Col_Solid || curcol == Col_Right || rightcol == Col_Left ) {
				cellRatio.x = 0.55;
			}
		}

		// left blocked
		if ( cellRatio.x < 0.45 ) {
			var leftcol = level.getCollision( cx-1, cy );
			if ( leftcol == Col_Solid || curcol == Col_Left || leftcol == Col_Right ) {
				cellRatio.x = 0.45;
			}
		}
	}

	override function onPreStepY() {
		super.onPreStepY();
		var curcol = level.getCollision( cellLocation.x, cellLocation.y );
		var cx = cellLocation.x;
		var cy = cellLocation.y;

		// bottom blocked
		if ( cellRatio.y > 0.55 ) {
			var bottomcol = level.getCollision( cx, cy+1 );
			if ( bottomcol == Col_Solid || curcol == Col_Bottom || bottomcol == Col_Top ) {
				cellRatio.y = 0.55;
			}
		}
		// top blocked
		if ( cellRatio.y < 0.45 ) {
			var topcol = level.getCollision( cx, cy-1 );
			if ( topcol == Col_Solid || curcol == Col_Top || topcol == Col_Bottom ) {
				cellRatio.y = 0.45;
			}
		}
	}

	override function onUpdate() {
		super.onUpdate();

		game.camLocation.x = M.lerp( game.camLocation.x, spr.x, 0.33 );
		game.camLocation.y = M.lerp( game.camLocation.y, spr.y, 0.33 );
	}

	var mvspd: Point = new Point(); // requested move dir
	override function onPreUpdate() {
		super.onPreUpdate();

		// movement vector based on screen mouse pos distance from center of window
		var m = new Point( game.scrMouseX, game.scrMouseY );
		var wnd = game.window;
		var gscale = G.SCALE;
		var scrc = new Point( wnd.width/gscale/2.0, wnd.height/gscale/2.0 );

		mvspd.set();
		if ( Key.isDown( Key.MOUSE_LEFT ) ) {
			var dst = m.distanceSq( scrc );
			if ( dst > 0 ) {
				tfwd.x = m.x - scrc.x;
				tfwd.y = m.y - scrc.y;
				tfwd.normalize();
				cfwd.lerp( cfwd, tfwd, 0.45 );
				cfwd.normalize();
				g2.rotation = M.atan2( cfwd.y, cfwd.x );
			}
			mvspd.load( cfwd );
		}
	}

	override function onFixedUpdate() {
		super.onFixedUpdate();

		if ( mvspd.lengthSq() > 0 ) {
			// dont ask
			velocity.x += mvspd.x * (1.0 / G.FIXED_FPS / 5 * 1.4) * tps;
			velocity.y += mvspd.y * (1.0 / G.FIXED_FPS / 5 * 1.4) * tps;
		}
	}

	var afwd = true;
	var astart = 0;
	override function onPostUpdate() {
		super.onPostUpdate();

		var qang = (M.PI / 4.0);
		var ang = M.atan2( cfwd.y, cfwd.x );
		if ( ang > (-qang) && ang < (qang) ) { // right
			if ( astart != 4 ) fi = 4;
			astart = 4;
		}
		if ( ang > (qang) && ang < (qang * 3) ) { // down
			if ( astart != 0 ) fi = 0;
			astart = 0;
		}
		if ( ang > (-qang * 3) && ang < (-qang) ) { // up
			if ( astart != 8 ) fi = 8;
			astart = 8;
		}
		if ( ang > (qang * 3) || ang < (-qang * 3) ) { // left
			if ( astart != 12 ) fi = 12;
			astart = 12;
		}

		var arate = afps / G.FPS * game.tmod; // fps
		if ( velocity.length() <= 0.01 ) {arate = 0; fi = astart;}
		// frame start and end
		var aframes = 4;
		var aend = astart + aframes-1;
		// loop
		fi += arate;
		if ( fi >= aend + 1 ) fi = astart;
		// pong
		/*if ( afwd ) {
			fi += arate;
			if ( fi >= aend + 1 ) { fi = aend; afwd = false; }
		} else {
			fi -= arate;
			if ( fi <= astart ) { fi = astart + 1; afwd = true; }
		}*/

		spr.tile = frames[int(fi)];
	}

	override function onDestroyed() {
		trace( 'Player destroyed!' );
		frames = null;
		super.onDestroyed();
	}
}
