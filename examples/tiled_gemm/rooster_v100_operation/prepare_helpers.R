# Run once before launching any campaign processes. Workers only load this library.
root <- normalizePath(Sys.getenv("CAMPAIGN_ROOT", "."))
Rcpp::sourceCpp(file.path(root,"inputs.cpp"), cacheDir=file.path(root,"prepared-cache"), rebuild=TRUE)
wrappers <- list.files(file.path(root,"prepared-cache"), pattern="inputs.cpp.R$", recursive=TRUE, full.names=TRUE)
stopifnot(length(wrappers)==1L)
file.copy(wrappers, file.path(root,"prepared_helpers.R"), overwrite=TRUE)
