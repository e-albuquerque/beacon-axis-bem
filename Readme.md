# BEM Axis (Fortran)

Projeto organizado para rodar os casos de benchmark do BEACON (esfera axissimetrica e cilindro 2D) com compilacao gfortran no Windows.

## Estrutura

- src/: codigo fonte principal
- data/: entradas dos problemas
- results/: saidas finais de referencia para uso humano
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

## Notas

- O include Fortran usado pelo solver esta em src/beacon_common.inc.
- As tabelas extraidas do livro permanecem em docs/benchmark_tables.md.
- Scripts de reconstrucao OCR estao em scripts/ocr/.
