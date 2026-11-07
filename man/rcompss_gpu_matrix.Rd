\name{rcompss_gpu_matrix}
\alias{rcompss_gpu_matrix_upload}
\alias{rcompss_gpu_matrix_gemm}
\alias{rcompss_gpu_matrix_download}
\alias{rcompss_gpu_matrix_release}
\title{Worker-local GPU-resident matrices}
\usage{
rcompss_gpu_matrix_upload(x)
rcompss_gpu_matrix_gemm(A, B, C, alpha = 1, beta = 0, tile = 512L)
rcompss_gpu_matrix_download(x)
rcompss_gpu_matrix_release(x)
}
\arguments{
\item{x}{A nonempty double matrix for upload; a GPU matrix handle otherwise. Release also accepts NULL.}
\item{A, B, C}{GPU matrix handles with conformable dimensions. C must not alias A or B.}
\item{alpha, beta}{Finite scalars in C = alpha A B + beta C.}
\item{tile}{Positive tile size, including support for partial edge tiles.}
}
\description{Upload once, perform repeated tiled FP64 GEMM updates on the GPU, and download once. Requires a CUDA build and an active GPU operation context on the owning device.}
\details{GEMM updates C in place. In asynchronous contexts work may remain queued; events order subsequent operations and finalization. Upload and download synchronize before returning. Handles own device memory, are process-local, and cannot be serialized or passed between COMPSs tasks. Create and consume them within the same task. Release explicitly or allow garbage collection to release them. Releasing the same handle twice is safe. All matrices must fit device memory.}
\value{Upload returns an external pointer of class rcompss_gpu_matrix; GEMM returns the same C handle; download returns an ordinary R matrix; release returns NULL invisibly.}
