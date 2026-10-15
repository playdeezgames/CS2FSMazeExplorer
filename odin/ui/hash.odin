package ui

// FNV-1a over the frame's bytes (R, G, B, A of every pixel, row by row). Used by the parity check
// (tools/parity.sh) and the regression pins in the tests.
FNV64_OFFSET :: u64(0xcbf29ce484222325)
FNV64_PRIME :: u64(0x100000001b3)

frame_hash64 :: proc(fb: ^Framebuffer) -> u64 {
	h := FNV64_OFFSET
	for p in fb.pixels {
		h = (h ~ u64(p & 0xFF)) * FNV64_PRIME
		h = (h ~ u64((p >> 8) & 0xFF)) * FNV64_PRIME
		h = (h ~ u64((p >> 16) & 0xFF)) * FNV64_PRIME
		h = (h ~ u64(p >> 24)) * FNV64_PRIME
	}
	return h
}

// The 32-bit variant the page's own script can recompute from the bytes it copies out of wasm
// memory, which checks that the exported pixels are what the game drew.
frame_hash32 :: proc(fb: ^Framebuffer) -> u32 {
	h := u32(0x811c9dc5)
	for p in fb.pixels {
		h = (h ~ (p & 0xFF)) * 0x01000193
		h = (h ~ ((p >> 8) & 0xFF)) * 0x01000193
		h = (h ~ ((p >> 16) & 0xFF)) * 0x01000193
		h = (h ~ (p >> 24)) * 0x01000193
	}
	return h
}

// A running digest over every frame a scripted session draws.
digest_fold :: proc(digest: u64, frame_hash: u64) -> u64 {
	return (digest ~ frame_hash) * FNV64_PRIME
}
