# BEM Axis (Fortran)

Implementacao do codigo BEACON do livro do Becker em Fortran moderno, dedicada apenas a problemas axissimetrico-elasticos.

## Escopo

- Formulação axissimetrica apenas.
- Fluxo de build, execucao e benchmark para o caso da esfera.
- Fonte principal em Fortran free-form e sem COMMON blocks.
- Montagem das matrizes de influencia paralelizada com OpenMP.
- Resolucao do sistema linear com rotina do LAPACK (SGESV).

## Estrutura

- src/: codigo-fonte do solver
- data/: arquivos de entrada
- scripts/: automacao de build, execucao e benchmark
- benchmarks/reference/: saidas de referencia para regressao
- results/: saidas geradas localmente
- docs/: material de apoio
- archive/: historico de OCR e referencias

## Pre-requisitos

- gfortran com suporte a OpenMP
- LAPACK e BLAS disponiveis para linkagem
- GNU Make (Linux/macOS) ou mingw32-make (Windows)
- Windows PowerShell (para os scripts .ps1)

## Build

### Linux/macOS

```bash
make
```

### Windows (MinGW/MSYS2)

No Windows, use mingw32-make:

```powershell
mingw32-make
```

Para limpar os binarios antes de recompilar:

```powershell
mingw32-make clean
mingw32-make
```

O executavel e gerado em bin/beacon (Linux/macOS) ou bin/beacon.exe (Windows).

Opcionalmente, no PowerShell:

```powershell
.\scripts\build.ps1
```

## Execucao

Executar o caso axissimetrico da esfera:

```powershell
.\scripts\run_case.ps1 -Case sphere
```

Saidas:

- results/sphere.out
- results/sphere.err

## Benchmark

Executa o caso da esfera e compara com os arquivos de referencia versionados:

```powershell
.\scripts\benchmark.ps1 -Rebuild
```

Para reduzir falsos negativos entre ambientes com BLAS/LAPACK diferentes, o
arquivo sphere.out e comparado com tolerancia numerica (parametros opcionais
-AbsTol e -RelTol).

Referencias usadas:

- benchmarks/reference/sphere.out
- benchmarks/reference/sphere.err

## Notas

- O solver moderno esta em src/beacon_modern.f90 e usa o modulo beacon_state.
- O paralelismo com OpenMP e aplicado na etapa de montagem das matrizes de influencia.
- O sistema linear global e resolvido com o solver SGESV da biblioteca LAPACK.
- O projeto foi ajustado para foco exclusivo em formulacao axissimetrica.
