#!/bin/bash

### Parâmetros utilizados
sp="$1"
clean_mode="$2"
aligner="$3"
n_threads="12"

### Caminhos
# Caminho para este diretório
path="$(cd "$(dirname "$0")" && pwd)/"
# Caminho para os arquivos associados à spécie que está sendo analisado
path_sp="${path}${sp}/"
# Caminho para acessar os arquivos *.gff de uma espécie de bactéria do spécie Maribacter
path_gff="${path_sp}gff/"
# Caminho para salvar os resultados da análise
path_output="${path_sp}output/"
# Caminho para os resultados de um spécie baseados nos parâmetros utilizados
path_sub="${path_output}${sp}_${clean_mode}_${aligner}/"
# Caminho para os arquivos gff que o panaroo vai utilizar
path_panaroo="${path_gff}panaroo/"
# Gera um relatório com o tempo de execução
report="${path_output}${sp}_report.txt"
# Gera um log detalhado sobre a execução do panaroo
log="${path_output}${sp}_${clean_mode}_${aligner}.log"

# Diretórios contendo os genomas os resultados do Prokka
dir=$(find "$path_gff" -mindepth 1 -maxdepth 1 -type d -not -name ".")

rm -R "${path_panaroo}"
mkdir "${path_panaroo}"

# Percorrer cada diretório
for d in $dir; do
    # ls "${d}"
	id=$(basename $d)
	# Obter o nome do arquivo  gff
	file=$(ls "${d}" | grep ".*\.gff$")
    # echo "$file"
	path_file="${d}/${file}"
    # echo "${path_panaroo}${id}.gff"

	# Copiar para outro diretório e renomear
	cp "${path_file}" "${path_panaroo}${id}.gff"
done


mkdir -p "${path_output}"

# cp "$(find "${path_gff}" | grep '.*\.gff$')" "${path_panaroo}/panaroo/"

echo -e "Parâmetros utilizados:\n    clean_mode -> ${clean_mode}\n    aligner -> ${aligner}\n    n_threads -> ${n_threads}\n" >> "$report"

echo -e "Início do programa\n$(date "+%Y-%m-%d %H:%M:%S")\n" >> "$report"

panaroo -i "${path_panaroo}"*.gff -o "${path_sub}" --clean-mode "${clean_mode}" -a core --aligner "${aligner}" -t "${n_threads}" > "${log}"

echo -e "Fim do programa\n$(date "+%Y-%m-%d %H:%M:%S")\n" >> "$report"