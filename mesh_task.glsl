#[mesh_task]
#version 460

#extension GL_EXT_mesh_shader : require

layout (local_size_x = 1) in;

struct Payload {
	uint value;
};
taskPayloadSharedEXT Payload payload;

void main() {
	payload.value = gl_WorkGroupID.x;
	EmitMeshTasksEXT(gl_NumWorkGroups.x, 1, 1);
}