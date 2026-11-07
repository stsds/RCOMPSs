test_that("releasing a NULL device matrix does not initialize a GPU", {
  expect_null(rcompss_gpu_matrix_release(NULL))
})

test_that("resident GEMM supports ragged tiles and nonzero beta", {
  skip_if(Sys.getenv("RCOMPSs_TEST_GPU") != "true", "Requires GPU")
  name <- "resident_test"
  RCOMPSs.CreateRunContext(name); RCOMPSs.SetOperationPlacement(name,"GPU")
  RCOMPSs.SetOperationContext(name)
  handles <- list()
  on.exit({for(x in handles)rcompss_gpu_matrix_release(x);RCOMPSs.DeleteRunContext(name)})
  set.seed(400)
  for(mode in c("sync","async")) {
    RCOMPSs.SetRunMode(name,mode)
    for(d in list(c(1,1,1),c(17,9,13),c(32,19,7))) {
      A<-matrix(rnorm(d[1]*d[2]),d[1],d[2]);B<-matrix(rnorm(d[2]*d[3]),d[2],d[3]);C<-matrix(rnorm(d[1]*d[3]),d[1],d[3])
      da<-rcompss_gpu_matrix_upload(A);db<-rcompss_gpu_matrix_upload(B);dc<-rcompss_gpu_matrix_upload(C)
      handles<-c(handles,list(da,db,dc));expected<-C
      for(i in 1:3) {
        rcompss_gpu_matrix_gemm(da,db,dc,.51,-.42,tile=8L)
        expected<-.51*(A%*%B)-.42*expected
        expect_equal(rcompss_gpu_matrix_download(dc),expected,tolerance=1e-12)
      }
      expect_equal(rcompss_gpu_matrix_download(da),A)
      expect_equal(rcompss_gpu_matrix_download(db),B)
      rcompss_gpu_matrix_release(da);rcompss_gpu_matrix_release(db);rcompss_gpu_matrix_release(dc)
      expect_null(rcompss_gpu_matrix_release(dc))
      expect_error(rcompss_gpu_matrix_download(dc),"released")
    }
  }
})

test_that("resident handles validate dimensions and aliasing", {
  skip_if(Sys.getenv("RCOMPSs_TEST_GPU") != "true", "Requires GPU")
  name<-"resident_errors";RCOMPSs.CreateRunContext(name);RCOMPSs.SetOperationPlacement(name,"GPU");RCOMPSs.SetOperationContext(name)
  a<-rcompss_gpu_matrix_upload(matrix(1,3,3));bad<-rcompss_gpu_matrix_upload(matrix(1,2,2));c<-rcompss_gpu_matrix_upload(matrix(NaN,3,3))
  on.exit({for(x in list(a,bad,c))rcompss_gpu_matrix_release(x);RCOMPSs.DeleteRunContext(name)})
  expect_error(rcompss_gpu_matrix_gemm(a,a,a),"alias")
  expect_error(rcompss_gpu_matrix_gemm(a,bad,c),"Nonconformable")
  expect_error(rcompss_gpu_matrix_gemm(a,a,c,tile=0),"positive")
  expect_error(rcompss_gpu_matrix_gemm(a,a,c,alpha=Inf),"finite")
  expect_error(rcompss_gpu_matrix_download(1),"handle")
  expect_error(rcompss_gpu_matrix_release(1),"handle")
  rcompss_gpu_matrix_gemm(a,a,c,beta=0,tile=2L)
  expect_equal(rcompss_gpu_matrix_download(c),matrix(3,3,3))
  p<-tempfile();on.exit(unlink(p),add=TRUE)
  expect_error(compss_serialize(a,p,"cpp"),"Unsupported SEXP")
})

test_that("events order work across contexts and GC protects pending reads", {
  skip_if(Sys.getenv("RCOMPSs_TEST_GPU") != "true", "Requires GPU")
  for(name in c("resident_s1","resident_s2")) {
    RCOMPSs.CreateRunContext(name);RCOMPSs.SetOperationPlacement(name,"GPU");RCOMPSs.SetRunMode(name,"async")
  }
  on.exit({RCOMPSs.DeleteRunContext("resident_s1");RCOMPSs.DeleteRunContext("resident_s2")})
  A<-matrix(as.double(1:30),5,6);B<-matrix(as.double(1:42),6,7);expected<-A%*%B
  RCOMPSs.SetOperationContext("resident_s1")
  a<-rcompss_gpu_matrix_upload(A);b<-rcompss_gpu_matrix_upload(B);c<-rcompss_gpu_matrix_upload(matrix(0,5,7))
  on.exit(rcompss_gpu_matrix_release(c),add=TRUE)
  RCOMPSs.SetOperationContext("resident_s2")
  rcompss_gpu_matrix_gemm(a,b,c,tile=4L)
  RCOMPSs.SetOperationContext("resident_s1")
  expect_equal(rcompss_gpu_matrix_download(c),expected)
  RCOMPSs.SetOperationContext("resident_s2")
  rcompss_gpu_matrix_gemm(a,b,c,beta=1,tile=4L)
  rm(a,b);gc()
  expect_equal(rcompss_gpu_matrix_download(c),2*expected)
})
