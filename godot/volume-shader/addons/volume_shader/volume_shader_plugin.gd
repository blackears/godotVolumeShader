# MIT License
#
# Copyright (c) 2025 Mark McKay
# https://github.com/blackears/cyclopsLevelBuilder
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
extends EditorPlugin

#@onready var image_stack_window:ImageStackPreporcessor = preload("res://addons/volume_shader/preprocessors/image_stack/image_stack_preprocessor.tscn").instantiate()

var submenu:PopupMenu

func _ready():
#	image_stack_window.set_unparent_when_invisible(true)
	#print("ready submenu ", submenu)
	pass


func on_submenu_pressed(index:int):
	match index:
		0:
			#var win:Window = Window.new()
			#win.close_requested.connect(func() : win.queue_free())
			#win.size = Vector2i(800, 600)
			#win.initial_position = Window.WINDOW_INITIAL_POSITION_CENTER_PRIMARY_SCREEN
			#win.exclusive = true
			#win.add_child(image_stack_window)
			#
			#EditorInterface.popup_dialog(win)
			
			var image_stack_window:ImageStackPreporcessor = preload("res://addons/volume_shader/preprocessors/image_stack/image_stack_preprocessor.tscn").instantiate()
			EditorInterface.popup_dialog(image_stack_window)
		1:
			var win:NpyPreprocessor = preload("res://addons/volume_shader/preprocessors/npy/npy_preprocessor.tscn").instantiate()
			EditorInterface.popup_dialog(win)
			
			pass
	pass

func _enter_tree() -> void:
	# Initialization of the plugin goes here.
	if !submenu:
		submenu = PopupMenu.new()
		submenu.index_pressed.connect(on_submenu_pressed)
		
		submenu.add_item("Image Stack")
		submenu.add_item("Npy Data")
		
	#print("submenu ", submenu)
	add_tool_submenu_item("Volume Data Preprocessor", submenu)
	pass


func _exit_tree() -> void:
	# Clean-up of the plugin goes here.
	remove_tool_menu_item("Volume Data Converter")
	pass
