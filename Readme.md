# BEM Axis (Fortran)

This repository provides a modern Fortran reimplementation of the BEACON code described in Becker's text, restricted to axisymmetric linear elasticity analyses.

## Scope and Objectives

- Exclusive focus on axisymmetric formulation.
- Reproducible workflow for compilation, execution, and verification using the sphere case.
- Primary solver source in free-form Fortran with modular state handling and no COMMON blocks.
- OpenMP-based parallel assembly of influence matrices.
- Solution of the global linear system through LAPACK (SGESV).

## Repository Organization

- src/: numerical solver implementation
- data/: input datasets
- scripts/: automation for compilation, execution, and benchmarking
- benchmarks/reference/: reference outputs for regression validation
- results/: locally generated outputs
- docs/: supplementary technical material
- archive/: OCR processing history and reference artifacts

## Computational Prerequisites

- gfortran with OpenMP support
- LAPACK and BLAS available for linking
- GNU Make (Linux/macOS) or mingw32-make (Windows)
- Windows PowerShell (for .ps1 automation scripts)

## Compilation

### Linux/macOS

```bash
make
```

### Windows (MinGW/MSYS2)

On Windows platforms, use mingw32-make:

```powershell
mingw32-make
```

If MSYS2 toolchain binaries are not available in PATH, run:

```powershell
$env:PATH = "C:\msys64\ucrt64\bin;" + $env:PATH
```

For a clean rebuild:

```powershell
mingw32-make clean
mingw32-make
```

The executable artifact is generated as bin/beacon (Linux/macOS) or bin/beacon.exe (Windows).

Alternatively, from PowerShell:

```powershell
.\scripts\build.ps1
```

## Execution

Execute the axisymmetric sphere case:

```powershell
.\scripts\run_case.ps1 -Case sphere
```

Generated outputs:

- results/sphere.out
- results/sphere.err

## Verification and Regression Benchmarking

The benchmarking workflow executes the sphere case and compares results against versioned reference files:

```powershell
.\scripts\benchmark.ps1 -Rebuild
```

To reduce false negatives across environments with different BLAS/LAPACK implementations,
sphere.out is compared using numerical tolerances (optional parameters -AbsTol and -RelTol).

Reference artifacts:

- benchmarks/reference/sphere.out
- benchmarks/reference/sphere.err

## Dynamic Memory Allocation Strategy

- Legacy fixed-size arrays were refactored into allocatable arrays in the solver state module.
- Shared runtime arrays are provisioned by ALLOCATE_SHARED_STATE and released by DEALLOCATE_SHARED_STATE.
- Thread-private OpenMP work arrays are provisioned per thread by ALLOCATE_THREAD_STATE.
- SGESV uses runtime-consistent dimensions aligned with the allocated global matrix layout.

## Implementation Notes

- The modern solver is implemented in src/beacon_modern.f90 and organized around the beacon_state module.
- OpenMP parallelization is applied in the influence-matrix assembly stage.
- The global linear system is solved with LAPACK SGESV.
- The repository scope is intentionally restricted to axisymmetric formulation.
