# ninefold.github.io

Homepage for **Ninefold** — a Kolkata-based web & software studio.

## Editing the site's content

All text content lives in **`site-config.js`** — never edit the HTML
directly for copy changes.

### Recommended way (no code editing)

1. Open **`settings.html`** in a browser.
2. Edit the fields (it generates the form automatically from the config).
3. **Save changes** → instant preview in *that* browser.
4. **Download config file** → replace `site-config.js` with the
   downloaded file and push, to publish for all visitors.

> The site is static, so it can't write files itself. "Save changes"
> keeps edits in the browser (localStorage, key `nf-config`); to
> publish for everyone, download the updated `site-config.js` and
> re-upload it.

### Quick file reference

| File | Purpose |
| --- | --- |
| `index.html` | Homepage layout, styles, config renderer |
| `site-config.js` | **All editable text** on the homepage |
| `site.js` | Shared theme + config-loading helpers |
| `settings.html` | Visual content editor |
| `*.demo.html` | Sample client builds |
| `favicon.*`, `apple-touch-icon.png` | Site icon set |

## Theme

Light/dark follows the OS preference; the toggle (sun/moon icon) lets
visitors override it per browser (localStorage key `nf-theme`).