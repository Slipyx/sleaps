package actors;

class Player extends Actor {
	// static reference to single player
	public static var ME: Player = null;
	var frames: Array<Tile>;
	var fi: Float;

	var g2: h2d.Graphics;
	var statText: h2d.Text;
	// current, target forward dir
	var cfwd: Point;
	var tfwd: Point;
	var tps = 5; // 5
	var afps = 10; // 6
	var atkCD = 0.0;

	public function new() {
		super();
		ME = this;

		touchActors = true;
		bumpActors = true;
		radius = level.GRID / 2.67;
		friction = 0.72;
		bumpForce = 5e-3;

		trace( 'New player! ${location}' );

		statText = new h2d.Text( game.font0 );
		statText.dropShadow = {dx:1,dy:1,color:0x000000,alpha:1};
		game.uiRoot.add( statText, G.LAYER_UI );
		cfwd = new Point(1,0);
		tfwd = new Point(1,0);
		life = 600;

		spr.tile = Res.pchar.toTile();
		//spr.t = Tile.autoCut( Res.char.toBitmap(), 16, 16 ).main;
		//be.t.setCenterRatio();
		frames = new Array<Tile>();
		for ( y in 0...(int(spr.tile.height/32)) )
			for ( x in 0...(int(spr.tile.width/16)) ) {
				frames.push( spr.tile.sub( x*16,y*32,16,32, -8,-24 ) );
			}
		fi = 0;

		// snap cam to spawn
		game.camLocation.x = spr.x;
		game.camLocation.y = spr.y;

		// cur fwd dir
		g2 = new h2d.Graphics( spr );
		g2.beginFill( 0x0000ff );
		g2.drawRect( radius, -1, 8, 2 );
		g2.endFill();
	}

	override function onBeginPlay() {
		super.onBeginPlay();
		//lifeSpan = 4;
		//takeDamage( 100 );
		spr.removeChildren();
	}

	override function onTouch( other: Actor ) {
		//super.onTouch( other );
		//trace('Player has been touched!');
		//other.destroy();
	}

	override function onBump( other: Actor ) {
		//trace( 'Player has been bumped!' );
	}

	override function onPreStepX() {
		super.onPreStepX();
		var curcol = level.getCollision( cellLocation.x, cellLocation.y );
		var cx = cellLocation.x;
		var cy = cellLocation.y;

		// right blocked
		if ( cellRatio.x > 0.5 ) {
			var rightcol = level.getCollision( cx+1, cy );
			if ( rightcol == Col_Solid || curcol == Col_Right || rightcol == Col_Left ) {
				cellRatio.x = 0.5;
			}
		}

		// left blocked
		if ( cellRatio.x < 0.5 ) {
			var leftcol = level.getCollision( cx-1, cy );
			if ( leftcol == Col_Solid || curcol == Col_Left || leftcol == Col_Right ) {
				cellRatio.x = 0.5;
			}
		}
	}

	override function onPreStepY() {
		super.onPreStepY();
		var curcol = level.getCollision( cellLocation.x, cellLocation.y );
		var cx = cellLocation.x;
		var cy = cellLocation.y;

		// bottom blocked
		if ( cellRatio.y > 0.5 ) {
			var bottomcol = level.getCollision( cx, cy+1 );
			if ( bottomcol == Col_Solid || curcol == Col_Bottom || bottomcol == Col_Top ) {
				cellRatio.y = 0.5;
			}
		}
		// top blocked
		if ( cellRatio.y < 0.5 ) {
			var topcol = level.getCollision( cx, cy-1 );
			if ( topcol == Col_Solid || curcol == Col_Top || topcol == Col_Bottom ) {
				cellRatio.y = 0.5;
			}
		}
	}

	override function onUpdate() {
		super.onUpdate();

		game.camLocation.x = M.lerp( game.camLocation.x, spr.x, 0.33 );
		game.camLocation.y = M.lerp( game.camLocation.y, spr.y, 0.33 );

		// life countdown
		life -= game.dt;
		// attack cooldown
		if ( atkCD > 0 ) atkCD -= game.dt;

		// stat text
		statText.text = 'LIFE ${M.ceil( life )}';
	}

	var mvdir: Point = new Point(); // requested move dir
	override function onPreUpdate() {
		super.onPreUpdate();

		// movement vector based on screen mouse pos distance from center of window
		var m = new Point( game.scrMouseX, game.scrMouseY );
		var wnd = game.window;
		var gscale = G.SCALE;
		var scrc = new Point( wnd.width/gscale/2.0, wnd.height/gscale/2.0 );

		mvdir.set();
		if ( Key.isDown( Key.MOUSE_LEFT ) ) {
			var dst = m.distanceSq( scrc );
			if ( dst > 0 ) {				
				tfwd = m.sub( scrc ).normalized();
			}
			mvdir.load( cfwd );
		}

		// attack
		if ( atkCD <= 0.0 && Key.isDown( Key.MOUSE_RIGHT ) ) {
			var mdir = new Point( game.mouseX, game.mouseY ).sub( location ).normalized();
			var p = spawn( Projectile, this, location.add( mdir.multiply( 8 ) ) );
			p.velocity = mdir.multiply( 0.55 );
			p.spr.rotation = M.atan2( mdir.y, mdir.x ) + (M.PI/2);
			tfwd.load( mdir );
			atkCD = 0.33;
		}

		cfwd.lerp( cfwd, tfwd, 0.45 );
		cfwd.normalize();
		g2.rotation = M.atan2( cfwd.y, cfwd.x );
	}

	override function onFixedUpdate() {
		super.onFixedUpdate();

		if ( mvdir.lengthSq() > 0 ) {
			// dont ask
			velocity.x += mvdir.x * (1.0 / G.FIXED_FPS / 5 * 1.4) * tps;
			velocity.y += mvdir.y * (1.0 / G.FIXED_FPS / 5 * 1.4) * tps;
		}
	}

	var afwd = true;
	var astart = 0;
	override function onPostUpdate() {
		super.onPostUpdate();

		var flip = false;
		var qang = (M.PI / 4.0);
		var ang = M.atan2( cfwd.y, cfwd.x );
		if ( ang > (-qang) && ang < (qang) ) { // right
			if ( astart != 8 ) { fi = 8; }
			astart = 8;
		}
		if ( ang > (qang) && ang < (qang * 3) ) { // down
			if ( astart != 1 ) fi = 1;
			astart = 1;
		}
		if ( ang > (-qang * 3) && ang < (-qang) ) { // up
			if ( astart != 15 ) fi = 15;
			astart = 15;
		}
		if ( ang > (qang * 3) || ang < (-qang * 3) ) { // left
			if ( astart != 8 ) { fi = 8; }
			astart = 8;
			flip = true;
		}

		var arate = afps / G.FPS * game.tmod; // fps
		if ( velocity.length() <= 0.01 ) {arate = 0; fi = astart-1;}
		// frame start and end
		var aframes = 6;
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
		if ( flip != spr.tile.xFlip )
			spr.tile.flipX();

		statText.y = game.window.height / G.SCALE - 8;

		if ( blinkCD <= 0 ) {
			blinkCol *= M.pow( 0.6, game.tmod );
		} else { blinkCD -= game.dt; }

		spr.colorAdd.load( new h3d.Vector() );
		spr.colorAdd.r += blinkCol;
		spr.colorAdd.g += blinkCol;
		spr.colorAdd.b += blinkCol;
	}

	var blinkCD = 0.0;
	var blinkCol = 0.0;
	override function takeDamage( dmg: Float, ?from: Actor ) {
		blinkCD = 0.06;
		blinkCol = 0.5;
		super.takeDamage( dmg, from );
	}

	override function onDie() {
		trace( 'Player died!?' );
		life = 600;
		//super.onDie();
	}

	override function onDestroyed() {
		trace( 'Player destroyed!' );
		frames = null;
		statText.remove();
		super.onDestroyed();
	}
}
