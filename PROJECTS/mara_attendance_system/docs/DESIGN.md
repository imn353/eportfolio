# DESIGN.md

## 1. Design Direction

This project should follow a **Paperpillar-inspired, minimal, professional, mobile-first** design style.

The UI should feel:

- Clean
- Soft
- Modern
- Calm
- Professional
- Easy to understand
- Suitable for an academic / attendance management system

The design should prioritize clarity and usability over decoration.

This app is not a heavy enterprise dashboard. It should look like a simple, polished mobile web app that can also work well as an APK-friendly Flutter app.

---

## 2. Product UI Principle

The interface should help users complete attendance-related tasks quickly.

Main UX priority:

> Users should always know what screen they are on, what action they need to take, and what the current status of the data is.

Avoid confusing layouts, hidden actions, and overly complex screens.

---

## 3. Target Users

The UI should be understandable for:

- Lecturer
- Admin Staff
- Head of Program

Use simple academic/admin language. Avoid technical wording such as:

- database
- collection
- document ID
- API
- query
- backend error
- Firestore

Use user-facing terms instead:

- timetable
- session
- class
- attendance
- report
- student
- subject
- lecturer
- room
- status

---

## 4. Layout Rules

### General Layout

Use a simple vertical layout.

Preferred structure:

1. Page title
2. Short page description, if needed
3. Main content card/list
4. Primary action button
5. Secondary actions, if needed

Keep spacing comfortable. Do not make screens feel crowded.

### Mobile-first Rule

Design for mobile first.

The app should work well on phone-sized screens before desktop screens.

Avoid wide tables as the main UI on mobile. Use:

- cards
- list rows
- collapsible sections
- simple filters

Tables may be used on larger screens, but the mobile version should remain readable.

---

## 5. Visual Style

### Overall Style

Use:

- light background
- soft cards
- rounded corners
- clean spacing
- simple icons
- clear text hierarchy
- minimal shadows

Avoid:

- loud colors
- heavy gradients
- too many animations
- dense admin dashboards
- unnecessary charts
- complex sidebars for mobile

### Inspiration

The style can be inspired by Paperpillar-style interfaces:

- soft minimal layout
- modern SaaS-like cards
- clean spacing
- friendly but professional look

Do not copy any specific brand asset, illustration, or exact design.

---

## 6. Color Direction

Use a calm and professional color palette.

Recommended direction:

- Background: off-white or very light neutral
- Surface/card: white or near-white
- Primary accent: one consistent brand color
- Text: dark neutral
- Secondary text: muted gray
- Borders: light gray
- Success: green tone
- Warning: amber/yellow tone
- Error: red tone
- Info: blue tone

Do not use too many accent colors.

Status colors must always include text labels. Do not rely on color only.

Example:

Good:
- Present — green badge
- Late — amber badge
- Absent — red badge

Bad:
- Showing only a colored dot with no label

---

## 7. Typography Rules

Use clean and readable typography.

Text hierarchy:

- Page title: large and clear
- Section title: medium weight
- Body text: normal readable size
- Helper text: smaller, muted
- Error text: clear and visible

Avoid long paragraphs inside app screens.

Use short, direct UI copy.

---

## 8. Component Rules

### Cards

Use cards for grouped information such as:

- timetable session
- attendance summary
- student attendance record
- report summary
- pending approval item

Card should include only important information.

Do not overload one card with too many details.

### Buttons

Use clear button hierarchy:

- Primary button: main action
- Secondary button: optional action
- Danger button: destructive action

Examples:

- Submit Attendance
- Confirm Import
- Upload Schedule
- View Report
- Cancel
- Delete / Remove, only when necessary

Do not place too many primary buttons on one screen.

### Badges

Use badges for statuses.

Common badges:

- Present
- Late
- Absent
- MC
- CK
- Pending
- Approved
- Rejected
- Below 80%
- 80% or Above

Badges should be readable and not too decorative.

### Forms

Forms should be simple and guided.

Each input should have:

- label
- placeholder, if helpful
- validation message, if invalid
- helper text, if the field may confuse users

Avoid forms with too many fields on one screen.

For long forms, group fields into clear sections.

---

## 9. Screen Design Rules

### Login Screen

Purpose:

Allow authorized users to enter the system.

Design:

- Simple centered layout
- App name visible
- Email field
- Password field
- Login button
- Error message area

Avoid:

- too many graphics
- unnecessary onboarding
- complicated role selection unless required

---

### Dashboard Screen

Purpose:

Give users a quick overview and entry point to main tasks.

Show only useful summary cards.

Recommended sections:

- Today’s sessions
- Pending attendance
- Attendance summary
- Quick actions

Avoid:

- complex analytics
- too many charts
- large desktop-style dashboard

---

### Timetable Screen

Purpose:

Help lecturer/admin find the correct session.

Each session card should show:

- subject
- class group
- lecturer
- room
- day/date
- start time
- end time
- session status, if needed

Primary action:

- Take Attendance
- View Session

Empty state:

- No timetable sessions found.

---

### Session Detail Screen

Purpose:

Show one selected timetable session before attendance is taken.

Show:

- subject
- class group
- lecturer
- room
- date
- time
- attendance status
- student count

Primary action:

- Take Attendance
- View Attendance Record, if already submitted

---

### Take Attendance Screen

Purpose:

Allow lecturer to mark student attendance for one session.

Each student row/card should show:

- student name
- student ID, if available
- attendance status selector

Allowed statuses:

- Present
- Late
- Absent
- MC
- CK

Important rule:

Late counts as attended for attendance percentage.

Primary action:

- Submit Attendance

Before submit:

- Show confirmation if needed
- Make sure unmarked students are handled clearly

After submit:

- Show success confirmation

---

### Report Screen

Purpose:

Show basic attendance summary.

Recommended sections:

- class/session summary
- student attendance percentage
- attendance status counts
- below 80% indicator

Avoid:

- advanced analytics
- unnecessary charts
- complicated filtering for P0

---

### Upload / Schedule Input Screen

Purpose:

Allow admin to upload or prepare timetable data.

Show:

- upload area
- file requirements
- accepted format
- template guide link/button
- validation result

Do not save imported data silently.

Use review step before confirmation if upload/import is implemented.

---

## 10. UI State Rules

Every important screen should define these states:

### Loading State

Use:

- loading spinner
- skeleton card
- disabled button
- clear loading text

Example copy:

- Loading timetable...
- Uploading file...
- Saving attendance...

### Empty State

Empty states should guide the user to the next action.

Example copy:

- No timetable sessions found.
- No attendance records yet.
- No pending approvals.
- Upload a schedule to begin.

### Error State

Error messages should be simple and actionable.

Good:

- Unable to load timetable. Please try again.
- This file is missing required columns.
- Attendance could not be submitted. Please check your connection.

Bad:

- Firebase permission denied.
- Null value exception.
- Query failed.

### Success State

Success messages should confirm what happened.

Example copy:

- Attendance submitted successfully.
- Schedule uploaded successfully.
- Report generated successfully.
- Changes saved.

---

## 11. Validation Rules

Forms should validate before submission.

Common validation:

- Required fields cannot be empty
- Start time must be before or equal to end time rule where applicable
- Selected time slots must be valid
- Attendance status must be selected
- Upload file must be correct type
- Required Excel columns must exist
- Invalid module/subject names should be shown clearly

Validation messages should appear near the related field.

Do not show only a generic error if the exact issue is known.

---

## 12. Attendance Status UX Rules

Attendance statuses must be consistent across the app.

Use the same labels everywhere:

- Present
- Late
- Absent
- MC
- CK

For percentage calculation display:

- Present counts as attended
- Late counts as attended
- Absent does not count as attended
- MC / CK handling should follow the approved product rule

If a student is below the required attendance threshold, show it clearly:

- Below 80%
- At Risk
- Attendance below requirement

If a student meets the threshold:

- 80% or Above
- Eligible
- Meets attendance requirement

---

## 13. Navigation Rules

Navigation should be simple.

Recommended bottom/navigation items for mobile:

- Dashboard
- Timetable
- Attendance
- Reports
- Settings/Profile, if needed

Do not create too many navigation tabs.

For P0, only include navigation items that are actually implemented.

---

## 14. Copywriting Rules

Use clear and direct UI copy.

Preferred:

- Upload Schedule
- Take Attendance
- Submit Attendance
- View Report
- Confirm Import
- No records found
- Please check the file format

Avoid:

- Execute
- Commit transaction
- Sync document
- Fetch collection
- Process entity
- Invalid payload

The app should speak like a practical admin tool, not like backend logs.

---

## 15. Accessibility Rules

The UI should be readable and usable.

Basic rules:

- Text must have enough contrast
- Buttons must be easy to tap
- Do not use color alone to communicate status
- Use clear labels
- Keep font sizes readable
- Avoid tiny icons without text
- Important actions should be reachable on mobile

---

## 16. AI Agent Instructions

When generating UI for this project, AI agents must follow these rules:

1. Use mobile-first layout.
2. Use clean card-based UI.
3. Keep the interface minimal and professional.
4. Do not create complex dashboards unless requested.
5. Do not add unnecessary screens.
6. Do not invent new attendance statuses.
7. Do not use technical backend terms in user-facing UI.
8. Do not rely only on colors for status.
9. Do not create wide mobile tables as the main layout.
10. Do not add role/auth complexity unless requested.
11. Keep P0 screens simple and usable.
12. Follow the approved product scope and do not expand features without instruction.

---

## 17. P0 Design Priority

For P0, prioritize these screens:

1. Dashboard
2. Timetable list
3. Session detail
4. Take attendance
5. Basic report
6. Schedule input/upload, if included in the current task

Do not spend time polishing P1/P2 screens before the P0 flow is usable.

P0 success means:

> A user can go from timetable session to attendance submission to basic attendance report with a clear and consistent UI.

---

## 18. Out of Scope for Design Unless Requested

Do not design these unless specifically assigned:

- advanced analytics dashboard
- complex chart system
- notification center
- full discipline case workflow
- replacement class booking approval flow
- multi-campus management
- AI insights
- advanced role permission management
- highly customized admin settings

---

## 19. Design Review Checklist

Before accepting any generated UI, check:

- Is it mobile-first?
- Is the page purpose clear?
- Is the main action obvious?
- Are statuses consistent?
- Are error messages understandable?
- Are empty states helpful?
- Does it avoid unnecessary complexity?
- Does it follow the Paperpillar-inspired minimal professional style?
- Does it avoid backend/technical language?
- Does it support the P0 attendance flow?

---

## 20. Final Design Rule

When unsure, choose:

- simpler layout
- fewer actions
- clearer wording
- card-based mobile UI
- consistent status labels
- practical academic/admin workflow

Do not make the UI fancy at the cost of clarity.