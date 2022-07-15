// grid pathfinding / line of sight
package lib;

class PathFinder {
	// bresenham line check.
	public static inline function checkLine( x0: Int, y0: Int, x1: Int, y1: Int, canPass: (Int,Int)->Bool ) {
		if ( !canPass( x0, y0 ) || !canPass( x1, y1 ) ) {
			return false;
		}
		var valid = true;
		var swapXY = M.iabs( y1 - y0 ) > M.iabs( x1 - x0 );
		var tmp: Int;
		if ( swapXY ) {
			tmp = x0; x0 = y0; y0 = tmp;
			tmp = x1; x1 = y1; y1 = tmp;
		}
		if ( x0 > x1 ) {
			tmp = x0; x0 = x1; x1 = tmp;
			tmp = y0; y0 = y1; y1 = tmp;
		}
		var deltax = x1 - x0;
		var deltay = M.floor( M.iabs( y1 - y0 ) );
		var error = M.floor( deltax / 2 );
		var y = y0;
		var ystep = if ( y0 < y1 ) 1 else -1;
		for ( x in x0...x1+1 ) {
			if ( swapXY && !canPass( y, x ) || !swapXY && !canPass( x, y ) ) {
				valid = false; break;
			}
			error -= deltay;
			if ( error < 0 ) {
				y += ystep;
				error = error + deltax;
			}
		}

		return valid;
	}
}
