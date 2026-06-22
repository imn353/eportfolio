# Role Management Module

The Role Management module provides Administrators with a centralized dashboard to manage user access, assign administrative and teaching roles, and approve newly registered accounts.

> [!TIP]
> Only users with the **Admin** role can access the "Manage Users" page.

## Available System Roles

The system operates on a rigid role hierarchy. A user can only hold **one primary role** at any given time.

1. **Admin**: Has full system access. Can modify user roles, edit the timetable, and view all system data. Admins cannot be assigned teaching classes.
2. **Lecturer**: A standard teaching role. Can view their own timetable, mark attendance, and file discipline reports.
3. **HOD (Head of Department)**: A teaching role with elevated reporting access. Receives "First Warning" discipline reports.
4. **Head of Program (HOP)**: A teaching role with elevated reporting access. Receives "Second Warning" discipline reports.
5. **Deputy Academic Dean**: A teaching role with the highest reporting access. Receives "Third Warning" discipline reports.

## Workflows

### 1. Approving Lecturer Accounts
When a new staff member registers for an account, they may initially have a pending or default status.
1. Log in as an **Admin**.
2. Navigate to the **Manage Users** section via the sidebar.
3. Locate the newly registered user in the list.
4. Click on the user's status chip (e.g., Pending/Inactive) to toggle their account to **Active**. They will immediately be able to log in.

### 2. Assigning & Changing Roles
Roles dictate what the user sees in the sidebar and what discipline reports they receive.
1. In the **Manage Users** page, locate the desired user.
2. Click the **"Change Role"** button (or tap the user card on mobile).
3. A bottom sheet will present all available roles along with their descriptions.
4. Select the new role and confirm the change.

> [!WARNING]
> **Important Constraint**: If you change an active Lecturer/HOD/HOP/Dean to an **Admin**, they will lose the ability to be assigned teaching classes in the timetable, as Admins are strictly non-teaching personnel in the system structure. The system will warn you if this action affects existing timetables.
