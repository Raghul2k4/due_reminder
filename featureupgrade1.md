# Feature Upgrade: Subscription Reminder Manager

Enhance my existing reminder app by adding a **Subscription Reminder Manager**. This should be a small, well-integrated upgrade that reuses the existing app architecture, UI components, local storage, and notification system wherever possible.

## 1. Subscription Management
Allow users to create and manage subscriptions with the following fields:
- Subscription name (e.g., Netflix, Spotify, YouTube Premium, gym membership).
- Subscription price and currency.
- Billing cycle: weekly, monthly, quarterly, or yearly.
- Next renewal date.
- Optional renewal reminder.
- Reminder lead time: on the renewal date, 1 day, 3 days, or 7 days before renewal.
- Optional notes.
- Status: Active, Paused, or Cancelled.

Users must be able to add, edit, view, pause, and cancel subscriptions.

## 2. Subscription Dashboard
Create a dedicated Subscription screen that matches the existing app's dark theme, mint-green accents, typography, and component styling.

Display:
- Total estimated monthly subscription spending.
- Total estimated yearly subscription spending.
- Upcoming renewals.
- Subscription name, price, billing cycle, and next renewal date.
- Clear indicators for subscriptions renewing soon.

Include an intuitive button to add a new subscription.

Calculate monthly and yearly estimates correctly for all supported billing cycles. Only include active subscriptions in spending totals.

## 3. Notifications and Reminders
Integrate subscription alerts with the existing notification system.

Requirements:
- Schedule notifications based on the user's selected reminder lead time.
- Support recurring renewal notifications according to the billing cycle.
- Reschedule notifications when the renewal date or reminder settings change.
- Cancel scheduled notifications when a subscription is paused or cancelled.
- Prevent duplicate notifications.
- Handle notification permissions and scheduling failures gracefully.
- Ensure notification scheduling is compatible with the existing app's Android lifecycle and persistence approach.

Do not create a separate notification engine if the existing one can support this functionality.

## 4. Integration With Existing Features
- Reuse the existing data storage and architectural patterns.
- Keep subscription data persistent across app restarts.
- Add appropriate navigation to the new Subscription screen without overcrowding the existing bottom navigation.
- If practical, allow subscription renewals to appear in the existing calendar and search screens.
- Keep subscription reminders separate from ordinary reminders where appropriate, while allowing them to share common functionality.
- Preserve all existing reminder functionality.

## 5. UI/UX Requirements
- Follow the current app design and dark theme.
- Use consistent spacing, typography, icons, buttons, and rounded corners.
- Include proper empty states, validation messages, loading states, and error handling.
- Confirm before destructive actions such as deleting subscription records.
- Make the interface responsive and accessible.

## 6. Technical Requirements
Before making changes, inspect the existing codebase to understand its architecture, data models, navigation, storage, and notification implementation.

Then:
1. Identify the minimum files and components that need modification.
2. Implement the feature using the existing technology and coding conventions.
3. Update database schemas or migrations if necessary.
4. Handle date calculations, recurring billing cycles, and month-end renewal dates safely.
5. Test adding, editing, pausing, cancelling, and renewing subscriptions.
6. Test notification scheduling, duplicate prevention, persistence, and edge cases.
7. Verify that existing reminders, calendar functionality, search, settings, and notifications continue working.

Do not rewrite working components or introduce unnecessary dependencies.

**Important:** This feature tracks subscriptions and reminds users about upcoming renewals. It must not claim to automatically cancel subscriptions with external providers.

## Expected Result
A fully integrated Subscription Reminder Manager that lets users track recurring expenses, see upcoming renewals, estimate monthly and yearly costs, and receive timely renewal notifications, while preserving the existing app's functionality and visual identity.