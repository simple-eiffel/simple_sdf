note
	description: "[
		SIMPLE_SDF - Facade class for Signed Distance Field operations.

		Provides factory methods for creating:
		- Vectors (2D and 3D)
		- Primitive shapes (sphere, box, capsule, cylinder, torus, plane)
		- Boolean operations
		- Scenes (composition of shapes)
		- Ray marching for rendering

		Usage:
			local
				sdf: SIMPLE_SDF
				s: SDF_SCENE
				sphere: SDF_SPHERE
				box: SDF_BOX
				marcher: SDF_RAY_MARCHER
				hit: SDF_RAY_HIT
			do
				create sdf
				s := sdf.scene
				s.add (sdf.sphere (1.0))
				s.add_smooth_union (sdf.cube (1.5), 0.2)
				marcher := sdf.ray_marcher
				hit := marcher.march (s, origin, direction)
			end
	]"
	author: "Larry Rix"
	date: "$Date$"
	revision: "$Revision$"

class
	SIMPLE_SDF

create
	default_create

feature -- Vector Factory

	vec2 (a_x, a_y: REAL_64): SDF_VEC2
			-- Create 2D vector
		do
			create Result.make (a_x, a_y)
		ensure
			result_attached: Result /= Void
			x_set: Result.x = a_x
			y_set: Result.y = a_y
		end

	vec3 (a_x, a_y, a_z: REAL_64): SDF_VEC3
			-- Create 3D vector
		do
			create Result.make (a_x, a_y, a_z)
		ensure
			result_attached: Result /= Void
			x_set: Result.x = a_x
			y_set: Result.y = a_y
			z_set: Result.z = a_z
		end

	vec2_zero: SDF_VEC2
			-- Zero 2D vector
		do
			create Result.make_zero
		ensure
			result_attached: Result /= Void
			is_zero: Result.is_zero_vector
		end

	vec3_zero: SDF_VEC3
			-- Zero 3D vector
		do
			create Result.make_zero
		ensure
			result_attached: Result /= Void
			is_zero: Result.is_zero_vector
		end

	vec3_unit_x: SDF_VEC3
			-- Unit vector along X axis
		do
			create Result.make (1.0, 0.0, 0.0)
		ensure
			result_attached: Result /= Void
			is_unit: Result.is_unit_vector
		end

	vec3_unit_y: SDF_VEC3
			-- Unit vector along Y axis
		do
			create Result.make (0.0, 1.0, 0.0)
		ensure
			result_attached: Result /= Void
			is_unit: Result.is_unit_vector
		end

	vec3_unit_z: SDF_VEC3
			-- Unit vector along Z axis
		do
			create Result.make (0.0, 0.0, 1.0)
		ensure
			result_attached: Result /= Void
			is_unit: Result.is_unit_vector
		end

feature -- Shape Factory: Sphere

	sphere (a_radius: REAL_64): SDF_SPHERE
			-- Create sphere with given radius at origin
		require
			positive_radius: a_radius > 0.0
		do
			create Result.make (a_radius)
		ensure
			result_attached: Result /= Void
			radius_set: Result.radius = a_radius
		end

	sphere_at (a_center: SDF_VEC3; a_radius: REAL_64): SDF_SPHERE
			-- Create sphere at specified center
		require
			center_attached: a_center /= Void
			positive_radius: a_radius > 0.0
		do
			create Result.make (a_radius)
			Result.set_position (a_center).do_nothing
		ensure
			result_attached: Result /= Void
		end

feature -- Shape Factory: Box

	box (a_width, a_height, a_depth: REAL_64): SDF_BOX
			-- Create box with full dimensions at origin
		require
			positive_width: a_width > 0.0
			positive_height: a_height > 0.0
			positive_depth: a_depth > 0.0
		do
			create Result.make (a_width, a_height, a_depth)
		ensure
			result_attached: Result /= Void
		end

	cube (a_size: REAL_64): SDF_BOX
			-- Create cube with edge length at origin
		require
			positive_size: a_size > 0.0
		do
			create Result.make_cube (a_size)
		ensure
			result_attached: Result /= Void
		end

feature -- Shape Factory: Capsule

	capsule (a_point_a, a_point_b: SDF_VEC3; a_radius: REAL_64): SDF_CAPSULE
			-- Create capsule between two points
		require
			point_a_attached: a_point_a /= Void
			point_b_attached: a_point_b /= Void
			positive_radius: a_radius > 0.0
		do
			create Result.make (a_point_a, a_point_b, a_radius)
		ensure
			result_attached: Result /= Void
		end

	capsule_vertical (a_height, a_radius: REAL_64): SDF_CAPSULE
			-- Create vertical capsule at origin
		require
			positive_height: a_height > 0.0
			positive_radius: a_radius > 0.0
		do
			create Result.make_vertical (a_height, a_radius)
		ensure
			result_attached: Result /= Void
		end

feature -- Shape Factory: Cylinder

	cylinder (a_height, a_radius: REAL_64): SDF_CYLINDER
			-- Create vertical cylinder at origin
		require
			positive_height: a_height > 0.0
			positive_radius: a_radius > 0.0
		do
			create Result.make (a_height, a_radius)
		ensure
			result_attached: Result /= Void
		end

feature -- Shape Factory: Torus

	torus (a_major_radius, a_minor_radius: REAL_64): SDF_TORUS
			-- Create torus (donut) at origin
		require
			positive_major: a_major_radius > 0.0
			positive_minor: a_minor_radius > 0.0
			minor_less_than_major: a_minor_radius < a_major_radius
		do
			create Result.make (a_major_radius, a_minor_radius)
		ensure
			result_attached: Result /= Void
		end

feature -- Shape Factory: Plane

	plane (a_normal: SDF_VEC3; a_height: REAL_64): SDF_PLANE
			-- Create plane with given normal and height
		require
			normal_attached: a_normal /= Void
			normal_is_unit: a_normal.is_unit_vector
		do
			create Result.make (a_normal, a_height)
		ensure
			result_attached: Result /= Void
		end

	ground_plane (a_height: REAL_64): SDF_PLANE
			-- Create horizontal ground plane (XZ) at given Y height
		do
			create Result.make_xz (a_height)
		ensure
			result_attached: Result /= Void
		end

feature -- Operations

	ops: SDF_OPS
			-- Boolean and smooth operations
		once
			create Result
		ensure
			result_attached: Result /= Void
		end

feature -- Scene Factory

	scene: SDF_SCENE
			-- Create empty scene
		do
			create Result.make
		ensure
			result_attached: Result /= Void
			is_empty: Result.is_empty
		end

feature -- Ray Marcher Factory

	ray_marcher: SDF_RAY_MARCHER
			-- Create ray marcher with default settings
		do
			create Result.make_default
		ensure
			result_attached: Result /= Void
		end

	ray_marcher_custom (a_max_steps: INTEGER; a_max_distance, a_threshold: REAL_64): SDF_RAY_MARCHER
			-- Create ray marcher with custom settings
		require
			positive_steps: a_max_steps > 0
			positive_distance: a_max_distance > 0.0
			positive_threshold: a_threshold > 0.0
		do
			create Result.make (a_max_steps, a_max_distance, a_threshold)
		ensure
			result_attached: Result /= Void
		end

feature -- Convenience: Distance evaluation

	distance (a_shape: SDF_SHAPE; a_point: SDF_VEC3): REAL_64
			-- Evaluate distance from point to shape
		require
			shape_attached: a_shape /= Void
			point_attached: a_point /= Void
		do
			Result := a_shape.distance (a_point)
		end

	union_distance (a_shapes: ARRAY [SDF_SHAPE]; a_point: SDF_VEC3): REAL_64
			-- Distance to union of all shapes
		require
			shapes_attached: a_shapes /= Void
			has_shapes: a_shapes.count > 0
			point_attached: a_point /= Void
		local
			i: INTEGER
		do
			Result := {REAL_64}.max_value
			from i := a_shapes.lower until i > a_shapes.upper loop
				Result := ops.op_union (Result, a_shapes [i].distance (a_point))
				i := i + 1
			end
		end

end
