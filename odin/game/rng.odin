package game

import "core:math/bits"

// xoshiro256** seeded through splitmix64. The core owns its generator so a seed reproduces a game
// exactly on every platform (docs/PORT.md D9).
Rng :: struct {
	s: [4]u64,
}

splitmix64 :: proc(x: ^u64) -> u64 {
	x^ += 0x9E3779B97F4A7C15
	z := x^
	z = (z ~ (z >> 30)) * 0xBF58476D1CE4E5B9
	z = (z ~ (z >> 27)) * 0x94D049BB133111EB
	return z ~ (z >> 31)
}

rng_seed :: proc(r: ^Rng, seed: u64) {
	x := seed
	for i in 0 ..< 4 {
		r.s[i] = splitmix64(&x)
	}
}

rng_u64 :: proc(r: ^Rng) -> u64 {
	result := bits.rotate_left64(r.s[1] * 5, 7) * 9
	t := r.s[1] << 17
	r.s[2] ~= r.s[0]
	r.s[3] ~= r.s[1]
	r.s[1] ~= r.s[2]
	r.s[0] ~= r.s[3]
	r.s[2] ~= t
	r.s[3] = bits.rotate_left64(r.s[3], 45)
	return result
}

// A value in [0, n). Like System.Random.Next(n); n must be positive.
rng_int :: proc(r: ^Rng, n: int) -> int {
	if n <= 1 {return 0}
	return int(rng_u64(r) % u64(n))
}
