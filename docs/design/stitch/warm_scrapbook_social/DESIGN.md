---
name: Warm Scrapbook Social
colors:
  surface: '#fdf9f2'
  surface-dim: '#dddad3'
  surface-bright: '#fdf9f2'
  surface-container-lowest: '#ffffff'
  surface-container-low: '#f7f3ec'
  surface-container: '#f1ede6'
  surface-container-high: '#ebe8e1'
  surface-container-highest: '#e6e2db'
  on-surface: '#1c1c18'
  on-surface-variant: '#58423c'
  inverse-surface: '#31302c'
  inverse-on-surface: '#f4f0e9'
  outline: '#8c716a'
  outline-variant: '#dfc0b8'
  surface-tint: '#a83819'
  primary: '#a53616'
  on-primary: '#ffffff'
  primary-container: '#c64d2c'
  on-primary-container: '#fffbff'
  inverse-primary: '#ffb5a1'
  secondary: '#845400'
  on-secondary: '#ffffff'
  secondary-container: '#ffb142'
  on-secondary-container: '#6f4600'
  tertiary: '#48624e'
  on-tertiary: '#ffffff'
  tertiary-container: '#607b65'
  on-tertiary-container: '#f6fff4'
  error: '#ba1a1a'
  on-error: '#ffffff'
  error-container: '#ffdad6'
  on-error-container: '#93000a'
  primary-fixed: '#ffdbd1'
  primary-fixed-dim: '#ffb5a1'
  on-primary-fixed: '#3c0800'
  on-primary-fixed-variant: '#872002'
  secondary-fixed: '#ffddb6'
  secondary-fixed-dim: '#ffb95b'
  on-secondary-fixed: '#2a1800'
  on-secondary-fixed-variant: '#643f00'
  tertiary-fixed: '#cdead0'
  tertiary-fixed-dim: '#b1ceb5'
  on-tertiary-fixed: '#072010'
  on-tertiary-fixed-variant: '#334c39'
  background: '#fdf9f2'
  on-background: '#1c1c18'
  surface-variant: '#e6e2db'
typography:
  display-lg:
    fontFamily: Epilogue
    fontSize: 36px
    fontWeight: '700'
    lineHeight: 44px
    letterSpacing: -0.03em
  display-lg-mobile:
    fontFamily: Epilogue
    fontSize: 30px
    fontWeight: '700'
    lineHeight: 38px
    letterSpacing: -0.02em
  headline-lg:
    fontFamily: Epilogue
    fontSize: 26px
    fontWeight: '700'
    lineHeight: 34px
    letterSpacing: -0.02em
  headline-md:
    fontFamily: Epilogue
    fontSize: 22px
    fontWeight: '600'
    lineHeight: 30px
    letterSpacing: -0.01em
  headline-sm:
    fontFamily: Epilogue
    fontSize: 18px
    fontWeight: '600'
    lineHeight: 26px
  title-md:
    fontFamily: Plus Jakarta Sans
    fontSize: 16px
    fontWeight: '600'
    lineHeight: 24px
  body-lg:
    fontFamily: Plus Jakarta Sans
    fontSize: 16px
    fontWeight: '400'
    lineHeight: 24px
  body-md:
    fontFamily: Plus Jakarta Sans
    fontSize: 14px
    fontWeight: '400'
    lineHeight: 22px
  body-sm:
    fontFamily: Plus Jakarta Sans
    fontSize: 13px
    fontWeight: '400'
    lineHeight: 18px
  label-lg:
    fontFamily: Plus Jakarta Sans
    fontSize: 14px
    fontWeight: '600'
    lineHeight: 20px
    letterSpacing: 0.01em
  label-md:
    fontFamily: Plus Jakarta Sans
    fontSize: 12px
    fontWeight: '600'
    lineHeight: 16px
    letterSpacing: 0.02em
  label-sm:
    fontFamily: Plus Jakarta Sans
    fontSize: 11px
    fontWeight: '700'
    lineHeight: 14px
    letterSpacing: 0.04em
rounded:
  sm: 0.5rem
  DEFAULT: 1rem
  md: 1.5rem
  lg: 2rem
  xl: 3rem
  full: 9999px
spacing:
  gutter-xs: 0.25rem
  gutter-sm: 0.5rem
  gutter-md: 1rem
  gutter-lg: 1.5rem
  gutter-xl: 2rem
  margin-screen: 1.25rem
  margin-screen-tablet: 2rem
  card-padding: 1.25rem
  badge-padding-x: 0.75rem
  badge-padding-y: 0.375rem
---

## Brand & Style

This design system expresses a warm, welcoming, and sun-drenched social atmosphere centered on shared memories, spontaneous outings, and heartfelt friendships. It blends editorial intimacy with casual tactility—drawing from the nostalgic warmth of personal scrapbooks, analog journals, and afternoon golden hour gatherings, translated thoughtfully into a fluid modern mobile interface.

### Aesthetic Foundation
- **Tactile Paper & Warm Editorial:** Interfaces favor textured, comforting paper tones over sterile grays or stark whites. The visual language feels tangible, human, and grounded.
- **Vibrant Yet Natural:** Anchored in sunbaked terracotta, radiant amber, soft peach, and herbal sage, the aesthetic sparks joy, camaraderie, and nostalgia without becoming childish or chaotic.
- **Friendly Geometry:** Deep, organic pill counters, generous corner radii (`rounded-2xl` to `rounded-3xl`), and subtle stamp/pin-inspired affordances celebrate human connection.

## Colors

The color system delivers high accessibility compliance (WCAG AA/AAA) while preserving an organic, warm-toned paper texture across light mode surfaces.

### Core Palette
- **Primary (`#D85A38` - Sunlit Terracotta):** The hero brand color. Used for prominent calls to action, active navigation states, memory highlight pins, and emotional anchors. Pair with `#FFFFFF` or `#FFF9F5` for accessible contrast.
- **Secondary (`#E59B2C` - Golden Amber):** The warmth generator. Applied to activity badges, celebration moments, reactive micro-interactions, and status accents.
- **Tertiary (`#6C8771` - Muted Sage Green):** The grounding balance. Used for completed milestones, outdoor/nature activity tags, quiet confirmation markers, and balancing energetic reds.
- **Accent Soft Peach (`#F4AB8E` / `#FCEEE6`):** Supportive tint for chips, secondary memory cards, and subtle backdrops.
- **Neutral Paper Canvas (`#FBF7F0` - Warm Parchment):** The foundational screen surface. Replaces stark optical whites to minimize eye fatigue and impart diary warmth.
- **Neutral Deep Ink (`#2B231E` - Roasted Espresso):** Primary text and structural line work. Provides sharp, readable contrast against warm cream backgrounds without the harshness of pure black.
- **Neutral Surface Container (`#F3ECE1` - Pressed Paper):** Tonal surface for recessed sections, search inputs, and inactive cards.

## Typography

The typographic pairing balances spirited, handcrafted character with optimal readability on mobile screens.

- **Headlines (`Epilogue`):** Expressive, confident, and contemporary with humanistic geometric traits. It lends personality to activity headlines, milestone titles, and user memory captures without feeling juvenile.
- **Body & Controls (`Plus Jakarta Sans`):** Clean, rounded, highly legible humanist sans-serif. Ensures prolonged reading comfort for social feed commentary, descriptions, and metadata.
- **Rules of Use:** Never use condensed font weights. Set headlines with tight negative letter spacing (`-0.01em` to `-0.03em`) to mimic poster design, while maintaining neutral spacing in long-form text blocks.

## Layout & Spacing

A rhythmic, fluid layout system tailored for handheld ergonomics, thumb-reach navigation, and relaxed content discovery.

### Grid & Ergonomics
- **Base Grid:** 4pt base spatial grid (`4px`, `8px`, `12px`, `16px`, `24px`, `32px`).
- **Screen Margin:** Strict mobile horizontal margin of `1.25rem` (20px) ensuring touch targets remain well inside physical screen bezels. Scales to `2rem` (32px) on tablets.
- **Feed Composition:** Cards use asymmetric, loose vertical rhythms (`16px` to `24px` gaps) to simulate a physical journal/scrapbook flow rather than a rigid table or dashboard.
- **Touch Targets:** Interactive elements adhere to an absolute minimum dimension of `48px x 48px`.

## Elevation & Depth

Visual depth avoids cold, clinical drop shadows. Instead, it relies on warm ambient tinting and tonal layering to create an illusion of stacked papers, polaroids, and notebook slips.

### Layering Hierarchy
- **Level 0 (Canvas):** Pure `#FBF7F0` parchment.
- **Level 1 (Flat Cards & Sections):** `#FFFFFF` or `#F7EFE4` with soft `0 2px 8px -2px rgba(43, 35, 30, 0.04)` and a delicate `1px` border in `#EADDCF`.
- **Level 2 (Interactive Floating Cards / Active Pins):** Raised elements use warm-tinted ambient shadows: `0 8px 24px -6px rgba(216, 90, 56, 0.12), 0 4px 8px -2px rgba(43, 35, 30, 0.04)`.
- **Level 3 (Modals, Action Sheets, Floating Buttons):** Deep diffused warmth: `0 16px 36px -8px rgba(43, 35, 30, 0.14), 0 4px 12px -2px rgba(43, 35, 30, 0.06)`.

### Scrapbook Motifs
Subtle angle offsets (e.g., `-1deg` to `+1.5deg` rotations on memory previews or photo polaroids) accentuate physical charm without impacting touch hitboxes.

## Shapes

The shape system adopts a deeply tactile pill-and-pocket profile. By using maximum roundedness levels, screens communicate openness, warmth, and safe social spaces.

- **Cards & Sheets:** Default to `rounded-3xl` (24px on mobile) to produce soft, cushion-like surfaces.
- **Buttons, Pins & Chips:** Fully rounded pill silhouettes (`rounded-full` / 9999px).
- **Embedded Media:** Image frames utilize `rounded-2xl` (16px) with an inner soft 1px border stroke (`rgba(43, 35, 30, 0.05)`) to replicate physical printed photo borders.

## Components

### Buttons
- **Primary:** Terracotta background (`#D85A38`), crisp white text, fully pill-shaped (`rounded-full`), height `52px`. Pressed state shifts to darker terracotta (`#BF4A2B`) with a subtle inward scale transform (`scale-98`).
- **Secondary (Sun Warmth):** Soft cream background (`#F4E8DB`), dark espresso text (`#2B231E`), pill-shaped with `border: 1.5px solid #E5D5C2`.
- **Tertiary / Ghost:** No fill; text color `#D85A38` with active tactile tap tint.

### Memory & Activity Cards
- Built with `rounded-3xl`, high-purity white or soft parchment backings, and generous internal padding (`20px`).
- Features a faux-washi tape or pin badge in the top corner for group activity categories (e.g., "Trilha", "Café com Papo", "Noite de Jogos").
- Accommodates collaborative multi-avatar clusters overlapping with `border: 2px solid #FFFFFF`.

### Chips & Badges
- **Status / Category Chips:** Pill-shaped (`rounded-full`), padding `6px 14px`.
- Amber tint (`#FEF5E7` background, `#9A6300` text) for upcoming activities.
- Sage tint (`#EEF3EF` background, `#3D5943` text) for completed moments.
- Terracotta tint (`#FDF1ED` background, `#D85A38` text) for high-priority or RSVP actions.

### Input Fields
- Enclosed pill and squircle inputs with `#F3ECE1` filled background, 16px horizontal padding, and zero border in resting state.
- Focus state triggers a vibrant terracotta ring: `border: 1.5px solid #D85A38` with an ambient terracotta halo (`box-shadow: 0 0 0 3px rgba(216, 90, 56, 0.15)`).

### Lists & Activity Feeds
- Avoid sterile horizontal dividing rules. Use separated floating list items or dot-connected timeline threads mimicking a travel itinerary or shared journal log.

### Scrapbook Pins & Stickers (App Specific)
- Floating reactions and stickers feature high-contrast, playful micro-borders (`2px solid #FFFFFF`) with warm drop shadows, allowing users to "stamp" photos and memories collaboratively.