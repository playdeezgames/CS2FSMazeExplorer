#!/usr/bin/env python3
"""Generate odin/ui/patterns_gen.odin from the F# pattern sources (the oracle for the port).

  gen_patterns.py            write the Odin file
  gen_patterns.py --check    fail if the file is out of date
  gen_patterns.py --dump     print "name hexrows" for every pattern (compared with the F# itself by
                             tools/check_patterns.sh)
  gen_patterns.py --fsx      print an F# script that loads the original files and prints the same
"""
import os, re, sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SRC = os.path.join(ROOT, "MazeExplorer", "MazeExplorerUILibrary")
OUT = os.path.join(ROOT, "odin", "ui", "patterns_gen.odin")


def read(name):
    with open(os.path.join(SRC, name), encoding="utf-8-sig") as f:
        return f.read()


def parse_patterns(filename):
    """Every `let Name = [ "........"; ... ] |> Pattern.patternFromStringListX` -> {Name: [8 strings]}."""
    text = read(filename)
    result = {}
    order = []
    for m in re.finditer(r"let (\w+)\s*=\s*\[(.*?)\]\s*\|>\s*Pattern\.patternFromStringListX", text, re.S):
        rows = re.findall(r'"([.X]*)"', m.group(2))
        assert len(rows) == 8 and all(len(r) == 8 for r in rows), (filename, m.group(1), rows)
        result[m.group(1)] = rows
        order.append(m.group(1))
    return result, order


def row_byte(row):
    v = 0
    for ch in row:
        v = v << 1 | (1 if ch == "X" else 0)
    return v


def fmt(rows):
    return " ".join("%02x" % row_byte(r) for r in rows)


def collect():
    chars, char_order = parse_patterns("CharacterPatterns.fs")
    common, _ = parse_patterns("CommonPatterns.fs")
    explorer, _ = parse_patterns("ExplorerPatterns.fs")
    monsters, _ = parse_patterns("MonsterPatterns.fs")
    rooms, _ = parse_patterns("RoomPatterns.fs")
    assert char_order == ["character%d" % i for i in range(256)]

    # which character pattern each code point uses (FontTiles.fs; note the original maps \u0010
    # to character6, not character16: docs/PORT.md Q11)
    font = read("FontTiles.fs")
    pairs = re.findall(r"\('\\u([0-9A-F]{4})',CharacterPatterns\.(character\d+)\)", font)
    assert len(pairs) == 256 and [int(h, 16) for h, _ in pairs] == list(range(256))
    font_names = [n for _, n in pairs]

    # room patterns by exit flags (north, east, south, west) -> index n + 2e + 4s + 8w
    room_tiles = read("RoomTiles.fs")
    card = room_tiles.split("let createCardinalLocks")[0]
    room_by_index = [None] * 16
    for m in re.finditer(r"\(\((true|false)\s*,(true|false)\s*,(true|false)\s*,(true|false)\s*\),\s*RoomPatterns\.(\w+)\)", card):
        n, e, s, w = [g == "true" for g in m.groups()[:4]]
        room_by_index[int(n) + 2 * int(e) + 4 * int(s) + 8 * int(w)] = m.group(5)
    assert all(room_by_index)
    locks = read("RoomTiles.fs").split("let createCardinalLocks")[1]
    lock_by_dir = {}
    for m in re.finditer(r"\(\((true|false)\s*,(true|false)\s*,(true|false)\s*,(true|false)\s*\),\s*RoomPatterns\.(\w+)\)", locks):
        flags = [g == "true" for g in m.groups()[:4]]
        assert sum(flags) == 1
        lock_by_dir[flags.index(True)] = m.group(5)
    assert sorted(lock_by_dir) == [0, 1, 2, 3]

    items = []   # (odin name, qualified F# name, rows)

    def add(odin, module, name, table):
        items.append((odin, "%s.%s" % (module, name), table[name]))

    for i in range(256):
        add("font_%d" % i, "CharacterPatterns", "character%d" % i, chars)
    add("filled", "CommonPatterns", "Filled", common)
    add("empty", "CommonPatterns", "Empty", common)
    for d, n in zip(["north", "east", "south", "west"], ["ExplorerN", "ExplorerE", "ExplorerS", "ExplorerW"]):
        add("explorer_" + d, "ExplorerPatterns", n, explorer)
    for n in ["Treasure", "Key", "Sword", "Shield", "Hourglass", "Potion", "LoveInterest", "Amulet", "Exit"]:
        add("item_" + n.lower(), "ExplorerPatterns", n, explorer)
    for n in ["Skeleton", "Zombie", "Mummy", "Ghoul", "Golem", "Wizard"]:
        add("monster_" + n.lower(), "MonsterPatterns", n, monsters)
    for i, n in enumerate(room_by_index):
        add("room_%d" % i, "RoomPatterns", n, rooms)
    for i in range(4):
        add("lock_%d" % i, "RoomPatterns", lock_by_dir[i], rooms)
    return items, font_names


def palette():
    """Colors.fs: the PaletteColor union order and each color's ARGB."""
    text = read("Colors.fs")
    union = re.search(r"type PaletteColor =(.*)", text).group(1)
    names = [n.strip() for n in union.split("|") if n.strip()]
    argb = {}
    for m in re.finditer(r"\|\s*(\w+)\s*->\s*Color\.FromArgb\(\s*(\d+),\s*(\d+),\s*(\d+),\s*(\d+)\)", text):
        argb[m.group(1)] = tuple(int(m.group(i)) for i in range(2, 6))
    assert sorted(argb) == sorted(names), (set(names) ^ set(argb))
    return names, argb


def ada(name):
    return re.sub(r"(?<!^)(?=[A-Z])", "_", name)


def generate():
    items, font_names = collect()
    by_odin = {o: r for o, _, r in items}
    out = []
    w = out.append
    w("// Code generated by tools/gen_patterns.py from MazeExplorer/MazeExplorerUILibrary/*.fs. DO NOT EDIT.")
    w("package ui")
    w("")
    w("// One 8 by 8 pattern: eight rows, bit 7 is the leftmost pixel (the F# 'X' cells).")
    w("Pattern :: [8]u8")
    w("")

    def lit(rows):
        return "{" + ", ".join("0x%02x" % row_byte(r) for r in rows) + "}"

    names, argb = palette()
    w("// Colors.fs: PaletteColor, in the original order. Transparent has alpha 0 and is never drawn.")
    w("Palette_Color :: enum u8 {")
    for n in names:
        w("\t%s," % ada(n))
    w("}")
    w("")
    w("// Bytes R, G, B, A (a little-endian u32 is A<<24 | B<<16 | G<<8 | R).")
    w("PALETTE := [Palette_Color]u32 {")
    for n in names:
        a, r, g, b = argb[n]
        w("\t.%s = 0x%02x%02x%02x%02x," % (ada(n), a, b, g, r))
    w("}")
    w("")
    w("// FontTiles.fs: code point -> pattern. Code point 16 uses the pattern of character 6, as the original does.")
    w("FONT_PATTERNS := [256]Pattern {")
    for cp, name in enumerate(font_names):
        w("\t%s, // %d" % (lit(by_odin["font_" + name[len("character"):]]), cp))
    w("}")
    w("")
    w("PATTERN_FILLED := Pattern%s" % lit(by_odin["filled"]))
    w("PATTERN_EMPTY := Pattern%s" % lit(by_odin["empty"]))
    w("")
    w("// Indexed by game.Direction (North, East, South, West).")
    w("PATTERN_EXPLORER := [4]Pattern {")
    for d in ["north", "east", "south", "west"]:
        w("\t%s," % lit(by_odin["explorer_" + d]))
    w("}")
    w("")
    w("// Indexed by the exits: north = 1, east = 2, south = 4, west = 8.")
    w("PATTERN_ROOM := [16]Pattern {")
    for i in range(16):
        w("\t%s," % lit(by_odin["room_%d" % i]))
    w("}")
    w("")
    w("// Indexed by game.Direction: the lock drawn on the side of a locked cell that faces the corridor.")
    w("PATTERN_LOCK := [4]Pattern {")
    for i in range(4):
        w("\t%s," % lit(by_odin["lock_%d" % i]))
    w("}")
    w("")
    for n in ["treasure", "key", "sword", "shield", "hourglass", "potion", "loveinterest", "amulet", "exit"]:
        w("PATTERN_ITEM_%s := Pattern%s" % (n.upper(), lit(by_odin["item_" + n])))
    w("")
    for n in ["skeleton", "zombie", "mummy", "ghoul", "golem", "wizard"]:
        w("PATTERN_MONSTER_%s := Pattern%s" % (n.upper(), lit(by_odin["monster_" + n])))
    w("")
    return "\n".join(out)


def dump():
    items, _ = collect()
    return "\n".join("%s %s" % (fq, fmt(rows)) for _, fq, rows in items) + "\n"


def fsx():
    root = SRC.replace("\\", "/")
    items, _ = collect()
    lines = []
    lines.append('#load "%s/Pattern.fs"' % root)
    for f in ["CharacterPatterns", "CommonPatterns", "ExplorerPatterns", "MonsterPatterns", "RoomPatterns"]:
        lines.append('#load "%s/%s.fs"' % (root, f))
    lines.append("let show (name: string) (p: bool list list) =")
    lines.append("    let rows = p |> List.map (fun r -> r |> List.fold (fun acc b -> acc * 2 + (if b then 1 else 0)) 0 |> sprintf \"%02x\")")
    lines.append("    printfn \"%s %s\" name (System.String.Join(\" \", rows))")
    for _, fq, _ in items:
        lines.append('show "%s" %s' % (fq, fq))
    return "\n".join(lines) + "\n"


if __name__ == "__main__":
    arg = sys.argv[1] if len(sys.argv) > 1 else ""
    if arg == "--dump":
        sys.stdout.write(dump())
    elif arg == "--fsx":
        sys.stdout.write(fsx())
    elif arg == "--check":
        with open(OUT) as f:
            if f.read() != generate() + "\n":
                sys.exit("odin/ui/patterns_gen.odin is out of date: run tools/gen_patterns.py")
        print("patterns_gen.odin is up to date")
    else:
        with open(OUT, "w") as f:
            f.write(generate() + "\n")
        print("wrote", OUT)
