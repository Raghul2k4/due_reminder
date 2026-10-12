# Upgrade the Subscription UI: Premium Design + Alignment Fixes

Inspect the existing codebase and redesign the **Subscriptions screen** and **New Subscription screen** to feel like a polished, premium financial management app. Preserve all existing functionality, data models, navigation, and business logic.

## 1. Subscription Picker With Logos

Replace the plain subscription Name text field with a searchable dropdown or selection sheet for common subscription services.

Include recognizable services such as:
- Netflix
- Spotify
- YouTube Premium
- Amazon Prime
- Disney+
- Apple Music
- ChatGPT Plus
- Google One
- Microsoft 365
- PlayStation Plus
- Xbox Game Pass
- Adobe Creative Cloud
- Gym membership
- Internet / Wi-Fi
- Mobile recharge
- Other

### Dropdown design
- Display each service with its recognizable logo or brand icon, name, and optional category.
- Use a clean, vertically scrolling list with consistent icon sizes, spacing, and alignment.
- Include a search field at the top to filter services instantly.
- Use actual brand assets from reliable sources or existing project assets where possible. Do not substitute random emoji for recognizable logos.
- Handle missing logos gracefully with a clean fallback icon.
- Match the existing dark theme and mint/teal accent palette.
- Make the dropdown or bottom sheet responsive and easy to use on mobile.

### Other option: Manual entry
When the user selects **Other**, reveal a custom subscription name input.

- Let the user type any service name manually.
- Validate that the name is not empty.
- Preserve the manually entered name when the user edits other form fields.
- Ensure custom subscriptions save and display exactly like predefined subscriptions.
- If the user selects a predefined service again, restore the standard selection flow.
- Do not save the literal word "Other" as the subscription name.

Selecting a predefined service should automatically populate its name. If practical, support sensible default categories or logos without forcing the user to accept incorrect pricing or billing details.

## 2. Subscriptions Screen Alignment

- Remove the duplicate "Add subscription" buttons. Display exactly one primary action.
- Position the action button consistently without overlapping the bottom navigation.
- Fix the bottom navigation labels so "Subscriptions" does not wrap awkwardly.
- Correct the vertical alignment and spacing of the empty-state icon, title, description, and CTA.
- Keep the empty state visually balanced on different screen sizes.
- Maintain consistent margins and safe-area insets.

## 3. New Subscription Form

### Billing cycle selector
Fix the segmented control containing Weekly, Monthly, Quarterly, and Yearly.

- Keep every label on a single line.
- Distribute the four options evenly across the available width.
- Adjust padding, text constraints, and font sizes appropriately.
- Provide a clearly visible selected state.
- Avoid text clipping and awkward line breaks.

### Price and currency
- Align the Price input and Currency selector cleanly.
- Use consistent heights, corner radii, borders, and internal padding.
- Prevent text and icons from appearing vertically misaligned.

### Renewal date and reminders
- Align the renewal date icon, title, date, and trailing arrow.
- Make the upcoming renewal preview readable and visually consistent.
- Keep reminder controls aligned and accessible.
- Ensure reminder lead-time selection is not clipped.

### Form scrolling
- Make the entire form scrollable when the available screen height is insufficient.
- Ensure the Status section and save action remain accessible.
- Respect status bar, bottom navigation, keyboard, and system navigation insets.
- Avoid fixed heights that hide content.

## 4. Premium Visual Design

Elevate the existing interface without making it visually noisy.

- Preserve the dark background and mint/teal accent colors.
- Use consistent typography, font weights, spacing, and corner radii.
- Add subtle tonal contrast between cards, inputs, and the background.
- Use restrained elevation or shadows where appropriate.
- Give the subscription picker a refined selected state with a subtle accent border or background.
- Use polished empty-state illustrations or icons.
- Maintain clear visual hierarchy and comfortable touch targets.
- Avoid excessive gradients, oversized buttons, unnecessary borders, or decorative elements that reduce readability.

## 5. Small Animational Touches

Add restrained, smooth micro-interactions to make the app feel responsive and premium.

- Animate the subscription dropdown or bottom sheet when opening and closing.
- Use a subtle fade or scale transition when revealing the manual name input for Other.
- Animate selection changes with a short color transition.
- Add a subtle checkmark or selection indicator when choosing a service.
- Use gentle transitions for expanding and collapsing form sections.
- Provide light press feedback on interactive elements.
- Keep animations short, smooth, and purposeful, generally around 150–250 ms.
- Respect reduced-motion preferences when supported.
- Avoid distracting bouncing, excessive motion, and animations that delay interaction.

## 6. Responsive Design and Implementation

- Inspect the existing architecture and UI framework before modifying anything.
- Reuse existing components and design tokens where possible.
- Follow the project's established patterns, whether Jetpack Compose, Flutter, or another framework.
- Avoid arbitrary margin changes that hide underlying layout problems.
- Prevent duplicate buttons, overflow, overlapping elements, and clipped content.
- Preserve existing database schemas and subscription creation/editing functionality unless a change is genuinely necessary.
- Keep service selection, manual entry, validation, and saving behavior consistent.
- Handle loading states, empty results, and missing brand assets gracefully.

## 7. Acceptance Tests

Verify the following before considering the work complete:

1. The subscription list contains only one Add Subscription action.
2. All bottom navigation labels display correctly.
3. Every billing cycle label fits on one line.
4. The subscription picker displays service logos and supports searching.
5. Selecting a predefined service fills the subscription name.
6. Selecting Other reveals a working manual text input.
7. Empty custom names cannot be saved.
8. Custom subscription names persist correctly after saving and reopening.
9. The price, currency, renewal date, reminder, and status controls remain aligned.
10. The complete form is accessible on smaller screens and when the keyboard is open.
11. Animations are subtle, smooth, and do not interfere with input.
12. Existing subscription functionality continues to work.

Implement the changes directly in the existing project. Run the available build and tests, fix any regressions, and report which files were modified and what was verified. Do not merely provide suggestions or mockups.