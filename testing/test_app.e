note
	description: "Test runner application for simple_sdf"
	author: "Larry Rix"
	date: "$Date$"
	revision: "$Revision$"

class
	TEST_APP

create
	make

feature {NONE} -- Initialization

	make
			-- Run the tests.
		do
			print ("Running SIMPLE_SDF tests...%N%N")
			passed := 0
			failed := 0

			run_lib_tests

			print ("%N========================%N")
			print ("Results: " + passed.out + " passed, " + failed.out + " failed%N")

			if failed > 0 then
				print ("TESTS FAILED%N")
			else
				print ("ALL TESTS PASSED%N")
			end
		end

feature {NONE} -- Test Runners

	run_lib_tests
			-- Run LIB_TESTS test cases.
		do
			print ("--- LIB_TESTS ---%N")
			create lib_tests

			-- Vector tests
			run_test (agent lib_tests.test_vec2_creation, "test_vec2_creation")
			run_test (agent lib_tests.test_vec2_length, "test_vec2_length")
			run_test (agent lib_tests.test_vec2_operations, "test_vec2_operations")
			run_test (agent lib_tests.test_vec2_normalize, "test_vec2_normalize")
			run_test (agent lib_tests.test_vec3_creation, "test_vec3_creation")
			run_test (agent lib_tests.test_vec3_length, "test_vec3_length")
			run_test (agent lib_tests.test_vec3_cross_product, "test_vec3_cross_product")
			run_test (agent lib_tests.test_vec3_dot_product, "test_vec3_dot_product")

			-- Primitive tests
			run_test (agent lib_tests.test_sphere_distance, "test_sphere_distance")
			run_test (agent lib_tests.test_sphere_inside_outside, "test_sphere_inside_outside")
			run_test (agent lib_tests.test_box_distance, "test_box_distance")
			run_test (agent lib_tests.test_box_corners, "test_box_corners")
			run_test (agent lib_tests.test_plane_distance, "test_plane_distance")
			run_test (agent lib_tests.test_capsule_distance, "test_capsule_distance")
			run_test (agent lib_tests.test_cylinder_distance, "test_cylinder_distance")
			run_test (agent lib_tests.test_torus_distance, "test_torus_distance")

			-- Boolean operation tests
			run_test (agent lib_tests.test_union_operation, "test_union_operation")
			run_test (agent lib_tests.test_subtraction_operation, "test_subtraction_operation")
			run_test (agent lib_tests.test_intersection_operation, "test_intersection_operation")
			run_test (agent lib_tests.test_smooth_union, "test_smooth_union")

			-- Facade tests
			run_test (agent lib_tests.test_facade_factories, "test_facade_factories")

			-- Scene tests
			run_test (agent lib_tests.test_scene_composition, "test_scene_composition")
			run_test (agent lib_tests.test_scene_smooth_blend, "test_scene_smooth_blend")

			-- Ray marcher tests
			run_test (agent lib_tests.test_ray_march_hit, "test_ray_march_hit")
			run_test (agent lib_tests.test_ray_march_miss, "test_ray_march_miss")
			run_test (agent lib_tests.test_ray_normal_computation, "test_ray_normal_computation")
		end

feature {NONE} -- Implementation

	lib_tests: LIB_TESTS

	passed: INTEGER
	failed: INTEGER

	run_test (a_test: PROCEDURE; a_name: STRING)
			-- Run a single test and update counters.
		local
			l_retried: BOOLEAN
		do
			if not l_retried then
				a_test.call (Void)
				print ("  PASS: " + a_name + "%N")
				passed := passed + 1
			end
		rescue
			print ("  FAIL: " + a_name + "%N")
			failed := failed + 1
			l_retried := True
			retry
		end

end
