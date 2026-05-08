# 🌬️ Wind Farm Real-Time Data Pipeline

---

## English Version
<details open>
  <summary>Click to expand/collapse</summary>
  
### Data Lakehouse on AWS with Terraform, PySpark, and Medallion Architecture

## 📋 About the Project
This project implements an end-to-end data pipeline for monitoring wind farms. The goal is to capture raw sensor data in **JSON** format, process it using distributed computing, and make it available for analysis in highly optimized **Parquet** format.

The infrastructure is fully managed via **Terraform (IaC)**, ensuring reproducibility and following cloud governance and security best practices.

---

## 🏗️ Data Architecture (Multi-hop)
The project utilizes a decoupled, multi-layer architecture pattern inspired by the *Medallion* concept, focusing on data organization and quality:

* **Bronze Layer (Raw):** Storage of raw JSON data in S3, preserving the fidelity of the original source.
* **Silver Layer (Processed):** Data transformed by the Glue Spark Job. In this stage, we perform cleaning, schema enforcement, and conversion to Parquet, optimizing the data for analysis and consumption.

### Components Used:
* **Amazon S3:** Distributed storage for data layers.
* **AWS Glue Crawlers:** Automatic schema mapping and Data Catalog updates.
* **AWS Glue Jobs (PySpark):** Large-scale data transformation.
* **AWS Glue Workflows:** Event and state-based orchestration.
* **IAM (Identity and Access Management):** Least privilege policies for resource security.

---

## 🚀 Automation Workflow
The key differentiator of this project is its intelligent orchestration. The workflow is configured to be **100% automatic**:

1. **On-Demand Trigger:** Starts the *Raw Crawler*.
2. **Conditional Trigger:** Once the Crawler identifies the data and creates the table, the *Spark Job* is triggered.
3. **Final Trigger:** After successful processing, a second Crawler maps the *Processed* layer, making the data immediately available for analysis.

---

## 🛠️ Technologies and Technical Decisions
* **Terraform:** The entire infrastructure (Buckets, Roles, Policies, Jobs, and Triggers) is versioned.
* **Parquet + Snappy:** Chosen for the processed layer to reduce storage costs and accelerate Athena queries.
* **Security (Least Privilege):** IAM policies were granularly refined to allow only necessary actions (`ListBucket`, `PutObject`, `CreateTable`, etc.), avoiding the use of administrator permissions.

---

## 📁 Repository Structure
```bash
├── app/
│   ├── common/
│   │   └── config.py            # Centralized configurations and utilities
│   ├── etl/
│   │   └── process_wind_farm.py # PySpark Script (Bronze -> Silver Transformation)
│   ├── producers/               # Real-time sensor simulation scripts
│   │   ├── hydraulic_pressure.py
│   │   ├── power_factor.py
│   │   └── temperature_battery.py
│   └── infra/                   # Infrastructure as Code (Terraform)
│       ├── athena.tf            # Resources for analytical queries
│       ├── firehose.tf          # Stream and ingestion configuration
│       ├── glue.tf              # Jobs, Crawlers, and Orchestration Workflows
│       ├── main.tf              # S3 Buckets and IAM Roles definitions
│       ├── providers.tf         # AWS providers and versions
│       └── variables.tf         # Project variables
├── .gitignore                   # Exclusion of sensitive and temporary files
├── requirements.txt             # Python dependencies
└── README.md                    # Technical documentation
```

---

## 🔧 How to Run
1. Clone the repository.

2. Configure your AWS credentials via CLI.

3. Navigate to the infra folder and run:

```bash
terraform init
terraform apply
```

4. Upload your JSON files to the raw bucket.

5. In the AWS Glue console, start the wind-farm-etl-workflow.

---

## 📈 Results
Upon completion, the data can be queried via Amazon Athena using standard SQL, enabling the creation of dashboards in tools such as Amazon QuickSight or PowerBI.
</details>

---

## Versão em Português
<details>
  <summary>Clique para expandir/recolher</summary>
  
  ### Data Lakehouse na AWS com Terraform, PySpark e Medallion Architecture

## 📋 Sobre o Projeto
Este projeto implementa um pipeline de dados ponta a ponta para monitoramento de parques eólicos. O objetivo é capturar dados brutos de sensores em formato **JSON**, processá-los utilizando processamento distribuído e disponibilizá-los para análise em formato **Parquet** altamente otimizado.

A infraestrutura é totalmente gerenciada via **Terraform (IaC)**, garantindo reprodutibilidade e seguindo as melhores práticas de governança e segurança na nuvem.

---

## 🏗️ Arquitetura de Dados (Multicamadas)
O projeto utiliza um padrão de arquitetura desacoplada e multicamadas, inspirado no conceito *Medallion*, focando na organização e qualidade do dado:

* **Camada Bronze (Raw):** Armazenamento dos dados brutos em JSON, preservando a fidelidade da fonte original no S3.
* **Camada Silver (Processed):** Dados transformados pelo Glue Spark Job. Nesta etapa, realizamos a limpeza, definição de tipos (schema enforcement) e conversão para Parquet, otimizando o dado para análise e consumo.

### Componentes Utilizados:
* **Amazon S3:** Armazenamento distribuído para as camadas de dados.
* **AWS Glue Crawlers:** Mapeamento automático de esquemas e atualização do Data Catalog.
* **AWS Glue Jobs (PySpark):** Transformação de dados em escala.
* **AWS Glue Workflows:** Orquestração baseada em eventos e estados.
* **IAM (Identity and Access Management):** Políticas de menor privilégio para segurança dos recursos.

---

## 🚀 Fluxo de Automação
O diferencial deste projeto é a sua orquestração inteligente. O workflow foi configurado para ser **100% automático**:

1. **Trigger On-Demand:** Inicia o *Raw Crawler*.
2. **Conditional Trigger:** Assim que o Crawler identifica os dados e cria a tabela, o *Spark Job* é disparado.
3. **Final Trigger:** Após o sucesso do processamento, um segundo Crawler mapeia a camada *Processed*, tornando os dados imediatamente disponíveis para análise.

---

## 🛠️ Tecnologias e Decisões Técnicas
* **Terraform:** Toda a infraestrutura (Buckets, Roles, Policies, Jobs e Triggers) é versionada.
* **Parquet + Snappy:** Escolhido para a camada processada visando reduzir custos de armazenamento e acelerar consultas no Athena.
* **Segurança (Least Privilege):** As políticas de IAM foram detalhadamente refinadas para permitir apenas as ações necessárias (`ListBucket`, `PutObject`, `CreateTable`, etc.), evitando o uso de permissões de administrador.

---

## 📁 Estrutura do Repositório
```bash
├── app/
│   ├── common/
│   │   └── config.py            # Configurações centralizadas e utilitários
│   ├── etl/
│   │   └── process_wind_farm.py # Script PySpark (Transformação Bronze -> Silver)
│   ├── producers/               # Scripts para simulação de sensores em tempo real
│   │   ├── hydraulic_pressure.py
│   │   ├── power_factor.py
│   │   └── temperature_battery.py
│   └── infra/                   # Infraestrutura como Código (Terraform)
│       ├── athena.tf            # Recursos para consultas analíticas
│       ├── firehose.tf          # Configuração de stream e ingestão
│       ├── glue.tf              # Jobs, Crawlers e Workflows de orquestração
│       ├── main.tf              # Definições de Buckets e Roles IAM
│       ├── providers.tf         # Provedores e versões da AWS
│       └── variables.tf         # Variabilização do projeto
├── .gitignore                   # Exclusão de arquivos sensíveis e temporários
├── requirements.txt             # Dependências Python do projeto
└── README.md                    # Documentação técnica
```

---

## 🔧 Como Executar
1. Clone o repositório.

2. Configure suas credenciais AWS via CLI.

3. Na pasta terraform, execute:

```bash
terraform init
terraform apply
```

4. Suba seus arquivos JSON para o bucket raw.

5. No console do AWS Glue, inicie o wind-farm-etl-workflow.

---

## 📈 Resultados
Ao final da execução, os dados podem ser consultados via Amazon Athena com SQL padrão, permitindo a criação de dashboards em ferramentas como Amazon QuickSight ou PowerBI.
</details>
