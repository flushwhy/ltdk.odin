package ldtk

// Data model for an LDtk project. Shapes match the LDtk JSON schema closely
// enough for `core:encoding/json` to fill them in via reflection; fields
// whose JSON name doesn't follow Odin naming conventions get an explicit
// `json:"..."` tag.

import "core:encoding/json"
import "core:mem/virtual"

// A rectangle within a tileset image. Used both for enum-value icons and
// (as of the current schema) for the "Tile" field instance type.
Tileset_Rect :: struct {
	tileset_uid: int `json:"tilesetUid"`,
	x:           int `json:"x"`,
	y:           int `json:"y"`,
	w:           int `json:"w"`,
	h:           int `json:"h"`,
}

Field_Instance :: struct {
	identifier: string     `json:"__identifier"`,
	type:       string     `json:"__type"`,
	value:      json.Value `json:"__value"`,
	def_uid:    int        `json:"defUid"`,
}

Level_Neighbor :: struct {
	// "n"/"s"/"e"/"w", the diagonal corners "ne"/"nw"/"se"/"sw" (added in
	// 1.5.3), or the depth markers "<"/">"/"o" (added in 1.4.0).
	dir: string `json:"dir"`,

	// `levelIid` is the current way to identify the neighbor; `levelUid`
	// was removed from the JSON export in 1.2.0 and will always be 0 on
	// projects made with a recent LDtk. Kept for old exports.
	level_iid: string `json:"levelIid"`,
	level_uid: int    `json:"levelUid"`,
}

Entity_Instance :: struct {
	identifier:      string           `json:"__identifier"`,
	grid:            [2]int           `json:"__grid"`,
	px:              [2]int           `json:"px"`,
	def_uid:         int              `json:"defUid"`,
	field_instances: []Field_Instance `json:"fieldInstances"`,
}

// Shared shape for both `autoLayerTiles` and `gridTiles`.
Tile_Instance :: struct {
	px:  [2]int `json:"px"`,
	src: [2]int `json:"src"`,
	f:   int    `json:"f"`,
	t:   int    `json:"t"`,
}

// Legacy per-cell `intGrid` array (as opposed to the flat `intGridCsv`).
Int_Grid_Value :: struct {
	coord_id: int `json:"coordId"`,
	v:        int `json:"v"`,
}

Layer_Instance :: struct {
	identifier:       string            `json:"__identifier"`,
	type:             string            `json:"__type"`,
	c_wid:            int               `json:"__cWid"`,
	c_hei:            int               `json:"__cHei"`,
	grid_size:        int               `json:"__gridSize"`,
	level_id:         int               `json:"levelId"`,
	layer_def_uid:    int               `json:"layerDefUid"`,
	px_offset_x:      int               `json:"pxOffsetX"`,
	px_offset_y:      int               `json:"pxOffsetY"`,
	int_grid_csv:     []int             `json:"intGridCsv"`,
	auto_layer_tiles: []Tile_Instance   `json:"autoLayerTiles"`,
	grid_tiles:       []Tile_Instance   `json:"gridTiles"`,
	entity_instances: []Entity_Instance `json:"entityInstances"`,
	int_grid:         []Int_Grid_Value  `json:"intGrid"`,
}

Level :: struct {
	identifier:      string           `json:"identifier"`,
	iid:             string           `json:"iid"`,
	uid:             int              `json:"uid"`,
	px_wid:          int              `json:"pxWid"`,
	px_hei:          int              `json:"pxHei"`,
	world_x:         int              `json:"worldX"`,
	world_y:         int              `json:"worldY"`,
	world_depth:     int              `json:"worldDepth"`,
	field_instances: []Field_Instance `json:"fieldInstances"`,
	neighbors:       []Level_Neighbor `json:"__neighbours"`,
	layer_instances: []Layer_Instance `json:"layerInstances"`,
}

Tileset_Def :: struct {
	identifier:     string `json:"identifier"`,
	uid:            int    `json:"uid"`,
	rel_path:       string `json:"relPath"`,
	px_wid:         int    `json:"pxWid"`,
	px_hei:         int    `json:"pxHei"`,
	tile_grid_size: int    `json:"tileGridSize"`,
	spacing:        int    `json:"spacing"`,
	padding:        int    `json:"padding"`,
}

Enum_Value_Def :: struct {
	id: string `json:"id"`,

	// `tileRect` is the current way to get an enum value's icon; `tileId`
	// and `__tileSrcRect` were both removed from the JSON export in 1.4.0
	// and will be absent (zero value) on projects made with a recent LDtk.
	// Kept for old exports.
	tile_rect:     ^Tileset_Rect `json:"tileRect"`, // nil if the value has no icon
	tile_id:       int          `json:"tileId"`,
	tile_src_rect: [4]int       `json:"__tileSrcRect"`,
}

Enum_Def :: struct {
	identifier:       string           `json:"identifier"`,
	uid:              int              `json:"uid"`,
	icon_tileset_uid: int              `json:"iconTilesetUid"`,
	values:           []Enum_Value_Def `json:"values"`,
}

Defs :: struct {
	tilesets: []Tileset_Def `json:"tilesets"`,
	enums:    []Enum_Def    `json:"enums"`,
}

// A World holds its own levels plus world-layout settings. Only populated
// when the project has the (currently opt-in/preview) "Multi-worlds" flag
// enabled -- otherwise `Project.worlds` is empty and levels live directly
// in `Project.levels` instead. Use `all_levels()` in query.odin rather than
// reading `.levels` / `.worlds` directly if you want code that works either
// way.
World :: struct {
	identifier: string  `json:"identifier"`,
	iid:        string  `json:"iid"`,
	levels:     []Level `json:"levels"`,
}

Project :: struct {
	json_version:      string  `json:"jsonVersion"`,
	default_pivot_x:   f64     `json:"defaultPivotX"`,
	default_pivot_y:   f64     `json:"defaultPivotY"`,
	default_grid_size: int     `json:"defaultGridSize"`,
	bg_color:          string  `json:"bgColor"`,
	next_uid:          int     `json:"nextUid"`,
	defs:              Defs    `json:"defs"`,
	levels:            []Level `json:"levels"`,
	worlds:            []World `json:"worlds"`,

	// Backing storage for every string/slice/map above. Freed as a unit
	// in `free_project` -- see loader.odin.
	arena: virtual.Arena,
}

// Simple 2D integer point, used for LDtk's Point field type.
Point :: struct {
	cx, cy: int,
}
