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

	fmt.println("json version:", proj.json_version)
	fmt.println("levels:", len(proj.levels))

	level := ldtk.find_level_by_name(proj, "Level_0")
	if level == nil {
		fmt.eprintln("level not found")
		return
	}

	layer := ldtk.find_layer(level, "Collisions")
	if layer != nil {
		fmt.println("collision layer size:", layer.c_wid, "x", layer.c_hei)
	}

	spawns := ldtk.find_entities(level, "PlayerSpawn", context.temp_allocator)
	for spawn in spawns {
		fmt.println("spawn at:", spawn.px)

		if f := ldtk.find_field(spawn.field_instances, "target"); f != nil {
			if pt, ok := ldtk.field_as_point(f); ok {
				fmt.println("  target point:", pt)
			}
		}
	}
}
