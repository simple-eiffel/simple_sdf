note
	description: "[
		SDF-specific GLSL code generator.

		Generates GLSL compute shader source code from SDF primitives
		and scenes. Includes:
		- SDF primitive functions (sphere, box, cylinder, etc.)
		- Boolean operations (union, subtraction, intersection)
		- Smooth blending operations
		- Ray marching code
		- Full shader generation from SDF_SCENE
	]"
	author: "Larry Rix"
	date: "$Date$"
	revision: "$Revision$"

class
	SDF_GLSL_BUILDER

inherit
	GLSL_BUILDER
		rename
			make as make_builder
		end

create
	make

feature {NONE} -- Initialization

	make
			-- Initialize SDF GLSL builder.
		do
			make_builder
		end

feature -- Primitive Functions

	emit_sphere_sdf
			-- Emit sdSphere function.
		do
			emit_raw_line ("float sdSphere(vec3 p, vec3 c, float r) {")
			emit_raw_line ("    return length(p - c) - r;")
			emit_raw_line ("}")
			newline
		end

	emit_box_sdf
			-- Emit sdBox function.
		do
			emit_raw_line ("float sdBox(vec3 p, vec3 c, vec3 b) {")
			emit_raw_line ("    vec3 q = abs(p - c) - b;")
			emit_raw_line ("    return length(max(q, 0.0)) + min(max(q.x, max(q.y, q.z)), 0.0);")
			emit_raw_line ("}")
			newline
		end

	emit_cylinder_sdf
			-- Emit sdCylinder function (vertical cylinder).
		do
			emit_raw_line ("float sdCylinder(vec3 p, vec3 c, float r, float h) {")
			emit_raw_line ("    vec2 d = abs(vec2(length((p - c).xz), p.y - c.y)) - vec2(r, h);")
			emit_raw_line ("    return min(max(d.x, d.y), 0.0) + length(max(d, 0.0));")
			emit_raw_line ("}")
			newline
		end

	emit_capsule_sdf
			-- Emit sdCapsule function.
		do
			emit_raw_line ("float sdCapsule(vec3 p, vec3 a, vec3 b, float r) {")
			emit_raw_line ("    vec3 pa = p - a, ba = b - a;")
			emit_raw_line ("    float h = clamp(dot(pa, ba) / dot(ba, ba), 0.0, 1.0);")
			emit_raw_line ("    return length(pa - ba * h) - r;")
			emit_raw_line ("}")
			newline
		end

	emit_torus_sdf
			-- Emit sdTorus function.
		do
			emit_raw_line ("float sdTorus(vec3 p, vec3 c, float R, float r) {")
			emit_raw_line ("    vec2 q = vec2(length((p - c).xz) - R, p.y - c.y);")
			emit_raw_line ("    return length(q) - r;")
			emit_raw_line ("}")
			newline
		end

	emit_plane_sdf
			-- Emit sdPlane function.
		do
			emit_raw_line ("float sdPlane(vec3 p, vec3 n, float h) {")
			emit_raw_line ("    return dot(p, normalize(n)) + h;")
			emit_raw_line ("}")
			newline
		end

	emit_cone_sdf
			-- Emit sdCone function.
		do
			emit_raw_line ("float sdCone(vec3 p, vec3 c, float r, float h) {")
			emit_raw_line ("    vec3 q = p - c;")
			emit_raw_line ("    vec2 d = abs(vec2(length(q.xz), q.y)) - vec2(r * (1.0 - q.y / h), h);")
			emit_raw_line ("    return min(max(d.x, d.y), 0.0) + length(max(d, 0.0));")
			emit_raw_line ("}")
			newline
		end

feature -- Operation Functions

	emit_union_op
			-- Emit opUnion function.
		do
			emit_raw_line ("float opUnion(float d1, float d2) {")
			emit_raw_line ("    return min(d1, d2);")
			emit_raw_line ("}")
			newline
		end

	emit_subtraction_op
			-- Emit opSubtraction function.
		do
			emit_raw_line ("float opSubtraction(float d1, float d2) {")
			emit_raw_line ("    return max(d1, -d2);")
			emit_raw_line ("}")
			newline
		end

	emit_intersection_op
			-- Emit opIntersection function.
		do
			emit_raw_line ("float opIntersection(float d1, float d2) {")
			emit_raw_line ("    return max(d1, d2);")
			emit_raw_line ("}")
			newline
		end

	emit_smooth_union_op
			-- Emit opSmoothUnion function.
		do
			emit_raw_line ("float opSmoothUnion(float d1, float d2, float k) {")
			emit_raw_line ("    float h = max(k - abs(d1 - d2), 0.0) / k;")
			emit_raw_line ("    return min(d1, d2) - h * h * k * 0.25;")
			emit_raw_line ("}")
			newline
		end

	emit_smooth_subtraction_op
			-- Emit opSmoothSubtraction function.
		do
			emit_raw_line ("float opSmoothSubtraction(float d1, float d2, float k) {")
			emit_raw_line ("    float h = clamp(0.5 - 0.5 * (d2 + d1) / k, 0.0, 1.0);")
			emit_raw_line ("    return mix(d2, -d1, h) + k * h * (1.0 - h);")
			emit_raw_line ("}")
			newline
		end

	emit_smooth_intersection_op
			-- Emit opSmoothIntersection function.
		do
			emit_raw_line ("float opSmoothIntersection(float d1, float d2, float k) {")
			emit_raw_line ("    float h = clamp(0.5 - 0.5 * (d2 - d1) / k, 0.0, 1.0);")
			emit_raw_line ("    return mix(d2, d1, h) + k * h * (1.0 - h);")
			emit_raw_line ("}")
			newline
		end

feature -- All Primitives and Operations

	emit_all_primitives
			-- Emit all standard SDF primitive functions.
		do
			emit_block_comment ("SDF Primitives")
			emit_sphere_sdf
			emit_box_sdf
			emit_cylinder_sdf
			emit_capsule_sdf
			emit_torus_sdf
			emit_plane_sdf
			emit_cone_sdf
		end

	emit_all_operations
			-- Emit all standard SDF operation functions.
		do
			emit_block_comment ("SDF Operations")
			emit_union_op
			emit_subtraction_op
			emit_intersection_op
			emit_smooth_union_op
			emit_smooth_subtraction_op
			emit_smooth_intersection_op
		end

feature -- Shader Header

	emit_compute_header (a_work_group_x, a_work_group_y: INTEGER)
			-- Emit compute shader header.
		require
			valid_x: a_work_group_x > 0
			valid_y: a_work_group_y > 0
		do
			emit_raw_line ("#version 450")
			emit_raw_line ("layout(local_size_x = " + a_work_group_x.out +
				", local_size_y = " + a_work_group_y.out + ", local_size_z = 1) in;")
			newline
			emit_raw_line ("layout(std430, binding = 0) buffer OutputBuffer { uint pixels[]; };")
			emit_raw_line ("layout(std430, binding = 1) buffer Params {")
			emit_raw_line ("    float cam_x, cam_y, cam_z;")
			emit_raw_line ("    float cam_yaw, cam_pitch;")
			emit_raw_line ("    float time;")
			emit_raw_line ("    uint width, height;")
			emit_raw_line ("};")
			newline
		end

feature -- Ray Marching

	emit_ray_march_main
			-- Emit standard ray marching main function.
		do
			emit_raw_line ("void main() {")
			emit_raw_line ("    uvec2 gid = gl_GlobalInvocationID.xy;")
			emit_raw_line ("    if (gid.x >= width || gid.y >= height) return;")
			newline
			emit_raw_line ("    // Screen UV coordinates")
			emit_raw_line ("    vec2 uv = (vec2(gid) + 0.5) / vec2(width, height) * 2.0 - 1.0;")
			emit_raw_line ("    uv.x *= float(width) / float(height);")
			newline
			emit_raw_line ("    // Camera setup")
			emit_raw_line ("    float cy = cos(cam_yaw), sy = sin(cam_yaw);")
			emit_raw_line ("    float cp = cos(cam_pitch), sp = sin(cam_pitch);")
			emit_raw_line ("    vec3 forward = vec3(sy * cp, sp, -cy * cp);")
			emit_raw_line ("    vec3 right = vec3(cy, 0, sy);")
			emit_raw_line ("    vec3 up = cross(forward, right);")
			newline
			emit_raw_line ("    vec3 ro = vec3(cam_x, cam_y, cam_z);")
			emit_raw_line ("    vec3 rd = normalize(forward + right * uv.x + up * uv.y);")
			newline
			emit_raw_line ("    // Ray march")
			emit_raw_line ("    float t = 0.0;")
			emit_raw_line ("    for (int i = 0; i < 128; i++) {")
			emit_raw_line ("        vec3 p = ro + rd * t;")
			emit_raw_line ("        float d = sceneSDF(p);")
			emit_raw_line ("        if (d < 0.001) break;")
			emit_raw_line ("        t += d;")
			emit_raw_line ("        if (t > 200.0) break;")
			emit_raw_line ("    }")
			newline
			emit_raw_line ("    // Shading")
			emit_raw_line ("    vec3 col;")
			emit_raw_line ("    if (t < 200.0) {")
			emit_raw_line ("        vec3 p = ro + rd * t;")
			emit_raw_line ("        vec3 n = calcNormal(p);")
			emit_raw_line ("        vec3 lightDir = normalize(vec3(1.0, 2.0, -1.0));")
			emit_raw_line ("        float diff = max(dot(n, lightDir), 0.0);")
			emit_raw_line ("        float amb = 0.2;")
			emit_raw_line ("        col = vec3(0.8, 0.7, 0.6) * (diff + amb);")
			emit_raw_line ("    } else {")
			emit_raw_line ("        col = vec3(0.4, 0.6, 0.9);  // Sky color")
			emit_raw_line ("    }")
			newline
			emit_raw_line ("    // Output pixel (BGRA format)")
			emit_raw_line ("    uint r = uint(clamp(col.r, 0.0, 1.0) * 255.0);")
			emit_raw_line ("    uint g = uint(clamp(col.g, 0.0, 1.0) * 255.0);")
			emit_raw_line ("    uint b = uint(clamp(col.b, 0.0, 1.0) * 255.0);")
			emit_raw_line ("    pixels[gid.y * width + gid.x] = 0xFF000000u | (b << 16) | (g << 8) | r;")
			emit_raw_line ("}")
		end

	emit_calc_normal
			-- Emit surface normal calculation function.
		do
			emit_raw_line ("vec3 calcNormal(vec3 p) {")
			emit_raw_line ("    const float e = 0.001;")
			emit_raw_line ("    return normalize(vec3(")
			emit_raw_line ("        sceneSDF(p + vec3(e, 0, 0)) - sceneSDF(p - vec3(e, 0, 0)),")
			emit_raw_line ("        sceneSDF(p + vec3(0, e, 0)) - sceneSDF(p - vec3(0, e, 0)),")
			emit_raw_line ("        sceneSDF(p + vec3(0, 0, e)) - sceneSDF(p - vec3(0, 0, e))")
			emit_raw_line ("    ));")
			emit_raw_line ("}")
			newline
		end

feature -- Full Shader Generation

	generate_basic_shader (a_scene_sdf: STRING): STRING
			-- Generate complete compute shader with custom sceneSDF.
		require
			scene_sdf_not_empty: not a_scene_sdf.is_empty
		do
			output.wipe_out
			indent_level := 0

			emit_compute_header (16, 16)
			emit_all_primitives
			emit_all_operations

			-- Scene SDF function
			emit_raw_line ("float sceneSDF(vec3 p) {")
			emit_raw_line (a_scene_sdf)
			emit_raw_line ("}")
			newline

			emit_calc_normal
			emit_ray_march_main

			Result := output.twin
		end

end
