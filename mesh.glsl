#[mesh]
#version 460

#extension GL_EXT_mesh_shader : require

layout (binding = 0, std430) buffer Data {
	vec4 spheres[];
} data;

layout (binding = 1) uniform Camera {
	mat4 projectionView;
} camera;

layout (push_constant) uniform Instance {
	mat4 transform;
} instance;

layout (local_size_x = 1) in;
layout (triangles, max_vertices = 3, max_primitives = 1) out;

struct Payload {
	uint value;
};
taskPayloadSharedEXT Payload payload;

void main() {
	SetMeshOutputsEXT(3, 1);

	vec3 origin = data.spheres[gl_WorkGroupID.x].xyz;
	vec3 offset = vec3(0, payload.value, 0);
	vec3 v0 = vec3( 0.0,  0.5, 0) + origin + offset;
	vec3 v1 = vec3(-0.5, -0.5, 0) + origin + offset;
	vec3 v2 = vec3( 0.5, -0.5, 0) + origin + offset;

	gl_MeshVerticesEXT[0].gl_Position = camera.projectionView * instance.transform * vec4(v0, 1);
	gl_MeshVerticesEXT[1].gl_Position = camera.projectionView * instance.transform * vec4(v1, 1);
	gl_MeshVerticesEXT[2].gl_Position = camera.projectionView * instance.transform * vec4(v2, 1);

	gl_PrimitiveTriangleIndicesEXT[0] = uvec3(0, 1, 2);
}