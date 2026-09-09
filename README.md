<div align="center">

<img src="https://ssoqe.github.io/SSoQE_website/photos/SSOQE_logo3.png" width="200" alt="SSoQE logo">

# SSoQE website

**Public website for the Science School on Quantitative Ecology**

[Visit the website](https://ssoqe.github.io/SSoQE_website/) · [View the programme](https://ssoqe.github.io/SSoQE_website/About/program.html)


| **🏫 Repository information** | **🧰 Technical** | **📌 Status** |
|:---:|:---:|:---:|
| ![SSoQE](https://img.shields.io/badge/SSoQE-2026-155560) | ![Type](https://img.shields.io/badge/Type-Quarto_Website-155560) | ![Status](https://img.shields.io/badge/Status-Active-509A8E) |
| ![Scope](https://img.shields.io/badge/Scope-Public_Information-C2A337) | ![Topic](https://img.shields.io/badge/Topic-School_Website-155560) | ![Tools](https://img.shields.io/badge/Tools-Quarto_%7C_SCSS-276DC3) |

</div>

This repository contains the Quarto sources for the SSoQE website. The website provides the authoritative public information about the school, including the current programme, application information, participant preparation, travel and accommodation, the teaching team, and reports from previous years.

## 📅 SSoQE 2026

SSoQE 2026 takes place from 14 to 19 September 2026 in Wallenfels, Germany. The programme in `About/program.qmd` is the source for the published timetable.

## ✍️ Authoring

- Edit `.qmd`, `_quarto.yml`, `styles.scss`, and source assets.
- Keep each Markdown paragraph on one physical source line; the 80-character convention applies only to R code.
- Keep links to internal pages relative and provide alternative text for meaningful images.
- Edit shared visual tokens in the source SCSS and preserve the original SSoQE logo.
- Do not hand-edit files under `docs/`; they are rendered publication output.

## 🛠️ Preview and render

From the repository root, preview the website with:

```powershell
quarto preview
```

Render the publication output with:

```powershell
quarto render
```

The Quarto project writes the rendered website to `docs/`. Review the render log and inspect navigation, links, images, accessibility, and responsive layout before publishing any change.

## 📦 Annual lesson release contract

The participant downloader derives the current year from the computer's system date and selects the most recently published full release whose case-sensitive tag contains that annual token. For 2026, the token is `ssoqe-2026`; valid examples include `ssoqe-2026-v1` and `course-ssoqe-2026-final`. The release title and suffix do not control selection. An explicit `year` argument can select a different year when needed.

Release metadata and archives are retrieved through `{gh}`. It uses the participant's R-accessible GitHub credential for private repositories and works anonymously for public repositories. A private lesson therefore requires both repository access and a successful `gh::gh_whoami()` check.

Teachers should:

1. Prepare and check the lesson on the commit intended for participants.
2. Create a draft GitHub Release with a lowercase tag containing the annual token.
3. Publish it as a full release, not a prerelease, when it is ready for participants.

A later matching release becomes active because it has a newer publication date. Previously downloaded folders remain intact, while `ssoqe-active-releases.csv` tells the preparation script which copy to use. If no matching release exists, the downloader reports `LESSON_NOT_AVAILABLE` with the participant-facing message "There is no lesson data to download yet." Technical errors retain the `FAIL` status. The `current_year()` helper automatically changes the selection token with the calendar year; only the year-specific website text and programme configuration need their normal annual update.

## 🤝 Contributing

Check the repository status and read the local agent instructions before editing. Local edits, staging, commits, pushes, and pull-request actions are separate authorization steps.
