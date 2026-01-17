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

### Deploy to TrueNAS SCALE
1. Build site: `hugo`
2. Copy `public/` contents to web server directory
3. Or use Cloudflare Tunnel (as configured)

### Cloudflare Tunnel Setup
- Ensure tunnel is configured to point to your site
- Update `baseURL` in `hugo.toml` to match your domain

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
├── themes/           # Installed themes
│   └── papermod/     # Current theme
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

**Last Updated**: 2026-01-17
