note
	description: "[
		Scene: Composition of multiple SDF shapes.

		Allows combining shapes using boolean operations:
		- Union: combine shapes (OR)
		- Subtraction: cut one shape from another (AND NOT)
		- Intersection: keep only overlap (AND)

		Operations can be exact (sharp) or smooth (blended).
		The first shape added is the base; subsequent shapes are combined
		using the specified operation.
	]"
	author: "Larry Rix"
	date: "$Date$"
	revision: "$Revision$"

class
	SDF_SCENE

create
	make

feature {NONE} -- Initialization

	make
			-- Create empty scene.
		do
			create shapes.make (10)
			create ops
		ensure
			empty_scene: shapes.is_empty
		end

feature -- Access

	shapes: ARRAYED_LIST [SDF_SCENE_ENTRY]
			-- Shapes with their operations

	ops: SDF_OPS
			-- Boolean operation functions

	count: INTEGER
			-- Number of shapes in scene
		do
			Result := shapes.count
		end

feature -- Status report

	is_empty: BOOLEAN
			-- Is scene empty?
		do
			Result := shapes.is_empty
		end

feature -- Distance evaluation

	distance (p: SDF_VEC3): REAL_64
			-- Combined signed distance from point to scene.
			-- Returns max value if scene is empty.
		local
			entry: SDF_SCENE_ENTRY
			d: REAL_64
			i: INTEGER
		do
			if shapes.is_empty then
				Result := {REAL_64}.max_value
			else
				-- Start with first shape's distance
				Result := shapes.first.shape.distance (p)

				-- Combine with remaining shapes
				from i := 2 until i > shapes.count loop
					entry := shapes [i]
					d := entry.shape.distance (p)

					inspect entry.operation
					when Op_union then
						if entry.blend > 0.0 then
							Result := ops.smooth_union (Result, d, entry.blend)
						else
							Result := ops.op_union (Result, d)
						end
					when Op_subtraction then
						if entry.blend > 0.0 then
							Result := ops.smooth_subtraction (d, Result, entry.blend)
						else
							Result := ops.op_subtraction (d, Result)
						end
					when Op_intersection then
						if entry.blend > 0.0 then
							Result := ops.smooth_intersection (Result, d, entry.blend)
						else
							Result := ops.op_intersection (Result, d)
						end
					else
						-- Default to union
						Result := ops.op_union (Result, d)
					end

					i := i + 1
				end
			end
		end

feature -- Element change

	add (a_shape: SDF_SHAPE): like Current
			-- Add shape with union operation (base case).
		require
			shape_attached: a_shape /= Void
		do
			shapes.extend (create {SDF_SCENE_ENTRY}.make (a_shape, Op_union, 0.0))
			Result := Current
		ensure
			shape_added: shapes.count = old shapes.count + 1
			result_is_current: Result = Current
		end

	add_union (a_shape: SDF_SHAPE): like Current
			-- Add shape combined with union (OR).
		require
			shape_attached: a_shape /= Void
		do
			shapes.extend (create {SDF_SCENE_ENTRY}.make (a_shape, Op_union, 0.0))
			Result := Current
		ensure
			shape_added: shapes.count = old shapes.count + 1
			result_is_current: Result = Current
		end

	add_subtraction (a_shape: SDF_SHAPE): like Current
			-- Add shape combined with subtraction (cuts from existing).
		require
			shape_attached: a_shape /= Void
		do
			shapes.extend (create {SDF_SCENE_ENTRY}.make (a_shape, Op_subtraction, 0.0))
			Result := Current
		ensure
			shape_added: shapes.count = old shapes.count + 1
			result_is_current: Result = Current
		end

	add_intersection (a_shape: SDF_SHAPE): like Current
			-- Add shape combined with intersection (AND).
		require
			shape_attached: a_shape /= Void
		do
			shapes.extend (create {SDF_SCENE_ENTRY}.make (a_shape, Op_intersection, 0.0))
			Result := Current
		ensure
			shape_added: shapes.count = old shapes.count + 1
			result_is_current: Result = Current
		end

	add_smooth_union (a_shape: SDF_SHAPE; a_blend: REAL_64): like Current
			-- Add shape with smooth union blending.
		require
			shape_attached: a_shape /= Void
			positive_blend: a_blend > 0.0
		do
			shapes.extend (create {SDF_SCENE_ENTRY}.make (a_shape, Op_union, a_blend))
			Result := Current
		ensure
			shape_added: shapes.count = old shapes.count + 1
			result_is_current: Result = Current
		end

	add_smooth_subtraction (a_shape: SDF_SHAPE; a_blend: REAL_64): like Current
			-- Add shape with smooth subtraction blending.
		require
			shape_attached: a_shape /= Void
			positive_blend: a_blend > 0.0
		do
			shapes.extend (create {SDF_SCENE_ENTRY}.make (a_shape, Op_subtraction, a_blend))
			Result := Current
		ensure
			shape_added: shapes.count = old shapes.count + 1
			result_is_current: Result = Current
		end

	add_smooth_intersection (a_shape: SDF_SHAPE; a_blend: REAL_64): like Current
			-- Add shape with smooth intersection blending.
		require
			shape_attached: a_shape /= Void
			positive_blend: a_blend > 0.0
		do
			shapes.extend (create {SDF_SCENE_ENTRY}.make (a_shape, Op_intersection, a_blend))
			Result := Current
		ensure
			shape_added: shapes.count = old shapes.count + 1
			result_is_current: Result = Current
		end

	clear
			-- Remove all shapes from scene.
		do
			shapes.wipe_out
		ensure
			empty: shapes.is_empty
		end

feature {NONE} -- Operation constants

	Op_union: INTEGER = 1
	Op_subtraction: INTEGER = 2
	Op_intersection: INTEGER = 3

invariant
	shapes_attached: shapes /= Void
	ops_attached: ops /= Void

end
