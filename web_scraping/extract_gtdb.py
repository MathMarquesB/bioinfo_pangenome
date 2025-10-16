import time
import pandas as pd
from pathlib import Path
from datetime import datetime
from bs4 import BeautifulSoup
from selenium import webdriver
from selenium.webdriver.common.by import By
from selenium.webdriver.firefox.service import Service
from selenium.webdriver.firefox.options import Options

# Caminho do GeckoDriver
gecko_driver_path = 'C:\\Users\\Matheus\\Downloads\\geckodriver-v0.35.0-win64\\geckodriver.exe'

# Configuração do Firefox
options = Options()
options.binary_location = 'C:\\Program Files\\Mozilla Firefox\\firefox.exe'  # Ajuste se necessário
# options.add_argument("--headless")  # roda sem abrir janela (opcional)

# Inicializar o WebDriver
service = Service(gecko_driver_path)
driver = webdriver.Firefox(service=service, options=options)

# Caminhos
PATH = Path(__file__).parent
PATH_IDS = PATH / 'ids.txt'

# URL base
URL = 'https://gtdb.ecogenomic.org/genome?gid='

# XPATHS
XPATH_NAME = '/html/body/div/div/div/div[1]/main/div/div/div/div[1]/div/div[2]/div/i'
XPATH_LSPN = '/html/body/div/div/div/div/main/div/div/div/div[1]/div/div[3]/div[3]/fieldset/div/div[2]/a/img'

# Carregar IDs dos genomas
with open(PATH_IDS, 'r') as f:
    IDS = [line.strip() for line in f if line.strip()]

# Lista para armazenar resultados
dados = []

# Loop nos IDs
for id in IDS:
    full_url = f"{URL}{id}"
    driver.get(full_url)

    # esperar carregar (ajuste se precisar mais tempo)
    time.sleep(3)

    # Pegar o HTML
    soup = BeautifulSoup(driver.page_source, 'html.parser')

    # Pega o nome no NCBI
    name = driver.find_element(By.XPATH, XPATH_NAME).text

    # Verifica se o nome no LSPN está igual no NCBI
    try:
        link = driver.find_element(By.XPATH, XPATH_LSPN)
        link.click()

        time.sleep(3)

        # --- fechar a aba/janela recém-aberta ---
        all_windows = driver.window_handles

        # se abriu nova aba/janela
        if len(all_windows) > 1:
            original_window = driver.current_window_handle
            new_window = [w for w in all_windows if w != original_window][0]

            # mudar para a nova aba
            driver.switch_to.window(new_window)

            # Extrai o nome da URL do LSPN
            current_url = driver.current_url
            current_name = current_url.split('/')[-1].replace('-', ' ')
            if current_name.lower() == name.lower():
                lspn = f"Yes - {name}"
            else:
                lspn = f"No - {current_name}"

            # fechar a aba nova
            driver.close()
            # voltar para a aba original
            driver.switch_to.window(original_window)
    except Exception as e:
        print(f"Não foi possível acessar o link externo de {id}: {e}")
        lspn = 'No'

    # Encontrar todas as tabelas
    tables = soup.find_all("table")
    
    # Tabela 0: Taxonomic Information
    tabela0 = tables[0]
    linhas = tabela0.find_all("tr")

    gtdb_taxonomy = None
    ncbi_strain = None

    for linha in linhas:
        colunas = linha.find_all("td")
        if len(colunas) < 2:
            continue
        chave = colunas[0].get_text(strip=True)
        valor = colunas[1]

        if chave == "GTDB Taxonomy":
            # junta todos os textos (links + spans)
            gtdb_taxonomy = " ".join(valor.stripped_strings)
        elif chave == "NCBI strain identifiers":
            ncbi_strain = valor.get_text(strip=True)
            break

    # Tabela 1: Genome Characteristics
    checkm2_completeness = None
    checkm2_contamination = None
    contig_count = None
    n50_contigs = None
    genome_size = None
    protein_count = None
    coding_density = None
    gc_percentage = None

    tabela1 = tables[1]
    linhas1 = tabela1.find_all("tr")

    for linha in linhas1:
        colunas = linha.find_all("td")
        if len(colunas) < 2:
            continue

        chave = colunas[0].get_text(strip=True)
        if chave == "CheckM2":
            # colunas[1] = Completeness, colunas[2] = Contamination
            comp_text = colunas[1].get_text(strip=True).replace("Completeness:", "").replace("%", "").strip()
            cont_text = colunas[2].get_text(strip=True).replace("Contamination:", "").replace("%", "").strip()
            
            try:
                checkm2_completeness = float(comp_text)
            except:
                checkm2_completeness = None
            try:
                checkm2_contamination = float(cont_text)
            except:
                checkm2_contamination = None
        
        elif chave == "Contig Count":
                contig_count = int(colunas[1].get_text(strip=True).replace(",", ""))

        elif chave == "N50 Contigs":
            n50_contigs = int(colunas[1].get_text(strip=True).replace(",", "").replace(" bp", ""))

        elif chave == "Genome Size":
            genome_size = int(colunas[1].get_text(strip=True).replace(",", "").replace(" bp", ""))

        elif chave == "Protein Count":
            protein_count = int(colunas[1].get_text(strip=True).replace(",", ""))

        elif chave == "Coding Density":
            coding_density = float(colunas[1].get_text(strip=True).replace("%", "").strip())

        elif chave == "GC Percentage":
            gc_percentage = float(colunas[1].get_text(strip=True).replace("%", "").strip())
            break

    # Tabela 2: NCBI Metadata
    assembly_level = None
    country = None
    date = None
    genome_category = None
    cds_count = None
    seq_rel_date = None

    tabela2 = tables[2]
    linhas2 = tabela2.find_all("tr")

    for linha in linhas2:
        colunas = linha.find_all("td")
        if not colunas:
            continue

        chave = colunas[0].get_text(strip=True)
        valor = colunas[1].get_text(strip=True)

        if chave == "Assembly Level":
            assembly_level = valor

        elif chave == "Biosample":
            biosample_url = f"https://www.ncbi.nlm.nih.gov/biosample/?term={valor}"

        elif chave == "Country":
            country = valor

        elif chave == "Date":
            try:
                date = datetime.strptime(valor, "%Y-%m-%d").strftime("%Y-%m-%d")
            except:
                try:
                    date = datetime.strptime(valor, "%Y/%m/%d").strftime("%Y-%m-%d")
                except:
                    date = valor  # mantém original se não conseguir parsear

        elif chave == "Genome Category":
            genome_category = valor

        elif chave == "CDS Count":
            try:
                cds_count = int(valor.replace(",", ""))
            except:
                cds_count = None

        elif chave == "Seq Rel Date":
            try:
                seq_rel_date = datetime.strptime(valor, "%Y-%m-%d").strftime("%Y-%m-%d")
            except:
                try:
                    seq_rel_date = datetime.strptime(valor, "%Y/%m/%d").strftime("%Y-%m-%d")
                except:
                    seq_rel_date = valor
            break


    driver.get(biosample_url)
    time.sleep(3)
    biosample_soup = BeautifulSoup(driver.page_source, 'html.parser')
    biosample_table = biosample_soup.find_all("table")[0] # Há somente uma tabela na página
    biosample_rows = biosample_table.find_all("tr")

    # Inicializa dicionário com valores vazios
    biosample_info = {
        "host": "",
        "geographic location": "",
        "latitude and longitude": "",
        "description": ""
    }

    # Percorre a tabela
    for row in biosample_rows:
        th = row.find("th").get_text(strip=True).lower()
        td = row.find("td").get_text(strip=True)

        if th in biosample_info:
            biosample_info[th] = td
    try:
        biosample_info["description"] = driver.find_element(By.XPATH, "/html/body/div[1]/div[1]/form/div[1]/div[4]/div/div[4]/div/div[1]/dl[5]/dd/p").text
    except:
        print(f"{id}: Não foi possível extrair a descrição da URL {biosample_url}")
        
    # Salva no dataset
    dados.append({
        "ID": id,
        "GTDB species": name,
        "GTDB Taxonomy": gtdb_taxonomy,
        "NCBI Strain Identifiers": ncbi_strain,
        "CheckM2 Completeness (%)": checkm2_completeness,
        "CheckM2 Contamination (%)": checkm2_contamination,
        "Contig Count": contig_count,
        "N50 Contigs (bp)": n50_contigs,
        "Genome Size (bp)": genome_size,
        "Protein Count": protein_count,
        "Coding Density (%)": coding_density,
        "GC Percentage (%)": gc_percentage,
        "Assembly Level": assembly_level,
        "Country": country,
        "Date": date,
        "Genome Category": genome_category,
        "CDS Count": cds_count,
        "Seq Rel Date": seq_rel_date,
        "Biosample Host": biosample_info['host'],
        "Biosample Geographic Location": biosample_info['geographic location'],
        "Biosample Latitude and Longitude": biosample_info['latitude and longitude'],
        "Biosample Description": biosample_info['description'],
        "LPSN species validation": lspn
    })

# Fechar o navegador
driver.quit()

# Criar DataFrame
df = pd.DataFrame(dados)
print("\nPrévia do DataFrame:")
print(df.head())

# Salvar CSV
df.to_csv(PATH / "genomes_info.csv", index=False)
