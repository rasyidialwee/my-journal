# Hugo Blog Controls & Reference Guide

This guide covers all the essential controls and commands you need to manage your Hugo blog.

## Table of Contents
- [Basic Commands](#basic-commands)
- [Content Management](#content-management)
- [Front Matter Controls](#front-matter-controls)
- [Configuration](#configuration)
- [Theme Controls](#theme-controls)
- [Development Workflow](#development-workflow)
- [Deployment](#deployment)
- [Production VPS (Docker)](#production-vps-docker)

---

## Basic Commands

### Start Development Server
```bash
hugo server
```
- Starts local server at `http://localhost:1313`
- Auto-reloads on file changes
- Use `-D` flag to include draft posts: `hugo server -D`

### Build Static Site
```bash
hugo
```
- Generates static site in `public/` directory
- Use `-D` to include drafts: `hugo -D`

### Build with Drafts
```bash
hugo -D
```

### Clean Generated Files
```bash
hugo --cleanDestinationDir
```

### Check Configuration
```bash
hugo config
```

---

## Content Management

### Create New Post
```bash
hugo new posts/your-post-name.md
```

### Content File Structure
```
content/
  └── posts/
      └── your-post.md
```

### Content Organization
- **Posts**: `content/posts/`
- **Pages**: `content/` (root level)
- **Sections**: Create subdirectories in `content/`

---

## Front Matter Controls

Front matter is the YAML/TOML metadata at the top of each content file (between `---` markers).

### Essential Fields

#### `title`
```yaml
title: "Your Post Title"
```
- Display title of the post

#### `date`
```yaml
date: 2026-01-17T11:30:00+08:00
```
- Publication date (ISO 8601 format)
- Controls chronological ordering
- Format: `YYYY-MM-DDTHH:MM:SS+TZ`

#### `draft`
```yaml
draft: false
```
- `true`: Post is hidden (not published)
- `false`: Post is published
- Drafts excluded from build unless using `-D` flag

#### `weight`
```yaml
weight: 1
```
- Controls manual ordering in lists
- **Lower numbers appear first**
- Posts with same weight are sorted by date
- Use sequential numbers: 1, 2, 3, etc.

### Additional Useful Fields

#### `description`
```yaml
description: "Short description for SEO and previews"
```

#### `tags`
```yaml
tags:
  - web-development
  - javascript
  - tutorial
```

#### `categories`
```yaml
categories:
  - Programming
  - Web Development
```

#### `author`
```yaml
author: "Your Name"
```

#### `featured`
```yaml
featured: true
```
- Mark post as featured (theme-dependent)

#### `cover`
```yaml
cover:
  image: "/images/cover.jpg"
  alt: "Cover image description"
```

#### `toc`
```yaml
toc: true
```
- Enable table of contents

#### `math`
```yaml
math: true
```
- Enable math rendering

### Complete Front Matter Example
```yaml
---
title: "My Awesome Post"
date: 2026-01-17T11:30:00+08:00
draft: false
weight: 1
description: "A comprehensive guide to Hugo"
tags:
  - hugo
  - static-site
categories:
  - Tutorials
author: "Your Name"
featured: true
toc: true
---
```

---

## Configuration

### Main Config File: `hugo.toml`

#### Basic Settings
```toml
baseURL = "http://192.168.0.101:8085"  # Your site URL
languageCode = "en-us"                  # Language code
title = "Your Blog Title"               # Site title
theme = "papermod"                      # Active theme
```

#### Common Configuration Options

**Pagination**
```toml
paginate = 10  # Posts per page
```

**Taxonomies**
```toml
[taxonomies]
  tag = "tags"
  category = "categories"
```

**Menu**
```toml
[[menu.main]]
  identifier = "about"
  name = "About"
  url = "/about/"
  weight = 10
```

**Params (Theme-Specific)**
```toml
[params]
  # PaperMod theme example
  env = "production"
  title = "Your Site Title"
  description = "Site description"
  keywords = ["blog", "hugo"]
  author = "Your Name"
  
  # Social links
  [[params.socialIcons]]
    name = "github"
    url = "https://github.com/username"
```

**Markup**
```toml
[markup]
  [markup.highlight]
    style = "github"
    lineNos = true
```

---

## Theme Controls

### Current Theme: PaperMod

#### Theme-Specific Params
Check `themes/papermod/README.md` for theme-specific controls.

#### Override Theme Templates
Create matching structure in `layouts/`:
```
layouts/
  └── _default/
      └── single.html  # Overrides theme template
```

#### Custom CSS
Add to `assets/css/custom.css` or use `static/css/custom.css`

---

## Development Workflow

### 1. Create New Post
```bash
hugo new posts/my-new-post.md
```

### 2. Edit Post
- Open file in `content/posts/`
- Edit front matter and content
- Save file

### 3. Preview Locally
```bash
hugo server -D
```
- View at `http://localhost:1313`
- Changes auto-reload

### 4. Test Build
```bash
hugo -D
```
- Check `public/` directory for generated files

### 5. Publish
- Set `draft: false` in front matter
- Build: `hugo`
- Deploy `public/` directory

---

## Deployment

### Build for Production
```bash
hugo --minify
```
- Minifies HTML, CSS, and JS

### Cloudflare Tunnel Setup
- Ensure tunnel is configured to point to your site
- Update `baseURL` in `hugo.toml` to match your domain

---

## Production VPS (Docker)

The site ships with a multi-stage **Docker** build (Hugo Extended + nginx) and **Docker Compose**. Pushes to `main` can deploy via **GitHub Actions** over SSH.

### One-time VPS setup

1. Install Docker and the Compose plugin on the server.
2. Clone this repository **with submodules** (PaperMod lives under `themes/papermod`):

   ```bash
   git clone --recurse-submodules https://github.com/<you>/<repo>.git /opt/my-journal
   ```

   If you already cloned without submodules:

   ```bash
   cd /opt/my-journal && git submodule update --init --recursive
   ```

3. Optional: copy [`deploy/.env.example`](deploy/.env.example) to `.env` at the **repository root** on the server to set `BLOG_HTTP_PORT` (defaults to `8080` mapped to nginx port 80 in the container).

4. Create a deployment user (recommended), add it to the `docker` group, and authorize the **public** half of an SSH key pair used only for deploys (`~/.ssh/authorized_keys`).

5. Run the stack:

   ```bash
   cd /opt/my-journal
   docker compose -f deploy/docker-compose.yml up -d --build
   ```

6. Put TLS and your domain in front of the published port (for example **Caddy** or **nginx** on the host reverse-proxying to `127.0.0.1:8080`).

### Cloudflare (subdomain)

If you use **Cloudflare DNS** for a subdomain (for example `blog.example.com` → this VPS):

1. Create an **A** (or **AAAA**) record: subdomain name → your VPS public IP. Enable the **proxied** (orange cloud) icon if you want Cloudflare’s CDN and TLS at the edge.
2. Point traffic to whatever listens on the server: typically **HTTPS on 443** on the host (Caddy/nginx) that reverse-proxies to `127.0.0.1:8080` where Compose publishes the blog. Avoid exposing plain HTTP :8080 publicly unless you know why you need it.
3. **SSL/TLS** (Cloudflare → SSL/TLS → Overview): use **Full** or **Full (strict)** when your origin serves HTTPS with a valid certificate. Use **Flexible** only if the origin is HTTP-only (weaker; not ideal long term).
4. Set `baseURL` in [`hugo.toml`](hugo.toml) to the **exact public URL** visitors use (including `https://` and the subdomain), then rebuild or redeploy so canonical URLs, RSS, and Open Graph stay correct.

If you prefer **Cloudflare Tunnel** instead of opening inbound HTTP(S) to the VPS, run `cloudflared` on the server and map the tunnel to `http://127.0.0.1:8080` (or your origin port); `baseURL` should still match the public hostname you attach in Cloudflare.

### GitHub Actions (push to deploy)

Workflow: [`.github/workflows/deploy.yml`](.github/workflows/deploy.yml).

On every push to `main`, it builds the Docker image to verify the site, then SSHs into the VPS and runs [`deploy/scripts/deploy.sh`](deploy/scripts/deploy.sh) (`git pull`, submodule update, `docker compose build` / `up -d`).

**Repository secrets** (Settings → Secrets and variables → Actions):

| Secret | Purpose |
|--------|---------|
| `SSH_HOST` | VPS hostname or IP |
| `SSH_USER` | SSH login user |
| `SSH_PRIVATE_KEY` | Private key (full PEM, including headers) |
| `DEPLOY_PATH` | Absolute path to the repo on the server (e.g. `/opt/my-journal`) |

Optional: add `port: ${{ secrets.SSH_PORT }}` under `with:` in the workflow if SSH is **not** on port 22, and create an `SSH_PORT` secret.

If deploy fails with host key warnings, add [host fingerprint verification](https://github.com/appleboy/ssh-action#host-fingerprint-verification) (`fingerprint` input) or pin `known_hosts` as appropriate for your threat model.

### Manual deploy on the VPS

Same steps as CI:

```bash
cd /opt/my-journal
bash deploy/scripts/deploy.sh
```

Ensure `deploy/scripts/deploy.sh` is executable (`chmod +x deploy/scripts/deploy.sh`).

### Optional: webhook instead of Actions

If you prefer **not** to store an SSH key in GitHub, you can run [adnanh/webhook](https://github.com/adnanh/webhook) on the VPS and trigger the same script from a GitHub **repository webhook**. Start from [`deploy/webhook/hooks.json.example`](deploy/webhook/hooks.json.example), replace paths and the secret, and restrict access to your webhook port at the firewall.

### Previously: TrueNAS SCALE

You can still build with `hugo --minify` and sync `public/` to any static host; the Docker layout above replaces the old TrueNAS custom-app workflow for day-to-day publishing.

---

## Common Tasks

### Change Post Order
Edit `weight` in front matter:
- Lower weight = appears first
- Example: weight 1 appears before weight 2

### Hide/Show Post
```yaml
draft: true   # Hidden
draft: false  # Visible
```

### Update Post Date
Change `date` field in front matter to republish or reorder

### Add Images
1. Place images in `static/images/`
2. Reference: `/images/filename.jpg`
3. Or use theme's image shortcodes

### Create Categories/Tags
Add to front matter:
```yaml
tags: ["tag1", "tag2"]
categories: ["Category1"]
```

---

## Troubleshooting

### Posts Not Showing
- Check `draft: false`
- Use `hugo server -D` to include drafts
- Verify file is in `content/posts/`

### Changes Not Reflecting
- Restart server: `Ctrl+C` then `hugo server`
- Clear cache: Delete `resources/_gen/`
- Check file syntax (YAML front matter)

### Build Errors
- Check YAML syntax (indentation, quotes)
- Verify theme is installed
- Check `hugo.toml` syntax

### Images Not Loading
- Use absolute paths: `/images/filename.jpg`
- Ensure images in `static/images/`
- Check file permissions

### Docker deploy / CI
- **`themes/papermod` missing in build**: Run `git submodule update --init --recursive` on the server and ensure clones use `--recurse-submodules`.
- **GitHub Actions SSH fails**: Confirm secrets, non-default SSH port (see Production section), and host key / fingerprint settings for `appleboy/ssh-action`.
- **Site returns 404 for posts**: Rebuild the image after pulls; confirm `baseURL` in `hugo.toml` matches your public URL.

---

## Quick Reference

| Task | Command |
|------|---------|
| Start server | `hugo server` |
| Start with drafts | `hugo server -D` |
| Build site | `hugo` |
| Build with drafts | `hugo -D` |
| Create post | `hugo new posts/name.md` |
| Minify build | `hugo --minify` |
| Check config | `hugo config` |

---

## File Structure Overview

```
hugo/
├── content/          # Your content files
│   └── posts/        # Blog posts
├── static/           # Static files (images, CSS, JS)
├── themes/           # Installed themes (git submodule)
│   └── papermod/     # PaperMod
├── deploy/           # Docker Compose, Dockerfile, deploy scripts
├── public/           # Generated site (gitignored)
├── resources/        # Generated resources (gitignored)
├── hugo.toml         # Main configuration
└── README.md         # This file
```

---

## Resources

- [Hugo Documentation](https://gohugo.io/documentation/)
- [PaperMod Theme](https://github.com/adityatelange/hugo-PaperMod)
- [Hugo Front Matter](https://gohugo.io/content-management/front-matter/)

---

**Last Updated**: 2026-05-04
