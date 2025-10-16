### Curva de Acúmulo do Pangenoma (Panaroo + ggplot2)
## Visualize como o tamanho do pangenoma e core genome varia com o acréscimo de genomas

lines <- readLines(summary_txt)

# A linha abaixo filtra as linhas que contêm os dados que você quer e as divide
# com base em um ou mais espaços em branco, criando uma lista de vetores.
clean_data <- lines %>%
  str_subset("^\\w") %>% # Filtra as linhas que começam com uma letra
  str_split("\\s{2,}") # Divide as strings por dois ou mais espaços

# 4. Crie um data.frame a partir dos dados limpos
# Usamos 'bind_rows' para combinar os dados da lista em um data.frame.
# A função 'lapply' aplica a transformação a cada vetor da lista.
pan_summary <- bind_rows(
  lapply(clean_data, function(x) {
    tibble(
      tipo_gene = str_trim(x[1]), # O primeiro elemento é o tipo de gene
      total_genes = as.numeric(str_trim(x[2])) # O segundo é a contagem de genes
    )
  })
)

# 5. Visualize o resultado
# Agora você pode usar o 'pan_summary' para criar um gráfico.
ggplot(pan_summary, aes(x = tipo_gene, y = total_genes, fill = tipo_gene)) +
  geom_bar(stat = "identity") +
  labs(title = "Distribuição de Genes no Pangenoma",
       x = "Tipo de Gene",
       y = "Número de Genes") +
  theme_minimal() +
  coord_flip() # O gráfico de barras é melhor visualizado deitado.

# Salva o gráfico como um arquivo PNG
ggsave(file.path(graphs_dir, "genes_distribution.png"), width = 12, height = 6, dpi = 300)


### Distribuição de Genes (Core/Acessório/Exclusivo)
## Use o arquivo gene_presence_absence.csv para classificar genes

# Calcular frequência de genes
gene_data <- read.csv(gpa_csv, header = TRUE)
num_genomes <- ncol(gene_data) - 3  # Colunas de metadata (Gene, Annotation, etc.)
gene_counts <- rowSums(gene_data[, 4:ncol(gene_data)] != "")

# Classificar genes
gene_stats <- data.frame(
  Category = c("Core (95-100%)", "Shell (15-95%)", "Cloud (0-15%)"),
  Count = c(
    sum(gene_counts >= 0.95 * num_genomes),
    sum(gene_counts >= 0.15 * num_genomes & gene_counts < 0.95 * num_genomes),
    sum(gene_counts < 0.15 * num_genomes)
  )
)

# O geom_text() adiciona os rótulos.
# position = position_stack(vjust = 0.5) centraliza os rótulos nos segmentos.
# label = paste0(Count) formatará o rótulo como o valor absoluto.
ggplot(gene_stats, aes(x = "", y = Count, fill = Category)) +
  geom_col(width = 1) +
  geom_text(
    aes(label = Count),
    position = position_stack(vjust = 0.5), # Centraliza os rótulos nas fatias
    color = "black", # Garante boa visibilidade
    size = 2 # Ajuste o tamanho da fonte se necessário
  ) +
  coord_polar("y") +
  labs(title = "Distribuição de Categorias de Genes") +
  theme_void()

# Salva o gráfico como um arquivo PNG
ggsave(file.path(graphs_dir, "grafico_pangenoma.png"), width = 6, height = 6, dpi = 300)

### Análise de Entropia dos Sítios

# Ler o arquivo de entropia sem cabeçalho
entropy_data <- read.csv(entropy_csv, header = FALSE, 
                         col.names = c("Gene", "Entropy"))

# Verificar a estrutura dos dados
head(entropy_data)
str(entropy_data)

# 1. Histograma da distribuição de entropia
ggplot(entropy_data, aes(x = Entropy)) +
  geom_histogram(bins = 30, fill = "steelblue", alpha = 0.7) +
  labs(title = "Distribuição de Entropia entre Genes",
       x = "Entropia", y = "Contagem") +
  theme_minimal()

ggsave(file.path(graphs_dir, "distribuicao_entropia_hist.png"), width = 8, height = 6, dpi = 300)

# 2. Gráfico de densidade
ggplot(entropy_data, aes(x = Entropy)) +
  geom_density(fill = "purple", alpha = 0.5) +
  labs(title = "Densidade de Entropia entre Genes",
       x = "Entropia", y = "Densidade") +
  theme_minimal()

ggsave(file.path(graphs_dir, "distribuicao_entropia_densidade.png"), width = 8, height = 6, dpi = 300)

# 3. Boxplot da entropia
ggplot(entropy_data, aes(y = Entropy)) +
  geom_boxplot(fill = "orange", alpha = 0.7) +
  labs(title = "Distribuição de Entropia entre Genes",
       y = "Entropia") +
  theme_minimal()

ggsave(file.path(graphs_dir, "distribuicao_entropia_boxplot.png"), width = 6, height = 8, dpi = 300)

# 4. Top 10 genes com maior entropia (mais variáveis)
top_entropy <- entropy_data %>%
  arrange(desc(Entropy)) %>%
  head(10)

ggplot(top_entropy, aes(x = reorder(Gene, Entropy), y = Entropy)) +
  geom_bar(stat = "identity", fill = "red", alpha = 0.7) +
  coord_flip() +
  theme_bw(base_size = 20) +
  labs(title = "Top 10 Genes com Maior Entropia",
       x = "Gene", y = "Entropia") 

ggsave(file.path(graphs_dir, "top10_genes_entropia.png"), width = 24, height = 12, dpi = 300)

# 5. Top 10 genes com menor entropia (menos variáveis)
bottom_entropy <- entropy_data %>%
  arrange(Entropy) %>%  # Ordena em ordem crescente de entropia
  head(10)

ggplot(bottom_entropy, aes(x = reorder(Gene, Entropy), y = Entropy)) +
  geom_bar(stat = "identity", fill = "blue", alpha = 0.7) +
  coord_flip() +
  theme_bw(base_size = 20) +
  labs(title = "Top 10 Genes com Menor Entropia (Mais Conservados)",
       x = "Gene", 
       y = "Entropia")

ggsave(file.path(graphs_dir, "top10_genes_menor_entropia.png"), width = 24, height = 12, dpi = 300)

# Estatísticas descritivas
cat("Estatísticas descritivas da entropia:\n")
summary(entropy_data$Entropy)
cat("\nDesvio padrão:", sd(entropy_data$Entropy))