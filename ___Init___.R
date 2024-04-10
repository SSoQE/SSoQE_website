if (
  require("usethis")
) {
  library(usethis)
} else {
  devtools::install_github("r-lib/usethis")
  library(usethis)
}

if (
  require("here")
) {
  library(here)
} else {
  devtools::install_github("r-lib/here")
  library(here)
}

usethis::create_project(
  here::here()
)

if (
  require("qtwAcademic")
) {
  library(qtwAcademic)
} else {
  devtools::install_github("andreaczhang/qtwAcademic")
  library(qtwAcademic)
}

qtwAcademic::make_qtw_template(
  path = here::here(),
  template_option = "Course"
)
