# Figma Design Spec — Illustration-Based Portfolio Template

**Source:** https://www.figma.com/design/UQlrtg4q9YquZjERvazPTK/Illustration-Based-Portfolio-Website-Template--Community-?node-id=412-655
**File key:** `UQlrtg4q9YquZjERvazPTK`  •  **Frame inspected:** `412:655` (Mockup) → `412:846` (Landing, 590×2036, full design at 916×4096)
**Cached renders:** `design/figma/landing_full.jpg` (full page), `boy_responsive.jpg`, `girl_responsive.jpg` (side decorative crops)

> **Important note for implementer.** This community file is a *cover preview*, not the editable source. All section content is baked into a single JPG (`landing_full.jpg`). Only four design tokens are exposed as Figma variables (listed below); everything else has been read visually off the rendered preview and should be treated as a faithful approximation, not a pixel-exact spec. Re-measure against `landing_full.jpg` (916×4096) when implementing.

---

## 1. Design tokens

### 1.1 Variables exposed by the Figma file
| Token | Value |
|---|---|
| `Primary/White` | `#FFFFFF` |
| `Heading H5/Semibold` | Sora, SemiBold 600, 20px, line 24, letter-spacing **-2** |
| `Button Text/SemiBold` | Sora, SemiBold 600, 20px, line 24, letter-spacing **+2** |
| `Paragraph P2/Semibold` | Sora, SemiBold 600, 16px, line 24, letter-spacing **+2** |

> Note the unusual letter-spacing convention (-2 / +2 in Figma units — implement as roughly `-0.02em` / `+0.02em` in CSS, or `letter-spacing: -2px` / `2px` and trust the visual).

### 1.2 Color palette (read from rendered design)
| Role | Value | Where used |
|---|---|---|
| `--bg-light` | `#FFFFFF` | Page background (default), light sections (Hero, Skills, About, Testimonial, Contact) |
| `--bg-dark` | `#0E0E0E` (near-black) | Dark sections (Experience, Projects) and primary buttons |
| `--text-primary` | `#0E0E0E` | Headings + body text on light bg |
| `--text-on-dark` | `#FFFFFF` | Text on dark bg |
| `--text-muted` | `#7A7A7A` (mid-gray) | Lorem-ipsum body paragraphs, dates, sub-labels |
| `--border-card` | `#E5E5E5` | Card outlines, form input borders (light, hairline) |
| `--border-card-dark` | `#1F1F1F` | Card outlines on dark sections |
| `--accent-highlight` | `#FFD84D` (warm yellow) | Hand-drawn squiggle under emphasised words ("**Developer**", "**Skills**", "**Me**", "**Experience**", "**Projects**", "**Testimonial**", "**talk**") |
| `--shadow-card` | `0 20px 40px 0 rgba(17, 12, 46, 0.15)` | Confirmed exact value from the Landing frame's `boxShadow` |

> The yellow accent is the only chromatic colour in the whole design — everything else is monochrome. Treat it as the brand highlight.

### 1.3 Typography scale
Font family: **Sora** (Google Font), with `system-ui` fallback. The four sizes below are inferred — confirm against the JPG.

| Token | Sora weight / size | Use |
|---|---|---|
| `--font-display` | 700 · ~56px / line ~64 / tracking -1 | Hero H1 ("Hello I'am Evren Shah …") |
| `--font-h2` | 700 · ~40px / line ~48 / tracking -1 | Section headings ("My **Skills**", "About **Me**", "Let's **talk** for Something special") |
| `--font-h3` | 600 · ~24px / line ~32 | Card titles (project names, experience roles) |
| `--font-h5` | 600 · 20px / line 24 / tracking -2 | Variable-defined — small card titles, skill labels |
| `--font-body` | 400 · 14–15px / line ~22 | Paragraphs (lorem ipsum, about-me prose) |
| `--font-meta` | 500 · 12–13px | Dates, sub-labels, footer copyright |
| `--font-button` | 600 · 16–20px / tracking +2 / UPPERCASE optional | CTA buttons |

The display heading uses **mixed weight**: the proper nouns ("**Evren Shah**", "**Developer**", "**India**") are bold while the connecting words are regular. The bolded word also gets the yellow squiggle underline.

### 1.4 Spacing scale
A loose 8-pt scale is being used. Sample values measured off the preview:

| Token | Value | Where |
|---|---|---|
| `--space-xs` | 8px | Icon ↔ label gap inside skill card |
| `--space-sm` | 12px | Tag padding |
| `--space-md` | 16px | Card internal padding |
| `--space-lg` | 24px | Grid gaps |
| `--space-xl` | 40px | Section padding (top/bottom on dense sections) |
| `--space-2xl` | 80–96px | Outer section padding (between major sections) |
| `--container-max` | 1200px | Page content max-width |
| `--container-pad` | 24–32px | Left/right gutters |

### 1.5 Border-radius
| Token | Value |
|---|---|
| `--radius-sm` | 6px (form inputs, small icons) |
| `--radius-md` | 10–12px (skill cards, experience cards, project image frames, testimonial cards) |
| `--radius-pill` | 999px (only used on the round avatar) |
| Resume button | rectangular with ~6–8px radius |

### 1.6 Shadows
| Token | Value |
|---|---|
| `--shadow-card` | `0 20px 40px 0 rgba(17,12,46,0.15)` (from the Landing frame token — applies to all elevated white cards) |
| `--shadow-card-dark` | None or very subtle — dark cards rely on a thin `1px solid #1F1F1F` border instead |

---

## 2. Components

Format per component: **purpose · structure · variants/states**.

### 2.1 Top navigation
- Sticky top bar, white background, full-width with content centered to the `--container-max`.
- Left: small leaf/seedling icon + wordmark "Personal" (Sora SemiBold, 16–18px).
- Center: nav links — **About Me · Skills · Project · Contact Me**. Body weight, 14–16px, ~24–32px gap.
- Right: **Resume** CTA — black filled button, white text, small download glyph after the label. ~`8px 16px` padding, radius 6–8px.
- Variants: link `default` (text-primary), link `hover` (likely underline or yellow squiggle), CTA `default` and `hover` (probably lifts shadow or inverts).

### 2.2 Resume / Primary button (CTA)
- Filled `--bg-dark` background, white label, optional trailing/leading icon, radius ~6px, padding `12px 20px`, font `--font-button`.
- Used as: "Resume ↓" in nav, "Get In Touch" in the contact form.
- Variants needed: default, hover (slight elevation), disabled.

### 2.3 Social icon button
- Square, ~44×44px, white background, `1px solid #0E0E0E` border, radius ~6px, glyph centered.
- Used in: hero (under social paragraph), contact section above the email.
- Glyphs visible: GitHub, Twitter/X, LinkedIn, Instagram (4 in hero; 4 in contact area).

### 2.4 Skill card
- White bg, `1px solid var(--border-card)`, radius `--radius-md`, padding ~`20px 16px`, shadow `--shadow-card`.
- Layout: large monochrome glyph centered (~32–40px), small label below (`--font-h5`).
- Active variant: same dimensions, **black fill (`--bg-dark`)**, white glyph and label — used as the "currently hovered/selected" treatment.
- Grid: 5 columns × 2 rows (10 cards visible in the preview). Items shown: Git, Javascript (active), Sass/Scss, NextJs, Storybook, NextJs, Git, Storybook, SocketIo, Sass/Scss.

### 2.5 Experience card (dark section)
- Background `#161616` (slightly lifted from the section `#0E0E0E`), `1px solid #1F1F1F`, radius `--radius-md`, padding ~`20px 24px`.
- Layout: brand glyph on far left (~32px), then a two-line title block — **role** in white SemiBold, **company** as a continuation (e.g. "Lead Software Engineer at Google"), date range right-aligned in muted gray.
- Description paragraph below, full width, muted gray.
- Three cards in the preview, stacked with ~16–20px gap.

### 2.6 About card
- One large white card spanning the section width, `1px solid var(--border-card)`, radius `--radius-md`, shadow `--shadow-card`.
- Two-column inside: left = monochrome illustration (boy with arms crossed) on a white bg with subtle border; right = 3-paragraph self-introduction in body type, muted.

### 2.7 Project card
- Used three times with **alternating layout**: image-left/text-right, then text-left/image-right, then image-left/text-right.
- Image side: device-mockup illustration on a transparent / dark bg (project screenshots), radius `--radius-md`.
- Text side: large outlined numeral ("01" / "02" / "03") in muted gray; title in white H3; body paragraph in muted; small external-link square icon at the bottom (~32px, bordered).

### 2.8 Testimonial card
- Three cards in a row with ~16–20px gap.
- Each: avatar (round, ~48px) centered at top, quote paragraph below (3 short lines, centered text), name SemiBold + role muted at the bottom.
- Active variant (middle card in preview): dark fill `--bg-dark`, white text. Default variant: white bg, `1px solid --border-card`, shadow `--shadow-card`.

### 2.9 Form input
- Full-width, ~52px tall, white background, `1px solid var(--border-card)`, radius `--radius-sm`, placeholder in `--text-muted`, label-as-placeholder pattern (no separate label).
- Order: Your name → Email → Your website (if exists) → How can I help? (textarea, ~3× height).
- Submit button below is the Primary CTA ("Get In Touch ↗").

### 2.10 Section heading
- Centered, `--font-h2`, mixed weight: first word ("My", "Let's") in regular, second word in **bold** with a hand-drawn yellow squiggle underline applied behind/below it.
- Pattern repeats: "My **Skills**", "My **Experience**", "About **Me**", "My **Projects**", "My **Testimonial**", "Let's **talk** for Something special".
- Implementation tip: put the squiggle as an inline SVG/background-image behind a `<span>` wrapping the emphasised word; do not bake it into the font.

### 2.11 Footer
- Light bg, thin `1px solid --border-card` top border.
- Left: seedling icon + "Personal" wordmark.
- Right: "© 2019–2023 Personal" + "Made In Figma" pill/text, slight gap.

---

## 3. Section-by-section layout (top → bottom)

Container width ~1200px, gutters ~32px on desktop. Each section has ~96px vertical padding unless noted.

| # | Section | Bg | Layout | Notes |
|---|---|---|---|---|
| 1 | **Sticky nav** | white | flex row, space-between | sticky, 64–72px tall |
| 2 | **Hero** | white | 2-col grid (~55/45 split) | left = headline + paragraph + 4 social buttons; right = boy-with-laptop illustration |
| 3 | **Skills** | white | centered title + 5×2 grid | grid gap ~16–20px, equal-height tiles |
| 4 | **Experience** | dark | centered title + 1-col stack | 3 cards, dark inset cards on darker section |
| 5 | **About Me** | white | 2-col (~45/55 split) | left = illustration card; right = prose |
| 6 | **Projects** | dark | centered title + alternating 2-col rows | 3 projects, image side alternates left/right |
| 7 | **Testimonial** | white | centered title + 3-col card row | middle card is the dark-active variant |
| 8 | **Contact** | white | 2-col (~50/50) | left = form; right = blurb + email + phone + social row |
| 9 | **Footer** | white | flex row, space-between | wordmark + copyright |

### 3.1 Responsive behaviour (inferred — not in source)
The community file does not include a mobile breakpoint frame. A reasonable adaptation:

- **≥1024px:** as documented above (2-col hero/about/contact, 5-col skills, 3-col testimonials).
- **768–1023px:** hero/about/contact collapse to single column (illustration on top); skills 3-col; testimonials 2-col or 1-col.
- **<768px:** everything stacks to single column; nav collapses behind a hamburger; project image/text alternation drops to image-on-top + text-below for all three.

---

## 4. Decorative / illustration system

- All people-art is **black-and-white line illustration** (no flat fills) with strong outlines. Two characters are present: boy-with-laptop (hero) and boy-with-arms-crossed (about). Both are inside a thin-bordered white "frame" card.
- The yellow squiggle / hand-drawn underline is the only color accent in the entire site — used sparingly under bold words inside H2/H1 only.
- Background ellipses: the Mockup cover has decorative pink/purple gradient circles (see `Frame 17` siblings in metadata), but those belong to the cover composition, not the portfolio page itself. Do **not** carry them over.

---

## 5. Assets to source before implementation

| Asset | Purpose | Notes |
|---|---|---|
| Sora font | Display + body | Google Fonts, weights 400/500/600/700 |
| Two B&W character illustrations | Hero + About | Need to either source openly-licensed equivalents (unDraw, Open Doodles, Storyset) or commission custom ones — the originals are baked into the JPG and not extractable as SVG from this file |
| Yellow squiggle underline SVG | Section heading accent | Create as a small inline SVG (~3–4 wave peaks), stroke `#FFD84D`, ~8–10px tall |
| Skill / tool glyphs | Skill cards | Use Simple Icons or Devicon (Git, JavaScript, Sass, Next.js, Storybook, Socket.io, etc.) — recolour to monochrome to match the design |
| Project mockup images | Projects section | Replace with the implementer's own project screenshots |
| Social icons | Hero + Contact | Phosphor or Lucide (GitHub, LinkedIn, Twitter/X, Instagram) |

---

## 6. Suggested implementation checklist (for the future session)

1. Add the spec's CSS variables to `assets/style.css` (or replace existing dark theme).
2. Pull in Sora from Google Fonts.
3. Create reusable component CSS classes: `.btn-primary`, `.icon-btn`, `.card`, `.card--dark`, `.skill-tile`, `.experience-card`, `.project-row`, `.testimonial-card`, `.form-input`, `.section-heading`.
4. Build the squiggle as a small reusable `<span class="hl">word</span>` with an inline SVG background.
5. Re-content the template with the user's data: profile from `Resume_Iman_Abadi.pdf`, projects from `PROJECTS/`, experience/testimonials → may be repurposed or removed if not applicable, contact info from resume.
6. Re-test responsively at 1280 / 1024 / 768 / 375.
7. Keep the dark-section + light-section alternation — it's a key part of the design rhythm.
