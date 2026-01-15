note
	description: "Test cases for simple_sdf library"
	author: "Larry Rix"
	date: "$Date$"
	revision: "$Revision$"

class
	LIB_TESTS

inherit
	TEST_SET_BASE

feature -- Test: Vec2

	test_vec2_creation
			-- Test SDF_VEC2 creation.
		local
			v: SDF_VEC2
		do
			create v.make (3.0, 4.0)
			assert ("x_correct", v.x = 3.0)
			assert ("y_correct", v.y = 4.0)

			create v.make_zero
			assert ("zero_x", v.x = 0.0)
			assert ("zero_y", v.y = 0.0)
			assert ("is_zero", v.is_zero_vector)
		end

	test_vec2_length
			-- Test SDF_VEC2 length calculations.
		local
			v: SDF_VEC2
		do
			-- 3-4-5 triangle
			create v.make (3.0, 4.0)
			assert ("length_correct", (v.length - 5.0).abs < Epsilon)
			assert ("length_squared_correct", (v.length_squared - 25.0).abs < Epsilon)
		end

	test_vec2_operations
			-- Test SDF_VEC2 arithmetic operations.
		local
			a, b, c: SDF_VEC2
		do
			create a.make (1.0, 2.0)
			create b.make (3.0, 4.0)

			-- Addition
			c := a + b
			assert ("add_x", c.x = 4.0)
			assert ("add_y", c.y = 6.0)

			-- Subtraction
			c := b - a
			assert ("sub_x", c.x = 2.0)
			assert ("sub_y", c.y = 2.0)

			-- Scalar multiplication
			c := a * 2.0
			assert ("scale_x", c.x = 2.0)
			assert ("scale_y", c.y = 4.0)

			-- Dot product
			assert ("dot_correct", a.dot (b) = 11.0)  -- 1*3 + 2*4 = 11
		end

	test_vec2_normalize
			-- Test SDF_VEC2 normalization.
		local
			v, n: SDF_VEC2
		do
			create v.make (3.0, 4.0)
			n := v.normalized
			assert ("is_unit", n.is_unit_vector)
			assert ("unit_x", (n.x - 0.6).abs < Epsilon)
			assert ("unit_y", (n.y - 0.8).abs < Epsilon)
		end

feature -- Test: Vec3

	test_vec3_creation
			-- Test SDF_VEC3 creation.
		local
			v: SDF_VEC3
		do
			create v.make (1.0, 2.0, 3.0)
			assert ("x_correct", v.x = 1.0)
			assert ("y_correct", v.y = 2.0)
			assert ("z_correct", v.z = 3.0)

			create v.make_zero
			assert ("is_zero", v.is_zero_vector)
		end

	test_vec3_length
			-- Test SDF_VEC3 length calculations.
		local
			v: SDF_VEC3
		do
			create v.make (2.0, 3.0, 6.0)
			-- 2² + 3² + 6² = 4 + 9 + 36 = 49, sqrt(49) = 7
			assert ("length_correct", (v.length - 7.0).abs < Epsilon)
		end

	test_vec3_cross_product
			-- Test SDF_VEC3 cross product.
		local
			x_axis, y_axis, z_axis: SDF_VEC3
		do
			create x_axis.make (1.0, 0.0, 0.0)
			create y_axis.make (0.0, 1.0, 0.0)

			-- X × Y = Z
			z_axis := x_axis.cross (y_axis)
			assert ("cross_x", z_axis.x = 0.0)
			assert ("cross_y", z_axis.y = 0.0)
			assert ("cross_z", z_axis.z = 1.0)
		end

	test_vec3_dot_product
			-- Test SDF_VEC3 dot product.
		local
			a, b: SDF_VEC3
		do
			create a.make (1.0, 2.0, 3.0)
			create b.make (4.0, 5.0, 6.0)

			-- 1*4 + 2*5 + 3*6 = 4 + 10 + 18 = 32
			assert ("dot_correct", a.dot (b) = 32.0)
		end

feature -- Test: Sphere

	test_sphere_distance
			-- Test SDF_SPHERE distance calculation.
		local
			s: SDF_SPHERE
			p: SDF_VEC3
		do
			create s.make (1.0)  -- Unit sphere at origin

			-- Point on surface
			create p.make (1.0, 0.0, 0.0)
			assert ("on_surface", s.distance (p).abs < Epsilon)

			-- Point outside
			create p.make (2.0, 0.0, 0.0)
			assert ("outside", (s.distance (p) - 1.0).abs < Epsilon)

			-- Point inside
			create p.make (0.5, 0.0, 0.0)
			assert ("inside", (s.distance (p) - (-0.5)).abs < Epsilon)
		end

	test_sphere_inside_outside
			-- Test SDF_SPHERE inside/outside queries.
		local
			s: SDF_SPHERE
			p_in, p_out, p_surface: SDF_VEC3
		do
			create s.make (1.0)
			create p_in.make (0.0, 0.0, 0.0)
			create p_out.make (2.0, 0.0, 0.0)
			create p_surface.make (1.0, 0.0, 0.0)

			assert ("origin_inside", s.is_inside (p_in))
			assert ("far_outside", s.is_outside (p_out))
			assert ("edge_on_surface", s.is_on_surface (p_surface))
		end

feature -- Test: Box

	test_box_distance
			-- Test SDF_BOX distance calculation.
		local
			b: SDF_BOX
			p: SDF_VEC3
		do
			create b.make_cube (2.0)  -- 2x2x2 cube centered at origin

			-- Point at center (inside)
			create p.make_zero
			assert ("center_inside", b.distance (p) < 0.0)

			-- Point on face center
			create p.make (1.0, 0.0, 0.0)
			assert ("face_on_surface", b.distance (p).abs < Epsilon)

			-- Point outside
			create p.make (2.0, 0.0, 0.0)
			assert ("outside_distance", (b.distance (p) - 1.0).abs < Epsilon)
		end

	test_box_corners
			-- Test SDF_BOX corner distances.
		local
			b: SDF_BOX
			p: SDF_VEC3
		do
			create b.make_cube (2.0)

			-- Corner of the box (exactly at corner)
			create p.make (1.0, 1.0, 1.0)
			assert ("corner_on_surface", b.distance (p).abs < Epsilon)

			-- Outside corner region
			create p.make (2.0, 2.0, 2.0)
			-- Distance from (1,1,1) to (2,2,2) is sqrt(3) ≈ 1.732
			assert ("corner_outside", (b.distance (p) - {DOUBLE_MATH}.sqrt (3.0)).abs < 0.01)
		end

feature -- Test: Plane

	test_plane_distance
			-- Test SDF_PLANE distance calculation.
		local
			pl: SDF_PLANE
			p: SDF_VEC3
		do
			-- Ground plane at y=0
			create pl.make_xz (0.0)

			-- Point above
			create p.make (0.0, 1.0, 0.0)
			assert ("above_ground", (pl.distance (p) - 1.0).abs < Epsilon)

			-- Point below
			create p.make (0.0, -1.0, 0.0)
			assert ("below_ground", (pl.distance (p) - (-1.0)).abs < Epsilon)

			-- Point on plane
			create p.make (5.0, 0.0, 3.0)
			assert ("on_ground", pl.distance (p).abs < Epsilon)
		end

feature -- Test: Capsule

	test_capsule_distance
			-- Test SDF_CAPSULE distance calculation.
		local
			c: SDF_CAPSULE
			p: SDF_VEC3
		do
			create c.make_vertical (2.0, 0.5)  -- Height 2, radius 0.5

			-- Point on side surface
			create p.make (0.5, 0.0, 0.0)
			assert ("side_on_surface", c.distance (p).abs < Epsilon)

			-- Point at cap
			create p.make (0.0, 1.5, 0.0)
			assert ("cap_on_surface", c.distance (p).abs < Epsilon)
		end

feature -- Test: Cylinder

	test_cylinder_distance
			-- Test SDF_CYLINDER distance calculation.
		local
			cyl: SDF_CYLINDER
			p: SDF_VEC3
		do
			create cyl.make (2.0, 1.0)  -- Height 2, radius 1

			-- Point on side
			create p.make (1.0, 0.0, 0.0)
			assert ("side_on_surface", cyl.distance (p).abs < Epsilon)

			-- Point on top cap
			create p.make (0.0, 1.0, 0.0)
			assert ("top_on_surface", cyl.distance (p).abs < Epsilon)
		end

feature -- Test: Torus

	test_torus_distance
			-- Test SDF_TORUS distance calculation.
		local
			t: SDF_TORUS
			p: SDF_VEC3
		do
			create t.make (2.0, 0.5)  -- Major 2, minor 0.5

			-- Point on outer surface (along X)
			create p.make (2.5, 0.0, 0.0)
			assert ("outer_on_surface", t.distance (p).abs < Epsilon)

			-- Point on inner surface
			create p.make (1.5, 0.0, 0.0)
			assert ("inner_on_surface", t.distance (p).abs < Epsilon)
		end

feature -- Test: Boolean Operations

	test_union_operation
			-- Test union of two spheres.
		local
			ops: SDF_OPS
			d1, d2, d_union: REAL_64
		do
			create ops

			d1 := 1.0
			d2 := 2.0

			d_union := ops.op_union (d1, d2)
			assert ("union_is_min", d_union = 1.0)
		end

	test_subtraction_operation
			-- Test subtraction operation.
		local
			ops: SDF_OPS
			d_result: REAL_64
		do
			create ops

			-- If d1 < 0 (inside first shape) and d2 > 0 (outside second)
			-- Subtraction should give positive (outside result)
			d_result := ops.op_subtraction (-0.5, 0.3)
			assert ("subtraction_positive", d_result > 0.0)
		end

	test_intersection_operation
			-- Test intersection operation.
		local
			ops: SDF_OPS
			d_result: REAL_64
		do
			create ops

			-- Intersection is max
			d_result := ops.op_intersection (1.0, 2.0)
			assert ("intersection_is_max", d_result = 2.0)
		end

	test_smooth_union
			-- Test smooth union blends properly.
		local
			ops: SDF_OPS
			d_sharp, d_smooth: REAL_64
		do
			create ops

			-- Sharp union
			d_sharp := ops.op_union (1.0, 1.0)

			-- Smooth union should be less (blended inward)
			d_smooth := ops.smooth_union (1.0, 1.0, 0.5)

			assert ("smooth_is_less", d_smooth < d_sharp)
		end

feature -- Test: Facade

	test_facade_factories
			-- Test SIMPLE_SDF factory methods.
		local
			sdf: SIMPLE_SDF
			sphere: SDF_SPHERE
			box: SDF_BOX
			v: SDF_VEC3
		do
			create sdf

			sphere := sdf.sphere (1.0)
			assert ("sphere_created", sphere /= Void)
			assert ("sphere_radius", sphere.radius = 1.0)

			box := sdf.cube (2.0)
			assert ("box_created", box /= Void)

			v := sdf.vec3 (1.0, 2.0, 3.0)
			assert ("vec_created", v /= Void)
			assert ("vec_x", v.x = 1.0)
		end

feature -- Test: Scene

	test_scene_composition
			-- Test SDF_SCENE shape composition.
		local
			scene: SDF_SCENE
			s1, s2: SDF_SPHERE
			p: SDF_VEC3
			d: REAL_64
		do
			create scene.make

			-- Add two spheres: one at origin, one offset
			create s1.make (1.0)
			create s2.make (1.0)
			s2.set_position (create {SDF_VEC3}.make (3.0, 0.0, 0.0)).do_nothing

			scene.add (s1).do_nothing
			scene.add_union (s2).do_nothing

			-- Test at origin - should be inside first sphere
			create p.make_zero
			d := scene.distance (p)
			assert ("inside_first_sphere", d < 0.0)

			-- Test midway - should be positive (between spheres)
			create p.make (1.5, 0.0, 0.0)
			d := scene.distance (p)
			assert ("between_spheres", d > 0.0)

			-- Test at second sphere center
			create p.make (3.0, 0.0, 0.0)
			d := scene.distance (p)
			assert ("inside_second_sphere", d < 0.0)
		end

	test_scene_smooth_blend
			-- Test smooth blending in scene.
		local
			scene: SDF_SCENE
			s1, s2: SDF_SPHERE
			p: SDF_VEC3
			d_sharp, d_smooth: REAL_64
		do
			-- Create two spheres at same position for comparison
			create s1.make (1.0)
			create s2.make (1.0)

			-- Sharp union
			create scene.make
			scene.add (s1).do_nothing
			scene.add_union (s2).do_nothing
			create p.make (1.0, 0.0, 0.0)
			d_sharp := scene.distance (p)

			-- Smooth union (should be less due to blending inward)
			create scene.make
			scene.add (s1).do_nothing
			scene.add_smooth_union (s2, 0.5).do_nothing
			d_smooth := scene.distance (p)

			-- Sharp union gives 0 (on surface)
			-- Smooth union blends inward, giving negative distance
			assert ("sharp_near_surface", d_sharp.abs < 0.01)
			assert ("smooth_blends_inward", d_smooth < d_sharp)
		end

feature -- Test: Ray Marcher

	test_ray_march_hit
			-- Test ray marching hitting a sphere.
		local
			marcher: SDF_RAY_MARCHER
			scene: SDF_SCENE
			sphere: SDF_SPHERE
			origin, direction: SDF_VEC3
			hit: SDF_RAY_HIT
		do
			-- Create sphere at origin
			create sphere.make (1.0)
			create scene.make
			scene.add (sphere).do_nothing

			-- Create ray marcher
			create marcher.make_default

			-- Ray pointing at sphere from Z axis
			create origin.make (0.0, 0.0, 5.0)
			create direction.make (0.0, 0.0, -1.0)

			hit := marcher.march (scene, origin, direction)

			assert ("ray_hit", hit.is_hit)
			assert ("hit_distance_correct", (hit.distance - 4.0).abs < 0.01)
			-- Hit should be at approximately (0, 0, 1)
			assert ("hit_z_correct", (hit.position.z - 1.0).abs < 0.01)
		end

	test_ray_march_miss
			-- Test ray marching missing geometry.
		local
			marcher: SDF_RAY_MARCHER
			scene: SDF_SCENE
			sphere: SDF_SPHERE
			origin, direction: SDF_VEC3
			hit: SDF_RAY_HIT
		do
			-- Create sphere at origin
			create sphere.make (1.0)
			create scene.make
			scene.add (sphere).do_nothing

			-- Create ray marcher with limited distance
			create marcher.make (100, 10.0, 0.001)

			-- Ray pointing away from sphere
			create origin.make (0.0, 0.0, 5.0)
			create direction.make (0.0, 0.0, 1.0)  -- Pointing away

			hit := marcher.march (scene, origin, direction)

			assert ("ray_miss", hit.is_miss)
		end

	test_ray_normal_computation
			-- Test surface normal computation.
		local
			marcher: SDF_RAY_MARCHER
			sphere: SDF_SPHERE
			p, normal: SDF_VEC3
		do
			create sphere.make (1.0)
			create marcher.make_default

			-- Point on sphere surface along X axis
			create p.make (1.0, 0.0, 0.0)
			normal := marcher.compute_normal_shape (sphere, p)

			-- Normal should point outward along X
			assert ("normal_x", (normal.x - 1.0).abs < 0.01)
			assert ("normal_y", normal.y.abs < 0.01)
			assert ("normal_z", normal.z.abs < 0.01)
		end

feature {NONE} -- Constants

	Epsilon: REAL_64 = 0.0001

end
