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
}
