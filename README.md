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

## 🤝 Contributing

Check the repository status and read the local agent instructions before editing. Local edits, staging, commits, pushes, and pull-request actions are separate authorization steps.
