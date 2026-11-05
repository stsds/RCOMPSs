ftagging <- function(file_path, dict_path, output_path) {
  library(arrow); library(dplyr); library(quanteda); library(toOrdinal)
      
  vars <- c("id", "abstract", "title")
  db <- read_parquet(file_path, col_select = all_of(vars))
  db$abtit <- paste(db$title, db$abstract)
  db$title <- NULL; db$abstract <- NULL
  db <- db[!is.na(nchar(db$abtit)) & nchar(db$abtit) > 100, ]
  dictionary <- readRDS(dict_path)

  if (nrow(db) > 0) {
    dc   <- corpus(db, text_field = "abtit", docid_field = "id")
    dtok <- tokens_ngrams(
      tokens_remove(
        tokens(dc, remove_punct = T, remove_symbols = T, remove_separators = T),
        pattern = c(stopwords("en"), "[0-9]", toOrdinal(1:100))), n = 1:3)
    dr <- convert(dfm(tokens_lookup(dtok, dictionary, valuetype = "glob")), to = "data.frame")

    saveRDS(dr, file.path(output_path, gsub(".parquet", ".RDS", basename(file_path))))
    return(nrow(dr))
  }
  gc()
}
