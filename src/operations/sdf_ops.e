note
	description: "[
		Boolean and smooth blending operations for SDFs.

		Exact Boolean Operations:
		- Union: min(d1, d2) - combines shapes
		- Subtraction: max(-d1, d2) - cuts d1 from d2
		- Intersection: max(d1, d2) - keeps only overlap

		Smooth Operations (Inigo Quilez):
		- Smooth union: blends shapes with smooth transition
		- Smooth subtraction: smooth cutout
		- Smooth intersection: smooth overlap

		The blend radius k controls smoothness:
		- k = 0: exact (sharp) operation
		- k > 0: smooth transition over distance k
	]"
	author: "Larry Rix"
	date: "$Date$"
	revision: "$Revision$"

class
	SDF_OPS

create
	default_create

feature -- Exact Boolean Operations

	op_union (d1, d2: REAL_64): REAL_64
			-- Union of two distances (combines shapes).
			-- Returns the minimum distance.
		do
			Result := d1.min (d2)
		end

	op_subtraction (d1, d2: REAL_64): REAL_64
			-- Subtraction (d1 cuts from d2).
			-- Removes d1 from d2.
		do
			Result := (-d1).max (d2)
		end

	op_intersection (d1, d2: REAL_64): REAL_64
			-- Intersection of two distances.
			-- Keeps only where both shapes overlap.
		do
			Result := d1.max (d2)
		end

	op_xor (d1, d2: REAL_64): REAL_64
			-- XOR operation (either but not both).
		do
			Result := d1.min (d2).max (- d1.max (d2))
		end

feature -- Smooth Boolean Operations (Quadratic Polynomial)

	smooth_union (d1, d2, k: REAL_64): REAL_64
			-- Smooth union with blend radius k.
			-- Creates organic blending between shapes.
		require
			non_negative_k: k >= 0.0
		local
			h: REAL_64
		do
			if k <= 0.0 then
				Result := op_union (d1, d2)
			else
				h := ((k - (d1 - d2).abs).max (0.0)) / k
				Result := d1.min (d2) - h * h * k * 0.25
			end
		end

	smooth_subtraction (d1, d2, k: REAL_64): REAL_64
			-- Smooth subtraction with blend radius k.
			-- d1 smoothly cuts from d2.
		require
			non_negative_k: k >= 0.0
		local
			h: REAL_64
		do
			if k <= 0.0 then
				Result := op_subtraction (d1, d2)
			else
				h := ((k - (-d1 - d2).abs).max (0.0)) / k
				Result := (-d1).max (d2) + h * h * k * 0.25
			end
		end

	smooth_intersection (d1, d2, k: REAL_64): REAL_64
			-- Smooth intersection with blend radius k.
		require
			non_negative_k: k >= 0.0
		local
			h: REAL_64
		do
			if k <= 0.0 then
				Result := op_intersection (d1, d2)
			else
				h := ((k - (d1 - d2).abs).max (0.0)) / k
				Result := d1.max (d2) + h * h * k * 0.25
			end
		end

feature -- Cubic Smooth Operations (smoother transitions)

	smooth_union_cubic (d1, d2, k: REAL_64): REAL_64
			-- Cubic smooth union (smoother than quadratic).
		require
			non_negative_k: k >= 0.0
		local
			h: REAL_64
		do
			if k <= 0.0 then
				Result := op_union (d1, d2)
			else
				h := ((k - (d1 - d2).abs).max (0.0)) / k
				Result := d1.min (d2) - h * h * h * k * (1.0 / 6.0)
			end
		end

feature -- Utility Functions

	clamp (value, min_val, max_val: REAL_64): REAL_64
			-- Clamp value to range [min_val, max_val]
		require
			valid_range: min_val <= max_val
		do
			Result := value.max (min_val).min (max_val)
		ensure
			in_range: Result >= min_val and Result <= max_val
		end

	lerp (a, b, t: REAL_64): REAL_64
			-- Linear interpolation: a + (b - a) * t
		do
			Result := a + (b - a) * t
		end

	smoothstep (edge0, edge1, x: REAL_64): REAL_64
			-- Smooth Hermite interpolation
		local
			t: REAL_64
		do
			t := clamp ((x - edge0) / (edge1 - edge0), 0.0, 1.0)
			Result := t * t * (3.0 - 2.0 * t)
		ensure
			in_range: Result >= 0.0 and Result <= 1.0
		end

feature -- Distance Modifications

	round (d, r: REAL_64): REAL_64
			-- Round/expand a shape by radius r.
			-- Positive r expands, negative r shrinks.
		do
			Result := d - r
		end

	onion (d, thickness: REAL_64): REAL_64
			-- Create shell (hollow) with given thickness.
			-- Converts solid to hollow shell.
		require
			positive_thickness: thickness > 0.0
		do
			Result := d.abs - thickness
		end

	elongate_x (p: SDF_VEC3; h: REAL_64): SDF_VEC3
			-- Elongate shape along X axis by h.
		do
			create Result.make (
				(p.x.abs - h).max (0.0) * p.x.sign.to_double,
				p.y,
				p.z
			)
		end

	elongate_y (p: SDF_VEC3; h: REAL_64): SDF_VEC3
			-- Elongate shape along Y axis by h.
		do
			create Result.make (
				p.x,
				(p.y.abs - h).max (0.0) * p.y.sign.to_double,
				p.z
			)
		end

	elongate_z (p: SDF_VEC3; h: REAL_64): SDF_VEC3
			-- Elongate shape along Z axis by h.
		do
			create Result.make (
				p.x,
				p.y,
				(p.z.abs - h).max (0.0) * p.z.sign.to_double
			)
		end

end
