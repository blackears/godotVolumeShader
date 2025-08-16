#ifndef NPY_READER_H
#define NPY_READER_H

#include <godot_cpp/classes/resource.hpp>


namespace godot {

class NpyReader : public Resource {
	GDCLASS(NpyReader, Resource)

private:
    String path;

protected:
	static void _bind_methods();


public:
    NpyReader() {
    }
	~NpyReader() {}

    String get_path() const { return path; }
    void set_path(String _path) { 
        if (path == _path)
            return;
        path = _path; 
        emit_changed();
    }

};

}

#endif