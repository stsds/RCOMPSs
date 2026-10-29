check_tile_reduction <- function(gpu) {
  set.seed(4721)
  for (shape in list(c(1L,1L), c(7L,9L), c(32L,17L))) {
    m <- shape[1]; n <- shape[2]
    for (inner in list(3L, c(3L,1L,7L))) {
      A <- lapply(inner, function(k) matrix(rnorm(m*k),m,k))
      B <- lapply(inner, function(k) matrix(rnorm(k*n),k,n))
      C <- matrix(rnorm(m*n),m,n); before <- C
      for (scalars in list(c(1,0),c(.51,-.42),c(0,1))) {
        expected <- scalars[1]*Reduce(`+`,Map(`%*%`,A,B))+scalars[2]*C
        actual <- rcompss_gemm_tile_reduce(A,B,C,scalars[1],scalars[2],gpu)
        expect_equal(actual,expected,tolerance=1e-12)
        expect_identical(C,before)
      }
      # beta=0 must not propagate undefined/NaN initial C values.
      expect_equal(rcompss_gemm_tile_reduce(A,B,C*NaN,1,0,gpu),
                   Reduce(`+`,Map(`%*%`,A,B)),tolerance=1e-12)
    }
  }
}

test_that("native CPU tile reduction handles ragged panels and preserves inputs", {
  check_tile_reduction(FALSE)
})

test_that("tile reduction validates all pairs before computation", {
  A <- matrix(1,2,3); B <- matrix(1,3,4); C <- matrix(0,2,4)
  expect_error(rcompss_gemm_tile_reduce(list(),list(),C),"positive number")
  expect_error(rcompss_gemm_tile_reduce(list(A),list(B,B),C),"same positive")
  expect_error(rcompss_gemm_tile_reduce(list(A),list(1:3),C),"double matrices")
  expect_error(rcompss_gemm_tile_reduce(list(A,A),list(B,t(B)),C),"index 2")
  expect_error(rcompss_gemm_tile_reduce(list(A),list(B),C,Inf),"finite")
})

test_that("GPU tile reduction handles sync and async contexts", {
  skip_if(Sys.getenv("RCOMPSs_TEST_GPU") != "true", "Requires an available GPU")
  name <- "test_tile_reduce"
  RCOMPSs.CreateRunContext(name)
  on.exit(RCOMPSs.DeleteRunContext(name))
  RCOMPSs.SetOperationPlacement(name,"GPU")
  RCOMPSs.SetOperationContext(name)
  for (mode in c("sync","async")) {
    RCOMPSs.SetRunMode(name,mode)
    check_tile_reduction(TRUE)
  }
})
