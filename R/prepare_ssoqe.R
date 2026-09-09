# SSoQE 2026 pre-arrival preparation -----------------------------------------

current_year <- function() {
  as.integer(format(Sys.Date(), "%Y"))
}

ssoqe_validate_year <- function(year) {
  valid <- is.numeric(year) &&
    length(year) == 1L &&
    !is.na(year) &&
    is.finite(year) &&
    year >= 1000 &&
    year <= 9999 &&
    year == floor(year)
  if (!valid) {
    stop("year must be one four-digit number", call. = FALSE)
  }
  as.integer(year)
}

ssoqe_release_token <- function(year = current_year()) {
  year <- ssoqe_validate_year(year)
  paste0("ssoqe-", year)
}

ssoqe_package_manifest <- function() {
  workflow <- c(
    "countdown", "fs", "here", "janitor", "jsonlite", "knitr",
    "gh", "gitcreds", "languageserver", "palmerpenguins", "pander",
    "png", "qrcode", "quarto", "RcppTOML", "remotes", "renv",
    "reticulate", "rjson", "rlang", "showtext", "sysfonts", "targets",
    "tinytable", "tidyverse", "usethis", "visNetwork"
  )
  ecology <- c(
    "analogue", "ape", "Bchron", "caret", "cito", "geiger", "geodata",
    "geojsonsf", "GGally", "gganimate", "ggpubr", "ggspatial", "iNEXT",
    "lme4", "maps", "neotoma2", "phytools", "picante", "predicts",
    "rgbif", "scales", "sdm", "terra", "torch", "vegan"
  )

  data.frame(
    package = c(workflow, ecology),
    source = "CRAN",
    group = c(
      rep("workflow and teaching", length(workflow)),
      rep("ecology and modelling", length(ecology))
    ),
    stringsAsFactors = FALSE
  ) |>
    (\(x) x[order(tolower(x$package)), ])()
}

ssoqe_result <- function(component, status, detail) {
  data.frame(
    component = component,
    status = status,
    detail = detail,
    stringsAsFactors = FALSE
  )
}

ssoqe_lesson_manifest <- function(year = current_year()) {
  release_token <- ssoqe_release_token(year)
  data.frame(
    lesson = c(
      "Welcome and Ice Breaker",
      "Species Distribution Modelling",
      "Our Way of R and Reproducibility",
      "Hypothesis Testing and Null Models",
      "Biodiversity and Richness",
      "Sample Standardisation and Resampling",
      "Functional Programming in the World of AI",
      "Deep Learning",
      "Analysing Community Data",
      "Exploring Past Vegetation Using Fossil Pollen",
      "Biases in Ecological and Paleoecological Data",
      "Version Control",
      "Project Management and Collaboration using GitHub",
      "Phylogenetic Data in Ecology",
      "Phylogenies in Community Ecology",
      "Ecology of Speciation, Extinction and Macroevolution",
      "Model Based Ordinations",
      "Reproducible Analytical Pipelines"
    ),
    repository = c(
      "SSoQE-Welcome_and_Ice_Breaker",
      "SSoQE-Species_Distribution_Modelling",
      "SSoQE-Our_Way_of_R_and_Reproducibility",
      "SSoQE-Hypothesis_Testing_and_Null_Models",
      "SSoQE-Biodiversity_and_Richness",
      "SSoQE-Sample_Standardisation_and_Resampling",
      "SSoQE-Functional_Programming_in_the_World_of_AI",
      "SSoQE-Deep_Learning",
      "SSoQE-Analysing_Community_Data",
      "SSoQE-Exploring_Past_Vegetation_Using_Fossil_Pollen",
      "SSoQE-Biases_in_Ecological_and_Paleoecological_Data",
      "SSoQE-Version_Control",
      "SSoQE-Project_Management_and_Collaboration_using_GitHub",
      "SSoQE-Phylogenetic_Data_in_Ecology",
      "SSoQE-Phylogenies_in_Community_Ecology",
      "SSoQE-Ecology_of_Speciation_Extinction_and_Macroevolution",
      "SSoQE-Model_Based_Ordinations",
      "SSoQE-Reproducible_Analytical_Pipelines"
    ),
    release_token = release_token,
    stringsAsFactors = FALSE
  )
}

ssoqe_archive_is_safe <- function(entries) {
  entries <- gsub("\\\\", "/", entries)
  parts <- strsplit(entries, "/", fixed = TRUE)
  is_relative <- !grepl("^/|^[A-Za-z]:", entries)
  no_parent <- !vapply(parts, function(path) ".." %in% path, logical(1))
  all(is_relative & no_parent)
}

ssoqe_release_records <- function(metadata) {
  if (!length(metadata)) {
    return(data.frame())
  }
  records <- lapply(
    metadata,
    function(release) {
      data.frame(
        id = if (is.null(release$id)) NA_real_ else release$id,
        tag_name = if (is.null(release$tag_name)) {
          NA_character_
        } else {
          release$tag_name
        },
        draft = if (is.null(release$draft)) NA else release$draft,
        prerelease = if (is.null(release$prerelease)) {
          NA
        } else {
          release$prerelease
        },
        published_at = if (is.null(release$published_at)) {
          NA_character_
        } else {
          release$published_at
        },
        zipball_url = if (is.null(release$zipball_url)) {
          NA_character_
        } else {
          release$zipball_url
        },
        stringsAsFactors = FALSE
      )
    }
  )
  do.call(rbind, records)
}

ssoqe_release_page <- function(repository, page, year) {
  endpoint <- paste0("/repos/SSoQE/", repository, "/releases")
  metadata <- gh::gh(
    endpoint,
    per_page = 100,
    page = page,
    .progress = FALSE,
    .send_headers = c(
      `X-GitHub-Api-Version` = "2022-11-28",
      `User-Agent` = paste0("SSoQE-", year, "-preflight")
    )
  )
  ssoqe_release_records(metadata)
}

ssoqe_repository_releases <- function(repository, year) {
  releases <- list()
  page <- 1L
  repeat {
    current <- ssoqe_release_page(repository, page, year)
    if (!nrow(current)) {
      break
    }
    releases[[length(releases) + 1L]] <- current
    if (nrow(current) < 100L) {
      break
    }
    page <- page + 1L
  }
  if (!length(releases)) {
    return(data.frame())
  }
  do.call(rbind, releases)
}

ssoqe_select_release <- function(releases, year = current_year()) {
  token <- ssoqe_release_token(year)
  if (!nrow(releases)) {
    return(NULL)
  }
  required <- c(
    "id", "tag_name", "draft", "prerelease", "published_at",
    "zipball_url"
  )
  if (!all(required %in% names(releases))) {
    stop("Release metadata is incomplete", call. = FALSE)
  }
  matches <- !is.na(releases$tag_name) &
    grepl(token, releases$tag_name, fixed = TRUE) &
    !is.na(releases$draft) &
    !releases$draft &
    !is.na(releases$prerelease) &
    !releases$prerelease
  candidates <- releases[matches, , drop = FALSE]
  if (!nrow(candidates)) {
    return(NULL)
  }
  published <- as.POSIXct(
    candidates$published_at,
    format = "%Y-%m-%dT%H:%M:%SZ",
    tz = "UTC"
  )
  complete <- !is.na(published) &
    !is.na(candidates$id) &
    !is.na(candidates$zipball_url) &
    nzchar(candidates$zipball_url)
  if (!all(complete)) {
    stop("Matching release metadata is incomplete", call. = FALSE)
  }
  selected <- order(
    published,
    candidates$id,
    decreasing = TRUE
  )[1L]
  list(
    tag = candidates$tag_name[[selected]],
    zipball_url = candidates$zipball_url[[selected]],
    published_at = candidates$published_at[[selected]]
  )
}

ssoqe_latest_year_release <- function(repository, year) {
  releases <- ssoqe_repository_releases(repository, year)
  ssoqe_select_release(releases, year)
}

ssoqe_download_archive <- function(url, destination, year) {
  invisible(gh::gh(
    url,
    .destfile = destination,
    .overwrite = TRUE,
    .progress = FALSE,
    .send_headers = c(
      `X-GitHub-Api-Version` = "2022-11-28",
      `User-Agent` = paste0("SSoQE-", year, "-preflight")
    )
  ))
}

ssoqe_active_release_file <- function(materials_dir) {
  file.path(materials_dir, "ssoqe-active-releases.csv")
}

ssoqe_empty_active_releases <- function() {
  data.frame(
    year = integer(),
    repository = character(),
    release_tag = character(),
    published_at = character(),
    folder = character(),
    stringsAsFactors = FALSE
  )
}

ssoqe_read_active_releases <- function(materials_dir) {
  registry_file <- ssoqe_active_release_file(materials_dir)
  if (!file.exists(registry_file)) {
    return(ssoqe_empty_active_releases())
  }
  registry <- utils::read.csv(
    registry_file,
    stringsAsFactors = FALSE,
    check.names = FALSE
  )
  required <- names(ssoqe_empty_active_releases())
  if (!all(required %in% names(registry))) {
    stop("Active-release registry is incomplete", call. = FALSE)
  }
  registry[, required, drop = FALSE]
}

ssoqe_activate_release <- function(
    materials_dir,
    repository,
    year,
    release,
    target) {
  registry <- ssoqe_read_active_releases(materials_dir)
  year <- ssoqe_validate_year(year)
  keep <- registry$year != year | registry$repository != repository
  registry <- registry[keep, , drop = FALSE]
  registry <- rbind(
    registry,
    data.frame(
      year = year,
      repository = repository,
      release_tag = release$tag,
      published_at = release$published_at,
      folder = basename(target),
      stringsAsFactors = FALSE
    )
  )
  registry <- registry[order(registry$year, registry$repository), ]
  rownames(registry) <- NULL
  utils::write.csv(
    registry,
    ssoqe_active_release_file(materials_dir),
    row.names = FALSE
  )
}

ssoqe_download_release <- function(repository, materials_dir, year) {
  component <- paste("download:", repository)
  tryCatch(
    {
      release <- ssoqe_latest_year_release(repository, year)
      if (is.null(release)) {
        return(ssoqe_result(
          component,
          "LESSON_NOT_AVAILABLE",
          "There is no lesson data to download yet."
        ))
      }
      safe_tag <- gsub("[^A-Za-z0-9._-]+", "-", release$tag)
      target <- file.path(
        materials_dir,
        paste(repository, safe_tag, sep = "-")
      )
      marker <- file.path(target, ".ssoqe-release")
      if (file.exists(marker)) {
        recorded_tag <- trimws(readLines(marker, warn = FALSE, n = 1L))
        if (identical(recorded_tag, release$tag)) {
          ssoqe_activate_release(
            materials_dir,
            repository,
            year,
            release,
            target
          )
          return(ssoqe_result(
            component,
            "SKIP",
            paste("Release", release$tag, "is already downloaded")
          ))
        }
      }
      if (file.exists(target) || dir.exists(target)) {
        return(ssoqe_result(
          component,
          "FAIL",
          paste("Target already exists and was not overwritten:", target)
        ))
      }

      archive <- tempfile(fileext = ".zip")
      extract_dir <- tempfile(tmpdir = materials_dir)
      on.exit(unlink(archive), add = TRUE)
      on.exit(unlink(extract_dir, recursive = TRUE), add = TRUE)
      dir.create(extract_dir)
      ssoqe_download_archive(
        release$zipball_url,
        archive,
        year
      )

      contents <- utils::unzip(archive, list = TRUE)
      if (!nrow(contents) || !ssoqe_archive_is_safe(contents$Name)) {
        stop("Release archive has unsafe or empty paths", call. = FALSE)
      }
      utils::unzip(archive, exdir = extract_dir)
      extracted <- list.files(
        extract_dir,
        all.files = TRUE,
        full.names = TRUE,
        no.. = TRUE
      )
      source <- if (length(extracted) == 1L && dir.exists(extracted)) {
        extracted
      } else {
        extract_dir
      }
      if (!file.rename(source, target)) {
        stop("Could not move the extracted release into place", call. = FALSE)
      }
      writeLines(release$tag, marker, useBytes = TRUE)
      ssoqe_activate_release(
        materials_dir,
        repository,
        year,
        release,
        target
      )
      ssoqe_result(
        component,
        "PASS",
        paste("Downloaded release", release$tag, "to", target)
      )
    },
    error = function(error) {
      ssoqe_result(component, "FAIL", conditionMessage(error))
    }
  )
}

#' Download the latest matching SSoQE lesson releases
#'
#' @param materials_dir Destination folder for all lesson releases.
#' @param dry_run List planned downloads without network or file changes.
#' @param year Four-digit SSoQE programme year used to match release tags.
#' @return Invisibly, a data frame with one row per lesson.
download_ssoqe_materials <- function(
    materials_dir,
    dry_run = FALSE,
    year = current_year()) {
  stopifnot(
    is.character(materials_dir),
    length(materials_dir) == 1L,
    is.logical(dry_run),
    length(dry_run) == 1L
  )
  year <- ssoqe_validate_year(year)
  manifest <- ssoqe_lesson_manifest(year)
  if (dry_run) {
    report <- lapply(manifest$repository, function(repository) {
      ssoqe_result(
        paste("download:", repository),
        "DRY-RUN",
        paste(
          "Would download the most recently published full release",
          "with a tag containing",
          ssoqe_release_token(year)
        )
      )
    })
    report <- do.call(rbind, report)
    rownames(report) <- NULL
    print(report, row.names = FALSE)
    return(invisible(report))
  }

  dir.create(materials_dir, recursive = TRUE, showWarnings = FALSE)
  materials_dir <- normalizePath(
    materials_dir,
    winslash = "/",
    mustWork = TRUE
  )
  if (!requireNamespace("gh", quietly = TRUE)) {
    try(utils::install.packages("gh"), silent = TRUE)
  }
  if (!requireNamespace("gh", quietly = TRUE)) {
    report <- ssoqe_result(
      "release metadata",
      "FAIL",
      "Package gh could not be installed from CRAN"
    )
    print(report, row.names = FALSE)
    return(invisible(report))
  }

  report <- lapply(
    manifest$repository,
    ssoqe_download_release,
    materials_dir = materials_dir,
    year = year
  )
  report <- do.call(rbind, report)
  rownames(report) <- NULL
  print(report, row.names = FALSE)
  invisible(report)
}

ssoqe_command <- function(command, args = character()) {
  executable <- Sys.which(command)
  if (!nzchar(executable)) {
    return(list(ok = FALSE, output = paste(command, "was not found")))
  }

  output <- tryCatch(
    system2(executable, args, stdout = TRUE, stderr = TRUE),
    error = function(error) {
      structure(
        conditionMessage(error),
        class = c("ssoqe_command_error", "character")
      )
    }
  )
  status <- attr(output, "status")
  ok <- !inherits(output, "ssoqe_command_error") &&
    (is.null(status) || identical(status, 0L))
  list(ok = ok, output = paste(output, collapse = " "))
}

ssoqe_software_checks <- function() {
  results <- list()
  r_version <- getRversion()
  r_ok <- r_version >= "4.5.0" && r_version < "4.6.0"
  results[[1]] <- ssoqe_result(
    "R 4.5.x",
    if (r_ok) "PASS" else "WARN",
    paste("Detected", r_version)
  )

  rstudio <- Sys.getenv("RSTUDIO") == "1"
  results[[2]] <- ssoqe_result(
    "RStudio",
    if (rstudio) "PASS" else "WARN",
    if (rstudio) "Detected" else "Not detected in this R session"
  )

  for (tool in c("quarto", "git")) {
    checked <- ssoqe_command(tool, "--version")
    results[[length(results) + 1L]] <- ssoqe_result(
      tool,
      if (checked$ok) "PASS" else "FAIL",
      checked$output
    )
  }

  if (.Platform$OS.type == "windows") {
    make_path <- unname(Sys.which("make"))
    r_minor <- strsplit(R.version$minor, "[.]", fixed = FALSE)[[1]][1]
    expected_rtools <- paste0("rtools", R.version$major, r_minor)
    has_tools <- nzchar(make_path)
    matching_tools <- has_tools && grepl(
      tolower(expected_rtools),
      tolower(make_path),
      fixed = TRUE
    )
    results[[length(results) + 1L]] <- ssoqe_result(
      paste("Rtools for R", paste0(R.version$major, ".", r_minor)),
      if (matching_tools) "PASS" else "FAIL",
      if (matching_tools) {
        paste("Matching build tools detected at", make_path)
      } else if (has_tools) {
        paste("Build tools do not appear to match:", make_path)
      } else {
        "Matching Windows build tools were not detected"
      }
    )
  }

  for (key in c("user.name", "user.email")) {
    checked <- ssoqe_command("git", c("config", "--global", key))
    present <- checked$ok && nzchar(trimws(checked$output))
    results[[length(results) + 1L]] <- ssoqe_result(
      paste("Git", key),
      if (present) "PASS" else "FAIL",
      if (present) checked$output else "Global value is missing"
    )
  }

  python <- ssoqe_find_python()
  results[[length(results) + 1L]] <- ssoqe_result(
    "Python",
    if (python$ok) "PASS" else "FAIL",
    python$detail
  )
  torch <- ssoqe_check_torch(python)
  results[[length(results) + 1L]] <- ssoqe_result(
    "Python PyTorch",
    if (torch$ok) "PASS" else "FAIL",
    torch$detail
  )

  do.call(rbind, results)
}

ssoqe_find_python <- function() {
  candidates <- list(
    list(command = "python", prefix = character()),
    list(command = "python3", prefix = character()),
    list(command = "py", prefix = "-3")
  )
  unsupported <- NULL
  for (candidate in candidates) {
    checked <- ssoqe_command(
      candidate$command,
      c(candidate$prefix, "--version")
    )
    if (checked$ok) {
      version_text <- regmatches(
        checked$output,
        regexpr("[0-9]+[.][0-9]+([.][0-9]+)?", checked$output)
      )
      version <- tryCatch(
        numeric_version(version_text),
        error = function(error) numeric_version("0")
      )
      supported <- version >= "3.10" && version < "3.15"
      result <- list(
        ok = supported,
        found = TRUE,
        command = candidate$command,
        prefix = candidate$prefix,
        detail = paste(
          checked$output,
          if (supported) "(supported)" else "(requires Python 3.10-3.14)"
        )
      )
      if (supported) {
        return(result)
      }
      unsupported <- result
    }
  }
  if (!is.null(unsupported)) {
    return(unsupported)
  }
  list(ok = FALSE, found = FALSE, detail = "Python was not found")
}

ssoqe_check_torch <- function(python) {
  if (!python$ok) {
    return(list(
      ok = FALSE,
      detail = "Skipped because supported Python 3.10-3.14 was not found"
    ))
  }
  checked <- ssoqe_command(
    python$command,
    c(
      python$prefix,
      "-c",
      shQuote("import torch; print(torch.__version__)")
    )
  )
  list(ok = checked$ok, detail = checked$output)
}

ssoqe_install_packages <- function(dry_run) {
  manifest <- ssoqe_package_manifest()
  installed <- rownames(utils::installed.packages())
  missing <- manifest$package[!manifest$package %in% installed]

  if (!length(missing)) {
    return(ssoqe_result(
      "Global R packages",
      "SKIP",
      "All audited packages are already installed"
    ))
  }
  if (dry_run) {
    return(ssoqe_result(
      "Global R packages",
      "DRY-RUN",
      paste("Would install from CRAN:", paste(missing, collapse = ", "))
    ))
  }

  tryCatch(
    {
      utils::install.packages(missing)
      still_missing <- missing[
        !missing %in% rownames(utils::installed.packages())
      ]
      if (length(still_missing)) {
        ssoqe_result(
          "Global R packages",
          "FAIL",
          paste("Not installed:", paste(still_missing, collapse = ", "))
        )
      } else {
        ssoqe_result(
          "Global R packages",
          "PASS",
          paste("Installed", length(missing), "packages from CRAN")
        )
      }
    },
    error = function(error) {
      ssoqe_result("Global R packages", "FAIL", conditionMessage(error))
    }
  )
}

ssoqe_github_auth_check <- function() {
  if (!requireNamespace("gh", quietly = TRUE)) {
    return(ssoqe_result(
      "GitHub authentication for R",
      "WARN",
      "Package gh is not installed yet; rerun after package preparation"
    ))
  }
  tryCatch(
    {
      identity <- gh::gh_whoami()
      login <- if (is.list(identity) && !is.null(identity$login)) {
        identity$login
      } else {
        NA_character_
      }
      if (!length(login) || is.na(login) || !nzchar(login)) {
        return(ssoqe_result(
          "GitHub authentication for R",
          "FAIL",
          paste(
            "No GitHub credential is available to R.",
            "Use browser-managed credentials or the usethis PAT workflow."
          )
        ))
      }
      ssoqe_result(
        "GitHub authentication for R",
        "PASS",
        paste("Authenticated as", login)
      )
    },
    error = function(error) {
      ssoqe_result(
        "GitHub authentication for R",
        "FAIL",
        paste(
          conditionMessage(error),
          "Use browser-managed credentials or the usethis PAT workflow."
        )
      )
    }
  )
}

ssoqe_path_is_within <- function(path, parent) {
  identical(path, parent) || startsWith(path, paste0(parent, "/"))
}

ssoqe_projects <- function(
    materials_dir,
    year = current_year()) {
  year <- ssoqe_validate_year(year)
  lockfiles <- list.files(
    materials_dir,
    pattern = "^renv[.]lock$",
    recursive = TRUE,
    full.names = TRUE,
    include.dirs = FALSE
  )
  lockfiles <- lockfiles[!grepl("[/\\]renv[/\\]", lockfiles)]
  projects <- sort(unique(dirname(lockfiles)))
  if (!length(projects)) {
    return(projects)
  }
  projects <- normalizePath(
    projects,
    winslash = "/",
    mustWork = TRUE
  )
  registry_file <- ssoqe_active_release_file(materials_dir)
  if (!file.exists(registry_file)) {
    return(projects)
  }

  registry <- ssoqe_read_active_releases(materials_dir)
  registry <- registry[registry$year == year, , drop = FALSE]
  active_roots <- file.path(materials_dir, registry$folder)
  active_roots <- active_roots[dir.exists(active_roots)]
  active_roots <- normalizePath(
    active_roots,
    winslash = "/",
    mustWork = TRUE
  )
  marker_files <- list.files(
    materials_dir,
    pattern = "^[.]ssoqe-release$",
    recursive = TRUE,
    full.names = TRUE,
    all.files = TRUE,
    include.dirs = FALSE
  )
  automatic_roots <- normalizePath(
    dirname(marker_files),
    winslash = "/",
    mustWork = TRUE
  )
  is_automatic <- vapply(
    projects,
    function(project) {
      any(vapply(
        automatic_roots,
        function(root) ssoqe_path_is_within(project, root),
        logical(1)
      ))
    },
    logical(1)
  )
  is_active <- vapply(
    projects,
    function(project) {
      any(vapply(
        active_roots,
        function(root) ssoqe_path_is_within(project, root),
        logical(1)
      ))
    },
    logical(1)
  )
  projects[!is_automatic | is_active]
}

ssoqe_project_synchronized <- function(project) {
  if (!requireNamespace("renv", quietly = TRUE)) {
    return(FALSE)
  }
  tryCatch(
    isTRUE(renv::status(project = project, quiet = TRUE)$synchronized),
    error = function(error) FALSE
  )
}

ssoqe_run_restore <- function(project) {
  restore_script <- tempfile(fileext = ".R")
  on.exit(unlink(restore_script), add = TRUE)
  code <- c(
    sprintf("project <- %s", deparse(project)),
    "if (!requireNamespace('renv', quietly = TRUE)) {",
    "  install.packages('renv')",
    "}",
    "renv::restore(project = project, prompt = FALSE)",
    "status <- renv::status(project = project, quiet = TRUE)",
    "if (!isTRUE(status$synchronized)) quit(status = 2L)"
  )
  writeLines(code, restore_script, useBytes = TRUE)
  executable <- file.path(R.home("bin"), "Rscript")
  output <- tryCatch(
    system2(
      executable,
      c("--vanilla", shQuote(restore_script)),
      stdout = TRUE,
      stderr = TRUE
    ),
    error = conditionMessage
  )
  status <- attr(output, "status")
  ok <- !is.function(output) && (is.null(status) || identical(status, 0L))
  list(ok = ok, output = output)
}

ssoqe_restore_project <- function(project, dry_run) {
  label <- paste("renv:", basename(project))
  lockfile <- file.path(project, "renv.lock")
  hash_before <- unname(tools::md5sum(lockfile))

  if (ssoqe_project_synchronized(project)) {
    return(ssoqe_result(label, "SKIP", "Project is already synchronized"))
  }
  if (dry_run) {
    return(ssoqe_result(
      label,
      "DRY-RUN",
      "Would restore the project library in an isolated R process"
    ))
  }

  restored <- ssoqe_run_restore(project)
  hash_after <- unname(tools::md5sum(lockfile))

  if (!identical(hash_before, hash_after)) {
    return(ssoqe_result(
      label,
      "FAIL",
      "The restoration changed renv.lock; inspect the project immediately"
    ))
  }
  if (!restored$ok) {
    detail <- paste(tail(restored$output, 4L), collapse = " ")
    return(ssoqe_result(label, "FAIL", detail))
  }
  ssoqe_result(label, "PASS", "Project library restored; lockfile unchanged")
}

#' Prepare a computer for SSoQE 2026
#'
#' @param materials_dir Folder containing downloaded SSoQE repositories.
#' @param dry_run Report planned actions without installing or restoring.
#' @param restore_projects Restore projects that contain an renv.lock file.
#' @param year Four-digit SSoQE programme year to prepare.
#' @return Invisibly, a data frame with one row per checked component.
prepare_ssoqe <- function(
    materials_dir,
    dry_run = FALSE,
    restore_projects = TRUE,
    year = current_year()) {
  stopifnot(
    is.character(materials_dir),
    length(materials_dir) == 1L,
    is.logical(dry_run),
    length(dry_run) == 1L,
    is.logical(restore_projects),
    length(restore_projects) == 1L
  )
  year <- ssoqe_validate_year(year)
  materials_dir <- normalizePath(
    materials_dir,
    winslash = "/",
    mustWork = TRUE
  )
  if (!dir.exists(materials_dir)) {
    stop("materials_dir must be an existing directory", call. = FALSE)
  }

  report <- list(ssoqe_software_checks())
  report[[length(report) + 1L]] <- ssoqe_install_packages(dry_run)
  report[[length(report) + 1L]] <- ssoqe_github_auth_check()
  projects <- ssoqe_projects(materials_dir, year)

  if (!restore_projects) {
    report[[length(report) + 1L]] <- ssoqe_result(
      "renv projects",
      "SKIP",
      "Project restoration disabled"
    )
  } else if (!length(projects)) {
    report[[length(report) + 1L]] <- ssoqe_result(
      "renv projects",
      "WARN",
      "No downloaded project containing renv.lock was found"
    )
  } else {
    for (project in projects) {
      report[[length(report) + 1L]] <- ssoqe_restore_project(
        project,
        dry_run
      )
    }
  }

  report <- do.call(rbind, report)
  rownames(report) <- NULL
  print(report, row.names = FALSE)
  invisible(report)
}
