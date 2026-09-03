source(file.path("R", "prepare_ssoqe.R"))

manifest <- ssoqe_package_manifest()
stopifnot(
  identical(names(manifest), c("package", "source", "group")),
  !anyDuplicated(manifest$package),
  all(manifest$source == "CRAN")
)

lessons <- ssoqe_lesson_manifest()
stopifnot(
  nrow(lessons) == 18L,
  !anyDuplicated(lessons$lesson),
  !anyDuplicated(lessons$repository),
  all(startsWith(lessons$repository, "SSoQE-"))
)

stopifnot(
  ssoqe_archive_is_safe(c("repo/file.txt", "repo/Data/input.csv")),
  !ssoqe_archive_is_safe("../outside.txt"),
  !ssoqe_archive_is_safe("repo/../../outside.txt"),
  !ssoqe_archive_is_safe("C:/outside.txt"),
  !ssoqe_archive_is_safe("/outside.txt")
)

download_fixture <- tempfile("ssoqe-download-")
dir.create(download_fixture)
download_plan <- download_ssoqe_materials(
  download_fixture,
  dry_run = TRUE
)
stopifnot(
  nrow(download_plan) == nrow(lessons),
  all(download_plan$status == "DRY-RUN"),
  !length(list.files(download_fixture, all.files = TRUE, no.. = TRUE))
)

fixture <- tempfile("ssoqe-preflight-")
dir.create(fixture)
complete <- file.path(fixture, "complete-project")
incomplete <- file.path(fixture, "incomplete-project")
failing <- file.path(fixture, "failing-project")
dir.create(complete)
dir.create(incomplete)
dir.create(failing)

writeLines('{"R":{"Version":"4.5.1"},"Packages":{}}',
           file.path(complete, "renv.lock"))
writeLines("not valid JSON", file.path(failing, "renv.lock"))
hashes_before <- tools::md5sum(c(
  file.path(complete, "renv.lock"),
  file.path(failing, "renv.lock")
))

projects <- ssoqe_projects(fixture)
expected_projects <- normalizePath(
  c(complete, failing),
  winslash = "/",
  mustWork = TRUE
)
stopifnot(
  identical(projects, sort(expected_projects)),
  !incomplete %in% projects
)

dry_results <- lapply(projects, ssoqe_restore_project, dry_run = TRUE)
dry_results <- do.call(rbind, dry_results)
stopifnot(all(dry_results$status == "DRY-RUN"))

rerun_results <- lapply(projects, ssoqe_restore_project, dry_run = TRUE)
rerun_results <- do.call(rbind, rerun_results)
stopifnot(identical(dry_results, rerun_results))

original_runner <- ssoqe_run_restore
ssoqe_run_restore <- function(project) {
  list(ok = FALSE, output = "simulated isolated restore failure")
}
failure_result <- ssoqe_restore_project(failing, dry_run = FALSE)
ssoqe_run_restore <- original_runner
stopifnot(
  failure_result$status == "FAIL",
  grepl("simulated", failure_result$detail)
)

report <- prepare_ssoqe(fixture, dry_run = TRUE)
project_rows <- startsWith(report$component, "renv:")
stopifnot(
  sum(project_rows) == 2L,
  all(report$status[project_rows] %in% c("DRY-RUN", "SKIP"))
)

hashes_after <- tools::md5sum(names(hashes_before))
stopifnot(identical(unname(hashes_before), unname(hashes_after)))

error <- tryCatch(
  normalizePath(file.path(fixture, "missing"), mustWork = TRUE),
  error = identity
)
stopifnot(inherits(error, "error"))

unlink(fixture, recursive = TRUE)
unlink(download_fixture, recursive = TRUE)
message("All prepare_ssoqe.R checks passed.")
