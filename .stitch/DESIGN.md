---
name: Student Life OS Design System
colors:
  canvas: '#0E1015'
  surface: '#12151D'
  surface-card: '#161922'
  surface-elevated: '#1E2330'
  card-border: '#232734'
  card-border-subtle: '#1C202B'
  text-primary: '#F8FAFC'
  text-secondary: '#94A3B8'
  text-muted: '#64748B'
  primary-emerald: '#10B981'
  primary-emerald-glow: 'rgba(16, 185, 129, 0.15)'
  academic-sky: '#38BDF8'
  academic-sky-glow: 'rgba(56, 189, 248, 0.15)'
  anti-habit-crimson: '#F43F5E'
  anti-habit-glow: 'rgba(244, 63, 94, 0.15)'
  warning-amber: '#F59E0B'
  accent-violet: '#6366F1'
  accent-purple: '#8B5CF6'
typography:
  display-title:
    fontFamily: Plus Jakarta Sans
    fontSize: 28px
    fontWeight: '800'
    lineHeight: 36px
    letterSpacing: -0.02em
  section-header:
    fontFamily: Plus Jakarta Sans
    fontSize: 18px
    fontWeight: '700'
    lineHeight: 24px
    letterSpacing: -0.01em
  card-title:
    fontFamily: Plus Jakarta Sans
    fontSize: 15px
    fontWeight: '600'
    lineHeight: 20px
  body-text:
    fontFamily: Inter
    fontSize: 13px
    fontWeight: '400'
    lineHeight: 18px
  data-label:
    fontFamily: Inter
    fontSize: 11px
    fontWeight: '600'
    lineHeight: 14px
    letterSpacing: 0.02em
  code-timestamp:
    fontFamily: JetBrains Mono, monospace
    fontSize: 12px
    fontWeight: '600'
    letterSpacing: 0.04em
rounded:
  sm: 4px
  md: 8px
  lg: 12px
  xl: 16px
  pill: 9999px
spacing:
  xs: 4px
  sm: 8px
  md: 12px
  lg: 16px
  xl: 24px
---

## 1. Aesthetic Identity

The **Student Life OS** visual identity bridges **Tactical Academic Discipline** with **Lush Botanical Pixel Art Calm**:
- **Header**: Panoramic pixel-art botanical terrarium aquarium banner representing tranquil, focused study environments.
- **Surfaces**: Obsidian neutral background (`#0E1015`) with structured slate containers (`#161922`), bounded by crisp 1px borders (`#232734`).
- **Information Density**: High-utility grid layout optimized for simultaneous oversight of courses, active timers, holistic life balance, urgent reminders, and academic schedules.

---

## 2. Core Modules & Component Architecture

### Analog Clock & Life Progress Rail
- Left rail features an analog clock face with hour/minute/second hands and a digital timestamp (`HH:mm:ss Day Month D`).
- Life progress indicators display Year (34%), Month (10%), and Week (78%) completion percentages with segmented progress fills.
- Quick-Action navigation buttons (`+ New Task`, `+ New Course`, `+ New Assignment`, `+ New Exam`, `+ New Note`, `+ New Resource`).
- Quarterly Goal Trackers with collapsible Q1-Q4 percentage metrics.

### Courses Row
- Horizontal course cards with banner image thumbnails, course title, course code badge, assignment completion bar (`Completed / Total`), and upcoming exam counters.
- Quick `+ New page` link to create or add courses.

### 4-Hub Visual Cards
- High-contrast visual thumbnail cards for **Assignments**, **Resources**, **Notes**, and **Exams**, each with a dedicated creation action.

### Wheel of Life Radar Chart
- Holistic balance polygon radar chart with 6 axes: Career, Health, Social, Physical Health, Money, Family.
- Outer pentagonal/hexagonal web rings with subtle grid strokes and vibrant polygon fill (`#F43F5E` / `#EF4444`).
- Subtitle: `✦ Powered by ChartBase`.

### Mini-To-Do's & Reminders
- Fast-capture checklist with tactile custom checkboxes.
- Event reminder cards with calendar pin badges and date tags.

### Pomodoro Focus Timer
- Dedicated focus card with mode tabs (`Pomodoro` 25:00, `Short Break` 05:00, `Long Break` 15:00).
- Large glowing digital countdown display.
- Action buttons: `Start` (pill button), `Reset` (circular icon), and `Settings` (circular icon).

### Task Manager Priority Board
- Multi-view filter: `This Week`, `Unrelated Task`, `Task's Priority Board`.
- Data table containing Task Name, Course tag chip, Priority badge (High, Medium, Low), Status pill (Not Started, In Progress, Done), Due date, and completion checkbox.

### TimeTable Matrix
- Weekly grid matrix (Monday to Friday, 8:00 to 15:30) with course blocks and room codes.

### Academic Calendar
- Weekly/Monthly view with dates, "Open in Calendar" button wired to device calendar sync, and status-tagged assignment chips.

---

## 3. Stitch Generation Notes (Section 6 - Required)

When generating screens for this system:
1. Canvas must be `#0E1015` dark background with `#161922` container cards and `#232734` borders.
2. The top banner must include a lush green botanical terrarium / aquarium pixel art illustration with "Student Life OS" and an "A+" badge squircle.
3. Typography must use clean modern sans-serif for titles and crisp monospace for clocks, metrics, and progress percentages.
4. Maintain explicit status pills: Emerald green (`#10B981`) for completed, Crimson red (`#F43F5E`) for high priority / exams, Sky blue (`#38BDF8`) for courses, and Amber gold (`#F59E0B`) for in-progress.
5. All cards must have rounded corners (12px to 16px) with 1px border outlines.
