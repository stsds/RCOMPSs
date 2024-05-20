//sum.cpp
#include <Rcpp.h>
#include <fstream>
#include <vector>
using namespace Rcpp;

// [[Rcpp::export]]
double WriteBinary(RawVector rv, std::string filename) {
  FILE *f = fopen(filename.c_str(), "wb");
  fwrite(&rv[0], sizeof(unsigned char), rv.size(), f);
  fclose(f);
  return 0;
}

// [[Rcpp::export]]
Rcpp::RawVector ReadBinary(std::string filename, size_t size) {
  Rcpp::RawVector v(size);
  FILE *in = fopen(filename.c_str(), "rb");
  if (in == nullptr) Rcpp::stop("Cannot open file", filename);
  auto nr = fread(&v[0], sizeof(unsigned char), size, in);
  if (nr != size) Rcpp::stop("Bad payload");
  Rcpp::Rcout << nr << std::endl;
  fclose(in);
  return v;
}