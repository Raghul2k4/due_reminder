# Feature Upgrade: Spending History & Insights

Give subscriptions the accounting layer they currently lack: every "Mark renewed"
becomes a durable payment record, a new subscription detail screen shows history,
Statistics gains a spending section, totals stop mixing currencies, and the dead
`SubscriptionReminderBridge` gets wired.

## Verified current state (evidence)

| Finding | Evidence |
|---|---|
| Subscriptions module complete (CRUD, pause, renewals, notifications, calendar + search integration, backup) | `lib/features/subscriptions/*`, `subscription_provider.dart`, `app_database.dart:157` |
| `markRenewed` is amnesia — rolls `next_renewal_date`, records nothing | `subscription_repository.dart:101-116` |
| `markRenewed` is not atomic — read + write are separate steps (violates AGENTS.md §9.4 rule 5) | `subscription_repository.dart:101-116` |
| Spending totals sum across currencies into one number | `subscription_provider.dart:44-53`, caption `subscriptions_screen.dart:462` |
| Home has zero subscription surface | no `Subscription` reference in `home_screen.dart` |
| `SubscriptionReminderBridge` is dead code | only definition found, no usages |
| Statistics ignores subscriptions | no `Subscription` reference in `statistics_screen.dart` |
| Backup schema is v2 while DB is already v3 | `backup_service.dart:131` exports `schemaVersion: 2` |
| Subscription delete is a hard delete with confirm | `subscription_repository.dart:84-87`, `subscriptions_screen.dart:45-71` |

## Decisions

1. **Group totals by currency** — no exchange rates (offline rule, AGENTS.md §1.3 rule 6).
   Render one total per currency ("$45.99 · ₹1,299"), never a summed cross-currency number.
2. **Payment records are append-only**, mirroring `completion_records` (AGENTS.md §7.2).
   A record is written only on an explicit "Mark renewed" (UI or notification action).
   Catch-up roll-forward (`rollForwardOverdueRenewals`) never writes a payment — missed
   cycles stay visible as overdue, they are not silently "paid".
3. **Amount snapshot** = the subscription's `price`/`currency` at renewal time, plus a
   `billing_cycle` snapshot. `was_late` = `paid_at` later than the renewal date that was
   due (the pre-roll `next_renewal_date`).
4. **No backfill, no manual payment entry.** History starts empty at upgrade; the detail
   screen shows the empty state "No payments recorded yet."
5. **Backup v3**: `schemaVersion` 2 → 3, add `subscriptionPayments`. v2 files import with
   an empty payments array; `> 3` rejected; per-record validation skips bad rows.
6. **Deleting a subscription deletes its payments** (FK cascade, matching existing hard-delete
   behavior). Payments are also included in "Delete all data".

## Scope

### 1. Data layer
- New model `lib/data/models/subscription_payment.dart`: `id`, `subscriptionId`, `paidAt`,
  `amount`, `currency`, `billingCycle` snapshot, `wasLate`, `source`; `toMap/fromMap`,
  `toJson/fromJson`, `copyWith` — follow `subscription.dart` and `completion_record.dart`.
- New `PaymentSource` enum (`'app'`, `'notification'`) with stable string serialisation —
  add to `subscription_enums.dart` beside existing enums (never index-based).
- DB **v4** in `app_database.dart` `_onUpgrade` (`app_database.dart:139`): extract a shared
  `_createSubscriptionPaymentsTable(db)` helper used by both `onCreate` and the v4 upgrade
  branch, mirroring `_createSubscriptionsTable` (`app_database.dart:155`). Do NOT bump
  `_dbVersion` past the real onCreate definition — keep `onCreate` = latest schema, upgrade
  path additive only:

```sql
CREATE TABLE IF NOT EXISTS subscription_payments (
  id             TEXT PRIMARY KEY,
  subscription_id TEXT NOT NULL REFERENCES subscriptions(id) ON DELETE CASCADE,
  paid_at        INTEGER NOT NULL,
  amount         REAL NOT NULL,
  currency       TEXT NOT NULL,
  billing_cycle  TEXT NOT NULL,
  was_late       INTEGER NOT NULL DEFAULT 0,
  source         TEXT NOT NULL
);
CREATE INDEX IF NOT EXISTS idx_payments_subscription ON subscription_payments(subscription_id);
CREATE INDEX IF NOT EXISTS idx_payments_paid ON subscription_payments(paid_at);
```

- `subscription_repository.dart`:
  - `markRenewed` — rewrite as one `db.transaction`: insert payment row + update
    `next_renewal_date` atomically (§9.4 rule 5). Keep the existing signature
    `({required DateTime now})` so `SubscriptionProvider` callers are unchanged.
  - Add `getPaymentsForSubscription(id)` (newest first), `getAllPayments()`,
    `getPaymentsBetween(from, to)`, `deleteAllPayments()`.
  - `deleteSubscription` / `deleteAllSubscriptions` — verify FK cascade actually fires
    (requires `PRAGMA foreign_keys = ON`, AGENTS.md §7.5); if not enabled, add explicit
    payment deletes in the same transaction. Write a test proving payments disappear.

### 2. Money math (fix the currency bug)
- `subscription_recurrence.dart`: add pure helpers
  `Map<String, double> monthlyTotalsByCurrency(List<Subscription>)` and
  `Map<String, double> yearlyTotalsByCurrency(List<Subscription>)` — group, never sum
  across currencies. Existing `monthlyEquivalent`/`yearlyEquivalent` stay as-is.
- `subscription_provider.dart`: replace `totalMonthlySpending`/`totalYearlySpending`
  (lines 44–53) with the new map getters. No UI may show a single mixed-currency total.

### 3. Providers
- `SubscriptionProvider`: hold `payments`, `loadPayments()`, and reload payments in every
  mutation path (`markRenewed`, `setStatus`, `deleteSubscription`, `deleteAllSubscriptions`).
- `StatisticsProvider`: add `spendingStats` for the selected time range — payments in range
  grouped by currency, payment count, most expensive subscription, and a 6-month spend
  series (last 6 calendar months, totals per month per currency). Pure aggregation functions
  in the provider layer or a small util, unit-tested with injected `now`.

### 4. UI
- New `lib/features/subscriptions/screens/subscription_detail_screen.dart`:
  - Brand logo header, price/currency, billing cycle, next renewal, status.
  - Actions: **Mark renewed** (primary, only when active) · Edit · Pause/Resume · Delete
    (confirm dialog, existing pattern at `subscriptions_screen.dart:45-71`).
  - Payment history: newest first, each row `12 Oct 2026 · $15.99 · on time/late`,
    show 12 with a "Show all" affordance, empty state "No payments recorded yet." /
    "Payments will show up here each time you mark a renewal."
  - **Add renewal reminder** button that finally uses `SubscriptionReminderBridge`
    (`subscription_bridge.dart:9`): pushes the add/edit reminder screen prefilled with
    suggested title + suggested category + matching repeat (monthly/yearly).
- `subscriptions_screen.dart`: card tap (`:185-191`) navigates to **detail** (not edit);
  edit moves into the detail action bar. Summary cards (`:104-151`) render one line per
  currency; fix the caption at `:462` ("Based on N active subscriptions" + per-currency
  breakdown when >1 currency).
- `statistics_screen.dart`: new "Spending" section below the existing reminder stats,
  inside the same `ListView`, respecting the existing `StatsTimeRange` toggle
  (`:46-64`): totals per currency for the range, payment count, top subscription, and a
  6-month spend bar reusing the bar-chart pattern at `:148-189` (keep it per-currency when
  multiple currencies exist, else single series). Empty state when no payments in range.
- `home_screen.dart`: "Upcoming renewals" digest card — top 3 from
  `SubscriptionProvider.upcomingRenewals`, tapping goes to the subscription detail, header
  "See all" navigates to the Subs tab (`onNavigateToTab` already exists, `:25`). Hidden
  when empty. Placed above Today's reminders but below the counts row, keeping the §4.3
  hierarchy (overdue first, never bury).
- No new navigation destination and no new settings keys.

### 5. Notifications
- Subscription notifications (`notification_service.dart:185`): add a **Mark renewed**
  action routed through `SubscriptionProvider.markRenewed` so the payment row is written
  from the shade, matching the reminder Done action. Verify background execution works on
  the device; if the action is unreliable when the app is closed, degrade to a tap that
  opens the detail screen — record whichever was verified. No new channels.

### 6. Backup v3 (`backup_service.dart`)
- Export: `schemaVersion: 3` (`:131`), add `subscriptionPayments` array + `counts`.
- Validation (`:63-92`): reject `> 3`; accept `2` with missing `subscriptionPayments` as
  empty; every record needs non-empty `id`, `subscriptionId`, parseable `paidAt`, `amount`,
  `currency`, `billing_cycle`, `source` — skip individual bad records and report the count
  (§12.2 rule 4).
- Import: merge (default) inserts by id, skip conflicting ids; replace wipes payments too
  (`:183-191` region). Remainder of the import inside one transaction (§12.5 atomicity).
- Orphan payments whose `subscriptionId` resolves to neither file nor device: keep them if
  the subscription exists after import, else drop and count (mirror rule 5).

### 7. Tests (follow existing `test/integration/subscription_repository_test.dart` pattern, injected `now`)
- Model + enum round-trip incl. JSON (3).
- `markRenewed` writes exactly one payment atomically with correct amount/currency/cycle
  snapshot / `was_late` false when on time (4).
- `markRenewed` after the due date marks `was_late` true (2).
- `rollForwardOverdueRenewals` writes **zero** payments (2).
- Multi-cycle catch-up: two missed cycles → one payment, next date strictly after `now` (2).
- `deleteSubscription` / `deleteAllSubscriptions` remove payments (2).
- Per-currency monthly/yearly totals incl. mixed cycles and mixed currencies (4).
- Statistics spending aggregation for month/year/all-time + 6-month series (3).
- Backup: valid v3 round-trip, v2 import (no payments key), future version rejected,
  partial bad record skipped with count (5).

## Risks

- **FK cascade depends on `PRAGMA foreign_keys = ON`** — verify in code before relying on
  it; otherwise explicit transactional deletes. Covered by the delete tests.
- **Migration correctness**: v1 → v4 upgrade path must stay additive; test by upgrading a
  v3-state fixture DB, not just a fresh create.
- **Notification action reliability** when the app is closed on Android 13 — verify on the
  attached device and degrade to tap-opens-detail if unreliable.
- **History starts empty at upgrade** — intentional (no source data existed); empty state
  must make this legible, not look like a bug.
- Payments grow unbounded — acceptable (same as `completion_records`); removed only with
  the subscription or full data wipe.

## Validation

1. `flutter analyze` → zero issues (treat warnings as errors).
2. `flutter test` → all green, counts above.
3. On device `CPH2325`: create subscriptions in 2 currencies, mark renewed (on time and
   late), verify detail history, Stats spending section, per-currency totals, Home digest,
   notification action; export/import round-trip; verify `versionCode` bump if shipped.

## Out of scope

- Budget caps / overspend alerts (natural follow-on once history exists).
- Exchange rates or currency conversion.
- Editing or deleting individual payment records (append-only).
- Auto-backfill of past renewals.
- Any network call (unchanged: zero network, AGENTS.md §15).
