# BEM Axis (Fortran)

Implementacao do codigo BEACON do livro do Becker em Fortran moderno, dedicada apenas a problemas axissimetrico-elasticos.

## Escopo

- Formulação axissimetrica apenas.
- Fluxo de build, execucao e benchmark para o caso da esfera.
- Fonte principal em Fortran free-form e sem COMMON blocks.

## Estrutura

- src/: codigo-fonte do solver
- data/: arquivos de entrada
- scripts/: automacao de build, execucao e benchmark
- benchmarks/reference/: saidas de referencia para regressao
- results/: saidas geradas localmente
- docs/: material de apoio
- archive/: historico de OCR e referencias

## Pre-requisitos

- Windows PowerShell
- gfortran (recomendado: MSYS2 UCRT64)

## Build

Na raiz do projeto:

```powershell
.\scripts\build.ps1
```

O executavel e gerado em bin/beacon.exe a partir de src/beacon_modern.f90.

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

Referencias usadas:

- benchmarks/reference/sphere.out
- benchmarks/reference/sphere.err

## Notas

- O solver moderno esta em src/beacon_modern.f90 e usa o modulo beacon_state.
- O projeto foi ajustado para foco exclusivo em formulacao axissimetrica.
