@tool
extends Resource
class_name Volume3DReader

enum CompressionType { RAW, ZSTD, JPG, PNG }

var file:FileAccess
var mipmaps:bool
var compression:CompressionType
var volume:Vector3i
var num_frames:int
var version:Vector2i

var num_image_layers_per_frame:int

var image_table_index_pos:int

func open(path:String):
	file = FileAccess.open(path, FileAccess.READ)
	
	var magic_buf:PackedByteArray = file.get_buffer(4)
	var magic_num:String = magic_buf.get_string_from_ascii()
	if magic_num != "VOL3":
		#Bad number
		return
	
	version = Vector2i(file.get_32(), file.get_32())
	compression = file.get_16()
	mipmaps = file.get_16()
	
	volume = Vector3i(
		file.get_32(),
		file.get_32(),
		file.get_32()
	)
	
	num_frames = file.get_32()
	num_image_layers_per_frame = file.get_32()
	
	image_table_index_pos = file.get_position()
	
func read_image_stack(frame:int)->Array[Image]:
	frame = clamp(frame, 0, num_frames - 1)
	
	var image_stack:Array[Image]
	
	file.seek(image_table_index_pos + frame * num_image_layers_per_frame * 8)
	#print("table read ", file.get_position())
	
	var image_positions:PackedInt64Array
	image_positions.resize(num_image_layers_per_frame)
	for i in num_image_layers_per_frame:
		image_positions[i] = file.get_64()
	
	#print("image_positions ", image_positions)
	
	image_stack.resize(num_image_layers_per_frame)
	
	for i in num_image_layers_per_frame:
		file.seek(image_positions[i])
		var size:int = file.get_32()
		var data_buf:PackedByteArray = file.get_buffer(size)
		
		match compression:
			CompressionType.RAW:
				var width:int = data_buf.decode_u16(0)
				var height:int = data_buf.decode_u16(2)
				
				var img:Image = Image.create_from_data(width, height, false, Image.FORMAT_RGBAF, 
					data_buf.slice(4))
				image_stack[i] = img
			
			CompressionType.ZSTD:
				var width:int = data_buf.decode_u16(0)
				var height:int = data_buf.decode_u16(2)
				var buf_size:int = data_buf.decode_u32(4)
				
				var img_data:PackedByteArray = data_buf.slice(8).decompress(buf_size, FileAccess.COMPRESSION_ZSTD)
				var img:Image = Image.create_from_data(width, height, false, Image.FORMAT_RGBAF, 
					img_data)
				image_stack[i] = img

			#CompressionType.JPG:
				#var image:Image = Image.new()
				#image.load_jpg_from_buffer(data_buf)
				#image.convert(Image.FORMAT_RGBAF)
				#image_stack[i] = image
#
			#CompressionType.PNG:
				#var image:Image = Image.new()
				#image.load_png_from_buffer(data_buf)
				#image.convert(Image.FORMAT_RGBAF)
				#image_stack[i] = image
			
			
	
	return image_stack
