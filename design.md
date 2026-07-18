---
name: VitalPass Design System
colors:
  surface: '#faf8ff'
  surface-dim: '#d9d9e4'
  surface-bright: '#faf8ff'
  surface-container-lowest: '#ffffff'
  surface-container-low: '#f3f3fe'
  surface-container: '#ededf8'
  surface-container-high: '#e7e7f3'
  surface-container-highest: '#e2e1ed'
  on-surface: '#191b23'
  on-surface-variant: '#434654'
  inverse-surface: '#2e3039'
  inverse-on-surface: '#f0f0fb'
  outline: '#737686'
  outline-variant: '#c3c5d7'
  surface-tint: '#1353d8'
  primary: '#003fb1'
  on-primary: '#ffffff'
  primary-container: '#1a56db'
  on-primary-container: '#d4dcff'
  inverse-primary: '#b5c4ff'
  secondary: '#006a61'
  on-secondary: '#ffffff'
  secondary-container: '#86f2e4'
  on-secondary-container: '#006f66'
  tertiary: '#852b00'
  on-tertiary: '#ffffff'
  tertiary-container: '#ad3b00'
  on-tertiary-container: '#ffd4c5'
  error: '#ba1a1a'
  on-error: '#ffffff'
  error-container: '#ffdad6'
  on-error-container: '#93000a'
  primary-fixed: '#dbe1ff'
  primary-fixed-dim: '#b5c4ff'
  on-primary-fixed: '#00174d'
  on-primary-fixed-variant: '#003dab'
  secondary-fixed: '#89f5e7'
  secondary-fixed-dim: '#6bd8cb'
  on-secondary-fixed: '#00201d'
  on-secondary-fixed-variant: '#005049'
  tertiary-fixed: '#ffdbcf'
  tertiary-fixed-dim: '#ffb59a'
  on-tertiary-fixed: '#380d00'
  on-tertiary-fixed-variant: '#802a00'
  background: '#faf8ff'
  on-background: '#191b23'
  surface-variant: '#e2e1ed'
typography:
  display-lg:
    fontFamily: Inter
    fontSize: 48px
    fontWeight: '700'
    lineHeight: 56px
    letterSpacing: -0.02em
  headline-lg:
    fontFamily: Inter
    fontSize: 32px
    fontWeight: '700'
    lineHeight: 40px
  headline-lg-mobile:
    fontFamily: Inter
    fontSize: 28px
    fontWeight: '700'
    lineHeight: 36px
  headline-md:
    fontFamily: Inter
    fontSize: 24px
    fontWeight: '600'
    lineHeight: 32px
  body-lg:
    fontFamily: Inter
    fontSize: 18px
    fontWeight: '400'
    lineHeight: 28px
  body-md:
    fontFamily: Inter
    fontSize: 16px
    fontWeight: '400'
    lineHeight: 24px
  label-lg:
    fontFamily: Atkinson Hyperlegible Next
    fontSize: 16px
    fontWeight: '600'
    lineHeight: 20px
    letterSpacing: 0.01em
  label-md:
    fontFamily: Atkinson Hyperlegible Next
    fontSize: 14px
    fontWeight: '600'
    lineHeight: 18px
    letterSpacing: 0.02em
  caption:
    fontFamily: Inter
    fontSize: 12px
    fontWeight: '500'
    lineHeight: 16px
rounded:
  sm: 0.25rem
  DEFAULT: 0.5rem
  md: 0.75rem
  lg: 1rem
  xl: 1.5rem
  full: 9999px
spacing:
  base: 8px
  xs: 4px
  sm: 12px
  md: 20px
  lg: 32px
  xl: 48px
  container-max: 1200px
  gutter: 24px
  touch-target: 48px
---

## Brand & Style
The design system is anchored in the concepts of **Unwavering Trust, Clarity, and Vitality**. As a secure medical data wallet, the UI must bridge the gap between clinical professionalism and approachable personal care. The target audience includes a broad demographic spectrum, necessitating an extreme focus on accessibility for older users or those in high-stress medical situations.

The chosen style is **Corporate Modern with a Focus on High-Accessibility**. It leverages generous whitespace, a structured grid, and high-contrast elements to ensure that information is never obscured. Visual metaphors of security—such as encapsulated data cards and persistent status indicators—reinforce the "vault" nature of the application while maintaining a clean, medical aesthetic.

## Colors
This design system utilizes a palette engineered for high legibility and psychological reassurance. 

- **Primary (Medical Blue):** Used for primary actions, branding, and active navigation states. It establishes a sense of authority and stability.
- **Secondary (Teal):** Used for health-specific highlights and secondary functional elements.
- **Semantic Colors:** Green is strictly reserved for "Verified" or "Safe" states (e.g., a valid QR code), while Amber signifies "Pending" or "Temporary" access.
- **Neutral Scale:** We prioritize a Deep Slate (#111827) for all primary text to ensure contrast ratios exceed WCAG AAA standards where possible. Backgrounds remain pure white to maximize the "clean" medical feel.

## Typography
The typography strategy prioritizes **Inter** for its systematic clarity and high x-height, ensuring legibility on digital screens. For critical UI labels and data-heavy segments, we introduce **Atkinson Hyperlegible Next**, specifically designed to increase character recognition for users with low vision.

- **Scale:** Sizes are intentionally larger than standard web defaults. The base body size is set at 18px for primary content.
- **Hierarchy:** We use weight (SemiBold/Bold) rather than color alone to distinguish headers, ensuring that the information remains clear even in low-light environments (e.g., an emergency room).
- **Line Height:** Tight line heights are avoided. A minimum of 1.5x font size is maintained for body text to aid tracking.

## Layout & Spacing
The layout follows a **Fluid Grid** model with a strict 8px baseline rhythm. This ensures that every element—from icons to margins—scales predictably.

- **Touch Targets:** A minimum touch target of 48px is enforced for all interactive elements to accommodate users with limited motor dexterity.
- **Mobile-First:** On mobile devices, the layout uses a single-column stack with 20px side margins.
- **Grouping:** Related medical data points (e.g., Dosage + Frequency) are grouped using "md" (20px) spacing, while distinct sections (e.g., Allergies vs. Medications) are separated by "xl" (48px) spacing or structural dividers.

## Elevation & Depth
Elevation in this design system is used to indicate **Security and Containment**. We avoid floating elements; instead, we use depth to "lift" critical data cards from the surface.

- **Tonal Layers:** The background is #FFFFFF. Secondary surfaces (like search bars or background containers) use #F9FAFB.
- **Shadows:** We use high-diffusion, low-opacity shadows (Blur 15px, Opacity 4%, Color: Primary Blue) to give cards a subtle "pluck" from the page without creating visual clutter.
- **Security Cues:** Critical actions (like "Show QR Code") are housed in containers with a distinct 1px border (#E5E7EB) to reinforce the idea of a physical, secure document.

## Shapes
The shape language is **Soft and Structured**. We use a base corner radius of 8px (`rounded-md`) for buttons and small components, and 16px (`rounded-xl`) for main data cards.

- **Card Contours:** Larger radii on cards provide a friendly, modern feel that contrasts with the serious nature of medical data.
- **Icons:** Icons should be contained within circular or "squircle" backdrops when used as category identifiers (e.g., a heart icon for cardiology).
- **Standardization:** All input fields must match the button's roundedness (8px) to create a cohesive form-factor.

## Components
- **Buttons:** Primary buttons use a solid #1A56DB fill with white text. High-emphasis actions like "Emergency Access" use a high-contrast red outline. All buttons must have a height of 48px-56px.
- **Medical Cards:** These are the core of the UI. They feature a white background, a 1px border, and a 16px corner radius. The top right corner is reserved for a "Security Status" badge (e.g., "Encrypted" with a lock icon).
- **QR Vault:** A specialized component that blurs the QR code until an "Unlock" button is pressed, emphasizing privacy.
- **Chips:** Used for allergies (Red tint) or verified conditions (Teal tint). Chips use a pill-shape (32px radius) and semi-bold labels.
- **Input Fields:** Use a 2px border on focus in Primary Blue. Labels must always be visible (not floating) to ensure the user never loses context.
- **Category Lists:** Icons in lists should be color-coded (e.g., Medications = Blue, Allergies = Red) to allow for rapid visual scanning in emergencies.
