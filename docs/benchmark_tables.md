# Axisymmetric Benchmark Notes

Este repositorio usa o problema da esfera espessa pressurizada (formulacao axissimetrica) como benchmark de regressao.

## Caso de referencia

- Entrada: data/sphere.dat
- Saidas de referencia:
  - benchmarks/reference/sphere.out
  - benchmarks/reference/sphere.err
- Execucao local:
  - scripts/run_case.ps1 -Case sphere
- Comparacao automatica:
  - scripts/benchmark.ps1 -Rebuild

## Contexto

A implementacao segue o BEACON do livro do Becker para analise elastica axissimetrica por elementos de contorno. O fluxo atual do projeto foi reduzido para esse escopo unico.
