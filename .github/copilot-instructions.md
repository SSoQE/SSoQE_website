# Copilot instructions for this repository

## Project context
- This repository is the source for a Quarto website for the Science School on Quantitative Ecology.
- Main source files live at the repository root and in the About/ and Previous/ folders.
- The published site is generated into the docs/ folder; do not hand-edit generated HTML files there.

## Editing expectations
- Prefer small, targeted changes that preserve the existing structure and tone of the site.
- Keep the writing welcoming, academic, and concise. Content is mostly English with some German-facing references.
- Preserve Quarto frontmatter, YAML configuration, and existing page formatting unless a change clearly requires an update.
- Use relative paths and image references that match the current site structure, such as photos/... and About/....

## Navigation and site structure
- If you add, rename, or remove a page, update _quarto.yml so the navbar and page navigation remain correct.
- Keep the existing information architecture intact: About the Workshop, Meet the Team, and Previous runs.

## Content style
- Use clear Markdown and Quarto syntax.
- Preserve existing emoji usage and callout blocks where they are already used.
- When editing pages, keep section headings, titles, dates, and metadata consistent with nearby pages.
- Avoid unnecessary dependencies, large refactors, or unrelated changes.

## Verification
- If you change Quarto source files, render the site with Quarto when possible and confirm that the build succeeds.
- If rendering is not possible in the current environment, state that clearly instead of implying a successful build.
