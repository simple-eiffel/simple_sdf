# S01 - Project Inventory: simple_sdf

**Document Type:** BACKWASH (reverse-engineered from implementation)
**Library:** simple_sdf
**Version:** 1.0
**Date:** 2026-01-23

## Overview

Signed Distance Field (SDF) library for Eiffel providing geometric primitives, boolean operations, and ray marching for 3D rendering and physics.

## Project Files

### Core Source Files
| File | Purpose |
|------|---------|
| `src/simple_sdf.e` | Main facade class |
| `src/vectors/sdf_vec2.e` | 2D vector operations |
| `src/vectors/sdf_vec3.e` | 3D vector operations |
| `src/primitives/sdf_shape.e` | Base shape class |
| `src/primitives/sdf_sphere.e` | Sphere primitive |
| `src/primitives/sdf_box.e` | Box/cube primitive |
| `src/primitives/sdf_capsule.e` | Capsule primitive |
| `src/primitives/sdf_cylinder.e` | Cylinder primitive |
| `src/primitives/sdf_torus.e` | Torus primitive |
| `src/primitives/sdf_plane.e` | Plane primitive |
| `src/operations/sdf_ops.e` | Boolean operations |
| `src/scene/sdf_scene.e` | Scene composition |
| `src/rendering/sdf_ray_marcher.e` | Ray marching renderer |
| `src/rendering/sdf_ray_hit.e` | Ray hit information |

### Configuration Files
| File | Purpose |
|------|---------|
| `simple_sdf.ecf` | EiffelStudio project configuration |
| `simple_sdf.rc` | Windows resource file |

### Support Files
| File | Purpose |
|------|---------|
| `README.md` | Project documentation |
| `Clib/` | C bridge code |
| `shaders/` | GLSL shader files |

## Dependencies

### ISE Libraries
- base (core Eiffel classes)

### simple_* Libraries
- None (standalone library)

## Build Targets
- `simple_sdf` - Main library
- `simple_sdf_tests` - Test suite
- `simple_sdf_demo` - Demo application
