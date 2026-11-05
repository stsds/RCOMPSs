library(arrow)
library(dplyr)
library(quanteda)

base_dir <- "/gpfs/scratch/bsc19/bsc021292/project_SocialSciences/"
input_path <- file.path(base_dir, "test_data")
dict_path <- file.path(base_dir, "test_data/dictionary_test.RDS")

dir.create(input_path, recursive = TRUE, showWarnings = FALSE)

sample_dict <- quanteda::dictionary(list(
  economy = c("market", "inflation", "tax", "gdp", "trade", "investment"),
  politics = c("election", "parliament", "vote", "policy", "government", "law"),
  environment = c("climate", "emissions", "energy", "sustainability", "green"),
  social_welfare = c("education", "healthcare", "pensions", "housing", "labor")
))

saveRDS(sample_dict, file = dict_path)
cat("Saved synthetic dictionary to:", dict_path, "\n")

generate_parquet_file <- function(file_path, num_rows = 100) {
  sample_texts <- c(
    "The government proposed new economic policies on inflation and tax reform.",
    "Parliament members cast votes during yesterday's debate on climate law.",
    "Investments in green energy and sustainability are essential for long-term GDP growth.",
    "Education and healthcare remain primary focus areas for social welfare funding.",
    "Trade agreements were discussed to stabilize domestic market prices."
  )
  
  df <- data.frame(
    doc_id = paste0("doc_", seq_len(num_rows)),
    text = sample(sample_texts, num_rows, replace = TRUE),
    author = sample(c("Author A", "Author B", "Author C", "Author D"), num_rows, replace = TRUE),
    word_count = sample(50:500, num_rows, replace = TRUE),
    stringsAsFactors = FALSE
  )
  
  arrow::write_parquet(df, file_path)
}


sample_years <- 1960:2021

for (year in sample_years) {
  for (part in 1:2) {
    file_name <- sprintf("data_%d_part%d.parquet", year, part)
    full_file_path <- file.path(input_path, file_name)
    
    generate_parquet_file(full_file_path, num_rows = 150)
    cat("Generated:", file_name, "\n")
  }
}

cat("\nSynthetic data created:", input_path, "\n")