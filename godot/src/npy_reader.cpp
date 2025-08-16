#include "npy_reader.h"
#include <godot_cpp/core/class_db.hpp>

using namespace godot;

void NpyReader::_bind_methods() {
	ClassDB::bind_method(D_METHOD("get_path"), &NpyReader::get_path);
	ClassDB::bind_method(D_METHOD("set_path", "p_path"), &NpyReader::set_path);
	ADD_PROPERTY(PropertyInfo(Variant::STRING, "path", PROPERTY_HINT_FILE, "*.npy"), "set_path", "get_path");
}
