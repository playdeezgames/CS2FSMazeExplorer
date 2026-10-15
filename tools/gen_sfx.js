#!/usr/bin/env node
// Generates the fifteen sound effects of Maze Explorer of SPLORR!! with jsfxr (https://sfxr.me),
// replacing the original .wav files (docs/PORT.md D8). Deterministic: Math.random is seeded, so the
// same jsfxr scripts give the same files.
//
//   node tools/gen_sfx.js --sfxr DIR [--out odin/platform/web/page/sfx]
//
// DIR holds sfxr.js and riffwave.js as served by https://sfxr.me (they are not kept in this repo).
// Both are pure computation. The file names are the lower-case names of game.Sfx, in the same
// order as SFX in odin/platform/web/page/platform.js (a test pins that).
"use strict";
const fs = require("fs");
const path = require("path");

function arg(name, fallback) {
	const i = process.argv.indexOf(name);
	return i >= 0 && i + 1 < process.argv.length ? process.argv[i + 1] : fallback;
}
const sfxrDir = arg("--sfxr", null);
const outDir = arg("--out", path.join(__dirname, "..", "odin", "platform", "web", "page", "sfx"));
if (!sfxrDir) {
	console.error("usage: node tools/gen_sfx.js --sfxr DIR [--out DIR]");
	process.exit(2);
}

global.window = {};
const lib = require(path.resolve(sfxrDir, "sfxr.js"));
const api = lib.sfxr || lib;

// mulberry32, reseeded before every sound so each file is independent of the others
function seeded(seed) {
	let a = seed >>> 0;
	return function () {
		a = (a + 0x6D2B79F5) >>> 0;
		let t = a;
		t = Math.imul(t ^ (t >>> 15), t | 1);
		t ^= t + Math.imul(t ^ (t >>> 7), t | 61);
		return ((t ^ (t >>> 14)) >>> 0) / 4294967296;
	};
}

// name -> [preset, seed, overrides applied after the preset rolls its random numbers]
const SOUNDS = {
	acquire_loot:      ["pickupCoin", 101, { sound_vol: 0.14 }],
	acquire_hourglass: ["powerUp",    102, { p_env_sustain: 0.18, p_env_decay: 0.35 }],
	acquire_key:       ["pickupCoin", 103, { p_base_freq: 0.62, p_arp_mod: 0.5, p_arp_speed: 0.55, p_env_sustain: 0.12, p_env_decay: 0.3, sound_vol: 0.14 }],
	acquire_potion:    ["powerUp",    104, { p_vib_strength: 0.25, p_vib_speed: 0.45, p_env_decay: 0.3 }],
	acquire_shield:    ["blipSelect", 105, { wave_type: 0, p_base_freq: 0.28, p_env_decay: 0.25 }],
	acquire_sword:     ["laserShoot", 106, { p_base_freq: 0.75, p_freq_ramp: -0.3, p_env_decay: 0.22 }],
	trigger_trap:      ["explosion",  107, { p_env_sustain: 0.05, p_env_decay: 0.3 }],
	unlock_door:       ["click",      108, { p_env_decay: 0.18 }],
	blocked:           ["hitHurt",    109, { p_base_freq: 0.18, p_env_sustain: 0.12, p_env_decay: 0.25 }],
	drink_potion:      ["jump",       110, { p_vib_strength: 0.2, p_vib_speed: 0.4, p_env_decay: 0.4 }],
	amulet:            ["powerUp",    111, { wave_type: 2, p_env_sustain: 0.3, p_env_decay: 0.5, p_vib_strength: 0.15 }],
	death:             ["explosion",  112, { p_env_sustain: 0.2, p_env_decay: 0.7, p_base_freq: 0.12 }],
	exit:              ["powerUp",    113, { p_env_sustain: 0.35, p_env_decay: 0.55, p_arp_mod: 0.35, p_arp_speed: 0.6 }],
	fight:             ["hitHurt",    114, { sound_vol: 0.18 }],
	love_interest:     ["pickupCoin", 115, { wave_type: 2, p_arp_mod: 0.4, p_arp_speed: 0.5, p_env_decay: 0.5, sound_vol: 0.14 }],
};

fs.mkdirSync(outDir, { recursive: true });
for (const [name, [preset, seed, overrides]] of Object.entries(SOUNDS)) {
	Math.random = seeded(seed);
	const params = api.generate(preset, { sample_rate: 22050, sample_size: 8, sound_vol: 0.25 });
	Object.assign(params, overrides);
	const wave = api.toWave(params);
	const bytes = Buffer.from(wave.dataURI.split(",")[1], "base64");
	fs.writeFileSync(path.join(outDir, name + ".wav"), bytes);
	console.log(name.padEnd(18), String(bytes.length).padStart(7), "bytes");
}
