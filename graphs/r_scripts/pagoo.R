# === 1) Carregar no Pagoo ===
# Usa o importador nativo do Panaroo -> Pagoo
# Nota: genes marcados por Panaroo como 'stop', 'length' ou 'refound'
# são descartados por este importador (comportamento esperado).
p <- panaroo_2_pagoo(
  gene_presence_absence_csv = gpa_csv,
  gffs = gff_paths
)

# === 2) Gráficos ===

## 2.1 Pie: proporções core / shell / cloud
pie_plot <- p$gg_pie() +
  ggtitle("Composição do pangenoma (core / shell / cloud)")

ggsave(file.path(graphs_dir, "pagoo_core_shell_cloud.png"), pie_plot, width=6, height=5, dpi=300)


## 2.2 Distribuição de frequências (quantos clusters em 1 genoma, 2, ..., N)
freq_plot <- p$gg_barplot() +
  ggtitle("Distribuição de frequências de clusters")

ggsave(file.path(graphs_dir, "pagoo_freq_clusters.png"), freq_plot, width=7, height=5, dpi=300)

## 2.3 Binmap (matriz presença/ausência)
binmap_plot <- p$gg_binmap() +
  ggtitle("Mapa binário de presença/ausência por genoma")

ggsave(file.path(graphs_dir, "pagoo_binmap_pa.png"), binmap_plot, width=24, height=12, dpi=300)

## 2.4 Curvas de pangenoma e coregenoma com ajustes (Heaps e decaimento exp.)
# O Pagoo cuida da rarefação + ajustes e já plota via gg_curves()
curves_plot <- p$gg_curves() +
  ggtitle("Curvas de pangenoma e coregenoma (com ajustes)")

ggsave(file.path(graphs_dir, "pagoo_curvas_pg_cg.png"), curves_plot, width=7, height=5, dpi=300)

## 2.5 PCA por conteúdo gênico (se quiser colorir por algum metadado, ajuste 'colour')
# Se não houver metadados, apenas gere o biplot simples:
pca_plot <- p$gg_pca(size = 3) +
  ggtitle("PCA do conteúdo gênico (panmatrix)")

ggsave(file.path(graphs_dir, "pagoo_pca_pan.png"), pca_plot, width=7, height=5, dpi=300)

# (opcional) montar um painel compacto para o artigo
painel <- (pie_plot | freq_plot) /
  (curves_plot | pca_plot)
ggsave(file.path(graphs_dir, "fig_painel_pangenoma.png"), painel, width=12, height=10, dpi=300)



# === 3) Genes acessórios estão mais presentes ===

## 3.1 Calcular frequência de cada gene
gene_frequency <- data.frame(
  Gene = rownames(p$pan_matrix),
  Frequency = rowSums(p$pan_matrix) / ncol(p$pan_matrix) * 100
)

# 2. Identificar genes acessórios (não core, presentes em pelo menos 10% dos genomas)
accessory_genes <- gene_frequency %>%
  filter(Frequency < 100 & Frequency >= 10) %>%
  arrange(desc(Frequency))

# 3. Obter anotações funcionais dos genes - FORMA CORRIGIDA
# O objeto p$genes é uma lista especial, precisamos extrair as informações corretamente
if (length(p$genes) > 0) {
  # Extrair nomes dos genes e suas anotações
  gene_names <- names(p$genes)
  annotations <- sapply(p$genes, function(x) {
    if (!is.null(x$annotation)) {
      return(x$annotation[1])  # Pega a primeira anotação
    } else {
      return(NA)
    }
  })
  
  # Criar data.frame com as anotações
  gene_annotations <- data.frame(
    Gene = gene_names,
    Annotation = annotations,
    stringsAsFactors = FALSE
  )
  
  # Juntar com os genes acessórios
  accessory_genes <- accessory_genes %>%
    left_join(gene_annotations, by = c("Gene" = "Gene"))
}

# 4. Selecionar os top 20 genes acessórios mais frequentes
top_accessory <- accessory_genes %>%
  top_n(20, Frequency)

# 5. Gráfico de barras dos genes acessórios mais frequentes
accessory_plot <- ggplot(top_accessory, aes(x = fct_reorder(Gene, Frequency), y = Frequency)) +
  geom_bar(stat = "identity", fill = "steelblue", alpha = 0.8) +
  coord_flip() +
  labs(title = "Top 20 Genes Acessórios Mais Frequentes",
       subtitle = "Genes presentes em 10-99% dos genomas",
       x = "Gene",
       y = "Frequência de Ocorrência (%)") +
  theme_minimal() +
  theme(axis.text.y = element_text(size = 10),
        plot.title = element_text(face = "bold", size = 16),
        plot.subtitle = element_text(size = 12))

# Adicionar anotações se disponíveis
if ("Annotation" %in% colnames(top_accessory)) {
  accessory_plot <- accessory_plot +
    geom_label(aes(label = ifelse(!is.na(Annotation) & nchar(as.character(Annotation)) > 30, 
                                 paste0(substr(Annotation, 1, 30), "..."), 
                                 Annotation)),
              hjust = -0.05, size = 2.5, fill = "white", alpha = 0.7)
}

# 6. Gráfico de dispersão para todos os genes acessórios
scatter_plot <- ggplot(accessory_genes, aes(x = Frequency)) +
  geom_histogram(fill = "lightblue", bins = 30, alpha = 0.8) +
  geom_vline(xintercept = mean(accessory_genes$Frequency), 
             linetype = "dashed", color = "red") +
  annotate("text", x = mean(accessory_genes$Frequency) + 5, y = 10, 
           label = paste("Média:", round(mean(accessory_genes$Frequency), 1), "%"),
           color = "red") +
  labs(title = "Distribuição de Frequência dos Genes Acessórios",
       x = "Frequência de Ocorrência (%)",
       y = "Número de Genes") +
  theme_minimal()

# 7. Heatmap dos genes acessórios mais frequentes
# Selecionar os 30 genes acessórios mais frequentes para o heatmap
top_30_genes <- accessory_genes %>%
  top_n(30, Frequency) %>%
  pull(Gene)

heatmap_data <- as.data.frame(p$pan_matrix[top_30_genes, ])
heatmap_data$Gene <- rownames(heatmap_data)

heatmap_plot <- heatmap_data %>%
  pivot_longer(-Gene, names_to = "Genome", values_to = "Presence") %>%
  ggplot(aes(x = Genome, y = fct_reorder(Gene, value, .fun = sum), fill = as.factor(Presence))) +
  geom_tile() +
  scale_fill_manual(values = c("0" = "white", "1" = "blue"), 
                    labels = c("Ausente", "Presente")) +
  labs(title = "Presença/Ausência dos Genes Acessórios Mais Frequentes",
       x = "Genomas",
       y = "Genes",
       fill = "Status") +
  theme_minimal() +
  theme(axis.text.x = element_text(angle = 90, hjust = 1, size = 8),
        axis.text.y = element_text(size = 8),
        legend.position = "bottom")

# 8. Análise de enriquecimento funcional (se as anotações estiverem disponíveis)
if ("Annotation" %in% colnames(accessory_genes)) {
  # Extrair categorias funcionais comuns
  functional_categories <- accessory_genes %>%
    mutate(Category = case_when(
      grepl("hypothetical", Annotation, ignore.case = TRUE) ~ "Hipotético",
      grepl("membrane", Annotation, ignore.case = TRUE) ~ "Proteína de membrana",
      grepl("transport", Annotation, ignore.case = TRUE) ~ "Transportador",
      grepl("transferase", Annotation, ignore.case = TRUE) ~ "Transferase",
      grepl("kinase", Annotation, ignore.case = TRUE) ~ "Kinase",
      grepl("regulat", Annotation, ignore.case = TRUE) ~ "Regulador",
      grepl("ribosom", Annotation, ignore.case = TRUE) ~ "Ribossomal",
      TRUE ~ "Outros"
    )) %>%
    group_by(Category) %>%
    summarise(Count = n(), 
              MeanFrequency = mean(Frequency),
              .groups = 'drop') %>%
    filter(Count >= 3)  # Mostrar apenas categorias com pelo menos 3 genes
  
  functional_plot <- ggplot(functional_categories, 
                           aes(x = reorder(Category, Count), y = Count)) +
    geom_bar(stat = "identity", fill = "coral", alpha = 0.8) +
    coord_flip() +
    labs(title = "Categorias Funcionais dos Genes Acessórios",
         x = "Categoria Funcional",
         y = "Número de Genes") +
    theme_minimal()
}

# 9. Salvar os resultados
ggsave(file.path(graphs_dir, "top_accessory_genes.png"), plot = accessory_plot, width = 14, height = 10, dpi = 300)
ggsave(file.path(graphs_dir, "accessory_distribution.png"), plot = scatter_plot, width = 10, height = 6, dpi = 300)
ggsave(file.path(graphs_dir, "accessory_heatmap.png"), plot = heatmap_plot, width = 14, height = 10, dpi = 300)

if (exists("functional_plot")) {
  ggsave(file.path(graphs_dir, "functional_categories.png"), plot = functional_plot, width = 12, height = 8, dpi = 300)
}

write.csv(accessory_genes, "accessory_genes_frequency.csv", row.names = FALSE)

# Exibir os gráficos
print(accessory_plot)
print(scatter_plot)
print(heatmap_plot)

if (exists("functional_plot")) {
  print(functional_plot)
}

# 10. Estatísticas resumidas
cat("Estatísticas dos Genes Acessórios:\n")
cat("Total de genes no pangenoma:", nrow(gene_frequency), "\n")
cat("Total de genes core (100%):", sum(gene_frequency$Frequency == 100), "\n")
cat("Total de genes acessórios:", nrow(accessory_genes), "\n")
cat("Frequência média dos genes acessórios:", round(mean(accessory_genes$Frequency), 1), "%\n")
cat("Frequência mediana dos genes acessórios:", round(median(accessory_genes$Frequency), 1), "%\n")
cat("Intervalo de frequência:", round(min(accessory_genes$Frequency), 1), "-", 
    round(max(accessory_genes$Frequency), 1), "%\n")

# 11. Listar os 10 genes acessórios mais frequentes
cat("\nTop 10 genes acessórios mais frequentes:\n")
print(head(accessory_genes, 10))

## Extrair só os genes acessórios
accessory_genes <- p$accessory_genes

## Calcular frequência de presença
pa_matrix <- p$pan_matrix

# Filtrar só genes acessórios
acc_matrix <- pa_matrix[rownames(pa_matrix) %in% accessory_genes$gene, ]

# Soma por linha = número de genomas em que cada gene está presente
acc_freq <- rowSums(acc_matrix)

# Ordenar do mais frequente para o menos
acc_freq_sorted <- sort(acc_freq, decreasing = TRUE)

head(acc_freq_sorted)

head(rownames(pa_matrix))
head(accessory_genes$gene)