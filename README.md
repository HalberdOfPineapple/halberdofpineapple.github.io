# halberdofpineapple.github.io

Personal academic website of **Wenxuan Li** — https://halberdofpineapple.github.io

Built with [Jekyll](https://jekyllrb.com/) on the
[Academic Pages](https://github.com/academicpages/academicpages.github.io) template
(a fork of [Minimal Mistakes](https://mademistakes.com/work/minimal-mistakes-jekyll-theme/)),
hosted on GitHub Pages.

## Structure

| Path | Contents |
| --- | --- |
| `_pages/about.md` | Landing page (bio) |
| `_publications/` | One Markdown file per publication, rendered on `/publications/` |
| `_posts/` | Blog posts, rendered on `/year-archive/` |
| `_config.yml` | Site-wide settings, sidebar profile and links |
| `_data/navigation.yml` | Header menu |
| `images/profile.jpg` | Sidebar avatar |

## Local preview

```bash
./serve.sh
```

Installs bundler and the gems on first run (into `vendor/bundle`, no root needed),
then serves the site with livereload on http://localhost:4000. Over VSCode
Remote-SSH the port shows up in the **PORTS** panel; click the globe icon to open it.

Native gems need the Ruby headers, which the script checks for and tells you how
to install:

```bash
sudo apt install -y build-essential ruby-dev zlib1g-dev
```

Useful flags: `--port 4001` (livereload port moves with it), `--clean` (wipe
`_site/` first), `--build` (build once, no server). Any other flag is passed
through to `jekyll serve`.

**While the server runs**, just keep editing — saves to `_pages/`, `_publications/`,
`_posts/`, `_data/`, `_includes/`, `_layouts/`, `_sass/` and `images/` are picked up
automatically, including brand-new files, and the browser refreshes itself.
The exceptions are `_config.yml` and `Gemfile`, which the watcher deliberately
ignores: restart the server after changing those.

Alternatively, `docker compose up` uses the bundled `Dockerfile` /
`docker-compose.yaml`, and `.devcontainer/` supports "Reopen in Container".

## Adding a publication

Create `_publications/YYYY-MM-DD-short-name.md` with front matter containing
`title`, `collection: publications`, `category` (`conferences` or `preprints`,
defined in `_config.yml`), `permalink`, `authors`, `date`, `venue`, and `paperurl`.
`authors` accepts inline HTML, e.g. `<b>Wenxuan Li</b>*, Co Author`. Optional
`slidesurl` / `bibtexurl` add further links next to `Paper`.

## Adding a blog post

Create `_posts/YYYY-MM-DD-short-name.md` with `title`, `date`, and optional
`categories` / `tags` in the front matter.
