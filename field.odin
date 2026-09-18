package ldtk

// LDtk's `__value` on a field instance can be a number, bool, string, null,
// a {cx,cy} point object, or an array of any of those (Array<Int>,
// Array<Point>, ...). These accessors type-switch on the raw json.Value
// instead of requiring a separate typed struct field per possible type.

import "core:encoding/json"

@(private)
as_int :: proc(v: json.Value) -> (int, bool) {
	#partial switch n in v {
	case i64:
		return int(n), true
	case f64:
		return int(n), true
	}
	return 0, false
}

field_as_int :: proc(f: ^Field_Instance) -> (int, bool) {
	return as_int(f.value)
}

field_as_float :: proc(f: ^Field_Instance) -> (result: f64, ok: bool) {
	#partial switch n in f.value {
	case i64:
		return f64(n), true
	case f64:
		return n, true
	}
	return 0, false
}

field_as_bool :: proc(f: ^Field_Instance) -> (bool, bool) {
	return f.value.(bool)
}

field_as_string :: proc(f: ^Field_Instance) -> (string, bool) {
	return f.value.(string)
}

field_as_point :: proc(f: ^Field_Instance) -> (Point, bool) {
	obj, is_obj := f.value.(json.Object)
	if !is_obj {
		return {}, false
	}
	cx, cx_ok := as_int(obj["cx"])
	cy, cy_ok := as_int(obj["cy"])
	if !cx_ok || !cy_ok {
		return {}, false
	}
	return Point{cx, cy}, true
}

field_as_int_array :: proc(f: ^Field_Instance, allocator := context.allocator) -> []int {
	arr, is_arr := f.value.(json.Array)
	if !is_arr {
		return nil
	}
	result := make([]int, len(arr), allocator)
	for v, i in arr {
		result[i], _ = as_int(v)
	}
	return result
}

field_as_string_array :: proc(f: ^Field_Instance, allocator := context.allocator) -> []string {
	arr, is_arr := f.value.(json.Array)
	if !is_arr {
		return nil
	}
	result := make([]string, len(arr), allocator)
	for v, i in arr {
		result[i], _ = v.(string)
	}
	return result
}

field_as_point_array :: proc(f: ^Field_Instance, allocator := context.allocator) -> []Point {
	arr, is_arr := f.value.(json.Array)
	if !is_arr {
		return nil
	}
	result := make([]Point, len(arr), allocator)
	for v, i in arr {
		obj, ok := v.(json.Object)
		if !ok {
			continue
		}
		cx, _ := as_int(obj["cx"])
		cy, _ := as_int(obj["cy"])
		result[i] = Point{cx, cy}
	}
	return result
}
