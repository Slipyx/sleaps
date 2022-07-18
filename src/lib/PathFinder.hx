// grid pathfinding / line of sight
package lib;

class PathFinder {
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
	public static inline function losCanPass( px: Int, py: Int, tx: Int, ty: Int ): Bool {
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
