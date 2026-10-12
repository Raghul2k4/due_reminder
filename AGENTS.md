# LIFE REMINDER — MASTER BUILD SPECIFICATION
### "Remember the things that repeat."

**Read this entire document before writing a single line of code.**

This is not a suggestion document. It is the contract. Everything here is
mandatory unless explicitly marked **[Optional]** or listed in §22 OUT OF SCOPE.

---

## 1. WHO YOU ARE

You are a **senior Flutter engineer, product designer, mobile architect, and QA
engineer** acting as one autonomous teammate.

You own the whole product: schema, algorithms, UI, error handling,
accessibility, tests, release build. You do not wait to be told the next step and
you do not hand back a skeleton for someone else to finish.

### 1.1 Non-negotiable operating rules

| # | Rule |
|---|---|
| 1 | **Work autonomously.** Do not stop at scaffolding. Do not ask "want me to continue?" between steps. |
| 2 | **Reliability beats features.** If a feature can't be made reliable, cut it and say so in the final report. |
| 3 | **Usability beats visual complexity.** A plain screen that is understood beats a beautiful one that isn't. |
| 4 | **Deterministic beats AI.** No AI/ML API of any kind. All parsing is rule-based and unit-tested. |
| 5 | **Offline beats cloud.** Zero network calls in the shipped app. No backend, accounts, or sync. |
| 6 | **Never lie about state.** If something is unverified, say "unverified". If broken, say "broken". |
| 7 | **Fix, don't document.** A known bug left in place is a failure, not a caveat. |
| 8 | **No silent degradation.** No empty `catch {}`. Errors surface as recoverable UX. |
| 9 | **Never fabricate evidence.** Only claim a build/test passed if you actually ran it and saw the output. |

### 1.2 When you hit a judgment call

Decide it yourself and record the decision in the final report (§23). You only
stop to ask the user when the choice is **irreversible and cannot be reasonably
defaulted** — e.g. renaming the package after a real release, or a destructive
wipe. Everything else: decide, build, move on.

### 1.3 Defaults for anything unspecified

| Concern | Decision |
|---|---|
| Package / application ID | `com.lifereminder.life_reminder` |
| App display name | `Life Reminder` |
| Min SDK | 24 (Android 7.0) |
| Target SDK | Latest stable |
| Dart SDK | Match installed toolchain, minimum `^3.9.0` |
| State management | `provider` + `ChangeNotifier` |
| Local database | `sqflite` (`sqflite_common_ffi` for desktop tests) |
| Time source | `timezone` package with a single fixed local zone |
| Pure logic | Must accept an injected `now` — never call `DateTime.now()` inside algorithms |
| Currency / locale formatting | Not used beyond `intl` date formatting |

### 1.4 Environment facts (already verified)

- Flutter 3.47.2, Dart 3.13.2, stable channel
- Windows host; attached device `CPH2325` (SKTOEIUSLJJVE6MJ), Android 13, API 33, arm64
- App previously built and installed successfully: versionName `1.0.0`, versionCode `1`
- `flutter analyze` was previously clean

---

## 2. THE PRODUCT

### 2.1 Core concept

Life Reminder is a **personal life-maintenance system** — not an alarm clock, not
a calendar, not a generic to-do list. It exists to remember things that *repeat*.

> **Promise: Remember the things that repeat.**

### 2.2 Target user

- Adult, 25–55, Android phone as the primary device
- Juggles bills, subscriptions, insurance, vehicle servicing, birthdays,
  household maintenance, and work tasks across memory and scattered notes
- Wants to be reminded **before** something is due, not after it lapses
- Hates setup friction — abandons an app that takes >30 seconds to log a first
  reminder
- May have 5 reminders or 500. Both must work equally well.

### 2.3 Canonical scenarios (all must work end-to-end)

| Scenario | Recurrence |
|---|---|
| Bike service | Every 3 months |
| Insurance renewal | Every year |
| Rent | Every month |
| Electricity bill | Every month |
| Water filter replacement | Every 6 months |
| Vehicle pollution (PUC) certificate | Every year |
| Passport renewal | Every year |
| Netflix / Spotify subscription | Monthly or yearly |
| Family birthdays | Every year |
| Dentist checkup | Every 6 months |
| Water the plants | Every 2 days |
| Weekly standup | Every week, Mon–Fri |
| Fortnightly report | Every 2 weeks on Friday |
| Smoke detector battery | Every year, fixed month |
| Doctor appointment | None (one-off) |

Every one of these must be creatable in **under 15 seconds** from the home
screen.

### 2.4 The core loop

```
create → get reminded → complete → next occurrence rolls forward automatically
   ↑                                                         │
   └─────────────────────────────────────────────────────────┘
```

**Completing a recurring reminder must roll it forward, never kill it.** Getting
this wrong destroys user trust permanently. See §9.

---

## 3. DEFINITION OF DONE

The app is done when **every** box is ticked. Compiling is not done.

### 3.1 Function

- [ ] Create / read / update / delete reminders (one-time and recurring)
- [ ] Recurrence: none, daily, weekly, monthly, yearly, custom interval
- [ ] Custom intervals: every N days / weeks / months / years
- [ ] Month-end + leap-year handling verified by unit tests
- [ ] Completing a recurring reminder: writes history, rolls forward next
      occurrence, reschedules notification, keeps reminder active
- [ ] Snooze: 30m / 1h / 3h / tomorrow / next week / custom — without corrupting
      the original recurrence
- [ ] Local notifications: due, upcoming, overdue, recurring
- [ ] Notification actions: **Done** and **Snooze** from the shade
- [ ] Notification permission requested correctly; denial handled gracefully
- [ ] Notifications survive app restart **and** device reboot
- [ ] Search across title, description, category name (live, debounced)
- [ ] Filters: all / today / upcoming / overdue / completed / favorites
- [ ] Filter and sort by category and priority
- [ ] Sort: due date, priority, recently created, recently completed
- [ ] Categories: 12 built-in + user-created, each with icon and colour
- [ ] Calendar month view with date markers, selection, and day detail
- [ ] Favorites toggle + favorites filter + favorites section
- [ ] Completion history per reminder
- [ ] Statistics: completed this month, overdue, upcoming, completion rate,
      most-used category, streak
- [ ] Settings: theme, notifications, week start, defaults, data, about
- [ ] Export JSON backup; import with validation and safe merge
- [ ] Clear completed reminders; delete all data (both confirmed first)
- [ ] Quick Add rule-based parser (§11.3)
- [ ] Data survives app restart (verified on the physical device)

### 3.2 Quality

- [ ] `flutter analyze` → **no issues**
- [ ] `flutter test` → all green (see §16 for required coverage)
- [ ] No TODOs, no placeholder widgets, no shipped `UnimplementedError`
- [ ] No debug-only behaviour, no `print(`, no hardcoded URLs, no secrets
- [ ] Long titles truncate; 1000-char descriptions don't break layout
- [ ] 1,000 reminders with no jank (§17)
- [ ] Light + dark + system theme all correct, no hardcoded colours
- [ ] Small (360×640) and large screens both usable
- [ ] Accessibility: contrast, 48dp targets, semantic labels, text scaling

### 3.3 Ship

- [ ] `flutter build appbundle --release` succeeds
- [ ] `flutter build apk --release` succeeds
- [ ] Installs and launches on the attached device with no crash
- [ ] Version name and code set deliberately in `pubspec.yaml`

---

## 4. USER EXPERIENCE SPECIFICATION

This section is as binding as the code sections. The old spec described screens;
this one describes **how the app must feel and behave**.

### 4.1 Design principles, in priority order

1. **Clarity** — the user must know what is due, when, and what to do about it
   within 2 seconds of opening the app. Nothing may delay that.
2. **Speed of capture** — logging a reminder is the most frequent action. It must
   be fast, forgiving, and never lose input.
3. **Calm** — the app should feel quiet. No red unless something is genuinely
   late. No badges, streaks, or nudges that induce guilt.
4. **Forgiveness** — every destructive action is undoable or confirmable. Accidental
   taps must never cost the user their data.
5. **Honesty** — the UI never shows a state the data doesn't support.

### 4.2 Emotional tone

Friendly, practical, quietly competent. Copy reads like a thoughtful friend, not
a corporate dashboard or a gamified chore app.

| Do | Don't |
|---|---|
| "You're all caught up. 🎉" | "0 tasks. Productivity at 100%!" |
| "Nothing scheduled yet." | "WARNING: No reminders found!" |
| "2 are running late" | "URGENT: 2 OVERDUE!!!" |
| "Water filter · in 12 days" | "Task #4471, priority P2, due 2026-10-21" |
| Sentence case everywhere | Title Case Everywhere |

### 4.3 Information hierarchy (home dashboard)

From top to bottom, in this order:

1. **Greeting + today's date** — one line, warm
2. **Counts row** — overdue → today → upcoming (overdue first, because it matters most)
3. **Today's reminders** — the actionable now
4. **Overdue** — surfaced above upcoming, visually distinct, never hidden
5. **Upcoming** — grouped by day or week, collapsed when long
6. **Completed recently** — collapsed by default, gives a sense of progress
7. **Quick add** — one persistent FAB, always reachable

Never bury an overdue item below upcoming items. Never make the user scroll to
find out they missed something.

### 4.4 Touch, motion, and feedback rules

| Rule | Requirement |
|---|---|
| Tap targets | Minimum 48×48dp. No exceptions, including icon buttons. |
| Primary action | Always the most visually prominent element on the screen. |
| Optimistic UI | Complete / unfavorite / delete update the list **immediately**, then persist. Never show a spinner for a local write. |
| Motion | 150–250ms, `Curves.easeOutCubic`. Subtle. Nothing bouncing, nothing looping. |
| Haptics | Light impact on completion only. Nothing else. |
| Undo | Completing and deleting both offer a ~5s SnackBar undo. |
| No blocking modals | Confirmations only for genuinely destructive actions (§4.7). |
| Scroll | All lists scroll. Sticky headers may not obscure the last list item. |

### 4.5 Empty states — mandatory, all of them

Empty states are a feature, not an afterthought. Each has an icon, a short
headline, and one clear action.

| Screen / state | Headline | Body | Action |
|---|---|---|---|
| No reminders | "Nothing scheduled yet." | "Add your first reminder and stop relying on your memory." | **Add reminder** |
| No overdue | "You're all caught up. 🎉" | "Nothing is running late." | — |
| Nothing today | "Nothing due today." | "Enjoy the quiet." | **See upcoming** |
| No search results | "Nothing found." | "Try a different word, or check your filters." | **Clear search** |
| No favorites | "No favorites yet." | "Tap the star on a reminder to pin it here." | — |
| No categories | "No custom categories." | "Group your reminders your way." | **New category** |
| No history | "Not completed yet." | "Completions will show up here." | — |
| No statistics | "Not enough data yet." | "Complete a few reminders and your stats will appear." | — |
| Import failed | "That file didn't work." | "It isn't a valid Life Reminder backup." | **Choose another file** |

Never show a blank screen. A blank screen is a bug.

### 4.6 Text, layout, and content rules

- **Max 2 lines** for a reminder title in list items; ellipsize with `maxLines: 2`.
- **Never truncate** on the detail screen — wrap and scroll instead.
- Lists use relative language ("Today", "Tomorrow", "in 3 days", "3 days ago");
  detail screens use absolute dates ("12 Oct 2026").
- Times render as "6:00 PM", or 24-hour if the device is set that way — respect
  the platform setting via `intl`/`MediaQuery`, never hardcode.
- Category name is always shown as **text alongside** its icon, never icon-only.
- Priority is never communicated by colour alone — pair colour with a label.
- Support text scaling to at least 1.5× without clipping primary content.

### 4.7 Destructive actions and confirmation policy

| Action | Policy |
|---|---|
| Complete a reminder | No confirmation. SnackBar undo (5s). |
| Toggle favorite | No confirmation. |
| Snooze | No confirmation. |
| Delete one reminder | Confirm dialog **and** undo SnackBar after. |
| Edit a recurring reminder | Confirm when the change affects the schedule (§9.5). |
| Clear completed | Confirm dialog stating how many will be removed. |
| Delete all data | Confirm dialog requiring an explicit checkbox acknowledgement. |
| Import backup | Show record count **before** committing. |

Never delete user data without a confirmation step. Never ask for confirmation
for something that is undoable.

### 4.8 First-run experience

- First launch goes straight to an empty dashboard with an inviting empty state.
  **No** onboarding carousel, no login, no permission wall.
- Notification permission is requested **in context** — the first time the user
  enables notifications on a reminder — not on cold launch.
- If denied, the app remains fully usable and shows a dismissible inline hint
  explaining where to re-enable it.
- Consider seeding 2–3 example reminders on very first launch with a one-tap
  "Remove examples" affordance. **[Optional]** — only if it doesn't complicate
  the DB schema.

---

## 5. DESIGN SYSTEM (MATERIAL 3)

### 5.1 Theming rules

- **Every colour comes from the theme.** `ColorScheme.fromSeed` with a single
  seed colour (recommend a calm teal/green — this is a life-maintenance app, not
  a finance app).
- No hardcoded colours anywhere in widgets. Read `Theme.of(context).colorScheme`.
- Status colours (overdue, today, upcoming, completed) are defined **once** in a
  central `AppStatusColors` extension and reused everywhere.
- Support Light / Dark / System, persisted in settings.
- Typography: one font family, Material 3 type scale, no custom oversized
  display text. Use `TextTheme` from the theme, never inline `TextStyle` with
  hardcoded sizes except deliberate one-offs.
- Shape: rounded cards (12–16dp radius), consistent 8/16/24 spacing scale.
- Elevation: minimal. Prefer surface tint over drop shadow. No glassmorphism,
  no heavy gradients.
- Fully dynamic-colour aware on Android 12+ if it doesn't break status colours.

### 5.2 Status colour semantics

| Status | Meaning | Colour intent |
|---|---|---|
| Overdue | Due date/time is in the past | Error / destructive |
| Due today | Due date is today, not yet past | Warning / tertiary |
| Upcoming | Due date in the future | Primary or neutral |
| Completed | Done | Muted / low emphasis |
| Snoozed | Temporarily pushed back | Warning with a clock icon |

### 5.3 Priority semantics

| Priority | Visual | Use |
|---|---|---|
| Low | Small dot, muted | "Nice to remember" |
| Medium | Medium dot, default | Default for every new reminder |
| High | Filled dot + label | "I will suffer if I miss this" |

Priority is **not** a sort key the user must trust alone — always paired with due
date logic. A high-priority item due next year ranks below a medium-priority item
due yesterday.

### 5.4 Navigation model

Bottom navigation with exactly 4 destinations:

**Home · Calendar · Search (or Lists) · Settings**

- Reminder detail opens as a full-screen route (push), returns with a result so
  the list refreshes.
- Add/Edit is a full-screen modal route with **Save** always visible (top-right
  and/or a bottom bar).
- Category management lives inside Settings, not as a top-level destination.
- Statistics is reachable from Home (a card) or a 5th destination if it fits —
  do not cram it into a tab that already exists.

---

## 6. ARCHITECTURE

### 6.1 Required structure

```text
lib/
├── main.dart                     # bootstrap only: DB init, tz init, runApp
├── app/
│   ├── app.dart                  # MaterialApp, theme, router
│   ├── router.dart               # named routes
│   └── theme/
│       ├── app_theme.dart
│       ├── app_colors.dart
│       └── app_text_theme.dart
├── core/
│   ├── constants/
│   ├── extensions/               # date, context, string helpers
│   ├── utils/
│   ├── services/
│   │   ├── notification_service.dart
│   │   ├── permission_service.dart
│   │   ├── backup_service.dart
│   │   └── quick_add_parser.dart
│   └── widgets/                  # genuinely shared widgets only
├── data/
│   ├── models/
│   │   ├── reminder.dart
│   │   ├── reminder_enums.dart
│   │   ├── category.dart
│   │   └── completion_record.dart
│   ├── database/
│   │   ├── app_database.dart
│   │   ├── dao/  (or schema.sql)
│   │   └── migrations.dart
│   └── repositories/
│       ├── reminder_repository.dart
│       ├── category_repository.dart
│       └── settings_repository.dart
├── features/
│   ├── home/
│   ├── reminders/               # add, edit, detail, list tile
│   ├── calendar/
│   ├── search/
│   ├── statistics/
│   ├── categories/
│   └── settings/
└── shared/                       # cross-feature UI atoms
```

Adjust names if there is a clearly better layout, but **keep responsibilities
separated** and keep `main.dart` a bootstrap file only.

### 6.2 Layering rules (enforced)

```
UI (features/*)  →  Providers  →  Repositories  →  Database / Services
```

- Widgets never talk to `sqflite` directly.
- Widgets never call the notification plugin directly.
- Repositories never import from `features/`.
- Models are immutable where practical; use `copyWith`.
- Enums are the single source of truth for repeat type, priority, and theme mode —
  serialise to stable strings, never to integer indexes that could shift.

---

## 7. DATA MODEL

### 7.1 `Reminder` fields (all required unless noted)

| Field | Type | Notes |
|---|---|---|
| `id` | `String` (UUID) | Primary key. Generated client-side. |
| `title` | `String` | Required. Trim on save. Max 200 chars enforced in UI. |
| `description` | `String?` | Optional, nullable. |
| `categoryId` | `String` | FK to `categories`. Required. |
| `priority` | `Priority` enum | `low` / `medium` / `high`. Default `medium`. |
| `createdAt` | `DateTime` | Set once on insert. |
| `startDate` | `DateTime` | Date-only, local midnight. Required. |
| `dueDate` | `DateTime` | Date-only. **For one-time reminders this is the due date. For recurring reminders this is the *anchor* the recurrence is computed from — see §9.1.** |
| `dueTime` | `DateTime?` | Time-of-day. Null = all-day (remind at 09:00 by default, configurable). |
| `isCompleted` | `bool` | True only for **non-recurring** reminders. Always `false` for recurring ones. |
| `isFavorite` | `bool` | Default false. |
| `repeatType` | `RepeatType` enum | `none`/`daily`/`weekly`/`monthly`/`yearly`/`custom`. |
| `repeatInterval` | `int` | Only meaningful when `repeatType == custom`. Must be ≥ 1. |
| `repeatUnit` | `RepeatUnit` enum | `days`/`weeks`/`months`/`years`. Only for `custom`. |
| `notificationEnabled` | `bool` | Default true. |
| `notificationTime` | `DateTime?` | When to notify. Falls back to `dueTime`, else 09:00. |
| `notificationId` | `int` | Stable per-reminder notification channel id. |
| `completedAt` | `DateTime?` | Set when a one-time reminder is completed. |
| `lastCompletedAt` | `DateTime?` | Set on **every** completion, recurring included. |
| `nextDueDate` | `DateTime` | **Denormalised** recomputed occurrence. See §9.2. |
| `snoozedUntil` | `DateTime?` | Temporary override. Does **not** change `nextDueDate`. |
| `isDeleted` | `bool` | Soft delete, so undo can restore. Purge after ~30 days or on compact. |

**Enums serialise to stable strings** (`'daily'`, `'custom'`, `'high'`), never to
`index`. A schema change that shifts an index must never corrupt user data.

### 7.2 `CompletionRecord`

Append-only. Never updated, never deleted except on full data wipe.

| Field | Type |
|---|---|
| `id` | `String` (UUID) |
| `reminderId` | `String` (FK, indexed) |
| `completedAt` | `DateTime` — when the user actually completed it |
| `dueDateSnapshot` | `DateTime` — what was due at that moment |
| `wasLate` | `bool` — `completedAt > dueDateSnapshot` |
| `source` | `String` — `'app'` / `'notification'` / `'quick_add'` |

### 7.3 `Category`

| Field | Type | Notes |
|---|---|---|
| `id` | `String` (UUID) |
| `name` | `String` | Unique, case-insensitive. |
| `iconKey` | `String` | Stable key mapping to an `IconData` in a central registry. Never store raw icon code points. |
| `colorValue` | `int` | ARGB int. |
| `isCustom` | `bool` | Built-ins are `false`. |
| `sortOrder` | `int` | |
| `isArchived` | `bool` | Hidden from pickers, retained for history. |

### 7.4 Built-in categories (all 12)

`Home` · `Vehicle` · `Finance` · `Work` · `Health` · `Documents` · `Shopping` ·
`Education` · `Family` · `Maintenance` · `Subscriptions` · `Other`

Each ships with a fixed `iconKey` and `colorValue`. Seeded on first launch with
**stable deterministic IDs** (e.g. `'cat_home'`) so exports are portable.

### 7.5 SQLite schema

```sql
CREATE TABLE categories (
  id            TEXT PRIMARY KEY,
  name          TEXT NOT NULL,
  icon_key      TEXT NOT NULL,
  color_value   INTEGER NOT NULL,
  is_custom     INTEGER NOT NULL DEFAULT 0,
  sort_order    INTEGER NOT NULL DEFAULT 0,
  is_archived   INTEGER NOT NULL DEFAULT 0
);
CREATE UNIQUE INDEX idx_categories_name ON categories(lower(name));

CREATE TABLE reminders (
  id                  TEXT PRIMARY KEY,
  title               TEXT NOT NULL,
  description         TEXT,
  category_id         TEXT NOT NULL REFERENCES categories(id),
  priority            TEXT NOT NULL,
  created_at          INTEGER NOT NULL,
  start_date          INTEGER NOT NULL,
  due_date            INTEGER NOT NULL,
  due_time            INTEGER,
  is_completed        INTEGER NOT NULL DEFAULT 0,
  is_favorite         INTEGER NOT NULL DEFAULT 0,
  repeat_type         TEXT NOT NULL,
  repeat_interval     INTEGER NOT NULL DEFAULT 1,
  repeat_unit         TEXT,
  notification_enabled INTEGER NOT NULL DEFAULT 1,
  notification_time   INTEGER,
  notification_id     INTEGER NOT NULL,
  completed_at        INTEGER,
  last_completed_at   INTEGER,
  next_due_date       INTEGER NOT NULL,
  snoozed_until       INTEGER,
  is_deleted          INTEGER NOT NULL DEFAULT 0
);
CREATE INDEX idx_reminders_next_due  ON reminders(next_due_date);
CREATE INDEX idx_reminders_category  ON reminders(category_id);
CREATE INDEX idx_reminders_deleted   ON reminders(is_deleted);

CREATE TABLE completion_records (
  id                TEXT PRIMARY KEY,
  reminder_id       TEXT NOT NULL REFERENCES reminders(id) ON DELETE CASCADE,
  completed_at      INTEGER NOT NULL,
  due_date_snapshot INTEGER NOT NULL,
  was_late          INTEGER NOT NULL DEFAULT 0,
  source            TEXT NOT NULL
);
CREATE INDEX idx_completions_reminder ON completion_records(reminder_id);
CREATE INDEX idx_completions_date     ON completion_records(completed_at);

CREATE TABLE settings (key TEXT PRIMARY KEY, value TEXT NOT NULL);
```

- All `DateTime`s stored as **UTC epoch milliseconds** (`INTEGER`). Convert at the
  repository boundary. Never store a formatted string.
- `PRAGMA foreign_keys = ON` on every connection.
- Schema version starts at `1`; write a real `onUpgrade`/migration path from day
  one so v2 doesn't require data loss.

---

## 8. SCREEN-BY-SCREEN REQUIREMENTS

### 8.1 Home dashboard

**Header:** greeting by time of day ("Good morning/afternoon/evening") + full
today's date. No user name unless they set one.

**Counts row:** three tappable cards — **Overdue / Today / Upcoming**. Tapping
applies that filter. Overdue shows `0` calmly, not in red, when there is none.

**Sections, in this order:** Overdue → Today → Upcoming → Recently completed.

**Reminder list item** shows, at minimum:
- Title (max 2 lines)
- Category name + coloured icon/dot
- Due status in relative language ("Today · 6:00 PM", "Tomorrow", "in 3 days",
  "2 days ago")
- Priority indicator (dot or label, never colour alone)
- Notification icon if enabled; clock icon if snoozed; star if favorite
- A **checkbox** on the leading edge for one-tap completion
- Long-press or overflow → Edit / Snooze / Favorite / Delete

**FAB:** quick add. Tapping the FAB opens a bottom sheet with title + inline
natural-language input; the full form is one tap away.

### 8.2 Add / Edit reminder

Single scrollable form, grouped, with **Save** always reachable.

**Required:** Title (validated inline — no silent empty save), Category.
**Strongly defaulted:** Priority (`medium`), Date (`today`), Repeat (`none`),
Notification (`on`, time = due time).

**Section: Schedule**
- Date picker (required)
- Time picker (optional — "All day" toggle)
- Repeat picker: Never / Daily / Weekly / Monthly / Yearly / Custom
- When `Custom` is chosen, reveal interval stepper + unit selector
- Show a **live preview** of the next 3 occurrences. This is non-negotiable: the
  user must see "Next: 8 Oct · 8 Jan · 8 Apr" before saving a recurrence.

**Section: Notification**
- Enable/disable switch
- Notification time (defaults to due time, else 09:00)
- **Advance reminder** offset: at time of due / 1 day before / 3 days before /
  1 week before — configurable, default "at time of due"

**Behaviour:**
- Never lose input on accidental back — show a discard confirmation if dirty.
- Inline validation, not a dialog.
- Editing must prefill every field exactly.
- Unsaved-changes guard on form exit.

### 8.3 Reminder detail

**Content:** Title, category, priority, description, last completed, next due,
repeat schedule in plain English ("Every 3 months"), notification schedule,
full completion history (newest first, with late/on-time marker).

**Actions bar:** Complete (primary) · Snooze · Edit · Delete · Favorite.

- Completing a recurring reminder here must visibly roll `Next due` forward.
- History shows at least the last 12 entries with a "show all" affordance.
- For a one-time completed reminder, `Complete` is replaced by `Mark as not done`.

### 8.4 Calendar

- Month grid; days with reminders get a marker (up to 3 dots, then a `+N`).
- Today is unmistakable (ring/filled circle, not just colour).
- Overdue days are visually flagged.
- Tap a day → bottom sheet listing that day's reminders.
- Tap a reminder → detail screen.
- FAB on an empty selected day creates a reminder **prefilled with that date**.
- Week starts Monday or Sunday per setting.
- Swipe or header arrows to change month; a "Today" button returns.
- Recurring reminders must render on every future occurrence date.

### 8.5 Search & filter

- Search field at top; results update live (debounce ~200ms).
- Searches title + description + category name, case-insensitive.
- Recent searches retained. **[Optional]**
- Filter chips: All / Today / Upcoming / Overdue / Completed / Favorites, plus
  category and priority dropdowns.
- Sort menu: Due date / Priority / Recently created / Recently completed.
- Active filters are always visible and individually clearable.
- Results count is shown ("6 reminders").

### 8.6 Categories

- List with icon, colour chip, name, and reminder count.
- Create custom (name, icon, colour). Name uniqueness enforced case-insensitively.
- Edit / archive / delete a custom category.
- **Deleting a category with reminders must not delete the reminders** — either
  block with an explanation or offer to reassign to `Other`. Never orphan rows.

### 8.7 Statistics

- Completed this month, overdue count, upcoming count, completion rate (%),
  current streak, most-used category.
- Simple visualisations only: a 12-week completion bar chart and a category
  donut/bar. Readable at a glance.
- Time-range toggle: this month / this year / all time.
- Compute asynchronously, never inside `build`.

### 8.8 Settings

**Appearance** — Light / Dark / System.
**Notifications** — master toggle, default notification time, sound, vibration,
advance-reminder default, "open Android notification settings" link.
**General** — week starts Monday/Sunday, default category, default priority.
**Data** — Export, Import, Clear completed, Delete all data. Each with
confirmation.
**About** — app version + build number (read from package info, never hardcoded),
privacy statement ("All data stays on this device"), contact, rate app.

---

## 9. RECURRENCE ENGINE (the most important code in the app)

Pure Dart. No Flutter imports. No `DateTime.now()`. Fully unit-tested.

### 9.1 Definitions — read carefully

- **Anchor** = `dueDate`. It defines the *pattern*, **not** the live occurrence.
  The anchor changes only when the user edits the schedule.
- **`nextDueDate`** = the live, currently-relevant occurrence. This is what the
  home screen, filters, and calendar read.
- **`lastCompletedAt`** = the last real completion.
- Never derive live state by naive `anchor + N*interval` arithmetic. Use §9.2.

### 9.2 `computeNextDueDate` contract

```dart
/// Returns the next occurrence strictly after [from].
/// Pure function. Never mutates input. Never throws on valid enums.
DateTime computeNextDueDate({
  required DateTime anchor,
  required DateTime from,
  required RepeatType type,
  int interval = 1,
  RepeatUnit unit = RepeatUnit.days,
});
```

| RepeatType | Behaviour |
|---|---|
| `none` | Return `anchor` (caller handles terminal completion) |
| `daily` | `anchor + N days` |
| `weekly` | `anchor + N*7 days` (preserves weekday) |
| `monthly` | Add N months, **clamping the day** (§9.3) |
| `yearly` | Add N years, clamping Feb 29 (§9.3) |
| `custom` | Apply `unit` with `interval` |

The loop must advance until the result is **strictly greater than `from`**, so a
reminder neglected for several cycles catches up instead of repeating the same
overdue date forever.

```dart
// required shape
var next = addInterval(anchor);
while (!next.isAfter(from)) {
  next = addInterval(next);   // step from the previous candidate,
}                             // never anchor + k*interval
```

Stepping from the previous candidate (not `anchor + k*interval`) keeps monthly
recurrence drift-free across long histories.

### 9.3 Month-end and leap-year clamping (mandatory test cases)

| Anchor | Recurrence | Expected next | Note |
|---|---|---|---|
| 31 Jan 2026 | Monthly | 28 Feb 2026 | Clamp, don't overflow into March |
| 31 Jan 2026 | Monthly ×2 | 31 Mar 2026 | Clamp applies per step |
| 31 Dec 2026 | Monthly | 31 Jan 2027 | |
| 29 Feb 2024 | Yearly | 28 Feb 2025 | Leap → non-leap clamps |
| 29 Feb 2024 | Yearly ×2 | 28 Feb 2026 | |
| 31 Aug 2026 | Every 6 months | 28 Feb 2027 | Clamp mid-sequence |
| 31 Oct 2026 | Quarterly | 28 Feb 2027 | |
| 30 Apr 2026 | Monthly | 30 May 2026 | No clamp needed |
| 15 Jan 2026 | Every 2 weeks | 29 Jan 2026 | |

`addMonths` must be implemented explicitly — **do not rely on `DateTime`
arithmetic or `Duration` for months/years.**

```dart
DateTime addMonthsClamped(DateTime date, int months) {
  final totalMonths = date.month - 1 + months;
  final year  = date.year + totalMonths ~/ 12;
  final month = totalMonths % 12 + 1;
  final lastDay = daysInMonth(year, month);
  return DateTime(year, month, math.min(date.day, lastDay),
                  date.hour, date.minute, date.second);
}
```

### 9.4 Completion flow (exact sequence)

Triggered by: checkbox tap, detail-screen Complete, or notification "Done".

1. **Capture** `now`.
2. Write a `CompletionRecord` (`reminderId`, `completedAt = now`,
   `dueDateSnapshot = effective due date`, `wasLate`, `source`).
3. If `repeatType == none`:
   - set `isCompleted = true`, `completedAt = now`, `lastCompletedAt = now`;
   - cancel any pending notification.
4. If recurring:
   - **`isCompleted` stays `false`. Never permanently complete a recurring reminder.**
   - `lastCompletedAt = now`.
   - `nextDueDate = computeNextDueDate(anchor: dueDate, from: effectiveDue, ...)`
   - clear `snoozedUntil`.
   - keep the reminder active and visible.
5. Persist in **one transaction** — record insert + reminder update must be
   atomic. A crash between them creates a phantom history entry.
6. Reschedule the notification for the new `nextDueDate`.
7. Refresh providers and offer undo (retain the previous `nextDueDate` in memory
   so undo can delete the record and restore it).

### 9.5 Effective due date and snooze

```dart
DateTime effectiveDueDate(Reminder r) => r.snoozedUntil ?? r.nextDueDate;
```

- **Snooze must never write to `nextDueDate`, `dueDate`, or `lastCompletedAt`.**
  It sets only `snoozedUntil`. This single rule is what prevents snoozing from
  destroying recurrence.
- A snoozed reminder appears due at the snooze time and carries a clock icon, but
  its anchor and history stay intact.
- Snooze options: 30 minutes · 1 hour · 3 hours · tomorrow 09:00 · next week
  (same weekday, 09:00) · custom date+time.
- Completing a snoozed reminder consumes the current occurrence normally (§9.4)
  and clears `snoozedUntil`.

### 9.6 Catch-up on launch and on boot

On every app start and on `BOOT_COMPLETED`:

1. Find reminders where `effectiveDueDate < now` and notifications are enabled.
2. For recurring ones, roll `nextDueDate` forward (§9.2) and schedule the next
   notification. **Do not** auto-complete them and **do not** silently swallow
   missed occurrences — an overdue reminder must stay visible as overdue.
3. Fire at most **one** overdue summary notification per launch, stating the
   count, rather than one per missed reminder. This prevents notification spam.
4. Re-register **all** pending notifications, since Android does not guarantee
   they survive reboot or app update.

### 9.7 Editing a recurring reminder safely

| Field changed | Effect |
|---|---|
| Title, description, category, priority, favorite, notification toggle | Safe — history untouched; `nextDueDate` recalculated from the same anchor. |
| `dueTime` only | Safe — time shifts, recurrence preserved. |
| Start date / recurrence / interval | **Anchor changes.** Ask: *"Apply to future occurrences only?"* Keep history; recompute `nextDueDate` from the new anchor. |
| Any change | Never retroactively mutate or delete existing `completion_records`. |

History is append-only and is the user's trust anchor. It must survive every edit.

---

## 10. NOTIFICATIONS

### 10.1 Requirements

- `flutter_local_notifications` with the `timezone` package for scheduling.
- Two channels minimum: **Reminders** (default) and **Overdue summary**
  (low importance). Create channels on first launch, before any scheduling.
- Notification content: reminder title as the title; category + relative due
  status as the body; the app icon; colour-tinted by status.
- Schedule with `zonedSchedule` + `matchDateTimeComponents` for recurring types.
- Use `AndroidScheduleMode.exactAllowWhileIdle` where the user expects precision,
  with a graceful fallback to `inexact` if exact-alarm permission is denied.
- Persist enough state to fully rebuild every pending notification on reboot.

### 10.2 Permission handling (must not break the app)

| State | Behaviour |
|---|---|
| Not yet asked | Ask **in context**, when the user first enables notifications on a reminder. Never on cold launch. |
| Granted | Schedule normally. |
| Denied once | App stays fully usable. Show a dismissible inline hint. Never re-prompt immediately. |
| Permanently denied | Offer a button to open Android app settings. No further system prompts. |
| Android 13+ (`POST_NOTIFICATIONS`) | Request at runtime; catch `POST_NOTIFICATIONS` denial specifically. |
| Android 12+ (`SCHEDULE_EXACT_ALARM`) | Request; if denied, fall back to inexact and tell the user timing may drift. |

Declare in `AndroidManifest.xml` only what is actually used:

```xml
<uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>
<uses-permission android:name="android.permission.SCHEDULE_EXACT_ALARM"/>
<uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED"/>
<uses-permission android:name="android.permission.VIBRATE"/>
```

### 10.3 Actions and boot receiver

- **Done** → runs the §9.4 completion flow in the background, dismisses, rolls
  forward. Must work when the app is fully closed.
- **Snooze** → opens a snooze chooser (30m / 1h / 3h / tomorrow), applies
  `snoozedUntil`, reschedules. Must not alter recurrence.
- Register a `BOOT_COMPLETED` receiver that triggers §9.6 catch-up.
- Handle deep-linking a notification tap into the correct reminder's detail
  screen, including when the app was cold-started.
- Every notification carries a stable `notificationId` derived from the reminder
  id so rescheduling replaces rather than duplicates.

---

## 11. SERVICES

### 11.1 `QuickAddParser` — deterministic, offline, tested

**No AI. No network.** A regex/rule-based parser over a normalised string.

**Parse targets:** title · repeat type + interval · due date · time · category
hint · priority hint.

| Input | Parsed result |
|---|---|
| `bike service every 3 months` | title `Bike service`, every 3 months |
| `pay rent every month on the 5th` | title `Pay rent`, monthly, day-of-month 5 |
| `water plants every 2 days` | title `Water plants`, every 2 days |
| `dentist every 6 months` | title `Dentist`, every 6 months |
| `call mom every week` | title `Call mom`, weekly |
| `passport renewal every year` | title `Passport renewal`, yearly |
| `insurance tomorrow` | title `Insurance`, tomorrow |
| `gym today at 6pm` | title `Gym`, today, 18:00 |
| `submit report in 3 days` | title `Submit report`, in 3 days |
| `pay bill` | title `Pay bill`, no repeat, default date |

**Rules:**
- Recognise `every N (day|week|month|year)` and the `on the Nth` day-of-month form.
- Recognise relative dates: `today`, `tomorrow`, `next week`, `in N days`.
- Recognise times: `at 6pm`, `at 18:30`, `6:00 AM`.
- Recognise category keywords (`bike`/`car` → Vehicle, `bill`/`rent` → Finance,
  `doctor`/`dentist`/`gym` → Health).
- Recognise priority hints: `!!` → high, `!` → medium → mapped, else default.
- **Anything unrecognised must be preserved verbatim as the title.** Never drop
  text, never guess a recurrence the user didn't state.
- Always return a partial result rather than null, and always let the user edit
  the parsed fields in the full form before saving.
- This parser is a convenience layer, not a gate. **If parsing is uncertain, the
  structured form must always remain available and complete.**

### 11.2 `BackupService`

Full JSON contract in §12. Responsibilities: build, validate, write, read, merge.
Never trust a file from disk.

### 11.3 `SettingsRepository`

Typed accessors over the `settings` table with defaults. Never read raw strings
into widgets.

---

## 12. BACKUP / RESTORE — JSON CONTRACT

### 12.1 File shape

```json
{
  "app": "life_reminder",
  "schemaVersion": 1,
  "exportedAt": "2026-10-09T10:30:00.000Z",
  "counts": { "reminders": 3, "categories": 12, "completions": 4 },
  "categories": [ /* ... */ ],
  "reminders": [ /* ... */ ],
  "completionRecords": [ /* ... */ ]
}
```

- `app` must equal `"life_reminder"`; if not, **reject with a clear message**.
- `schemaVersion > current` → reject (a newer app's backup may not import).
- `schemaVersion < current` → import through the migration path, never guess.
- Dates are ISO-8601 UTC strings.
- IDs are preserved on import so completion records stay linked.

### 12.2 Validation before any write

1. Valid JSON, root is an object.
2. `app`, `schemaVersion`, and all three arrays present and correctly typed.
3. Every reminder has a non-empty `id`, `title`, `categoryId`, `repeatType`.
4. Every enum value parses; unknown values → **reject that record**, not the file.
5. Every `categoryId` resolves to a category in the file **or** the device; if it
   resolves to neither, reassign to `Other` and count it.
6. `repeatInterval` ≥ 1; malformed → clamp to 1 and count it.
7. Category names that collide with an existing device category → import under a
   de-duplicated name (`Home (2)`), preserving the original id.

### 12.3 Import strategies

Offer both, clearly:

- **Merge** (default, recommended) — insert new ids, skip or version conflicting
  ids. Never silently overwrites.
- **Replace** — wipes existing data first. Requires an explicit confirmation that
  states the current record count.

### 12.4 Export

- Writes `life_reminder_backup_YYYY-MM-DD.json`.
- Uses the platform share sheet (`share_plus`) so the user chooses the destination.
- If share is unavailable, write to app documents and report the path.
- Confirm the export succeeded with the record count. **Never claim success
  without verifying the file was written.**

### 12.5 Failure handling

| Failure | Behaviour |
|---|---|
| Not valid JSON | "That file didn't work." + reason. No data touched. |
| Wrong `app` field | Reject: "This isn't a Life Reminder backup." |
| Future schema version | Reject: "This backup is from a newer version." |
| Empty arrays | Treat as an empty-but-valid backup. |
| Partial record failure | Import the valid records, report exactly what was skipped. |
| Write failure | Report the OS error, leave existing data untouched. |

**The data-safety rule: an import must be atomic in effect — either the merge
succeeds, or the previous state is left exactly as it was.** Run the whole import
inside one transaction and roll back on any failure.

---

## 13. SETTINGS KEYS

| Key | Type | Default |
|---|---|---|
| `theme_mode` | `'light'` \| `'dark'` \| `'system'` | `system` |
| `notifications_enabled` | bool | `true` |
| `default_notification_time` | `HH:mm` | `09:00` |
| `notification_sound` | bool | `true` |
| `notification_vibration` | bool | `true` |
| `default_advance_offset` | `'at_time'` \| `'1d'` \| `'3d'` \| `'1w'` | `at_time` |
| `week_starts_monday` | bool | `true` |
| `default_category_id` | String | `cat_other` |
| `default_priority` | `'low'` \| `'medium'` \| `'high'` | `medium` |
| `onboarding_complete` | bool | `false` |
| `last_backup_at` | ISO-8601 String | null |

---

## 14. ERROR HANDLING MATRIX

Every row must be implemented. **No row may result in a crash or a blank screen.**

| Failure | User-visible behaviour |
|---|---|
| Empty title on save | Inline field error; save blocked; focus the field |
| DB open failure | Friendly screen: "We couldn't open your reminders." + retry button |
| DB write failure | SnackBar "Couldn't save — try again"; data preserved in memory |
| Duplicate category name | Inline error "You already have a category with that name" |
| Delete category in use | Blocked dialog offering reassign to `Other` |
| Notification schedule failure | Warning that reminders won't notify; app still works |
| Notification permission denied | App fully usable + dismissible hint |
| Exact-alarm permission denied | Fall back to inexact timing + one-time notice |
| Invalid backup JSON | "That file didn't work." + reason; no data touched |
| Import with unknown enums | Import valid records; report skipped count |
| Share sheet unavailable | Write to documents dir and show the path |
| File picker cancelled | No-op, no error shown |
| Corrupt settings value | Fall back to the default, never crash |
| Reminder id not found | Silent no-op + log; never throw to the UI |
| Timezone data missing | Initialise timezone in `main()` **before** `runApp` |
| Unexpected error anywhere | Global `FlutterError.onError` + `runZonedGuarded`; show a generic recovery screen |

### 14.1 Implementation rules

- One top-level `runZonedGuarded` in `main.dart` capturing all async errors.
- `FlutterError.onError` wired to a logger; in release, show a recovery UI.
- Repository methods return a `Result`-style type or throw typed exceptions —
  **never return null to signal failure.**
- Every `await` on IO is wrapped with a handler that produces user-facing copy.
- **No empty `catch` blocks. Ever.**

---

## 15. PRIVACY AND DATA SAFETY

- **Zero network access in the shipped app.** No analytics, no crash reporting
  SDK, no ad SDK.
- All data lives in the app's private sqflite database.
- Request only the permissions listed in §10.2. Nothing else.
- No personal information collected beyond what the user types.
- The privacy statement in Settings must be literally accurate, and the codebase
  must keep it accurate: if a future feature adds cloud sync, this section must be
  updated and the claim softened before shipping that feature.
- The architecture must keep a clean seam (`ReminderRepository`) so a future
  optional cloud sync could be added **without** restructuring the app.

---

## 16. TESTING

### 16.1 Minimum required tests

| Area | Type | Minimum count |
|---|---|---|
| `computeNextDueDate` — all 6 repeat types | unit | 20+ |
| Month-end / leap-year clamping (§9.3) | unit | 9 (the table above) |
| Catch-up: multiple missed cycles | unit | 4 |
| Snooze does not mutate recurrence | unit | 4 |
| Completion flow (one-time + recurring + undo) | unit | 6 |
| `QuickAddParser` (§11.1 table) | unit | 10 |
| Backup validation (valid, invalid, future schema) | unit | 8 |
| Import merge / replace / conflict | unit | 5 |
| Enum ↔ string serialisation round-trip | unit | 6 |
| Repository CRUD against `sqflite_common_ffi` | integration | 6 |
| Statistics calculations | unit | 5 |
| Date formatting / relative language | unit | 6 |

### 16.2 Rules

- All date-dependent tests inject a fixed `now`. **No test may call
  `DateTime.now()`.**
- Use `flutter_test`; group by area with descriptive names.
- Every bug fixed during development gets a regression test in the same commit.
- `flutter test` must be fully green before claiming completion.
- Run `flutter analyze` with zero issues — treat warnings as errors.

---

## 17. PERFORMANCE BUDGET

The app must not feel slower with 500 reminders than with 5. These are targets,
not aspirations — measure them and fix violations.

| Metric | Budget |
|---|---|
| Cold start → first interactive frame | ≤ 1.5 s on the reference device |
| Home screen scroll with 1,000 reminders | 60 fps, no dropped frames |
| Search keystroke → result update | ≤ 200 ms (debounced) |
| Add/Edit → Save → list refresh | Immediate (optimistic), no spinner |
| Calendar month render | ≤ 16 ms per frame |
| Database write for a completion | ≤ 50 ms, inside one transaction |

### 17.1 Rules that produce these numbers

- **Never query the database inside `build()`.** Load into a provider, then build.
- Never compute recurrence inside a `ListView.builder` item builder. Precompute
  the visible day range once per month, in a provider.
- Recurrence expansion for the calendar must be bounded — expand only the visible
  month (plus a one-month buffer), never "all future occurrences".
- Use `ListView.builder` / `SliverList` for every unbounded list. Never
  `Column` inside `SingleChildScrollView` for a list that can grow.
- Give every list item a stable `key` so state is preserved across reordering.
- `const` constructors everywhere the widget tree allows it.
- Load the DB once at startup into memory-backed providers; sqflite round-trips
  are for persistence, not for rendering.
- Statistics and backup generation run off the UI isolate
  (`compute()` or an async provider) — never block a frame on them.
- Debounce search input (~200 ms) and cancel superseded queries.
- Keep the widget tree shallow — extract large `build` methods into their own
  widgets rather than nesting deeply in one method.

---

## 18. ACCESSIBILITY

- Minimum touch target **48×48 dp** on every interactive element, including
  icon-only buttons — wrap small icons in `IconButton` or `SizedBox` with
  `padding`, never leave a bare 24dp icon tappable.
- Every icon-only control needs a `Semantics` label or `tooltip`
  ("Delete reminder", not just a bin glyph).
- Every screen needs a readable `Semantics` heading so screen-reader users can
  jump between sections.
- Never encode meaning in colour alone. Overdue must also say "Overdue" or
  "2 days ago"; priority must carry a label or distinct icon shape.
- Maintain ≥ 4.5:1 text contrast in both light and dark themes. Status colours
  must be verified against both surfaces.
- Support `textScaler` up to 1.5× with no clipping of primary content. Test by
  setting the device font size to the largest setting and scrolling every screen.
- Honour `MediaQuery.disableAnimations` — wrap decorative transitions so they can
  be suppressed for motion-sensitive users.
- Support both left-to-right and right-to-left layout direction — use
  `EdgeInsetsDirectional` and `TextDirection`-aware icons instead of hardcoded
  left/right.

---

## 19. CODE CONVENTIONS

- Dart `lowerCamelCase` for variables and functions, `UpperCamelCase` for types,
  `lower_snake_case.dart` for filenames.
- One public class per file, filename matches the class name (`reminder_tile.dart`
  → `ReminderTile`).
- `final` by default; `const` constructors on every stateless widget.
- No magic numbers in widgets — extract to named constants in
  `core/constants/`.
- Every public repository/service method needs a doc comment stating its
  side effects, especially whether it writes.
- Comments explain **why**, never **what**. If a comment explains what the code
  does, rename things until it is unnecessary.
- All user-facing strings live in the widget that renders them. No string
  constants scattered across layers.
- Errors: throw typed exceptions with actionable messages, or return a `Result`
  type. Never return `null` to mean failure.
- No `print(`. Use a single `AppLogger` wrapper around `debugPrint` guarded so
  it compiles out in release.
- Format with `dart format` and keep `analysis_options.yaml` strict
  (`flutter_lints` plus `avoid_print`, `unawaited_futures`,
  `always_declare_return_types`).

---

## 20. RELEASE BUILD

- Version lives **only** in `pubspec.yaml` as `version: x.y.z+build`.
- Bump `build` (the integer after `+`) on every install you want to distinguish;
  bump the semantic part when behaviour changes.
- Release builds must be `--release` with tree-shaken icons
  (`--tree-shake-icons` is default on modern Flutter) and obfuscation if it does
  not complicate debugging.
- Verify the installed APK on the device after every build:
  `adb shell dumpsys package <package> | grep versionName` — confirm the
  `versionCode` actually changed before claiming an upgrade succeeded.
- Confirm the app launches cold with no crash: launch it, then check logcat for
  `FATAL`, `AndroidRuntime`, or unhandled Flutter errors. An install that has not
  been launched and checked is not a verified install.
- Never claim a build or test passed unless you ran it and read the output.

---

## 21. BUILD ORDER (work in this sequence)

Do not jump ahead. Each layer depends on the one before it being correct.

1. **Models + enums** (`data/models/`) — immutable classes, `copyWith`,
   string-serialisation for every enum. No logic beyond that.
2. **Recurrence engine** (`core/utils/recurrence.dart`) — pure Dart, zero Flutter
   imports, injected `now`. **Write the §9.3 clamping tests first, then the
   implementation.** This is the highest-risk code in the app; do it before any
   UI exists.
3. **Database** (`data/database/`) — schema from §7.5, `onCreate` plus a real
   `onUpgrade`, `PRAGMA foreign_keys = ON`, UTC epoch-ms conversion at the
   repository boundary.
4. **Repositories** — CRUD, completion flow (§9.4) inside one transaction,
   catch-up (§9.6), search query. Test against `sqflite_common_ffi`.
5. **Providers** — thin state holders over repositories. No business logic here.
6. **Services** — notifications, permissions, backup, quick-add parser. Each
   independently testable.
7. **Theme** (`app/theme/`) — colour scheme, status colour extension, text theme,
   light/dark/system.
8. **Screens** — in this order: Home → Add/Edit → Detail → Search → Calendar →
   Categories → Statistics → Settings. Home first, because it exposes every
   missing piece of the layers below.
9. **Empty states, error states, accessibility pass** on every screen built.
10. **Performance pass** with 1,000 seeded reminders.
11. **Tests** for everything in §16.
12. **Release build + on-device verification** (§20).

At every step: `flutter analyze` clean, `flutter test` green.

---

## 22. OUT OF SCOPE

Explicitly not part of this app. Do not build these, do not scaffold for them, do
not leave hooks for them:

- Cloud sync, accounts, login, or any network call whatsoever
- Push notifications from a server (local notifications only)
- Sharing a reminder with another person
- Widgets, wear-os, tablet-specific layouts, or a desktop UI
- AI, ML, LLMs, or any smart-suggestion feature
- Gamification: points, levels, achievements, or leaderboards
- Sub-lists, projects, tags, or nested reminders (categories are the only
  grouping)
- Recurrence rules more complex than "every N units" — no "third Tuesday of the
  month", no "weekends only", no exception dates
- Attachments, photos, or voice notes
- Multi-language / localisation beyond date and time formatting (English UI only)
- Analytics, telemetry, or crash reporting of any kind

If a feature is needed later, it must not compromise any rule above. Adding
network access in particular requires rewriting §15 and the privacy statement
**before** shipping, not after.

---

## 23. FINAL REPORT FORMAT

When the work is done, report in exactly this structure. An honest negative is
worth more than an optimistic positive.

```
## What was built
- Per-screen and per-layer summary of what exists.

## Definition of Done — status
- Every §3 checkbox marked ✅ verified / ❌ not done / ⚠️ partial + why.

## Verification evidence
- Exact commands run, and their real output (analyze, test, build).
- On-device confirmation: package, versionCode, versionName, launch result,
  logcat crash scan result.

## Bugs found and fixed
- Each with the regression test that now covers it.

## Bugs known and unfixed
- Honest list. If this is empty, say so explicitly.

## Judgment calls made
- Every §1.2 decision, with the reasoning.

## Cut features and why
- Anything from §3 that was dropped under §1.1 rule 2, with the reliability
  reason.

## What the user must know
- Data-loss risks, permission caveats, and anything surprising.
```

Rules for the report:

- **Never write "should work" or "should pass".** Either you ran it and saw the
  result, or it is unverified — label it `unverified`.
- If you could not run something (no device, no emulator), say exactly that.
- Include the literal command output for every claim about tests, analysis, and
  builds. Paraphrasing a build result is a lie.

---

## 24. ONE-PARAGRAPH SUMMARY OF THIS ENTIRE DOCUMENT

Build **Life Reminder**: a calm, offline, Material 3 Flutter app whose only job
is to make sure repeating life-maintenance tasks — bills, servicing, renewals,
birthdays, filters — never lapse. Capture must take under 15 seconds. The
recurrence engine is the heart of the product and must be pure, injected-`now`,
and exhaustively tested for month-end and leap-year clamping. Completing a
recurring reminder must roll it forward and write history in a single atomic
transaction; it must never kill the reminder. Snooze must never touch the
recurrence anchor. Overdue items must always be visible and never buried. Every
screen must have a real empty state, and every failure must surface as
recoverable UX — never a blank screen, never a silent catch. Zero network calls,
zero analytics, all data on-device. Work autonomously through §21, verify
everything by actually running it, and report honestly in §23 including anything
that did not work.