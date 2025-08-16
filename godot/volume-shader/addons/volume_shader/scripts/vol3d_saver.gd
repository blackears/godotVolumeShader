@tool
extends Resource
class_name Volume3DSaver

var file:FileAccess

var image_table_offset:int
var image_table_write_offset:int
var image_data_write_pos:int

enum CompressionType { RAW, ZSTD, JPG, PNG }
var compress_type:CompressionType
var mipmaps:bool
var num_volume_layers:int

static func get_num_vol_layers_with_mipmaps(size:Vector3i)->int:
	if size == Vector3i.ONE:
		return 1
		
	return size.z + get_num_vol_layers_with_mipmaps(Image3DTools.shrink_mipmap_size(size))

func open(path:String, volume:Vector3i, num_frames:int, compress_type:CompressionType, mipmaps:bool = true):
	self.compress_type = compress_type
	self.mipmaps = mipmaps
	
	num_volume_layers = get_num_vol_layers_with_mipmaps(volume) \
		if mipmaps else volume.z
	
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(path)
		
	file = FileAccess.open(path, FileAccess.WRITE)
	if !file:
		var err:Error = FileAccess.get_open_error()
		print(error_string(err))
		print("Could not open file for writing: " + path)
		return
	
	file.store_buffer("VOL3".to_ascii_buffer())
	file.store_32(1) #Version major
	file.store_32(0) #Version minor
	
	file.store_16(compress_type)
	file.store_16(mipmaps)
	
	file.store_32(volume.x)
	file.store_32(volume.y)
	file.store_32(volume.z)
	file.store_32(num_frames)

	#Images per frame
	file.store_32(num_volume_layers)
	
	image_table_offset = file.get_position()
	image_table_write_offset = image_table_offset
	var data_offset:int = image_table_offset + num_volume_layers * num_frames * 8
#	file.seek(data_offset)
	
	image_data_write_pos = data_offset

func close():
	file.close()

func append_image_data(buffer:PackedByteArray):
	file.seek(image_table_write_offset)
	file.store_64(image_data_write_pos)
	image_table_write_offset = file.get_position()
	
	file.seek(image_data_write_pos)
	file.store_32(buffer.size())
	file.store_buffer(buffer)
	image_data_write_pos = file.get_position()

func append_image_stack(stack:Array[Image]):
	if stack.size() != num_volume_layers:
		printerr("Stack size " + str(stack.size()) + 
			" must match number of layers in a volume: ", num_volume_layers)
		return
	
	for img in stack:
		match compress_type:
			CompressionType.RAW:
				var data:PackedByteArray
				data.resize(4)
				data.encode_u16(0, img.get_width())
				data.encode_u16(2, img.get_height())
				data.append_array(img.get_data())
				append_image_data(data)
				
			CompressionType.ZSTD:
				var img_data:PackedByteArray = img.get_data()
				
				var data:PackedByteArray
				data.resize(8)
				data.encode_u16(0, img.get_width())
				data.encode_u16(2, img.get_height())
				data.encode_u32(4, img_data.size())
				data.append_array(img_data.compress(FileAccess.COMPRESSION_ZSTD))
				append_image_data(data)
				
			#CompressionType.JPG:
				#var buffer:PackedByteArray = img.save_jpg_to_buffer()
				#append_image_data(buffer)
				#
			#CompressionType.PNG:
				#var buffer:PackedByteArray = img.save_png_to_buffer()
				#append_image_data(buffer)
				
	
	
