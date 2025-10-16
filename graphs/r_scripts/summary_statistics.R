# 1. Ler o arquivo Rtab
data <- read.table(gpa_rtab, sep = "\t", row.names = 1,
                   header = TRUE, check.names = FALSE)

# 2. Calcular o tamanho do genoma
pangenome_size <- nrow(data)

# 3. Calcular a proporção de cada classe de gene
core_size <- length(rowSums(data)[rowSums(data) >= 0.95 * ncol(data)])
shell_size <- length(rowSums(data)[rowSums(data) < 0.95 * ncol(data) &
                                     rowSums(data) >= 0.15 * ncol(data)])
cloud_size <- length(rowSums(data)[rowSums(data) < 0.15 * ncol(data)])
par(mfrow = c(1, 2), pin = c(2.5, 2.5))

# 4. Gerar o gráfico
slices <- c(core_size, shell_size, cloud_size)
pct <- round(slices / sum(slices) * 100, 2)
lab <- paste(c("core", "shell", "cloud"), pct, "%", sep = " ")
pie(slices, labels = lab, main = "Pangenome", cex = 0.8)

# 5. Gerar o histograma
hist(rowSums(data), xlab = "Number of genomes containing a gene",
     ylab = "Number of genes", main = "Gene frequency",
     ylim = c(0, 5000), xlim = c(0, ncol(data) + 1),
     breaks = seq(min(rowSums(data)) - 0.5, max(rowSums(data)) + 0.5, by = 1))