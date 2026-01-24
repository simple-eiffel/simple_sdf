# S04 - Feature Specifications: simple_sdf

**Document Type:** BACKWASH (reverse-engineered from implementation)
**Library:** simple_sdf
**Date:** 2026-01-23

## Core Features

### Vector Operations (SDF_VEC2, SDF_VEC3)

| Feature | Signature | Description |
|---------|-----------|-------------|
| `make` | `(x, y[, z]: REAL_64)` | Create vector from components |
| `make_zero` | `()` | Create zero vector |
| `plus` | `(other: like Current): like Current` | Vector addition |
| `minus` | `(other: like Current): like Current` | Vector subtraction |
| `times` | `(scalar: REAL_64): like Current` | Scalar multiplication |
| `dot` | `(other: like Current): REAL_64` | Dot product |
| `cross` | `(other: SDF_VEC3): SDF_VEC3` | Cross product (3D only) |
| `length` | `: REAL_64` | Vector magnitude |
| `normalized` | `: like Current` | Unit vector |
| `is_unit_vector` | `: BOOLEAN` | Check if normalized |
| `is_zero_vector` | `: BOOLEAN` | Check if zero |

### Shape Distance (SDF_SHAPE)

| Feature | Signature | Description |
|---------|-----------|-------------|
| `distance` | `(point: SDF_VEC3): REAL_64` | Signed distance to surface |
| `set_position` | `(pos: SDF_VEC3): like Current` | Move shape center |
| `set_rotation` | `(euler: SDF_VEC3): like Current` | Rotate shape |
| `set_scale` | `(scale: REAL_64): like Current` | Uniform scale |

### Primitive Shapes

| Primitive | Parameters | Distance Formula |
|-----------|------------|------------------|
| `SDF_SPHERE` | radius | `length(p) - radius` |
| `SDF_BOX` | half_extents | `length(max(abs(p)-b, 0))` |
| `SDF_CAPSULE` | point_a, point_b, radius | `length(p - closest_on_line) - radius` |
| `SDF_CYLINDER` | height, radius | `max(length(p.xz)-r, abs(p.y)-h)` |
| `SDF_TORUS` | major_r, minor_r | `length(vec2(length(p.xz)-R, p.y)) - r` |
| `SDF_PLANE` | normal, height | `dot(p, normal) - height` |

### Boolean Operations (SDF_OPS)

| Feature | Signature | Description |
|---------|-----------|-------------|
| `op_union` | `(d1, d2: REAL_64): REAL_64` | `min(d1, d2)` |
| `op_subtraction` | `(d1, d2: REAL_64): REAL_64` | `max(d1, -d2)` |
| `op_intersection` | `(d1, d2: REAL_64): REAL_64` | `max(d1, d2)` |
| `smooth_union` | `(d1, d2, k: REAL_64): REAL_64` | Blended union |
| `smooth_subtraction` | `(d1, d2, k: REAL_64): REAL_64` | Blended subtract |
| `smooth_intersection` | `(d1, d2, k: REAL_64): REAL_64` | Blended intersect |

### Scene Composition (SDF_SCENE)

| Feature | Signature | Description |
|---------|-----------|-------------|
| `make` | `()` | Create empty scene |
| `add` | `(shape: SDF_SHAPE)` | Add shape (union) |
| `add_smooth_union` | `(shape: SDF_SHAPE; k: REAL_64)` | Add with smooth blend |
| `subtract` | `(shape: SDF_SHAPE)` | Subtract shape |
| `intersect` | `(shape: SDF_SHAPE)` | Intersect with shape |
| `is_empty` | `: BOOLEAN` | Check if empty |
| `distance` | `(point: SDF_VEC3): REAL_64` | Combined distance |

### Ray Marching (SDF_RAY_MARCHER)

| Feature | Signature | Description |
|---------|-----------|-------------|
| `make_default` | `()` | Default settings (256 steps, 1000.0 dist, 0.001 thresh) |
| `make` | `(steps: INTEGER; dist, thresh: REAL_64)` | Custom settings |
| `march` | `(scene: SDF_SCENE; origin, dir: SDF_VEC3): SDF_RAY_HIT` | Perform ray march |

### Ray Hit Result (SDF_RAY_HIT)

| Feature | Signature | Description |
|---------|-----------|-------------|
| `hit` | `: BOOLEAN` | Did ray hit surface? |
| `position` | `: SDF_VEC3` | Hit point |
| `normal` | `: SDF_VEC3` | Surface normal at hit |
| `distance` | `: REAL_64` | Distance traveled |
| `steps` | `: INTEGER` | Iterations used |
