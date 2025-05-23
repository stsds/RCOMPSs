% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/utils.R
\name{task}
\alias{task}
\title{task}
\usage{
task(f, filename, return_value = FALSE, info_only = FALSE, ...)
}
\arguments{
\item{f}{The function to be executed.}

\item{info_only}{Boolean. Whether the run is to print the information only.}

\item{...}{Metadata.}

\item{f_dir}{Absolute directory of the file where f is defined.}
}
\value{
The decorated function
}
\description{
This function is the decorator for tasks.
}
