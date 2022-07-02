// 64bit random gen based on xoshiro256**
package;

class Rand {
	var state: haxe.ds.Vector<Int64>;
	static var smstate: Int64 = 0; // splitmix64 state

	// 64bit int to uniform float
	static final __i64f_const: Float = 1.1102230246251565404236316680908203125e-16;
	static inline function i64f( x: Int64 ): Float {
		x = x >>> 11;
		return Math.max( 0, (x.high * 4294967296.0 + (x.low >>> 0)) * __i64f_const );
	}

	static inline function rotl( x: Int64, k: Int ): Int64 {
		return (x << k) | (x >>> (64 - k));
	}

	public function new( seed: Int64 ) {
		state = new haxe.ds.Vector<Int64>( 4 );
		init( seed );
	}

	// initialze state with new seed
	public function init( seed: Int64 ) {
		smstate = seed;
		for ( i in 0...state.length )
			state[i] = splitmix64();
	}

	// splitmix64
	static public function splitmix64(): Int64 {
		var z: Int64 = (smstate += Int64.make( 0x9e3779b9, 0x7f4a7c15 ));
		z = (z ^ (z >>> 30)) * Int64.make( 0xbf58476d, 0x1ce4e5b9 );
		z = (z ^ (z >>> 27)) * Int64.make( 0x94d049bb, 0x133111eb );
		return z ^ (z >>> 31);
	}

	// xoshiro256** random 64bit int
	public function int64(): Int64 {
		final res: Int64 = rotl( state[1] * 5, 7 ) * 9;
		final t: Int64 = state[1] << 17;
		state[2] ^= state[0];
		state[3] ^= state[1];
		state[1] ^= state[2];
		state[0] ^= state[3];
		state[2] ^= t;
		state[3] = rotl( state[3], 45 );
		return res;
	}

	// random float 0.0 - 1.0 (excluded)
	public inline function randf(): Float { return i64f( int64() ); }

	public inline function bool(): Bool { return (int64() < 0); }

	// random unsigned int 0 to 0x3fffffff
	public inline function uint(): Int { return (int64().low & 0x3fffffff); }

	// random int 0 to n (excluded)
	public inline function random( n: Int ): Int { return (uint() % n); }
}
