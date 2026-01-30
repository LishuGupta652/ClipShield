# Deploying the Docs

The docs site is static. Any static host works.

## GitHub Pages (Quickest)

1. Push this repo to GitHub
2. Go to **Settings -> Pages**
3. Set **Branch** to `main` and **Folder** to `/docs`
4. Save and wait for the site to build
5. (Optional) add a custom domain in `docs/CNAME`

## Netlify

1. Create a new site from your Git repo
2. Build command: _none_
3. Publish directory: `docs`

## Vercel

1. Import the repo
2. Framework preset: _Other_
3. Output directory: `docs`
