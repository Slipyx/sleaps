package;

class Actor implements IUpdater {
	public var game(default, null): Game;
	public var level(default, null): Level;

	public var destroyed(default, set): Bool = false;
	public var alive(get, never): Bool;
	// actor that owns this actor, null for no owner
	public var owner(default, set): Actor;
	// cell location
	public var cellLocation: IPoint;
	// ratio within cell location
	public var cellRatio: Point;
	// current pixel location
	public var location(get, never): Point;
	// collision radius
	public var radius: Float;
	// call onTouch when another touching actor overlaps
	public var touchActors: Bool = false;
	// bump into other bumping actors and call onBump
	public var bumpActors: Bool = false;
	// cell ratio velocity
	public var velocity: Point;
	// velocity friction
	public var friction: Float;
	// the force at which this actor repels away from other bumping actors
	// if 0, actor is treated as static and other actors use brute force
	// repositioning instead of their bumpForce
	public var bumpForce: Float;
	// tag
	public var tag: String = "None";
	// life
	public var life(default, set): Float = 1;
	// seconds until automatic death (onDie). 0 = forever.
	public var lifeSpan: Float = 0;
	// visual
	public var visible: Bool = true; // spr.visible
	public var spr: Sprite;

	// actors that have this actor as owner
	var ownees: List<Actor>;
	// previous fixed update pixel location
	var _lastFixedLocation: Point;
	// list of touching actors
	var touching: List<Actor>;
	// actors touching during current frame, for internal use only
	var _curTouching: List<Actor>;

	// temp spawn vars for base constructor
	static var _st_owner: Actor = null;
	static var _st_location: Point = null;

	@:access(Level)
	public function new() {
		game = Game.ME;
		level = Level.ME;
		destroyed = false;
		level.addActor( this ); // throws if no more room in level

		ownees = new List<Actor>();
		owner = _st_owner;
		touching = new List<Actor>();
		_curTouching = new List<Actor>();
		cellLocation = new IPoint( 0, 0 );
		cellRatio = new Point( 0, 0 );
		velocity = new Point( 0, 0 );
		friction = 0.8; // 0.8
		bumpForce = 0.25; // 0.25
		radius = level.GRID / 2.67;
		// default tag name is name of class
		tag = Type.getClassName( Type.getClass( this ) );

		_st_location = _st_location != null ? _st_location :
			(_st_owner != null ? _st_owner.location : new Point( 0, 0 ));

		setLocation( _st_location.x, _st_location.y );
		_lastFixedLocation = location.clone();

		spr = new Sprite( game.defaultTile );
		// snap spr pos to spawn loc
		spr.x = _st_location.x;
		spr.y = _st_location.y;
		game.scroller.add( spr, G.LAYER_MAIN );
	}

	// spawn a new actor in the level at location and with owner
	// returns null if unable to spawn in level
	@:generic
	public static function spawn<T: Constructible<Void->Void> & Actor>(
			base: Class<T>, ?ownerActor: Actor = null, ?loc: Point = null ): T {
		var a: T = null;
		// set spawn temps for base constructor
		_st_owner = ownerActor;
		_st_location = loc;
		// init and try to add to level
		try {
			a = new T();
		} catch ( e ) {
			trace( 'Failed to spawn actor of type \'${base}\' at ${_st_location}! ${e.message}' );
			return null;
		}
		return a;
	}

	// get pixel location
	inline function get_location()
		return new Point( (cellLocation.x + cellRatio.x) * level.GRID,
			(cellLocation.y + cellRatio.y) * level.GRID );

	// change, set, or remove the current owner
	function set_owner( value: Actor ) {
		if ( owner == value || owner == this ) return owner;
		var pOwner = owner;
		if ( value != null ) {
			// null to real owner
			if ( pOwner == null ) {
				owner = value;
				owner.ownees.add( this );
			// real owner to new real owner
			} else {
				pOwner.ownees.remove( this );
				owner = value;
				owner.ownees.add( this );
			}
		// real to null owner
		} else {
			pOwner.ownees.remove( this );
			owner = value;
		}
		return value;
	}

	// life setter. calls onDie if changes from > 0 to <= 0
	@:keep inline function set_life( v: Float ) {
		if ( life <= 0 ) return life = v;
		life = v;
		if ( life <= 0 ) onDie();
		return life;
	}

	inline function get_alive() return !destroyed && life > 0;

	// destroy and remove actor from level at end of frame
	public inline final function destroy() { destroyed = true; }
	// actual destruction is done when var is set
	@:access(Level)
	function set_destroyed( v: Bool ) {
		// only set to true once in lifetime
		if ( !destroyed ) {
			if ( v ) {
				destroyed = true;
				level.destroyActor( this );
				return true;
			} else return destroyed = false;
		}
		return true;
	}

	// set pixel location
	public function setLocation( x: Float, y: Float ) {
		cellLocation.x = int(x / level.GRID);
		cellLocation.y = int(y / level.GRID);
		cellRatio.x = (x - cellLocation.x * level.GRID) / level.GRID;
		cellRatio.y = (y - cellLocation.y * level.GRID) / level.GRID;
	}

	// subtract from life (or add...)
	public function takeDamage( dmg: Float, ?from: Actor ) {
		life = life - dmg;
	}

	// after level loaded and all actors spawned
	public function onBeginPlay() {
		// debug bounds
		var g = new h2d.Graphics( spr );
		//g.lineStyle( 0.5, 0x00ff00, 0.5 );
		//g.drawRect( -8 , -8, 16, 16 );
		g.lineStyle( 0.5, 0xff0000, 0.5 );
		g.drawCircle( 0, 0, radius );
	}

	// when life reaches 0. by default, destroy
	public function onDie() {
		destroyed = true;
	}

	// when destroyed and removed from level
	public function onDestroyed() {
		// sprite
		spr.remove();
		spr = null;
		// owner 
		owner = null;
		for ( o in ownees )
			o.owner = null;
		ownees.clear();
		touching.clear();
		touching = null;
		_curTouching.clear();
		_curTouching = null;
	}

	// when another actor touches
	function onTouch( other: Actor ) {
		//trace('Actor has been touched!');
	}
	// when another bumping actor bumps into this bumping actor
	function onBump( other: Actor ) {
		//trace('Actor has been bumped!');
	}

	// prestep collision / physics checks
	function onPreStepX() {}
	function onPreStepY() {}

	// update callbacks
	public function onPreUpdate() {}

	public function onUpdate() {}

	// actor to actor collisions
	final function handleActorCollisions() {
		_curTouching.clear();
		// actor collisions
		for ( other in level.allActors() ) {
			// fast check cell distance
			if ( other != this && !(other.destroyed) &&
					M.abs( other.cellLocation.distanceSq( cellLocation ) ) <= 4 ) {
				// fast check pixel distance
				var r = radius + other.radius;
				var oloc = other.location;
				var loc = location;
				var d2 = oloc.distanceSq( loc );
				if ( d2 < (r * r) ) {
					// touching
					if ( touchActors && (other.touchActors || other.bumpActors) ) {
						// bumping
						if ( bumpActors && other.bumpActors ) {
							var l = M.sqrt( d2 );
							var depth = r - l;
							// * 2 since we only apply bumpForce to one actor in each pair
							var power = depth / (r) * 2;
							// normal from this to other
							var n = l != 0 ? oloc.sub( loc ).multiply( 1.0 / l ) : new Point(0,1);
							// if other has 0 bumpforce, treat as static and brute force reposition
							if ( other.bumpForce == 0 )
								setLocation( loc.x - (n.x*(depth)), loc.y - (n.y*(depth)) );
							// use bump force
							else {
								// note: should apply opposing bumpForce to both actors?
								velocity.x -= n.x * power * bumpForce;
								velocity.y -= n.y * power * bumpForce;
							}
							// only call onBump during movement
							if ( other.velocity.lengthSq() > 0 ||
									(other.bumpForce == 0 && velocity.lengthSq() > 0) )
								other.onBump( this );
						} else {
							_curTouching.add( other );
						}
					}
				}
			}
		}
		// check for initial touch
		for ( ct in _curTouching ) {
			var wastouching = false;
			for ( t in touching ) {
				if ( ct == t ) { wastouching = true; break; }
			}
			if ( !wastouching ) {
				touching.add( ct );
				ct.onTouch( this );
			}
		}
		// untouched
		for ( t in touching ) {
			var istouching = false;
			for ( ct in _curTouching ) {
				if ( ct == t ) { istouching = true; break; }
			}
			if ( !istouching ) {
				touching.remove( t );
			}
		}
	}

	public function onFixedUpdate() {
		_lastFixedLocation.load( location );
		// actor collisions.
		handleActorCollisions();
		// step through movement. adopted from deepnight's gamebase entity
		var steps = M.ceil( (M.abs( velocity.x ) + M.abs( velocity.y )) / 0.33 );
		if ( steps > 0 ) {
			var n = 0;
			while ( n < steps ) {
				cellRatio.x += velocity.x / steps;
				if ( velocity.x != 0 ) onPreStepX();
				while ( cellRatio.x > 1 ) { cellRatio.x--; cellLocation.x++; }
				while ( cellRatio.x < 0 ) { cellRatio.x++; cellLocation.x--; }
				cellRatio.y += velocity.y / steps;
				if ( velocity.y != 0 ) onPreStepY();
				while ( cellRatio.y > 1 ) { cellRatio.y--; cellLocation.y++; }
				while ( cellRatio.y < 0 ) { cellRatio.y++; cellLocation.y--; }
				n++;
			}
		}
		// friction
		velocity.x *= friction;
		velocity.y *= friction;
		if ( M.abs( velocity.x ) <= 0.0005 ) velocity.x = 0;
		if ( M.abs( velocity.y ) <= 0.0005 ) velocity.y = 0;
	}

	public function onPostUpdate() {
		// update lerped sprite position.
		var loc = location;
		spr.x = M.lerp( _lastFixedLocation.x, loc.x, game.fixedAlpha );
		spr.y = M.lerp( _lastFixedLocation.y, loc.y, game.fixedAlpha );
		spr.visible = visible;
		// lifespan
		if ( alive && lifeSpan > 0 ) {
			lifeSpan -= game.tmod / G.FPS;
			if ( lifeSpan <= 0 ) {
				lifeSpan = 0;
				life = 0; // onDie
			}
		}
	}
}

// custom sprite
class Sprite extends h2d.Drawable {
	// tile
	public var tile: h2d.Tile;

	public function new( t: h2d.Tile, ?p: h2d.Object ) {
		super( p );
		tile = t;
	}

	override function onRemove() {
		tile = null;
		super.onRemove();
	}

	override function getBoundsRec( rel, out, forSize ) {
		super.getBoundsRec( rel, out, forSize );
		addBounds( rel, out, tile.dx, tile.dy, tile.width, tile.height );
	}

	override function draw( ctx: h2d.RenderContext ) {
		emitTile( ctx, tile );
	}

	override function sync( ctx: h2d.RenderContext ) {
		super.sync( ctx );
	}
}
