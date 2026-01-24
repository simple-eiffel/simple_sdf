# S05 - Constraints: simple_sdf

**Document Type:** BACKWASH (reverse-engineered from implementation)
**Library:** simple_sdf
**Date:** 2026-01-23

## Dimensional Constraints

### Positive Values Required
All size parameters must be strictly positive:

| Parameter | Constraint | Rationale |
|-----------|------------|-----------|
| Sphere radius | `> 0.0` | Zero radius is a point, not a sphere |
| Box dimensions | `> 0.0` | Zero dimension collapses shape |
| Capsule radius | `> 0.0` | Zero radius is a line segment |
| Cylinder height | `> 0.0` | Zero height is a disk |
| Cylinder radius | `> 0.0` | Zero radius is a line |
| Torus major radius | `> 0.0` | Shape definition requires |
| Torus minor radius | `> 0.0` | Shape definition requires |

### Torus Constraint
```eiffel
minor_radius < major_radius
```
The tube radius must be smaller than the ring radius to form a valid torus.

### Plane Normal Constraint
```eiffel
a_normal.is_unit_vector
```
Plane normals must be unit vectors for correct distance calculation.

## Numerical Constraints

### Ray Marching Parameters
| Parameter | Min | Max | Default | Rationale |
|-----------|-----|-----|---------|-----------|
| `max_steps` | 1 | 1000+ | 256 | Trade-off: quality vs performance |
| `max_distance` | > 0 | inf | 1000.0 | Scene bounding |
| `threshold` | > 0 | 0.1 | 0.001 | Surface precision |

### Floating Point Precision
- All coordinates use `REAL_64` (double precision)
- Threshold prevents infinite loops near surfaces
- Normalization tolerance: `1e-10`

## Scene Constraints

### Maximum Scene Complexity
- No hard limit on shape count
- Performance degrades with > 100 shapes (no spatial acceleration)
- Smooth operations increase cost

### Operation Order
- Operations applied in sequence
- Order affects final result (non-commutative)

## Memory Constraints

### Vector Allocation
- Vectors are value objects (copied on assignment)
- No pooling - relies on GC

### Shape Ownership
- Scene does not own shapes (shared references allowed)
- Shapes can be reused across scenes

## Thread Safety

### Not Thread-Safe
- All classes assume single-threaded access
- For SCOOP: wrap in separate processors

## Platform Constraints

### Windows-Specific
- Demo uses OpenGL rendering via WEL
- Core library is platform-independent
