note
	description: "[
		SDF primitive: Axis-Aligned Box.

		Distance formula (Inigo Quilez):
		q = abs(p - center) - dimensions
		d = length(max(q, 0)) + min(max(q.x, q.y, q.z), 0)

		Dimensions are half-extents (width/2, height/2, depth/2).
		This is an exact SDF with correct distance both inside and outside.
	]"
	author: "Larry Rix"
	date: "$Date$"
	revision: "$Revision$"

class
	SDF_BOX

inherit
	SDF_SHAPE

create
	make,
	make_cube

feature {NONE} -- Initialization

	make (a_width, a_height, a_depth: REAL_64)
			-- Create box with full dimensions at origin.
			-- Internally stored as half-extents.
		require
			positive_width: a_width > 0.0
			positive_height: a_height > 0.0
			positive_depth: a_depth > 0.0
		do
			make_at_origin
			create dimensions.make (a_width / 2.0, a_height / 2.0, a_depth / 2.0)
		ensure
			half_width: dimensions.x = a_width / 2.0
			half_height: dimensions.y = a_height / 2.0
			half_depth: dimensions.z = a_depth / 2.0
		end

	make_cube (a_size: REAL_64)
			-- Create cube with edge length `a_size' at origin.
		require
			positive_size: a_size > 0.0
		do
			make (a_size, a_size, a_size)
		ensure
			is_cube: dimensions.x = dimensions.y and dimensions.y = dimensions.z
		end

feature -- Access

	dimensions: SDF_VEC3
			-- Half-extents (width/2, height/2, depth/2)

	width: REAL_64
			-- Full width (x dimension)
		do
			Result := dimensions.x * 2.0
		end

	height: REAL_64
			-- Full height (y dimension)
		do
			Result := dimensions.y * 2.0
		end

	depth: REAL_64
			-- Full depth (z dimension)
		do
			Result := dimensions.z * 2.0
		end

feature -- Distance

	distance (p: SDF_VEC3): REAL_64
			-- Signed distance from point `p' to box surface.
			-- Exact SDF formula from Inigo Quilez.
		local
			q: SDF_VEC3
			l_zero: SDF_VEC3
		do
			-- Transform point to box-local coordinates
			q := p.minus (position).abs.minus (dimensions)

			-- Create zero vector for max operation
			create l_zero.make_zero

			-- Exact box distance:
			-- Outside: distance to nearest corner/edge/face
			-- Inside: negative distance to nearest face
			Result := q.max (l_zero).length + q.max_component.min (0.0)
		end

feature -- Element change (fluent API)

	set_dimensions (a_width, a_height, a_depth: REAL_64): like Current
			-- Set full dimensions and return self
		require
			positive_width: a_width > 0.0
			positive_height: a_height > 0.0
			positive_depth: a_depth > 0.0
		do
			create dimensions.make (a_width / 2.0, a_height / 2.0, a_depth / 2.0)
			Result := Current
		ensure
			result_is_current: Result = Current
		end

	set_half_extents (a_half_extents: SDF_VEC3): like Current
			-- Set half-extents directly and return self
		require
			half_extents_attached: a_half_extents /= Void
			positive_x: a_half_extents.x > 0.0
			positive_y: a_half_extents.y > 0.0
			positive_z: a_half_extents.z > 0.0
		do
			dimensions := a_half_extents
			Result := Current
		ensure
			dimensions_set: dimensions = a_half_extents
			result_is_current: Result = Current
		end

invariant
	dimensions_attached: dimensions /= Void
	positive_dimensions: dimensions.x > 0.0 and dimensions.y > 0.0 and dimensions.z > 0.0

end
