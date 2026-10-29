cpp_roundtrip <- function(object) {
  path <- tempfile("cpp-")
  on.exit(unlink(path))
  compss_serialize(object, path, "cpp")
  compss_unserialize(path)
}

test_that("C++ serialization preserves matrix types, shape, and dimnames", {
  values <- list(
    as.double(1:6), 1:6, c(TRUE, FALSE, NA, TRUE, FALSE, TRUE),
    c("a", NA_character_, "b", "c", "d", "e"), as.list(1:6)
  )
  for (value in values) {
    x <- matrix(value, nrow = 2L, ncol = 3L)
    expect_identical(cpp_roundtrip(x), x)
    dimnames(x) <- list(rows = c("r1", "r2"), cols = c("a", "b", "c"))
    expect_identical(cpp_roundtrip(x), x)
  }
})

test_that("C++ serialization preserves empty and higher-dimensional arrays", {
  objects <- list(
    matrix(numeric(), 0L, 3L), matrix(integer(), 3L, 0L),
    matrix(numeric(), 0L, 0L), matrix(1:3, 1L, 3L), matrix(1:3, 3L, 1L),
    array(as.double(1:24), c(2L, 3L, 4L),
          dimnames = list(c("a", "b"), NULL, c("w", "x", "y", "z")))
  )
  for (x in objects) expect_identical(cpp_roundtrip(x), x)
})

test_that("nested matrices retain shape without changing ordinary values", {
  x <- list(matrix = matrix(1:6, 2L), nested = list(array(1:8, c(2L, 2L, 2L))),
            vector = c(1, NA_real_, Inf), string = c("a", NA_character_),
            logical = c(TRUE, NA, FALSE), empty = NULL)
  expect_identical(cpp_roundtrip(x), x)
})

test_that("matrix products survive C++ task-payload round trips", {
  a <- matrix(as.double(1:6), 2L, 3L)
  b <- matrix(as.double(1:12), 3L, 4L)
  actual <- cpp_roundtrip(cpp_roundtrip(a) %*% cpp_roundtrip(b))
  expect_identical(actual, a %*% b)
  a <- matrix(as.double(1:9), 3L, 3L)
  expect_identical(cpp_roundtrip(a) %*% cpp_roundtrip(a), a %*% a)
})

test_that("C++ serialization still reads version 1 and 2 files", {
  path <- tempfile("cpp-")
  on.exit(unlink(path))
  for (version in 1:2) {
    con <- file(path, "wb")
    # Legacy unnamed numeric vector: magic, version, type, length, values.
    writeBin(c(0x52535343L, version, 3L, 3L), con, size = 4L)
    writeBin(c(1.5, NA_real_, Inf), con, size = 8L)
    close(con)
    expect_identical(compss_unserialize(path), c(1.5, NA_real_, Inf))
  }
  con <- file(path, "wb")
  # Version 2 named list, containing integer and numeric values.
  writeBin(c(0x52535343L, 2L, 5L, 2L, 1L), con, size = 4L)
  writeBin(1L, con, size = 4L); writeBin(charToRaw("a"), con)
  writeBin(1L, con, size = 4L); writeBin(charToRaw("b"), con)
  writeBin(c(2L, 1L, 7L, 3L, 2L), con, size = 4L)
  writeBin(c(2.5, 4.5), con, size = 8L)
  close(con)
  expect_identical(compss_unserialize(path), list(a = 7L, b = c(2.5, 4.5)))
})

test_that("array encoding is versioned and future versions are rejected", {
  path <- tempfile("cpp-")
  on.exit(unlink(path))
  compss_serialize(matrix(1:4, 2L), path, "cpp")
  expect_identical(readBin(path, integer(), n = 2L)[2L], 3L)
  con <- file(path, "wb")
  writeBin(c(0x52535343L, 99L), con, size = 4L)
  close(con)
  expect_error(compss_unserialize(path), "Unsupported serialization version")
})
