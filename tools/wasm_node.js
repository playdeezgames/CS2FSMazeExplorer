// Drives the web build (build/web/mazeexplorer.wasm) under node, without a browser.
//
//   node tools/wasm_node.js hash <seed> <keys> [step_ms]    digest of every frame, like odin/tools/replay
//   node tools/wasm_node.js dump <seed> <keys> <out.ppm> [step_ms]   last frame as a PPM picture
//
// <keys> is a comma separated list of ui.Key numbers (odin/ui/app.odin); the clock is fake: key i
// arrives at 1000 + (i + 1) * step_ms milliseconds (default 900).
"use strict";
const fs = require("fs");
const path = require("path");
const vm = require("vm");

const web = path.join(__dirname, "..", "build", "web");
const W = 256, H = 144;

// odin.js is a browser script that installs window.odin
globalThis.window = globalThis;
globalThis.requestAnimationFrame = function () {};
globalThis.fetch = async function (p) {
	const buf = fs.readFileSync(path.join(web, p));
	return { arrayBuffer: async () => buf.buffer.slice(buf.byteOffset, buf.byteOffset + buf.byteLength) };
};
vm.runInThisContext(fs.readFileSync(path.join(web, "odin.js"), "utf8"), { filename: "odin.js" });

async function load(seed) {
	const memory = new odin.WasmMemoryInterface();
	await odin.runWasm("mazeexplorer.wasm", null, {}, memory);
	const ex = memory.exports;
	ex.platform_init(seed >>> 0, Math.floor(seed / 4294967296) >>> 0);
	return { ex, memory };
}

// FNV-1a 32 over the bytes the page would copy out of wasm memory
function hash32(memory, ex) {
	const bytes = new Uint8Array(memory.memory.buffer, ex.platform_frame_ptr(), W * H * 4);
	let h = 0x811c9dc5;
	for (let i = 0; i < bytes.length; i++) {
		h = Math.imul(h ^ bytes[i], 0x01000193) >>> 0;
	}
	return h;
}

async function play(seed, keys, stepMs) {
	const { ex, memory } = await load(seed);
	let frames = 0;
	let now = 1000;
	if (ex.platform_frame(now)) { ex.platform_digest_fold(); frames++; }
	keys.forEach(function (k, i) {
		if (!(k > 0 && k <= 12)) return;
		now = 1000 + (i + 1) * stepMs;
		ex.platform_key(k, now);
		ex.platform_take_sfx();
		if (ex.platform_frame(now)) { ex.platform_digest_fold(); frames++; }
	});
	return { ex, memory, frames };
}

const hex = (n, w) => (n >>> 0).toString(16).padStart(w, "0");

(async function () {
	const [mode, seedArg, keysArg, a, b] = process.argv.slice(2);
	const seed = Number(seedArg || 1);
	const keys = (keysArg || "").split(",").filter(Boolean).map(Number);
	if (mode === "hash") {
		const stepMs = Number(a || 900);
		const { ex, memory, frames } = await play(seed, keys, stepMs);
		// the pixels copied out of memory must hash like the ones the game hashed in place
		const js = hash32(memory, ex);
		const inWasm = ex.platform_frame_hash32() >>> 0;
		if (js !== inWasm) { console.error("frame bytes differ from the in-wasm hash", hex(js, 8), hex(inWasm, 8)); process.exit(1); }
		console.log("digest " + hex(ex.platform_digest_hi(), 8) + hex(ex.platform_digest_lo(), 8));
		console.log("last " + hex(inWasm, 8));
		console.log("frames " + frames + " screen " + ex.platform_screen());
	} else if (mode === "dump") {
		const out = a;
		const stepMs = Number(b || 900);
		const { ex, memory } = await play(seed, keys, stepMs);
		const src = new Uint8Array(memory.memory.buffer, ex.platform_frame_ptr(), W * H * 4);
		const ppm = Buffer.alloc(W * H * 3);
		for (let i = 0; i < W * H; i++) {
			ppm[i * 3] = src[i * 4]; ppm[i * 3 + 1] = src[i * 4 + 1]; ppm[i * 3 + 2] = src[i * 4 + 2];
		}
		fs.writeFileSync(out, Buffer.concat([Buffer.from("P6\n" + W + " " + H + "\n255\n"), ppm]));
		console.log("wrote " + out);
	} else {
		console.error("usage: node tools/wasm_node.js hash|dump <seed> <keys> ...");
		process.exit(2);
	}
})().catch(function (e) { console.error(e); process.exit(1); });
