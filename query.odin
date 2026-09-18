package ldtk

// Lookups equivalent to the original getLevel / getLevelFromUid / getEntity
// / getLayer functions.

// Returns every level in the project, whether it's sitting directly under
// `proj.levels` (the default, single-world layout) or nested under
// `proj.worlds[i].levels` (multi-worlds mode). Prefer this over reading
// `.levels` directly so your code keeps working if multi-worlds gets
// switched on later.
all_levels :: proc(proj: ^Project, allocator := context.temp_allocator) -> []^Level {
	result: [dynamic]^Level
	result.allocator = allocator

	for &level in proj.levels {
		append(&result, &level)
	}
	for &world in proj.worlds {
		for &level in world.levels {
			append(&result, &level)
		}
	}
	return result[:]
}

find_level_by_name :: proc(proj: ^Project, identifier: string) -> ^Level {
	for level in all_levels(proj) {
		if level.identifier == identifier {
			return level
		}
	}
	return nil
}

find_level_by_uid :: proc(proj: ^Project, uid: int) -> ^Level {
	for level in all_levels(proj) {
		if level.uid == uid {
			return level
		}
	}
	return nil
}

// `iid` is the stable identifier current LDtk projects use to reference
// levels (including in `Level_Neighbor.level_iid`); prefer this over
// `find_level_by_uid` for anything written by a recent LDtk version.
find_level_by_iid :: proc(proj: ^Project, iid: string) -> ^Level {
	for level in all_levels(proj) {
		if level.iid == iid {
			return level
		}
	}
	return nil
}

find_layer :: proc(level: ^Level, identifier: string) -> ^Layer_Instance {
	for &layer in level.layer_instances {
		if layer.identifier == identifier {
			return &layer
		}
	}
	return nil
}

// Collects every entity with the given identifier across all Entity layers
// in a level. The returned slice is allocated with `allocator` (defaults to
// the caller's current allocator); the pointers inside it point into `level`.
find_entities :: proc(level: ^Level, identifier: string, allocator := context.allocator) -> []^Entity_Instance {
	matches: [dynamic]^Entity_Instance
	matches.allocator = allocator

	for &layer in level.layer_instances {
		if layer.type != "Entities" {
			continue
		}
		for &entity in layer.entity_instances {
			if entity.identifier == identifier {
				append(&matches, &entity)
			}
		}
	}
	return matches[:]
}

// Finds a field instance by identifier in any []Field_Instance slice --
// works for both level-level and entity-level fieldInstances.
find_field :: proc(fields: []Field_Instance, identifier: string) -> ^Field_Instance {
	for &f in fields {
		if f.identifier == identifier {
			return &f
		}
	}
	return nil
}
