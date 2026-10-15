package game

// Ported from MazeExplorerLibrary: Maze.fs, Cardinal.fs, Neighbor.fs. The maze is a spanning tree of
// a MAZE_COLUMNS by MAZE_ROWS square grid, grown Prim-style from a random cell.

cell_index :: proc(column, row: int) -> int {
	return row * MAZE_COLUMNS + column
}

cell_column :: proc(cell: int) -> int {
	return cell % MAZE_COLUMNS
}

cell_row :: proc(cell: int) -> int {
	return cell / MAZE_COLUMNS
}

opposite :: proc(d: Direction) -> Direction {
	switch d {
	case .North: return .South
	case .East: return .West
	case .South: return .North
	case .West: return .East
	}
	return .North
}

turn_clockwise :: proc(d: Direction) -> Direction {
	switch d {
	case .North: return .East
	case .East: return .South
	case .South: return .West
	case .West: return .North
	}
	return .North
}

// The cell one step from `cell`, or false when that is off the grid.
neighbor :: proc(cell: int, d: Direction) -> (int, bool) {
	c, r := cell_column(cell), cell_row(cell)
	switch d {
	case .North: r -= 1
	case .East: c += 1
	case .South: r += 1
	case .West: c -= 1
	}
	if c < 0 || r < 0 || c >= MAZE_COLUMNS || r >= MAZE_ROWS {return 0, false}
	return cell_index(c, r), true
}

exit_count :: proc(g: ^Game, cell: int) -> int {
	return card(g.exits[cell])
}

@(private)
connect :: proc(g: ^Game, cell: int, d: Direction, other: int) {
	g.exits[cell] += {d}
	g.exits[other] += {opposite(d)}
}

generate_maze :: proc(g: ^Game) {
	g.exits = {}
	inside: [MAZE_CELLS]bool
	in_frontier: [MAZE_CELLS]bool
	frontier: [MAZE_CELLS]int
	count := 0

	start := rng_int(&g.rng, MAZE_CELLS)
	inside[start] = true
	for d in Direction {
		if nb, ok := neighbor(start, d); ok && !in_frontier[nb] {
			in_frontier[nb] = true
			frontier[count] = nb
			count += 1
		}
	}

	for count > 0 {
		i := rng_int(&g.rng, count)
		cell := frontier[i]
		count -= 1
		frontier[i] = frontier[count]
		in_frontier[cell] = false

		candidates: [4]Direction
		n := 0
		for d in Direction {
			if nb, ok := neighbor(cell, d); ok && inside[nb] {
				candidates[n] = d
				n += 1
			}
		}
		// A frontier cell always touches the inside by construction.
		d := candidates[rng_int(&g.rng, n)]
		nb, _ := neighbor(cell, d)
		connect(g, cell, d, nb)
		inside[cell] = true

		for d2 in Direction {
			if nb2, ok := neighbor(cell, d2); ok && !inside[nb2] && !in_frontier[nb2] {
				in_frontier[nb2] = true
				frontier[count] = nb2
				count += 1
			}
		}
	}
}

// Initialization.visibleLocations: the straight ray from `from` in direction `d`, through open
// connections only, including `from` itself.
visible_ray :: proc(g: ^Game, from: int, d: Direction) -> (cells: [MAZE_COLUMNS + MAZE_ROWS]int, count: int) {
	cell := from
	cells[0] = cell
	count = 1
	for count < len(cells) {
		if d not_in g.exits[cell] {break}
		nb, ok := neighbor(cell, d)
		if !ok {break}
		cell = nb
		cells[count] = cell
		count += 1
	}
	return
}

refresh_visible :: proc(g: ^Game) {
	g.visible = {}
	cells, count := visible_ray(g, g.position, g.orientation)
	for i in 0 ..< count {
		g.visible[cells[i]] = true
	}
}
