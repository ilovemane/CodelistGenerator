#' Show mappings from source vocabularies to standard
#'
#' @param candidate_codelist Dataframe
#' @param source_vocabularies Character vector
#' @param db Database connection via DBI::dbConnect()
#' @param vocabulary_database_schema Name of database schema with vocab tables
#'
#' @return tibble
#' @export
#'
#' @examples
#' \dontrun{
#' library(DBI)
#' library(CodelistGenerator)
#' db <- DBI::dbConnect(" Your database connection here " )
#' vocabulary_database_schema <- " Your vocabulary schema here "
#' asthma_codes <- get_candidate_codes(
#'   keywords = "asthma",
#'   db = db,
#'   vocabulary_database_schema = " Your vocabulary schema here ")
#' show_mappings(
#'   candidate_codelist = asthma_codes,
#'   db = db,
#'   vocabulary_database_schema = " Your vocabulary schema here "
#' )
#' }
show_mappings <- function(candidate_codelist,
                          source_vocabularies = c(
                            "ATC", "ICD10CM", "ICD10PCS",
                            "ICD9CM", "ICD9Proc",
                            "LOINC", "OPCS4", "Read",
                            "RxNorm", "RxNorm Extension",
                            "SNOMED"
                          ),
                          db,
                          vocabulary_database_schema) {
  error_message <- checkmate::makeAssertCollection()

  checkmate::assertVector(source_vocabularies, add = error_message)
  checkmate::assertDataFrame(candidate_codelist, add = error_message)
  db_inherits <- inherits(db, "DBIConnection")
  if (!isTRUE(db_inherits)) {
    error_message$push("db must be a database connection via DBI::dbConnect()")
  }
  checkmate::reportAssertions(collection = error_message)

  concept_db <- dplyr::tbl(db, dplyr::sql(paste0(
    "SELECT * FROM ",
    vocabulary_database_schema,
    ".concept"
  )))
  concept_relationship_db <- dplyr::tbl(db, dplyr::sql(paste0(
    "SELECT * FROM ",
    vocabulary_database_schema,
    ".concept_relationship"
  )))
  # lowercase names
  concept_db <- dplyr::rename_with(concept_db, tolower)
  concept_relationship_db <- dplyr::rename_with(concept_relationship_db,
                                                tolower)

  mapped_codes <- concept_db %>%
    dplyr::inner_join(concept_relationship_db %>%
      dplyr::filter(.data$relationship_id == "Mapped from") %>%
      dplyr::filter(.data$concept_id_1 %in% !!candidate_codelist$concept_id) %>%
      dplyr::select("concept_id_1", "concept_id_2") %>%
      dplyr::rename("concept_id" = "concept_id_2"),
    by = c("concept_id")
    ) %>%
    dplyr::filter(.data$vocabulary_id %in% source_vocabularies) %>%
    dplyr::distinct() %>%
    dplyr::collect()

  mapped_codes <- mapped_codes %>%
    dplyr::select("concept_id_1", "concept_id",
                  "concept_name", "concept_code",
                  "vocabulary_id")

  mapped_codes <- mapped_codes %>%
    dplyr::select("concept_id_1") %>%
    dplyr::rename("concept_id" = "concept_id_1") %>%
    dplyr::left_join(concept_db %>%
      dplyr::filter(.data$concept_id %in% !!mapped_codes$concept_id_1) %>%
      dplyr::collect(),
      by = c("concept_id")) %>%
    dplyr::select("concept_id", "concept_name", "vocabulary_id") %>%
    dplyr::rename("standard_vocabulary_id" = "vocabulary_id") %>%
    dplyr::rename("concept_id_1" = "concept_id") %>%
    dplyr::rename("standard_concept_name" = "concept_name") %>%
    dplyr::full_join(mapped_codes,
                     by = "concept_id_1") %>%
    dplyr::rename("standard_concept_id" = "concept_id_1") %>%
    dplyr::rename("source_concept_id" = "concept_id") %>%
    dplyr::rename("source_concept_code" = "concept_code") %>%
    dplyr::rename("source_concept_name" = "concept_name") %>%
    dplyr::rename("source_vocabulary_id" = "vocabulary_id")

  mapped_codes %>%
    dplyr::distinct()
}
