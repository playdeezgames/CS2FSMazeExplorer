"use strict";
// Page glue for Maze Explorer of SPLORR!! (see odin/platform/web/main.odin for the exports it calls).
// Query options: ?seed=N (up to 15 digits) fixes the first maze; ?play=1 skips the title screen;
// ?touch=1 shows the touch controls on any device; ?log=1 logs every key.

(function () {
	const W = 256, H = 144;   // 32 by 18 cells of 8 by 8 pixels (design/PORT.md D4)
	const params = new URLSearchParams(location.search);
	const logKeys = params.get("log") === "1";
	const touch = params.get("touch") === "1" ||
		(window.matchMedia && window.matchMedia("(pointer: coarse)").matches);
	const canvas = document.getElementById("screen");
	const msg = document.getElementById("msg");
	const ctx2d = canvas.getContext("2d", { alpha: false });
	const picture = document.createElement("canvas");   // the frame as the game drew it
	picture.width = W; picture.height = H;
	const pctx = picture.getContext("2d", { alpha: false });
	const image = pctx.createImageData(W, H);
	const pad = document.getElementById("pad"), acts = document.getElementById("acts");
	let haveFrame = false;

	// ui.Key numbers (odin/ui/app.odin) in declaration order.
	const KEY = { Up: 1, Down: 2, Left: 3, Right: 4, Q: 5, Space: 6, F1: 7, F3: 8, Escape: 9, M: 10, P: 11, F2: 12 };

	// game.Sfx names in declaration order (odin/game/types.odin); index 0 is "no sound". Each is a
	// file in sfx/. A test pins this list against the enum.
	const SFX = ["", "acquire_loot", "acquire_hourglass", "acquire_key", "acquire_potion", "acquire_shield",
		"acquire_sword", "trigger_trap", "unlock_door", "blocked", "drink_potion", "amulet", "death", "exit",
		"fight", "love_interest"];

	// Read the logical `e.key` first (remote desktops send odd `e.code` values), then fall back to
	// `e.code` for the numpad.
	function keyOf(e) {
		switch (e.key) {
			case "ArrowUp": return KEY.Up;
			case "ArrowDown": return KEY.Down;
			case "ArrowLeft": return KEY.Left;
			case "ArrowRight": return KEY.Right;
			case "q": case "Q": return KEY.Q;
			case " ": case "Spacebar": return KEY.Space;
			case "F1": return KEY.F1;
			case "F2": return KEY.F2;
			case "F3": return KEY.F3;
			case "Escape": return KEY.Escape;
			case "m": case "M": return KEY.M;
			case "p": case "P": return KEY.P;
		}
		switch (e.code) {
			case "Numpad8": return KEY.Up;
			case "Numpad2": return KEY.Down;
			case "Numpad4": return KEY.Left;
			case "Numpad6": return KEY.Right;
		}
		return 0;
	}

	// ?seed=N (up to 15 digits) fixes the maze; otherwise the seed comes from the browser's entropy.
	function seedFromPage() {
		const s = params.get("seed");
		if (s && /^\d{1,15}$/.test(s)) {
			const n = Number(s);
			return [n >>> 0, Math.floor(n / 4294967296) >>> 0];
		}
		const r = new Uint32Array(2);
		window.crypto.getRandomValues(r);
		return [r[0], r[1] & 0xFFFFF];
	}

	// ---- fit to the window ------------------------------------------------------------------------
	// The picture is enlarged by a whole number (nearest neighbour, crisp), then the browser resizes
	// that canvas to the exact fit. Touch controls take the sides (landscape) or the bottom (portrait).
	function layout() {
		const portrait = window.innerHeight > window.innerWidth;
		document.body.classList.toggle("portrait", touch && portrait);
		document.body.classList.toggle("landscape", touch && !portrait);
		pad.classList.toggle("on", touch);
		acts.classList.toggle("on", touch);
		let availW = Math.max(1, window.innerWidth), availH = Math.max(1, window.innerHeight);
		if (touch) {
			if (portrait) availH = Math.max(1, availH - 240);   // room for the 4 rows of keys
			else availW = Math.max(1, availW - 2 * 150);   // room for 3 or 2 buttons of 62px and gaps
		}
		const fit = Math.min(availW / W, availH / H);
		const dpr = window.devicePixelRatio || 1;
		const k = Math.max(1, Math.min(8, Math.ceil(fit * dpr)));
		if (canvas.width !== W * k) {
			canvas.width = W * k;
			canvas.height = H * k;
		}
		canvas.style.width = Math.floor(W * fit) + "px";
		canvas.style.height = Math.floor(H * fit) + "px";
		if (touch && portrait) canvas.style.marginBottom = (window.innerHeight - availH) + "px";
		else canvas.style.marginBottom = "";
		if (haveFrame) present();
	}
	function present() {
		ctx2d.imageSmoothingEnabled = false;
		ctx2d.drawImage(picture, 0, 0, canvas.width, canvas.height);
	}
	window.addEventListener("resize", layout);
	layout();

	// ---- sound -------------------------------------------------------------------------------------
	// The files are fetched at once; decoding waits for the AudioContext, which a first key press or
	// touch unlocks (browsers refuse sound before that).
	const raw = {};          // name -> ArrayBuffer
	const buffers = {};      // name -> AudioBuffer
	let audio = null;
	SFX.forEach(function (name) {
		if (!name) return;
		fetch("sfx/" + name + ".wav").then(function (r) { return r.arrayBuffer(); })
			.then(function (b) { raw[name] = b; })
			.catch(function () { /* a missing sound is just silent */ });
	});
	function unlockAudio() {
		if (audio) { if (audio.state === "suspended") audio.resume(); return; }
		const AC = window.AudioContext || window.webkitAudioContext;
		if (!AC) return;
		try { audio = new AC(); } catch (e) { audio = null; return; }
		Object.keys(raw).forEach(function (name) {
			audio.decodeAudioData(raw[name].slice(0)).then(function (b) { buffers[name] = b; }, function () {});
		});
	}
	function play(id) {
		const name = SFX[id];
		if (!name || !audio) return;
		let b = buffers[name];
		if (!b && raw[name]) {   // arrived after the unlock: decode now, play next time
			audio.decodeAudioData(raw[name].slice(0)).then(function (d) { buffers[name] = d; }, function () {});
			return;
		}
		if (!b) return;
		const src = audio.createBufferSource();
		src.buffer = b;
		src.connect(audio.destination);
		src.start();
	}

	async function start() {
		const memory = new odin.WasmMemoryInterface();
		await odin.runWasm("mazeexplorer.wasm", null, {}, memory);
		const ex = memory.exports;
		if (ex.platform_width() !== W || ex.platform_height() !== H) {
			msg.textContent = "frame size mismatch";
			return;
		}
		msg.style.display = "none";
		canvas.focus();
		const [lo, hi] = seedFromPage();
		ex.platform_init(lo, hi);

		// options and best scores (design/PORT.md D11); every read is validated by the game
		const SETTINGS_KEY = "mex:settings";
		function storageGet() { try { return window.localStorage.getItem(SETTINGS_KEY); } catch (e) { return null; } }
		function storageSet(v) { try { window.localStorage.setItem(SETTINGS_KEY, v); return true; } catch (e) { return false; } }
		const saved = storageGet();
		if (saved) {
			const bytes = new TextEncoder().encode(saved);
			if (bytes.length > 0 && bytes.length <= ex.platform_io_size()) {
				new Uint8Array(memory.memory.buffer, ex.platform_io_ptr(), bytes.length).set(bytes);
				ex.platform_settings_load(bytes.length);
			}
		}
		function flushSettings() {
			if (!ex.platform_settings_dirty()) return;
			const n = ex.platform_settings_encode();
			const text = new TextDecoder().decode(new Uint8Array(memory.memory.buffer, ex.platform_io_ptr(), n));
			if (storageSet(text)) ex.platform_settings_ack();
		}

		// ?play=1 skips the title screen (QA and tests)
		if (params.get("play") === "1") ex.platform_start_game(performance.now());

		function press(code) {
			if (!code) return;
			unlockAudio();
			ex.platform_key(code, performance.now());
			const id = ex.platform_take_sfx();
			if (window.mex) window.mex.lastSfx = id;
			play(id);
			flushSettings();
		}

		// fullscreen is a page feature (key F or the corner button), not a game key
		function toggleFullscreen() {
			try {
				if (document.fullscreenElement) document.exitFullscreen();
				else if (document.documentElement.requestFullscreen) document.documentElement.requestFullscreen();
			} catch (err) { /* refused: stay windowed */ }
			canvas.focus();
		}
		const fsButton = document.getElementById("fs");
		if (fsButton) {
			if (!document.documentElement.requestFullscreen) fsButton.style.display = "none";
			fsButton.addEventListener("click", function (e) { e.preventDefault(); unlockAudio(); toggleFullscreen(); });
		}

		window.addEventListener("keydown", function (e) {
			if (e.ctrlKey || e.metaKey || e.altKey) return;
			if ((e.key === "f" || e.key === "F") && !e.repeat) { e.preventDefault(); toggleFullscreen(); return; }
			const code = keyOf(e);
			if (logKeys) console.log("key", e.key, e.code, "->", code);
			if (!code) return;
			e.preventDefault();
			press(code);
		});

		// touch buttons; a held arrow repeats
		document.querySelectorAll(".touch button").forEach(function (b) {
			const code = KEY[b.dataset.key];
			const repeats = ["Up", "Down", "Left", "Right"].indexOf(b.dataset.key) >= 0;
			let timer = null;
			function stop() { if (timer) { clearInterval(timer); timer = null; } }
			b.addEventListener("pointerdown", function (e) {
				e.preventDefault();
				press(code);
				if (repeats) { stop(); timer = setInterval(function () { press(code); }, 180); }
			});
			["pointerup", "pointercancel", "pointerleave"].forEach(function (n) { b.addEventListener(n, stop); });
		});
		canvas.addEventListener("pointerdown", function () { unlockAudio(); canvas.focus(); });

		window.mex = { ex: ex, seed: [lo, hi], press: press };   // for debugging and browser tests

		function frame() {
			if (ex.platform_frame(performance.now())) {
				const ptr = ex.platform_frame_ptr();
				image.data.set(new Uint8ClampedArray(memory.memory.buffer, ptr, W * H * 4));
				pctx.putImageData(image, 0, 0);
				haveFrame = true;
				present();
			}
			requestAnimationFrame(frame);
		}
		requestAnimationFrame(frame);
	}
	start().catch(function (e) { msg.textContent = "failed to start: " + e; });
})();
