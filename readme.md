# ldtk

A small Odin package for loading [LDtk](https://ldtk.io) project files
(`.ldtk`). Tested against the LDtk JSON schema through **v1.5.3**.

It leans on `core:encoding/json`'s struct unmarshaling instead of manually
walking the JSON tree, and loads a whole project into one arena so freeing
it is a single call instead of tracking down every nested allocation by
hand.

## Requirements

- A reasonably recent Odin compiler (uses `core:encoding/json`,
  `core:mem/virtual`, `core:os`).

## Installation

Copy the `ldtk/` directory into your project and import it by relative
path, the same way the bundled `example/` does:

```odin
import "../ldtk"
```

Or drop it under one of your `-collection` roots and import it by
collection name instead.

## Layout

```
ldtk/
  types.odin    -- Field_Instance, Level, Layer_Instance, Project, etc.
  loader.odin   -- load_project / free_project (arena-backed)
  query.odin    -- find_level_by_name, find_layer, find_entities, find_field
  field.odin    -- field_as_int/float/bool/string/point (+ array variants)
example/
  main.odin     -- a short program showing how the pieces fit together
```

## Quick start

```odin
package main

import "core:fmt"
import "../ldtk"

main :: proc() {
	proj, ok := ldtk.load_project("world.ldtk")
	if !ok {
		fmt.eprintln("failed to load project")
		return
	}
	defer ldtk.free_project(proj)

	level := ldtk.find_level_by_name(proj, "Level_0")
	if level == nil {
		return
	}

	layer := ldtk.find_layer(level, "Collisions")
	fmt.println("collision layer size:", layer.c_wid, "x", layer.c_hei)

	spawns := ldtk.find_entities(level, "PlayerSpawn", context.temp_allocator)
	for spawn in spawns {
		fmt.println("spawn at:", spawn.px)
	}
}
```

## Memory management

`load_project` allocates every string, slice, and map it fills in from a
growing arena stored on the `Project` itself (`Project.arena`). There's
nothing else to track:

```odin
proj, ok := ldtk.load_project("world.ldtk")
defer ldtk.free_project(proj) // releases the whole arena in one call
```

Anything returned by a `find_*` proc is a pointer into that arena, so it's
only valid until `free_project` runs. `find_entities` and the
`field_as_*_array` procs take an optional `allocator` parameter for the
*container* they return (a slice of pointers, or a converted array) --
pass `context.temp_allocator` if you don't want to think about freeing it,
or your own allocator otherwise.

## API overview

**Loading**

| Proc | Description |
|---|---|
| `load_project(path: string) -> (^Project, bool)` | Reads and parses a `.ldtk` file. |
| `free_project(proj: ^Project)` | Frees the project's arena. |

**Lookups** (`query.odin`)

| Proc | Description |
|---|---|
| `all_levels(proj, allocator) -> []^Level` | Every level, whether under `Project.levels` or nested in `Project.worlds[i].levels`. |
| `find_level_by_name(proj, identifier) -> ^Level` | |
| `find_level_by_uid(proj, uid) -> ^Level` | |
| `find_level_by_iid(proj, iid) -> ^Level` | Prefer this on projects made with a recent LDtk -- see note below. |
| `find_layer(level, identifier) -> ^Layer_Instance` | |
| `find_entities(level, identifier, allocator) -> []^Entity_Instance` | Every entity with this identifier across all Entity layers in the level. |
| `find_field(fields, identifier) -> ^Field_Instance` | Works on both level- and entity-level `fieldInstances`. |

**Field values** (`field.odin`)

LDtk field instances are polymorphic (`Int`, `Float`, `Bool`, `String`,
`Point`, `Array<...>`, ...). `Field_Instance.value` holds the raw
`json.Value`; read it with:

| Proc | Returns |
|---|---|
| `field_as_int(f) -> (int, bool)` | |
| `field_as_float(f) -> (f64, bool)` | |
| `field_as_bool(f) -> (bool, bool)` | |
| `field_as_string(f) -> (string, bool)` | |
| `field_as_point(f) -> (Point, bool)` | `Point :: struct { cx, cy: int }` |
| `field_as_int_array(f, allocator) -> []int` | |
| `field_as_string_array(f, allocator) -> []string` | |
| `field_as_point_array(f, allocator) -> []Point` | |

Each returns `false`/`nil` if the field isn't actually that type, rather
than panicking.

## LDtk version notes

The schema has drifted in a few places since earlier LDtk releases; this
package tracks the current shape:

- `Level_Neighbor.level_uid` was removed from the JSON export in 1.2.0,
  replaced by `level_iid` (a string instance id). Both fields exist here;
  `level_uid` will read as `0` on modern exports. Use
  `find_level_by_iid` / `level_iid` for anything written by a recent LDtk.
- `Enum_Value_Def.tile_id` and `tile_src_rect` were removed in 1.4.0,
  replaced by a `tile_rect: ^Tileset_Rect` (nil if the value has no icon).
  Both old fields are kept but will be zero on modern exports.
- The (currently opt-in/preview) multi-worlds mode nests levels under a
  top-level `worlds` array instead of `levels`. `all_levels` and the
  `find_level_by_*` procs search both, so code written against them keeps
  working whether or not multi-worlds is turned on for a given project.

If a future LDtk release changes the schema again, the fix is almost
always just adding/adjusting a `json:"..."` tag in `types.odin` --
`core:encoding/json` does the rest.

## Caveat

`core:encoding/json`'s `Value` union case names (`i64`, `f64`, `bool`,
`string`, `json.Array`, `json.Object`) and `core:mem/virtual`'s `Arena`
proc names (`arena_init_growing`, `arena_allocator`, `arena_destroy`) have
shifted slightly across Odin releases. If something doesn't compile,
those are the first places to check against your installed version.

## License

No external dependencies are bundled -- this package only uses Odin's
`core` collection. License it however you license the rest of your
project.