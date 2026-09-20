---
name: Clarity Anti-Habit & Academic Architecture
colors:
  surface: '#faf8ff'
  surface-dim: '#d2d9f4'
  surface-bright: '#faf8ff'
  surface-container-lowest: '#ffffff'
  surface-container-low: '#f2f3ff'
  surface-container: '#eaedff'
  surface-container-high: '#e2e7ff'
  surface-container-highest: '#dae2fd'
  on-surface: '#131b2e'
  on-surface-variant: '#3d4a42'
  inverse-surface: '#283044'
  inverse-on-surface: '#eef0ff'
  outline: '#6d7a72'
  outline-variant: '#bccac0'
  surface-tint: '#006c4a'
  primary: '#006948'
  on-primary: '#ffffff'
  primary-container: '#00855d'
  on-primary-container: '#f5fff7'
  inverse-primary: '#68dba9'
  secondary: '#ba0035'
  on-secondary: '#ffffff'
  secondary-container: '#e21e49'
  on-secondary-container: '#fffbff'
  tertiary: '#006194'
  on-tertiary: '#ffffff'
  tertiary-container: '#007bb9'
  on-tertiary-container: '#fdfcff'
  error: '#ba1a1a'
  on-error: '#ffffff'
  error-container: '#ffdad6'
  on-error-container: '#93000a'
  primary-fixed: '#85f8c4'
  primary-fixed-dim: '#68dba9'
  on-primary-fixed: '#002114'
  on-primary-fixed-variant: '#005137'
  secondary-fixed: '#ffdada'
  secondary-fixed-dim: '#ffb3b6'
  on-secondary-fixed: '#40000c'
  on-secondary-fixed-variant: '#920028'
  tertiary-fixed: '#cce5ff'
  tertiary-fixed-dim: '#93ccff'
  on-tertiary-fixed: '#001d31'
  on-tertiary-fixed-variant: '#004b73'
  background: '#faf8ff'
  on-background: '#131b2e'
  surface-variant: '#dae2fd'
typography:
  display-lg:
    fontFamily: Plus Jakarta Sans
    fontSize: 40px
    fontWeight: '800'
    lineHeight: 48px
    letterSpacing: -0.03em
  display-lg-mobile:
    fontFamily: Plus Jakarta Sans
    fontSize: 30px
    fontWeight: '800'
    lineHeight: 38px
    letterSpacing: -0.025em
  headline-lg:
    fontFamily: Plus Jakarta Sans
    fontSize: 28px
    fontWeight: '700'
    lineHeight: 36px
    letterSpacing: -0.02em
  headline-md:
    fontFamily: Plus Jakarta Sans
    fontSize: 22px
    fontWeight: '600'
    lineHeight: 30px
    letterSpacing: -0.015em
  headline-sm:
    fontFamily: Plus Jakarta Sans
    fontSize: 18px
    fontWeight: '600'
    lineHeight: 26px
    letterSpacing: -0.01em
  body-lg:
    fontFamily: Plus Jakarta Sans
    fontSize: 16px
    fontWeight: '500'
    lineHeight: 24px
    letterSpacing: -0.005em
  body-md:
    fontFamily: Plus Jakarta Sans
    fontSize: 14px
    fontWeight: '400'
    lineHeight: 20px
    letterSpacing: 0em
  body-sm:
    fontFamily: Plus Jakarta Sans
    fontSize: 12px
    fontWeight: '400'
    lineHeight: 16px
    letterSpacing: 0.01em
  label-lg:
    fontFamily: Plus Jakarta Sans
    fontSize: 14px
    fontWeight: '600'
    lineHeight: 18px
    letterSpacing: 0.02em
  label-md:
    fontFamily: Plus Jakarta Sans
    fontSize: 12px
    fontWeight: '600'
    lineHeight: 16px
    letterSpacing: 0.03em
  label-sm:
    fontFamily: Plus Jakarta Sans
    fontSize: 10px
    fontWeight: '700'
    lineHeight: 14px
    letterSpacing: 0.06em
rounded:
  sm: 0.25rem
  DEFAULT: 0.5rem
  md: 0.75rem
  lg: 1rem
  xl: 1.5rem
  full: 9999px
spacing:
  gutter: 1rem
  gutter-md: 1.5rem
  gutter-lg: 2rem
  margin: 1rem
  margin-md: 1.5rem
  margin-lg: 3rem
  space-xs: 0.25rem
  space-sm: 0.5rem
  space-md: 1rem
  space-lg: 1.5rem
  space-xl: 2rem
---

## Brand & Style

This design system establishes a high-clarity, high-agency productivity environment built explicitly around friction reduction, intentional omission, and academic discipline. The interface departs from gamified, noisy student trackers by employing a modern minimalist aesthetic with refined tactile structure: crisp off-white air, razor-sharp architectural surfaces, and definitive chromatic cues that partition productive routines from prohibited patterns ("not-to-dos").

The visual tone is assertive, calm, and intellectually focused. It blends Swiss typographic discipline with functional tactile surfaces, providing students with immediate visual differentiation between active commitments (timetables), virtuous progress (discipline streaks), and hard boundaries (anti-habits and time-sinks).

## Colors

The color palette is built on strict functional roles to eliminate cognitive ambiguity in high-stress academic contexts:

- **Canvas & Structural Surface:** The primary backdrop is set to `#F4F8F5` (Crisp Pale Mist) / `#FAF8FF`, providing a glare-free baseline that makes `#FFFFFF` container cards emerge with crisp dimension. Structural boundaries utilize `#E2ECE6` for soft, organic division that avoids harsh dark wireframing.
- **Primary — Focus & Discipline (`#006948` / `#059669` / `#10B981`):** Applied to active accomplishment, completed discipline metrics, positive counters, and affirming calls-to-action. Never used for destructive states.
- **Secondary — Prohibited / Anti-Habit ("Not-To-Do") (`#BA0035` / `#E11D48` / `#F43F5E`):** Distinct crimson-rose reserved exclusively for anti-goals, cognitive tripwires, break triggers, and negative triggers (e.g., social app limits, procrastination warnings).
- **Tertiary — Academic Timetable & Scheduling (`#006194` / `#0284C7` / `#38BDF8`):** Clear sky blue dedicated strictly to temporal events: lecture blocks, coursework milestones, academic calendar tags, and study intervals.
- **Neutrals (`#0F172A` / `#131B2E` / `#1E293B` / `#64748B` / `#908FA0`):** Deep slate and charcoal for uncompromising legibility against pale backgrounds. Body copy sits consistently at `#1E293B` / `#131B2E`, while section headers claim `#0F172A`.

### Dark Mode Counterparts:
- Canvas / Background: `#081C15` / `#0A0D14` / `#10131A`
- Surface Card: `#0E231B` / `#121826` / `#1D1F27`
- Card Border: `#1E3D32` / `#1F293D` / `#272A32`
- Text Primary: `#ECFDF5` / `#F8FAFC` / `#E1E2EC`
- Text Secondary: `#A7F3D0` / `#94A3B8` / `#C7C4D7`
- Text Muted: `#6EE7B7` / `#64748B` / `#908FA0`
- Primary Accent: `#4EDEA3` / `#10B981` / `#C0C1FF`
- Secondary (Anti-Habit): `#FB7185` / `#F43F5E`
- Tertiary (Academic Timetable): `#38BDF8` / `#7BD0FF`
