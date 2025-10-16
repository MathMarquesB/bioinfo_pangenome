# 1. Ler o CSV em um data.frame
gpa <- read.csv(gpa_csv, check.names = FALSE)

# 2. Transformar para o formato longo e remover duplicatas
long_data <- gpa %>%
  select(cluster = Gene, starts_with("data_")) %>%
  pivot_longer(
    cols = -cluster,
    names_to = "org",
    values_to = "gene"
  ) %>%
  filter(!is.na(gene) & gene != "") %>%  # Remover valores vazios e NA
  mutate(org = str_remove(org, "^data_")) %>%
  distinct() %>%  # Remover duplicatas completas
  group_by(org, gene) %>%
  filter(n() == 1) %>%  # Manter apenas genes únicos por organismo
  ungroup()

# 3. Verificar se ainda há duplicatas
duplicate_check <- long_data %>%
  group_by(org, gene) %>%
  summarise(n = n(), .groups = 'drop') %>%
  filter(n > 1)

if (nrow(duplicate_check) > 0) {
  print("Ainda existem genes duplicados:")
  print(duplicate_check)

  # Estratégia alternativa: adicionar sufixo aos genes duplicados
  long_data <- long_data %>%
    group_by(org, gene) %>%
    mutate(gene = ifelse(n() > 1, 
                         paste0(gene, "_dup", row_number()),
                         gene)) %>%
    ungroup()
}

# 4. Converter para data.frame
long_data_df <- as.data.frame(long_data)

# 5. Criar objeto Pagoo
p <- pagoo(
  data = long_data_df,
  core_level = 95,
  verbose = TRUE
)

# 6. Gerar gráficos
pie_plot <- p$gg_pie() +
  ggtitle("Proporção de Genes no Pangenoma") +
  theme_bw()
print(pie_plot)

bar_plot <- p$gg_barplot() +
  ggtitle("Distribuição de Frequência dos Clusters de Genes") +
  xlab("Número de Genomas") +
  ylab("Número de Clusters") +
  theme_minimal()
print(bar_plot)