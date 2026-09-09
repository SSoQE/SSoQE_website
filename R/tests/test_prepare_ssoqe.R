source(file.path("R", "prepare_ssoqe.R"))

manifest <- ssoqe_package_manifest()
stopifnot(
  identical(names(manifest), c("package", "source", "group")),
  !anyDuplicated(manifest$package),
  all(manifest$source == "CRAN")
)

expected_current_year <- as.integer(format(Sys.Date(), "%Y"))
stopifnot(
  identical(current_year(), expected_current_year),
  identical(
    ssoqe_release_token(),
    paste0("ssoqe-", expected_current_year)
  ),
  identical(ssoqe_release_token(2027), "ssoqe-2027")
)
invalid_year <- tryCatch(
  ssoqe_release_token(2026.5),
  error = identity
)
stopifnot(inherits(invalid_year, "error"))

lessons <- ssoqe_lesson_manifest()
stopifnot(
  identical(
    names(lessons),
    c("lesson", "repository", "release_token")
  ),
  nrow(lessons) == 18L,
  !anyDuplicated(lessons$lesson),
  !anyDuplicated(lessons$repository),
  all(startsWith(lessons$repository, "SSoQE-")),
  all(
    lessons$release_token == paste0("ssoqe-", expected_current_year)
  ),
  all(ssoqe_lesson_manifest(2027)$release_token == "ssoqe-2027")
)

release_fixture <- data.frame(
  id = c(1, 2, 3, 4, 5, 6),
  tag_name = c(
    "ssoqe-2026-v9",
    "course-ssoqe-2026-final",
    "SSOQE-2026-v10",
    "ssoqe-2025-v20",
    "ssoqe-2026-draft",
    "ssoqe-2026-prerelease"
  ),
  draft = c(FALSE, FALSE, FALSE, FALSE, TRUE, FALSE),
  prerelease = c(FALSE, FALSE, FALSE, FALSE, FALSE, TRUE),
  published_at = c(
    "2026-08-01T10:00:00Z",
    "2026-09-01T10:00:00Z",
    "2026-09-03T10:00:00Z",
    "2026-09-04T10:00:00Z",
    "2026-09-05T10:00:00Z",
    "2026-09-06T10:00:00Z"
  ),
  zipball_url = paste0("https://example.test/", 1:6, ".zip"),
  stringsAsFactors = FALSE
)
release_records <- ssoqe_release_records(list(
  list(
    id = 10,
    tag_name = "ssoqe-2026-v1",
    draft = FALSE,
    prerelease = FALSE,
    published_at = "2026-08-01T10:00:00Z",
    zipball_url = "https://example.test/release.zip"
  )
))
stopifnot(
  nrow(release_records) == 1L,
  identical(release_records$tag_name, "ssoqe-2026-v1"),
  identical(ssoqe_release_records(list()), data.frame())
)
selected <- ssoqe_select_release(release_fixture, 2026)
stopifnot(
  identical(selected$tag, "course-ssoqe-2026-final"),
  is.null(ssoqe_select_release(release_fixture, 2027)),
  is.null(ssoqe_select_release(data.frame(), 2026))
)
tie_fixture <- release_fixture[1:2, ]
tie_fixture$published_at <- "2026-09-01T10:00:00Z"
stopifnot(
  identical(
    ssoqe_select_release(tie_fixture, 2026)$tag,
    "course-ssoqe-2026-final"
  )
)
incomplete_release <- release_fixture[1, ]
incomplete_release$zipball_url <- ""
metadata_error <- tryCatch(
  ssoqe_select_release(incomplete_release, 2026),
  error = identity
)
stopifnot(inherits(metadata_error, "error"))

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
  all(grepl(
    paste0("ssoqe-", expected_current_year),
    download_plan$detail,
    fixed = TRUE
  )),
  !length(list.files(download_fixture, all.files = TRUE, no.. = TRUE))
)

original_release_lookup <- ssoqe_latest_year_release
ssoqe_latest_year_release <- function(repository, year) NULL
not_available <- ssoqe_download_release(
  "SSoQE-Test_Lesson",
  download_fixture,
  2026
)
ssoqe_latest_year_release <- function(repository, year) {
  stop("simulated network failure", call. = FALSE)
}
technical_failure <- ssoqe_download_release(
  "SSoQE-Test_Lesson",
  download_fixture,
  2026
)
ssoqe_latest_year_release <- original_release_lookup
stopifnot(
  identical(not_available$status, "LESSON_NOT_AVAILABLE"),
  identical(
    not_available$detail,
    "There is no lesson data to download yet."
  ),
  identical(technical_failure$status, "FAIL"),
  grepl("simulated network", technical_failure$detail, fixed = TRUE)
)

fixture <- tempfile("ssoqe-preflight-")
dir.create(fixture)
complete <- file.path(fixture, "complete-project")
incomplete <- file.path(fixture, "incomplete-project")
failing <- file.path(fixture, "failing-project")
old_release <- file.path(fixture, "SSoQE-Test-ssoqe-2026-v1")
active_release <- file.path(fixture, "SSoQE-Test-ssoqe-2026-v2")
dir.create(complete)
dir.create(incomplete)
dir.create(failing)
dir.create(old_release)
dir.create(active_release)

writeLines('{"R":{"Version":"4.5.1"},"Packages":{}}',
           file.path(complete, "renv.lock"))
writeLines("not valid JSON", file.path(failing, "renv.lock"))
writeLines(
  '{"R":{"Version":"4.5.1"},"Packages":{}}',
  file.path(old_release, "renv.lock")
)
writeLines(
  '{"R":{"Version":"4.5.1"},"Packages":{}}',
  file.path(active_release, "renv.lock")
)
writeLines(
  "ssoqe-2026-v1",
  file.path(old_release, ".ssoqe-release")
)
writeLines(
  "ssoqe-2026-v2",
  file.path(active_release, ".ssoqe-release")
)
ssoqe_activate_release(
  fixture,
  "SSoQE-Test",
  2026,
  list(
    tag = "ssoqe-2026-v1",
    published_at = "2026-08-01T10:00:00Z"
  ),
  old_release
)
ssoqe_activate_release(
  fixture,
  "SSoQE-Test",
  2026,
  list(
    tag = "ssoqe-2026-v2",
    published_at = "2026-09-01T10:00:00Z"
  ),
  active_release
)
active_registry <- ssoqe_read_active_releases(fixture)
stopifnot(
  nrow(active_registry) == 1L,
  identical(active_registry$release_tag, "ssoqe-2026-v2"),
  dir.exists(old_release),
  dir.exists(active_release)
)
hashes_before <- tools::md5sum(c(
  file.path(complete, "renv.lock"),
  file.path(failing, "renv.lock"),
  file.path(old_release, "renv.lock"),
  file.path(active_release, "renv.lock")
))

projects <- ssoqe_projects(fixture)
expected_projects <- normalizePath(
  c(complete, failing, active_release),
  winslash = "/",
  mustWork = TRUE
)
stopifnot(
  identical(projects, sort(expected_projects)),
  !incomplete %in% projects,
  !normalizePath(old_release, winslash = "/") %in% projects
)
projects_2027 <- ssoqe_projects(fixture, 2027)
expected_2027 <- normalizePath(
  c(complete, failing),
  winslash = "/",
  mustWork = TRUE
)
stopifnot(identical(projects_2027, sort(expected_2027)))

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
  sum(project_rows) == 3L,
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
