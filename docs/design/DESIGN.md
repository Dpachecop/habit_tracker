---
name: Serene Habit
colors:
  surface: '#f8f9ff'
  surface-dim: '#cbdbf5'
  surface-bright: '#f8f9ff'
  surface-container-lowest: '#ffffff'
  surface-container-low: '#eff4ff'
  surface-container: '#e5eeff'
  surface-container-high: '#dce9ff'
  surface-container-highest: '#d3e4fe'
  on-surface: '#0b1c30'
  on-surface-variant: '#3c4a42'
  inverse-surface: '#213145'
  inverse-on-surface: '#eaf1ff'
  outline: '#6c7a71'
  outline-variant: '#bbcabf'
  surface-tint: '#006c49'
  primary: '#006c49'
  on-primary: '#ffffff'
  primary-container: '#10b981'
  on-primary-container: '#00422b'
  inverse-primary: '#4edea3'
  secondary: '#006591'
  on-secondary: '#ffffff'
  secondary-container: '#39b8fd'
  on-secondary-container: '#004666'
  tertiary: '#855300'
  on-tertiary: '#ffffff'
  tertiary-container: '#e29100'
  on-tertiary-container: '#523200'
  error: '#ba1a1a'
  on-error: '#ffffff'
  error-container: '#ffdad6'
  on-error-container: '#93000a'
  primary-fixed: '#6ffbbe'
  primary-fixed-dim: '#4edea3'
  on-primary-fixed: '#002113'
  on-primary-fixed-variant: '#005236'
  secondary-fixed: '#c9e6ff'
  secondary-fixed-dim: '#89ceff'
  on-secondary-fixed: '#001e2f'
  on-secondary-fixed-variant: '#004c6e'
  tertiary-fixed: '#ffddb8'
  tertiary-fixed-dim: '#ffb95f'
  on-tertiary-fixed: '#2a1700'
  on-tertiary-fixed-variant: '#653e00'
  background: '#f8f9ff'
  on-background: '#0b1c30'
  surface-variant: '#d3e4fe'
typography:
  display:
    fontFamily: Inter
    fontSize: 32px
    fontWeight: '700'
    lineHeight: 40px
    letterSpacing: -0.02em
  headline-lg:
    fontFamily: Inter
    fontSize: 24px
    fontWeight: '600'
    lineHeight: 32px
    letterSpacing: -0.01em
  headline-md:
    fontFamily: Inter
    fontSize: 20px
    fontWeight: '600'
    lineHeight: 28px
  body-lg:
    fontFamily: Inter
    fontSize: 16px
    fontWeight: '400'
    lineHeight: 24px
  body-md:
    fontFamily: Inter
    fontSize: 14px
    fontWeight: '400'
    lineHeight: 20px
  label-caps:
    fontFamily: Inter
    fontSize: 12px
    fontWeight: '600'
    lineHeight: 16px
    letterSpacing: 0.05em
  headline-lg-mobile:
    fontFamily: Inter
    fontSize: 22px
    fontWeight: '600'
    lineHeight: 28px
rounded:
  sm: 0.25rem
  DEFAULT: 0.5rem
  md: 0.75rem
  lg: 1rem
  xl: 1.5rem
  full: 9999px
spacing:
  base: 4px
  xs: 4px
  sm: 8px
  md: 16px
  lg: 24px
  xl: 32px
  margin-mobile: 20px
  gutter-mobile: 12px
---

## Brand & Style

The brand personality is calm, encouraging, and focused. The design system prioritizes a **Minimalist** aesthetic to reduce cognitive load, helping users focus on their daily intentions without visual distraction. 

The emotional response should be one of "digital zen"—a sense of organized clarity. The interface utilizes generous whitespace, subtle depth, and a high-contrast interaction model to ensure that while the environment is peaceful, the actions are unmistakable.

## Colors

The palette is built on a foundation of "Soft Neutrals" to create a breathable canvas. 

- **Background & Surface:** Use `#F8FAFC` for the main application background and pure `#FFFFFF` for cards and elevated surfaces to create a subtle distinction.
- **Accents (Category-Driven):**
    - **Health (Mint Green):** `#10B981` — Used for wellness and physical activity.
    - **Focus (Sky Blue):** `#0EA5E9` — Used for deep work, study, or meditation.
    - **Creativity (Warm Orange):** `#F59E0B` — Used for hobbies and artistic habits.
- **Functional:** Use `#64748B` (Slate) for secondary text and icons to maintain a professional, grounded feel.

## Typography

This design system uses **Inter** exclusively to leverage its systematic, utilitarian nature. 

- **Headlines:** Use tight letter-spacing on larger sizes to create a modern, "tucked" look.
- **Body:** Maintain standard tracking for maximum legibility.
- **Labels:** Use the `label-caps` style for section headers and category tags to differentiate them from actionable body text.
- **Hierarchy:** Contrast is achieved through weight (Bold vs. Regular) rather than excessive size shifts to keep the UI compact.

## Layout & Spacing

The layout follows a **fluid grid** model optimized for mobile devices. 

- **Rhythm:** A 4px base unit governs all spacing.
- **Margins:** Standardize on a 20px side margin for mobile screens to provide a "frame" for the content.
- **Safe Areas:** Ensure interactive elements are at least 48px from the bottom edge of the device.
- **Groupings:** Use 16px (`md`) for spacing between related cards and 32px (`xl`) for major section breaks.

## Elevation & Depth

Visual hierarchy is established using **Ambient Shadows** and **Tonal Layers**. 

- **Level 0 (Background):** `#F8FAFC` flat.
- **Level 1 (Cards):** White surface with a very soft, diffused shadow.
    - *Shadow Specs:* `0px 4px 20px rgba(0, 0, 0, 0.04)`.
- **Level 2 (Active/Floating):** Use a slightly more pronounced shadow for floating action buttons (FABs).
    - *Shadow Specs:* `0px 8px 24px rgba(0, 0, 0, 0.08)`.
- **Interactive States:** When a user presses a card, it should visually "sink" by removing the shadow and scaling slightly (0.98x), providing a tactile feel.

## Shapes

The shape language is defined by significant **Roundedness** to appear friendly and non-intimidating.

- **Standard Cards:** Use `rounded-lg` (16px) as the default.
- **Large Containers:** Use `rounded-xl` (24px) for bottom sheets or primary habit dashboards.
- **Selection States:** Checkboxes and progress indicators should use `rounded-lg` to match the card language, rather than sharp circles, to maintain a consistent geometric theme.

## Components

- **Habit Cards:** High-contrast white containers. The left border or a small glyph should carry the category accent color (Mint, Blue, or Orange).
- **Buttons:** 
    - *Primary:* Solid accent color with white text. 
    - *Secondary:* Ghost style with a 1px border in the accent color.
- **Progress Rings:** Use a stroke width of 4px. The background path should be a faint version of the accent color (10% opacity) with the active path in full saturation.
- **Checkboxes:** Larger than standard (24x24px) with a `rounded-lg` corner radius. When checked, the box should fill with the habit's category color.
- **Input Fields:** Minimalist design with only a bottom border that highlights in the primary color on focus, or a subtle filled light-gray background (`#F1F5F9`).
- **Chips/Tags:** Used for frequency (e.g., "Daily", "Weekly"). These use `rounded-xl` for a pill-shape and a low-saturation background of the category color.