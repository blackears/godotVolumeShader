# MIT License
#
# Copyright (c) 2023 Mark McKay
# https://github.com/blackears/godot_volume_layers
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

@tool
extends ImageTexture3D
class_name VolumeImageTexture3D

@export_file("*.vol3d") var path:String:
	set(v):
		if path == v:
			return
		path = v
		
		source = Volume3DReader.new()
		source.open(path)
		update_data()
		
@export var frame:int:
	set(v):
		if frame == v:
			return
		frame = v
		update_data()

var source:Volume3DReader

func _validate_property(property : Dictionary):
	#Do not write image data to resource file
	if property.name == "_images":
		property.usage = PROPERTY_USAGE_NONE
		
func update_data():
	if !source:
		return
	
	#print("update_data")
	
	var image_stack:Array[Image] = source.read_image_stack(frame)
#	print("image_stack.size() ", image_stack.size())
	for i in image_stack.size():
		var img = image_stack[i]
#		print("iomg.size ", i, " ", img.get_width(), " ", img.get_height())
	
	#print("source.volume ", source.volume)
	create(Image.FORMAT_RGBAF, source.volume.x, source.volume.y, source.volume.z, source.mipmaps, image_stack)
	
