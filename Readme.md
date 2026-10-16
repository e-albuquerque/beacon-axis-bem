# BEM Axis (Fortran)

Projeto organizado para rodar os casos de benchmark do BEACON (esfera axissimetrica e cilindro 2D) com compilacao gfortran no Windows.

## Estrutura

- src/: codigo fonte principal
- data/: entradas dos problemas
- results/: saidas geradas nas execucoes locais
- benchmarks/reference/: saidas de referencia para comparacao automatica
- scripts/: scripts de build e execucao
- docs/: tabelas e material de apoio
- archive/: material historico (OCR, referencias)

## Pre-requisitos

- Windows PowerShell
- gfortran instalado (recomendado MSYS2 UCRT64)

## Build

No PowerShell, na raiz do projeto:

```powershell
.\scripts\build.ps1
```

Isso gera o executavel em bin/beacon.exe.

## Execucao dos casos

Rodar esfera:

```powershell
.\scripts\run_case.ps1 -Case sphere
```

Rodar cilindro:

```powershell
.\scripts\run_case.ps1 -Case cylinder
```

Resultados sao salvos em:

- results/sphere.out e results/sphere.err
- results/cylinder.out e results/cylinder.err

## Benchmark automatizado

Executa os dois casos e compara os resultados com as saidas de referencia:

```powershell
.\scripts\benchmark.ps1 -Rebuild
```

Arquivos de referencia versionados:

- benchmarks/reference/sphere.out
- benchmarks/reference/sphere.err
- benchmarks/reference/cylinder.out
- benchmarks/reference/cylinder.err

## Notas

- O include Fortran usado pelo solver esta em src/beacon_common.inc.
- As tabelas extraidas do livro permanecem em docs/benchmark_tables.md.
- Scripts de reconstrucao OCR estao em scripts/ocr/.
