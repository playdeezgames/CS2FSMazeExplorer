package ui

// A small fixed buffer for building screen text without an allocator.
Builder :: struct {
	buf: [64]u8,
	n:   int,
}

builder_str :: proc(b: ^Builder, s: string) {
	for i in 0 ..< len(s) {
		if b.n < len(b.buf) {
			b.buf[b.n] = s[i]
			b.n += 1
		}
	}
}

// F# sprintf "%<width>i": the number right-aligned and space-padded to `width` (Odin's own "%3d"
// pads with zeros), wider numbers just run on, a minus sign counted. Width 0 means no padding.
builder_int :: proc(b: ^Builder, value, width: int) {
	digits: [24]u8
	n := 0
	v := value
	negative := v < 0
	if negative {v = -v}
	for {
		digits[n] = u8('0' + v % 10)
		n += 1
		v /= 10
		if v == 0 {break}
	}
	if negative {
		digits[n] = '-'
		n += 1
	}
	for _ in n ..< width {
		builder_str(b, " ")
	}
	for i := n - 1; i >= 0; i -= 1 {
		if b.n < len(b.buf) {
			b.buf[b.n] = digits[i]
			b.n += 1
		}
	}
}

builder_len :: proc(b: ^Builder) -> int {
	return b.n
}

builder_string :: proc(b: ^Builder) -> string {
	return string(b.buf[:b.n])
}

// A literal prefix followed by a padded number, into a caller's buffer (the common case).
format_padded :: proc(buf: []u8, prefix: string, value, width: int) -> string {
	b: Builder
	builder_str(&b, prefix)
	builder_int(&b, value, width)
	n := min(b.n, len(buf))
	copy(buf[:n], b.buf[:n])
	return string(buf[:n])
}
