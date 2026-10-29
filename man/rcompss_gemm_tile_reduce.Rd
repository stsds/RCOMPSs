\name{rcompss_gemm_tile_reduce}
\alias{rcompss_gemm_tile_reduce}
\title{Reduce matrix tile pairs into one output tile}
\usage{
rcompss_gemm_tile_reduce(A, B, C0, alpha = 1, beta = 0, gpu = FALSE)
}
\arguments{
\item{A, B}{Nonempty lists of conformable double matrix tile pairs.}
\item{C0}{Initial output tile, with matching output dimensions.}
\item{alpha, beta}{Finite scalars.}
\item{gpu}{Use the active GPU context when true; otherwise use CPU BLAS.}
}
\description{Computes alpha times the sum of the tile products plus beta times
C0. Inputs are not modified. GPU mode retains the output tile in device memory,
reuses input buffers, and synchronizes before returning even in async mode.}
\value{A double matrix containing the reduced output tile.}
