# Design System: Midnight Navy + Sapphire Blue

> Design direction for a premium subscription and recurring-expense tracker.
> Core feeling: trustworthy, composed, modern, precise, and quietly premium.

## 1. Design principles

- **Trust before decoration:** financial information must be easy to scan and understand.
- **Purposeful colour:** use the brand accent for primary actions and focus, and semantic colours only for statuses.
- **Depth through surfaces:** distinguish layers with restrained shifts in navy, subtle borders, and limited elevation.
- **Consistent rhythm:** use a shared spacing scale, type scale, corner-radius scale, and component heights.
- **Mobile-first:** respect safe areas, keyboard insets, scrolling, and touch-target sizes.
- **Motion with restraint:** animations should clarify state changes, not slow the user down.

## 2. Colour palette

### Dark theme (primary)

| Token | Hex | Usage |
|---|---|---|
| `background` | `#0B1220` | Main app background |
| `surface` | `#151F30` | Cards, sheets, grouped content |
| `surfaceElevated` | `#1B2940` | Menus, dialogs, elevated cards |
| `surfacePressed` | `#22334D` | Pressed/selected surface states |
| `primary` | `#648CFF` | Main CTA, selected navigation, links, focused controls |
| `primaryPressed` | `#5278E8` | Pressed primary actions |
| `primaryTint` | `#192B50` | Subtle selected backgrounds |
| `textPrimary` | `#E8EEFA` | Headlines and primary content |
| `textSecondary` | `#A7B4C9` | Supporting text and metadata |
| `textMuted` | `#7F8DA5` | Low-emphasis labels, placeholders |
| `border` | `#2B3950` | Dividers and restrained outlines |
| `success` | `#42B883` | Successful payments and positive states |
| `warning` | `#F0B85A` | Upcoming renewals and reminders |
| `error` | `#F16C76` | Failed payments, overdue states, destructive actions |
| `info` | `#79B5FF` | Informational messages |
| `onPrimary` | `#081225` | Text/icons on primary blue buttons |

### Colour usage rules

- Use sapphire blue for the main CTA, active navigation, focused inputs, and selected items.
- Use emerald, amber, and coral for semantic status only. Do not use them as competing brand colours.
- Keep most surfaces neutral navy. Avoid large saturated gradients, neon glows, and bright borders around every card.
- Preserve third-party subscription logos in their authentic brand colours.
- Never communicate a status by colour alone. Pair colour with a label and/or icon.
- Check contrast for text, icons, and interactive states. If a token combination fails accessibility checks, adjust the token rather than reducing legibility.

## 3. Optional light theme

If the app already supports light mode, map the same tokens to a light palette rather than forcing dark mode.

| Token | Hex | Usage |
|---|---|---|
| `background` | `#F4F6FA` | Main app background |
| `surface` | `#FFFFFF` | Cards and sheets |
| `surfaceElevated` | `#FFFFFF` | Menus and dialogs |
| `surfacePressed` | `#E9EEFA` | Pressed/selected surfaces |
| `primary` | `#315FEA` | Primary actions and active states |
| `primaryPressed` | `#254DCA` | Pressed primary actions |
| `primaryTint` | `#E8EEFF` | Selected backgrounds |
| `textPrimary` | `#172033` | Headlines and main text |
| `textSecondary` | `#56647A` | Supporting text |
| `textMuted` | `#69778D` | Placeholders and low-emphasis text |
| `border` | `#DCE3EE` | Dividers and outlines |
| `success` | `#18794E` | Successful/positive states |
| `warning` | `#946200` | Renewal reminders |
| `error` | `#C53D4B` | Failed/overdue states |
| `info` | `#245FC7` | Informational messages |
| `onPrimary` | `#FFFFFF` | Text/icons on primary buttons |

## 4. Typography

- Use the platform's existing readable sans-serif font unless the project already has a defined typeface.
- Screen title: 26–30sp, medium or semibold.
- Section heading: 18–20sp, semibold.
- Card title: 15–17sp, medium or semibold.
- Body: 14–16sp, regular.
- Supporting labels: 12–14sp, regular.
- Numeric values and prices should use tabular numerals when supported.
- Avoid excessive all-caps, tiny labels, and unnecessarily light font weights.
- Keep labels on one line where possible; allow wrapping only where it is intentional and readable.

## 5. Spacing, shape, and elevation

Use a consistent 4dp-based spacing scale:

- `4dp`: tiny icon/text gap
- `8dp`: compact internal gap
- `12dp`: related controls
- `16dp`: standard component padding
- `20dp`: card padding / section spacing
- `24dp`: major section spacing
- `32dp`: screen-level separation

Shape guidelines:

- Small controls: 10–12dp radius.
- Inputs and standard buttons: 14–16dp radius.
- Cards and bottom sheets: 18–24dp radius.
- Pill controls: use full rounding only for genuinely pill-shaped controls.
- Borders: 1dp, low contrast.
- Use subtle elevation only for floating sheets, dialogs, and important overlays. Do not give every card a heavy shadow.

## 6. Component guidance

### Primary button
- Sapphire blue fill, high-contrast text/icon, 52–56dp minimum height.
- 14–16dp corner radius.
- Clear pressed, disabled, and loading states.
- One primary action per screen section. Avoid duplicate floating and inline Add Subscription buttons.

### Inputs
- Consistent heights, padding, icon alignment, border radius, and label treatment.
- Focused state uses a visible sapphire border or tint.
- Error state uses coral plus clear error text.
- Maintain sufficient contrast for placeholder text.
- Keep Price and Currency controls aligned to the same height.

### Subscription service picker
- Open as a rounded modal bottom sheet or dropdown appropriate to the platform.
- Include a search field and a curated list/grid of common services.
- Show service logo, service name, and optional category with consistent alignment.
- Use authentic logos from existing assets or reliable brand assets. If a logo is unavailable, use a neutral fallback icon; do not use random emoji as brand logos.
- Preserve third-party logo colours.
- Selecting a predefined service fills the name field but must not invent or force a price, currency, billing interval, or renewal date.
- Include an **Other** option. Selecting it reveals a manual name field.
- Validate custom names as non-empty and save the typed name, never the literal word `Other`.
- Keep the custom name when the user edits other fields.
- Make search filtering immediate and show a useful no-results state.

### Billing-cycle segmented control
- Options: Weekly, Monthly, Quarterly, Yearly.
- Keep every label on one line at supported screen widths.
- Use equal-width segments, compact horizontal padding, and a sensible minimum text size.
- Use horizontal scrolling only as a fallback on exceptionally narrow screens; do not clip text.
- Provide a clear selected state using a primary tint and a checkmark or equivalent indicator.
- Ensure selection remains accessible to screen readers.

### Renewal date and reminders
- Align icon, title, date, and trailing affordance on a consistent baseline.
- Make the upcoming renewal preview visually distinct but not overly bright.
- Use amber for reminders that need attention, paired with explicit text.
- Ensure reminder controls have comfortable touch targets.

### Status selector
- Keep all options visible and accessible through scrolling.
- Pair each status with a text label and a clear selected state.
- Do not let the system navigation bar obscure the last control or save action.

### Bottom navigation
- Use consistent icon size, label baseline, item width, and selected-state treatment.
- Avoid awkward label wrapping. For long labels, use a shorter label such as `Subs` only if necessary and consistent with product language.
- Respect device navigation insets and keep content clear of the navigation bar.
- Ensure there is exactly one Add Subscription action on the subscriptions screen.

### Empty state
- Keep the icon, heading, explanatory text, and CTA grouped with balanced vertical spacing.
- Use a modest illustration or icon; avoid oversized decorative graphics.
- On small screens, let the content scroll rather than collide with navigation.

## 7. Motion and interaction

- Typical transitions: 150–250ms.
- Prefer standard platform easing or an ease-out curve.
- Picker: subtle fade and upward movement when opening; reverse when closing.
- Selection: animate background/border colour and show a small check indicator.
- `Other`: reveal the manual field with a short fade/size transition.
- Buttons: restrained pressed-state feedback.
- Expand/collapse: animate layout changes without shifting unrelated content unexpectedly.
- Respect reduced-motion settings where supported.
- Never delay essential actions for animation.

## 8. Responsive layout and accessibility

- Design mobile-first and test the smallest supported viewport.
- Respect status-bar, gesture-navigation, and bottom-navigation insets.
- Ensure forms scroll when the keyboard is open.
- Avoid fixed heights for sections containing variable text or controls.
- Prevent horizontal overflow, clipped text, and overlapping buttons.
- Use touch targets of approximately 48dp where practical.
- Provide accessible labels and logical focus order.
- Do not rely on colour alone to convey selection, warning, success, or error.
- Test text scaling and long service names.

## 9. Screen-level direction

### Subscriptions screen
- Use a navy canvas with clearly grouped subscription cards.
- Establish hierarchy: service/logo and name, price and billing period, next renewal, then status/reminder.
- Keep the empty state centered within the usable content area.
- Show exactly one prominent `Add subscription` action.
- Keep the bottom navigation visually quiet and readable.

### New Subscription screen
- Keep the form single-column where possible.
- Place service selection first, followed by price/currency, billing cycle, renewal date, reminders, and status.
- Use consistent field heights and aligned labels/icons.
- Keep the renewal preview compact and readable.
- Ensure the save action and final fields remain reachable with scrolling and the keyboard open.

## 10. Implementation checklist

- [ ] Inspect the existing framework, theme setup, reusable components, and navigation before editing.
- [ ] Implement colour tokens centrally rather than scattering hex values across screens.
- [ ] Apply the palette consistently to both screens and all interactive states.
- [ ] Remove the duplicate Add Subscription action.
- [ ] Fix bottom navigation label wrapping and insets.
- [ ] Fix billing-cycle label wrapping.
- [ ] Align Price and Currency controls.
- [ ] Implement searchable service selection with logos and a working manual `Other` option.
- [ ] Preserve current persistence, validation, and subscription functionality.
- [ ] Verify scrolling and keyboard behavior on small screens.
- [ ] Check contrast, touch targets, text scaling, and accessibility.
- [ ] Run the project's build and available tests; resolve regressions.
- [ ] Report the files changed and what was actually verified.

## 11. Non-goals

- Do not rebuild unrelated parts of the app.
- Do not add decorative gradients, neon glows, or animations everywhere.
- Do not invent subscription prices or billing details.
- Do not replace authentic service logos with emoji.
- Do not make arbitrary margin changes to conceal a broken layout.
- Do not claim tests passed unless they were actually run.

**Overall target:** a calm, premium, trustworthy subscription manager with Midnight Navy surfaces, Sapphire Blue actions, clear financial hierarchy, and subtle motion.
