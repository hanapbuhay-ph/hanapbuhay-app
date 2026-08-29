---
name: Tarsi Verdant
colors:
  surface: '#f9f9f8'
  surface-dim: '#d9dad9'
  surface-bright: '#f9f9f8'
  surface-container-lowest: '#ffffff'
  surface-container-low: '#f3f4f3'
  surface-container: '#edeeed'
  surface-container-high: '#e7e8e7'
  surface-container-highest: '#e1e3e2'
  on-surface: '#191c1c'
  on-surface-variant: '#3f4a3b'
  inverse-surface: '#2e3131'
  inverse-on-surface: '#f0f1f0'
  outline: '#6e7b69'
  outline-variant: '#becab6'
  surface-tint: '#006e11'
  primary: '#006e11'
  on-primary: '#ffffff'
  primary-container: '#34a835'
  on-primary-container: '#003404'
  inverse-primary: '#6cdf64'
  secondary: '#2a6b2c'
  on-secondary: '#ffffff'
  secondary-container: '#acf4a4'
  on-secondary-container: '#307231'
  tertiary: '#835400'
  on-tertiary: '#ffffff'
  tertiary-container: '#ca8400'
  on-tertiary-container: '#3f2600'
  error: '#ba1a1a'
  on-error: '#ffffff'
  error-container: '#ffdad6'
  on-error-container: '#93000a'
  primary-fixed: '#88fc7d'
  primary-fixed-dim: '#6cdf64'
  on-primary-fixed: '#002202'
  on-primary-fixed-variant: '#00530a'
  secondary-fixed: '#acf4a4'
  secondary-fixed-dim: '#91d78a'
  on-secondary-fixed: '#002203'
  on-secondary-fixed-variant: '#0c5216'
  tertiary-fixed: '#ffddb5'
  tertiary-fixed-dim: '#ffb957'
  on-tertiary-fixed: '#2a1800'
  on-tertiary-fixed-variant: '#643f00'
  background: '#f9f9f8'
  on-background: '#191c1c'
  surface-variant: '#e1e3e2'
  leaf-bright: '#4CAF50'
  earth-brown: '#5D4037'
  surface-cream: '#FEFDFB'
  charcoal-soft: '#2D312E'
typography:
  display-lg:
    fontFamily: Plus Jakarta Sans
    fontSize: 48px
    fontWeight: '800'
    lineHeight: 56px
    letterSpacing: -0.02em
  headline-lg:
    fontFamily: Plus Jakarta Sans
    fontSize: 32px
    fontWeight: '700'
    lineHeight: 40px
  headline-lg-mobile:
    fontFamily: Plus Jakarta Sans
    fontSize: 28px
    fontWeight: '700'
    lineHeight: 36px
  headline-md:
    fontFamily: Plus Jakarta Sans
    fontSize: 24px
    fontWeight: '700'
    lineHeight: 32px
  body-xl:
    fontFamily: Plus Jakarta Sans
    fontSize: 20px
    fontWeight: '400'
    lineHeight: 30px
  body-lg:
    fontFamily: Plus Jakarta Sans
    fontSize: 18px
    fontWeight: '400'
    lineHeight: 28px
  body-md:
    fontFamily: Plus Jakarta Sans
    fontSize: 16px
    fontWeight: '400'
    lineHeight: 24px
  label-lg:
    fontFamily: Plus Jakarta Sans
    fontSize: 14px
    fontWeight: '600'
    lineHeight: 20px
    letterSpacing: 0.01em
  label-sm:
    fontFamily: Plus Jakarta Sans
    fontSize: 12px
    fontWeight: '600'
    lineHeight: 16px
    letterSpacing: 0.02em
rounded:
  sm: 0.25rem
  DEFAULT: 0.5rem
  md: 0.75rem
  lg: 1rem
  xl: 1.5rem
  full: 9999px
spacing:
  unit: 4px
  gutter: 24px
  margin-mobile: 16px
  margin-desktop: 48px
  container-max: 1280px
---

## Brand & Style

This design system evolves into a vibrant, community-focused platform for knowledge seekers. It sheds the generic dark-mode aesthetic for a "Digital Naturalist" style—one that is welcoming, friendly, and approachable. 

The aesthetic is **Modern-Tactile**, blending clean functional layouts with soft, organic shapes and a high-energy color palette inspired by the brand's character-driven identity. It aims to evoke a sense of discovery, reliability, and warmth.

- **Warmth & Community:** Deep greens and soft neutrals replace stark blacks.
- **Character-Driven:** The UI uses expressive typography and generous roundedness to feel less like a tool and more like a companion.
- **Clarity:** Despite the friendly tones, the system maintains a rigorous functional foundation for reading-intensive content.

## Colors

The palette is anchored by a **Vibrant Forest Green** (#34A835), pulled directly from the brand character’s attire and the magnifying glass. This primary color is used for key actions and brand moments.

- **Primary:** Vibrant Green for main CTAs and active states.
- **Secondary:** Deep Forest Green for navigation elements and secondary buttons, ensuring high contrast.
- **Tertiary:** Harvest Gold, used sparingly for accents, notifications, or "discovery" highlights.
- **Neutral:** A "Warm White" system. Surfaces use a cream-tinted base to reduce eye strain during long reading sessions, while text uses a soft charcoal rather than pure black.

## Typography

The typography system utilizes **Plus Jakarta Sans** for all levels to maintain a friendly, contemporary, and geometric feel. 

- **Headlines:** Use tighter letter-spacing and heavier weights (Bold/ExtraBold) to create a strong visual anchor.
- **Body:** Set with generous line-heights to optimize for the "knowledge seeker" audience, ensuring long-form articles are highly legible.
- **Labels:** Use Medium or SemiBold weights to differentiate interactive text from static content.

## Layout & Spacing

This design system employs a **Fluid Grid** model based on a 4px baseline shift. 

- **Desktop:** 12-column grid with a 1280px max-width. Gutters are fixed at 24px to ensure breathing room between content cards.
- **Tablet:** 8-column grid with 24px margins.
- **Mobile:** 4-column grid with 16px margins. 

The vertical rhythm follows a 4px scale (4, 8, 12, 16, 24, 32, 48, 64), encouraging whitespace to reduce cognitive load in information-dense environments.

## Elevation & Depth

To align with the friendly, character-driven style, depth is communicated through **Tonal Layers** and **Soft Ambient Shadows**.

- **Surfaces:** We use a "Level 0" cream background. Elevated components like cards use a pure white surface with a very soft, diffused green-tinted shadow (e.g., `rgba(52, 168, 53, 0.08)`).
- **Interactive Depth:** Buttons use a subtle 1px inner border to simulate a "pressed" or "tactile" look without full skeuomorphism. 
- **Backdrop:** For modals and overlays, a soft background blur (8px) is applied to maintain context while focusing the user's attention.

## Shapes

The shape language is **Rounded**, reflecting the soft features of the brand character and the circular magnifying glass. 

- **Default (8px):** Used for inputs and smaller UI components.
- **Large (16px):** Used for content cards and image containers.
- **Extra Large (24px):** Used for section containers and primary promotional banners.
- **Pill:** Reserved exclusively for tags, chips, and the primary "Search" bar to make them feel distinct and touch-friendly.

## Components

### Buttons
Primary buttons are vibrant green with white text. They must feature a subtle "lift" on hover (slight shadow increase) and a "press" effect (1px downward shift) to emphasize the tactile nature of the brand. Secondary buttons use a Deep Green outline.

### Cards
Cards are the primary vehicle for content. They must use the `rounded-lg` (16px) corner radius and a white background. Padding within cards should be generous (24px) to avoid a cramped "data-heavy" look.

### Input Fields
Inputs use a soft-gray border that transforms into a 2px Primary Green border on focus. Labels should always be visible (never placeholder-only) to maintain accessibility.

### Chips & Tags
Chips are pill-shaped. Use subtle tints of the Primary Green (10% opacity) for background colors with dark green text to signify categories or filters.

### Navigation
The navigation bar should be sticky with a slight "glass" effect (white at 90% opacity with blur) to keep the UI feeling light and airy as the user scrolls through content.