#!/bin/bash

### Caminhos
# Caminho para este diretório
path="$(cd "$(dirname "$0")" && pwd)/"

# Cada espécie precisa ter um diretório com seu nome
# Para realizar análises consecutivas de diferentes espécies, separe cada nome com um espaço em branco
# Ex: species='dokdonensis all_maribacter aquivivus'
species='all_maribacter'

# Essa variável pode ser uma lista caso queira usar dois modos diferentes para fins de comparação
# Ex: clean_modes='strict sensitive'
# strict -> Interespecies (indicado)
# sensitive -> Intraespecies
clean_modes='strict'

# Essa variável pode ser uma lista caso queira usar dois alinhadores diferentes para fins de comparação
# Ex: aligners='mafft prank'
# mafft -> mais eficiente, bom para lidar com grandes quantidades de amostras
# prank -> mais lento (dados pequenos)
aligners='mafft'

# Percorre cada espécie (diretório) realizando uma rotina de análise completa para a anotação do pangenoma bacteriano
# Análise completa: Coleta -> Preparação -> Alinhamento
for sp in $species; do
    # Baixa os arquivos FASTA do NCBI
    bash "${path}get_fasta.sh" "$sp"
    # Gera os arquivos GFF a por meio do Prokka
    bash "${path}only_prokka.sh" "$sp"
    # Realiza as análises para as diferentes combinações de parâmetros
    for cm in $clean_modes; do
        for a in $aligners; do
            # Constrói o pangenoma
            bash "${path}analyse_panaroo.sh" "$sp" "$cm" "$a"
        done
    done
done
