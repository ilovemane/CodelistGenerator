% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/compare_codelists.R
\name{compare_codelists}
\alias{compare_codelists}
\title{Compare two codelists}
\usage{
compare_codelists(codelist_1, codelist_2)
}
\arguments{
\item{codelist_1}{Output of get_candidate_codes}

\item{codelist_2}{Output of get_candidate_codes}
}
\value{
tibble
}
\description{
Compare two codelists
}
\examples{
\dontrun{
library(DBI)
library(CodelistGenerator)
db <- DBI::dbConnect(" Your database connection here " )
vocabulary_database_schema <- " Your vocabulary schema here "
asthma_codes <- get_candidate_codes(
  keywords = "asthma",
  db = db,
  vocabulary_database_schema = " Your vocabulary schema here ")
persistant_asthma_codes <- get_candidate_codes(
  keywords = "Persistent asthma",
  db = db,
  vocabulary_database_schema = " Your vocabulary schema here ")
  compare_codelists(
   codelist_1 = asthma_codes,
   codelist_2 = persistant_asthma_codes
 )
}
}
