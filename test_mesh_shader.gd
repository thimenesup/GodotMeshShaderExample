extends Node

const SIZEOF_U16 := 2
const SIZEOF_VECTOR3 := 12

@export var _task_shader: RDShaderFile = null
@export var _mesh_shader: RDShaderFile = null
@export var _fragment_shader: RDShaderFile = null

@export_range(1, 65535) var _sphere_count := 1
@export var _dispatch_indirect := false

var _stream := StreamPeerBuffer.new()

var _rd: RenderingDevice = null

var _shader := RID()
var _pipeline := RID()

var _color_texture := RID()
var _depth_texture := RID()
var _framebuffer := RID()

var _storage_buffer := RID()
var _uniform_buffer := RID()
var _uniform_set := RID()

var _indirect_buffer := RID()

func _ready() -> void:
	_rd = RenderingServer.get_rendering_device()
	
	if not _rd.has_feature(RenderingDevice.SUPPORTS_MESH_SHADER):
		printerr("The GPU doesn't support Mesh Shaders")
		set_process(false)
		return
	
	print(_rd.limit_get(RenderingDevice.LIMIT_MAX_MESH_TASK_WORKGROUP_COUNT_X))
	print(_rd.limit_get(RenderingDevice.LIMIT_MAX_MESH_TASK_WORKGROUP_COUNT_Y))
	print(_rd.limit_get(RenderingDevice.LIMIT_MAX_MESH_TASK_WORKGROUP_COUNT_Z))
	print(_rd.limit_get(RenderingDevice.LIMIT_MAX_MESH_WORKGROUP_COUNT_X))
	print(_rd.limit_get(RenderingDevice.LIMIT_MAX_MESH_WORKGROUP_COUNT_Y))
	print(_rd.limit_get(RenderingDevice.LIMIT_MAX_MESH_WORKGROUP_COUNT_Z))
	
	#Mesh Shader pipelines don't use any vertex format
	var vertex_format := RenderingDevice.INVALID_FORMAT_ID
	
	#Shader for pipeline
	if true:
		var bundle := RDShaderSPIRV.new()
		bundle.bytecode_mesh_task = _task_shader.get_spirv().bytecode_mesh_task if _task_shader != null else PackedByteArray()
		bundle.bytecode_mesh = _mesh_shader.get_spirv().bytecode_mesh
		bundle.bytecode_fragment = _fragment_shader.get_spirv().bytecode_fragment
		_shader = _rd.shader_create_from_spirv(bundle)
	
	#Framebuffer format
	var framebuffer_format := RenderingDevice.INVALID_FORMAT_ID
	if true:
		var color := RDAttachmentFormat.new()
		color.format = RenderingDevice.DATA_FORMAT_R8G8B8A8_UNORM
		color.usage_flags = RenderingDevice.TEXTURE_USAGE_COLOR_ATTACHMENT_BIT
		
		var depth := RDAttachmentFormat.new()
		depth.format = RenderingDevice.DATA_FORMAT_D32_SFLOAT
		depth.usage_flags = RenderingDevice.TEXTURE_USAGE_DEPTH_STENCIL_ATTACHMENT_BIT
		
		var attachments := [color, depth]
		framebuffer_format = _rd.framebuffer_format_create(attachments)
	
	#Pipeline
	if true:
		var primitive := RenderingDevice.RENDER_PRIMITIVE_TRIANGLES
		
		var rasterization := RDPipelineRasterizationState.new()
		
		var multisample := RDPipelineMultisampleState.new()
		
		var depth := RDPipelineDepthStencilState.new()
		depth.enable_depth_test = true
		depth.enable_depth_write = true
		depth.depth_compare_operator = RenderingDevice.COMPARE_OP_LESS_OR_EQUAL
		
		var blend := RDPipelineColorBlendState.new()
		if true:
			var blend0 := RDPipelineColorBlendStateAttachment.new()
			var attachments := [blend0]
			blend.attachments = attachments
		
		_pipeline = _rd.render_pipeline_create(_shader, framebuffer_format, vertex_format, primitive, rasterization, multisample, depth, blend)
	
	#Framebuffer
	if true:
		var width := 1280
		var height := 720
		
		if true:
			var color := RDTextureFormat.new()
			color.format = RenderingDevice.DATA_FORMAT_R8G8B8A8_UNORM
			color.width = width
			color.height = height
			color.texture_type = RenderingDevice.TEXTURE_TYPE_2D
			var flags := RenderingDevice.TEXTURE_USAGE_COLOR_ATTACHMENT_BIT
			flags |= RenderingDevice.TEXTURE_USAGE_SAMPLING_BIT #So we can then display the texture
			color.usage_bits = flags
			
			var view := RDTextureView.new()
			view.format_override = RenderingDevice.DATA_FORMAT_R8G8B8A8_UNORM
			_color_texture = _rd.texture_create(color, view)
		
		if true:
			var depth := RDTextureFormat.new()
			depth.format = RenderingDevice.DATA_FORMAT_D32_SFLOAT
			depth.width = width
			depth.height = height
			depth.texture_type = RenderingDevice.TEXTURE_TYPE_2D
			depth.usage_bits = RenderingDevice.TEXTURE_USAGE_DEPTH_STENCIL_ATTACHMENT_BIT
			
			var view := RDTextureView.new()
			view.format_override = RenderingDevice.DATA_FORMAT_D32_SFLOAT
			_depth_texture = _rd.texture_create(depth, view)
		
		var textures := [_color_texture, _depth_texture]
		_framebuffer = _rd.framebuffer_create(textures)
	
	#Shader uniforms
	if true:
		var uniforms := Array()
		
		if true:
			_stream.clear()
			for i in range(_sphere_count):
				var sphere := Vector4(i, 0, 0, 1)
				put_vector4(_stream, sphere)
			_storage_buffer = _rd.storage_buffer_create(_stream.data_array.size(), _stream.data_array)
			
			var uniform := RDUniform.new()
			uniform.uniform_type = RenderingDevice.UNIFORM_TYPE_STORAGE_BUFFER
			uniform.binding = 0
			uniform.add_id(_storage_buffer)
			uniforms.push_back(uniform)
		
		if true:
			_stream.clear()
			put_projection(_stream, Projection.IDENTITY)
			_uniform_buffer = _rd.uniform_buffer_create(_stream.data_array.size(), _stream.data_array)
			
			var uniform := RDUniform.new()
			uniform.uniform_type = RenderingDevice.UNIFORM_TYPE_UNIFORM_BUFFER
			uniform.binding = 1
			uniform.add_id(_uniform_buffer)
			uniforms.push_back(uniform)
		
		_uniform_set = _rd.uniform_set_create(uniforms, _shader, 0)
	
	#Dispatch indirect buffer
	if true:
		_stream.clear()
		_stream.put_u32(_sphere_count); _stream.put_u32(1); _stream.put_u32(1)
		_indirect_buffer = _rd.storage_buffer_create(_stream.data_array.size(), _stream.data_array, RenderingDevice.STORAGE_BUFFER_USAGE_DISPATCH_INDIRECT)
	
	#Display
	if true:
		var rd_texture := Texture2DRD.new()
		rd_texture.texture_rd_rid = _color_texture
		$TextureRect.texture = rd_texture

func _process(_delta: float) -> void:
	if true:
		var camera := $Camera3D as Camera3D
		var projection := camera.get_camera_projection()
		var projection_view := projection * Projection(camera.transform.affine_inverse())
		
		_stream.clear()
		put_projection(_stream, projection_view)
		_rd.buffer_update(_uniform_buffer, 0, _stream.data_array.size(), _stream.data_array)
	
	var initial := RenderingDevice.INITIAL_ACTION_CLEAR
	var final := RenderingDevice.FINAL_ACTION_STORE
	var clear_colors := PackedColorArray()
	clear_colors.append(Color(0.2, 0.2, 0.25))
	var clear_depth := 1.0
	
	_stream.clear()
	put_projection(_stream, Projection($MeshInstance3D.transform))
	
	var list := _rd.draw_list_begin(_framebuffer, initial, final, initial, final, clear_colors, clear_depth)
	_rd.draw_list_bind_render_pipeline(list, _pipeline)
	_rd.draw_list_bind_uniform_set(list, _uniform_set, 0)
	_rd.draw_list_set_push_constant(list, _stream.data_array, _stream.data_array.size())
	
	if _dispatch_indirect:
		_rd.draw_list_dispatch_mesh_indirect(list, _indirect_buffer, 0)
	else:
		_rd.draw_list_dispatch_mesh(list, _sphere_count, 1, 1)
	
	_rd.draw_list_end()


static func put_vector4(stream: StreamPeer, v: Vector4) -> void:
	stream.put_float(v.x); stream.put_float(v.y); stream.put_float(v.z); stream.put_float(v.w)

static func put_projection(stream: StreamPeer, p: Projection) -> void:
	stream.put_float(p.x.x); stream.put_float(p.x.y); stream.put_float(p.x.z); stream.put_float(p.x.w)
	stream.put_float(p.y.x); stream.put_float(p.y.y); stream.put_float(p.y.z); stream.put_float(p.y.w)
	stream.put_float(p.z.x); stream.put_float(p.z.y); stream.put_float(p.z.z); stream.put_float(p.z.w)
	stream.put_float(p.w.x); stream.put_float(p.w.y); stream.put_float(p.w.z); stream.put_float(p.w.w)
