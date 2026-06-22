# AGENTS.md

## Product
This is a Kolej Attendance System for students, admins, fellows, wardens, and kolej staff.

## UI Direction
Use a mobile-first, ZUS-inspired soft brand commerce UI style:
- Primary color: deep ZUS-like blue
- Background: clean white and soft light gray
- Large rounded cards
- Soft shadows
- Friendly empty states
- Clear hierarchy
- Modern rounded sans-serif typography
- Minimal but warm interface
- Avoid overly corporate, default Bootstrap/admin-dashboard look

## Components
Refactor repeated UI into reusable components:
- AppShell
- BottomNavigation
- TopHeader
- StatCard
- AttendanceStatusCard
- TableView
- FilterBar
- SearchInput
- EmptyState
- Modal
- PrimaryButton
- SecondaryButton
- Badge
- Toast/Alert

## Table View Rules
All tables should be modern and readable:
- Use rounded container cards
- Sticky header if useful
- Clear row spacing
- Search and filter controls above table
- Status badges instead of raw text
- Responsive mobile layout: convert table rows into cards on small screens
- Actions should be grouped clearly
- Avoid dense spreadsheet-like UI

## Engineering Rules
- Do not rewrite business logic unless needed
- Preserve existing routes and APIs unless instructed
- Refactor incrementally
- Run lint/tests after changes
- Explain what changed after each task