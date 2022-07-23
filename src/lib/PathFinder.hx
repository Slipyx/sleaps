package lib;

// grid pathfinding / line of sight
// uses AStar implementation from deepnightLibs
// by deepnight https://github.com/deepnight/deepnightLibs
// based on JS Source: https://briangrinstead.com/blog/astar-search-algorithm-in-javascript/

class PathFinder<T> {
	var nodes: Array<PathNode> = [];
	//var collisions: Map<Int, Bool> = new Map();
	var wid = -1;
	var hei = -1;

	var nodeToPoint: (Int,Int)->T;

	public function new( nodeToPoint: (Int,Int)->T ) {
		this.nodeToPoint = nodeToPoint;
	}

	public function init( w: Int, h: Int ) { //, hasCollision: (Int,Int)->Bool ) {
		wid = w;
		hei = h;
		//this.hasCollision = hasCollision;
		nodes = [];
		for ( cy in 0...hei )
		for ( cx in 0...wid ) {
			if ( losCanPass(cx,cy,cx,cy) )
			if ( !losCanPass(cx,cy,cx-1,cy-1) && losCanPass(cx,cy,cx,cy-1) && losCanPass(cx,cy,cx-1,cy)
				|| !losCanPass(cx,cy,cx+1,cy-1) && losCanPass(cx,cy,cx,cy-1) && losCanPass(cx,cy,cx+1,cy)
				|| !losCanPass(cx,cy,cx+1,cy+1) && losCanPass(cx,cy,cx,cy+1) && losCanPass(cx,cy,cx+1,cy)
				|| !losCanPass(cx,cy,cx-1,cy+1) && losCanPass(cx,cy,cx,cy+1) && losCanPass(cx,cy,cx-1,cy) )
				nodes.push( new PathNode( wid, cx, cy ) );
		}

		for ( n in nodes )
		for ( n2 in nodes )
			if ( n != n2 && sightCheck( n.cx, n.cy, n2.cx, n2.cy ) )
				n.link( n2 );
	}
	//dynamic function hasCollision( cx, cy ) return false;

	inline function sightCheck( fx, fy, tx, ty ) {
		return checkLine( fx, fy, tx, ty, losCanPass );
	}

	function getNodeAt( cx, cy ) {
		for ( n in nodes )
			if ( n.cx == cx && n.cy == cy )
				return n;
		return null;
	}

	public function getPath( fx: Int, fy: Int, tx: Int, ty: Int ) {
		if ( wid < 0 ) throw "AStar.init() should be called first.";

		// Simple case
		if ( sightCheck( fx, fy, tx, ty ) )
			return [nodeToPoint( tx, ty )];

		// Init network
		for ( n in nodes )
			n.initBeforeAStar();

		// Add start & end as PathNodes to existing node network
		var addeds = 0;
		var start = getNodeAt( fx, fy );
		if( start == null ) {
			addeds++;
			start = new PathNode( wid, fx, fy );
			for ( n in nodes )
				if ( sightCheck( start.cx, start.cy, n.cx, n.cy ) ) start.link( n, true );
			nodes.push( start );
		}
		var end = getNodeAt( tx, ty );
		if ( end == null ) {
			addeds++;
			end = new PathNode( wid, tx, ty );
			for ( n in nodes )
				if ( sightCheck( end.cx, end.cy, n.cx, n.cy ) ) end.link( n, true );
			nodes.push( end );
		}

		// Get path
		var path = astar( start, end ).map( function( n ) return nodeToPoint( n.cx, n.cy ) );
		for ( i in 0...addeds ) nodes.pop();
		return path;
	}

	function astar( start: PathNode, end: PathNode ) {
		var opens = [start];
		var openMarks = new Map();
		openMarks.set( start.id, true );
		var closedMarks = new Map();

		while ( opens.length > 0 ) {
			// Gets next best
			var best = -1;
			for ( i in 0...opens.length )
				if ( best < 0 || opens[i].distTotalSqr( end.cx, end.cy ) < opens[best].distTotalSqr( end.cx, end.cy ) )
					best = i;

			var cur = opens[best];

			// Found path
			if ( cur == end ) {
				// Build path output & clean useless nodes
				var path = [cur];
				var n = getDeepestParentOnSight( cur );
				while ( n != null ) {
					path.push( n );
					n = getDeepestParentOnSight( n );
				}
				path.reverse();
				return path;
			}

			// Update lists
			closedMarks.set( cur.id, true );
			opens.splice( best, 1 );
			openMarks.remove( cur.id );

			var i = 0;
			for ( n in cur.nexts ) {
				if ( closedMarks.exists( n.id ) ) continue;

				var homeDist = cur.homeDist + cur.distSqr( n.cx, n.cy );
				var isBetter = false;

				if ( !openMarks.exists( n.id ) ) {
					// Found new node
					isBetter = true;
					opens.push( n );
					openMarks.set( n.id, true );
				}
				else if ( homeDist < n.homeDist ) {
					// Found a better way to get here
					isBetter = true;
				}

				if ( isBetter ) {
					// Update visited node
					n.parent = cur;
					n.homeDist = homeDist;
					i++;
				}
			}
		}
		return [];
	}

	function getDeepestParentOnSight( cur: PathNode ) : Null<PathNode> {
		var n = cur.parent;
		var lastSight = n;
		while ( n != null ) {
			if ( sightCheck( cur.cx, cur.cy, n.cx, n.cy ) )
				lastSight = n;
			else
				return lastSight;
			n = n.parent;
		}
		return null;
	}

	// ==== los / linecheck functions ====

	// bresenham line check. canPass returns true if can pass from px,py -> tx,ty
	public static inline function checkLine( x0: Int, y0: Int, x1: Int, y1: Int, canPass: (Int,Int,Int,Int)->Bool ) {
		if ( !canPass( x0, y0, x0, y0 ) || !canPass( x1, y1, x1, y1 ) ) {
			return false;
		}
		var valid = true;

		var dx: Int = M.iabs( x1 - x0 );
		var sx: Int = x0 < x1 ? 1 : -1;
		var dy: Int = M.iabs( y1 - y0 );
		var sy: Int = y0 < y1 ? 1 : -1;
		var err: Int = int((dx > dy ? dx : -dy) / 2);
		var e2: Int = 0;
		var px: Int = x0;
		var py: Int = y0;

		while ( true ) {
			if ( !canPass( px, py, x0, y0 ) ) {
				valid = false; break;
			}
			px = x0; py = y0;
			if ( x0 == x1 && y0 == y1 ) break;
			e2 = err;
			if ( e2 > -dx ) { err -= dy; x0 += sx; }
			if ( e2 < dy ) { err += dx; y0 += sy; }
		}

		return valid;
	}

	// can los pass from one cell to a neighboring cell
	public static function losCanPass( px: Int, py: Int, tx: Int, ty: Int ): Bool {
		var level = Level.ME;
		// initial check
		if ( px == tx && py == ty )
			return level.getCollision( tx, ty ) != Col_Solid;
		// target is solid
		if ( level.getCollision( tx, ty ) == Col_Solid ) return false;
		// deltas should always be 0 to +/- 1
		var dx = tx - px;
		var dy = ty - py;
		var pc = level.getCollision( px, py );
		var tc = level.getCollision( tx, ty );
		// up
		if ( dx == 0 && dy == -1 ) {
			if ( pc == Col_Top || tc == Col_Bottom ) return false;
		}
		// down
		if ( dx == 0 && dy == 1 ) {
			if ( pc == Col_Bottom || tc == Col_Top ) return false;
		}
		// left
		if ( dx == -1 && dy == 0 ) {
			if ( pc == Col_Left || tc == Col_Right ) return false;
		}
		// right
		if ( dx == 1 && dy == 0 ) {
			if ( pc == Col_Right || tc == Col_Left ) return false;
		}
		// diagonals...
		// diag topleft
		if ( dx == -1 && dy == -1 )
			if ( !(losCanPass( px, py, px - 1, py ) &&
					losCanPass( px, py, px, py - 1 ) &&
					losCanPass( px - 1, py, px - 1, py - 1 ) &&
					losCanPass( px, py - 1, px - 1, py - 1 )) )
				return false;
		// diag topright
		if ( dx == 1 && dy == -1 )
			if ( !(losCanPass( px, py, px + 1, py ) &&
					losCanPass( px, py, px, py - 1 ) &&
					losCanPass( px + 1, py, px + 1, py - 1 ) &&
					losCanPass( px, py - 1, px + 1, py - 1 )) )
				return false;
		// diag bottomleft
		if ( dx == -1 && dy == 1 )
			if ( !(losCanPass( px, py, px - 1, py ) &&
					losCanPass( px, py, px, py + 1 ) &&
					losCanPass( px - 1, py, px - 1, py + 1 ) &&
					losCanPass( px, py + 1, px - 1, py + 1 )) )
				return false;
		// diag bottomright
		if ( dx == 1 && dy == 1 )
			if ( !(losCanPass( px, py, px + 1, py ) &&
					losCanPass( px, py, px, py + 1 ) &&
					losCanPass( px + 1, py, px + 1, py + 1 ) &&
					losCanPass( px, py + 1, px + 1, py + 1 )) )
				return false;

		return true;
	}
}

// **** Node ************************************************************

private class PathNode {
	public var id: Int;
	public var cx: Int;
	public var cy: Int;
	public var nexts: Array<PathNode> = [];
	var originalNexts: Array<PathNode> = [];

	// For astar
	public var homeDist = 0.0;
	public var parent: Null<PathNode>;

	public function new( wid, x, y ) {
		cx = x;
		cy = y;
		id = cx + cy * wid;
	}

	public function toString() return 'Node@$cx,$cy';

	public function initBeforeAStar() {
		homeDist = 0;
		parent = null;
		nexts = originalNexts.copy();
	}

	public inline function distSqr( tx,ty ) return ((cx-tx)*(cx-tx)+(cy-ty)*(cy-ty));
	public inline function distTotalSqr( tx, ty ) return homeDist + distSqr( tx, ty );

	public function link( n: PathNode, ?tmpLink = false ) {
		if ( tmpLink ) {
			nexts.push( n );
			n.nexts.push( this );
		} else {
			originalNexts.push( n );
			n.originalNexts.push( this );
		}
	}
}
