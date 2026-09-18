package ldtk

// Loading is arena-backed: every string/slice/map that `json.unmarshal`
// allocates while filling in a Project lives in `proj.arena`, so freeing a
// project is a single call instead of the field-by-field free tree the
// original C loader needed.

import "core:encoding/json"
import "core:mem/virtual"
import "core:os"

load_project :: proc(path: string) -> (proj: ^Project, ok: bool) {
    orig_allocator := context.allocator

    // Pass the allocator and check against the error return value
    data, read_err := os.read_entire_file(path, orig_allocator)
    if read_err != nil {
        return nil, false
    }
    // Ensure we delete 'data' using the original allocator
    defer delete(data, orig_allocator)

    proj = new(Project)

    if virtual.arena_init_growing(&proj.arena) != nil {
        free(proj)
        return nil, false
    }

    // Redirect allocations made during unmarshal into the arena
    context.allocator = virtual.arena_allocator(&proj.arena)

    if err := json.unmarshal(data, proj); err != nil {
        virtual.arena_destroy(&proj.arena)
        free(proj)
        return nil, false
    }

    return proj, true
}

free_project :: proc(proj: ^Project) {
	if proj == nil {
		return
	}
	virtual.arena_destroy(&proj.arena)
	free(proj)
}
