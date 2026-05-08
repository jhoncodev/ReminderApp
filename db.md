# ReminderApp Database Schema

## Overview
Database schema for the ReminderApp - a Flutter application for managing reminders, activities, courses, and academic periods.

---

## Tables/Entities

### 1. **users**
Stores user account information for authentication.

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| id | INTEGER | PRIMARY KEY, AUTO_INCREMENT | Unique user identifier |
| email | VARCHAR(255) | NOT NULL, UNIQUE | User email address |
| password | VARCHAR(255) | NOT NULL | Hashed password |
| created_at | TIMESTAMP | DEFAULT CURRENT_TIMESTAMP | Account creation date |
| updated_at | TIMESTAMP | DEFAULT CURRENT_TIMESTAMP ON UPDATE | Last update date |

**Key Fields for Login:**
- email
- password

---

### 2. **academic_periods**
Manages academic periods/cycles (e.g., "Ciclo 2024-A").

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| id | INTEGER | PRIMARY KEY, AUTO_INCREMENT | Unique period identifier |
| user_id | INTEGER | NOT NULL, FOREIGN KEY | Reference to users table |
| name | VARCHAR(100) | NOT NULL | Period name (e.g., "Ciclo 2024-A") |
| start_date | DATE | NOT NULL | Period start date |
| end_date | DATE | NOT NULL | Period end date |
| created_at | TIMESTAMP | DEFAULT CURRENT_TIMESTAMP | Creation date |
| updated_at | TIMESTAMP | DEFAULT CURRENT_TIMESTAMP ON UPDATE | Last update date |

**Relationships:**
- Foreign Key: `user_id` → `users.id` (One user has many periods)

---

### 3. **courses**
Stores course/class information.

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| id | INTEGER | PRIMARY KEY, AUTO_INCREMENT | Unique course identifier |
| user_id | INTEGER | NOT NULL, FOREIGN KEY | Reference to users table |
| academic_period_id | INTEGER | NULLABLE, FOREIGN KEY | Reference to academic_periods table |
| name | VARCHAR(255) | NOT NULL | Course name (e.g., "Modern Architecture 101") |
| is_weekly_schedule_enabled | BOOLEAN | DEFAULT FALSE | Whether weekly schedule is enabled |
| created_at | TIMESTAMP | DEFAULT CURRENT_TIMESTAMP | Creation date |
| updated_at | TIMESTAMP | DEFAULT CURRENT_TIMESTAMP ON UPDATE | Last update date |

**Relationships:**
- Foreign Key: `user_id` → `users.id` (One user has many courses)
- Foreign Key: `academic_period_id` → `academic_periods.id` (One period has many courses)

---

### 4. **course_schedule_days**
Tracks which days of the week courses are scheduled (Monday through Sunday).

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| id | INTEGER | PRIMARY KEY, AUTO_INCREMENT | Unique identifier |
| course_id | INTEGER | NOT NULL, FOREIGN KEY | Reference to courses table |
| day_of_week | INTEGER | NOT NULL | Day number (0=Monday, 1=Tuesday, ... 6=Sunday) |
| day_name | VARCHAR(10) | NOT NULL | Day name abbreviation (L, M, M, J, V, S, D) |

**Relationships:**
- Foreign Key: `course_id` → `courses.id` (One course has many scheduled days)

---

### 5. **activities**
Stores activity/reminder information (e.g., workouts, meditations, etc.).

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| id | INTEGER | PRIMARY KEY, AUTO_INCREMENT | Unique activity identifier |
| user_id | INTEGER | NOT NULL, FOREIGN KEY | Reference to users table |
| name | VARCHAR(255) | NOT NULL | Activity name (e.g., "Morning Meditation") |
| notes | TEXT | NULLABLE | Additional details/notes |
| budget_amount | DECIMAL(10,2) | NULLABLE | Budget for the activity |
| frequency | VARCHAR(50) | DEFAULT "Una vez" | Frequency (e.g., "Una vez", "Diarios", "Semanales") |
| created_at | TIMESTAMP | DEFAULT CURRENT_TIMESTAMP | Creation date |
| updated_at | TIMESTAMP | DEFAULT CURRENT_TIMESTAMP ON UPDATE | Last update date |

**Relationships:**
- Foreign Key: `user_id` → `users.id` (One user has many activities)

---

### 6. **activity_schedule_days**
Tracks which days of the week activities are scheduled.

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| id | INTEGER | PRIMARY KEY, AUTO_INCREMENT | Unique identifier |
| activity_id | INTEGER | NOT NULL, FOREIGN KEY | Reference to activities table |
| day_of_week | INTEGER | NOT NULL | Day number (0=Monday, 1=Tuesday, ... 6=Sunday) |
| day_name | VARCHAR(10) | NOT NULL | Day name abbreviation (L, M, M, J, V, S, D) |

**Relationships:**
- Foreign Key: `activity_id` → `activities.id` (One activity has many scheduled days)

---

### 7. **reminders** (Optional - for future scheduling/notifications)
Stores scheduled reminders linked to activities or courses.

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| id | INTEGER | PRIMARY KEY, AUTO_INCREMENT | Unique reminder identifier |
| user_id | INTEGER | NOT NULL, FOREIGN KEY | Reference to users table |
| activity_id | INTEGER | NULLABLE, FOREIGN KEY | Reference to activities table |
| course_id | INTEGER | NULLABLE, FOREIGN KEY | Reference to courses table |
| scheduled_time | TIME | NOT NULL | Time for the reminder |
| scheduled_date | DATE | NOT NULL | Date for the reminder |
| is_completed | BOOLEAN | DEFAULT FALSE | Whether reminder was completed |
| created_at | TIMESTAMP | DEFAULT CURRENT_TIMESTAMP | Creation date |

**Relationships:**
- Foreign Key: `user_id` → `users.id`
- Foreign Key: `activity_id` → `activities.id`
- Foreign Key: `course_id` → `courses.id`

---

## Entity Relationship Diagram (ERD)

```
┌─────────────────┐
│     users       │
├─────────────────┤
│ id (PK)         │
│ email           │
│ password        │
│ created_at      │
│ updated_at      │
└────────┬────────┘
         │
         ├─────────────────────────────────────────┐
         │                                         │
         ▼                                         ▼
┌──────────────────────┐              ┌──────────────────────┐
│ academic_periods     │              │    activities        │
├──────────────────────┤              ├──────────────────────┤
│ id (PK)              │              │ id (PK)              │
│ user_id (FK)         │              │ user_id (FK)         │
│ name                 │              │ name                 │
│ start_date           │              │ notes                │
│ end_date             │              │ budget_amount        │
│ created_at           │              │ frequency            │
│ updated_at           │              │ created_at           │
└──────────┬───────────┘              │ updated_at           │
           │                          └──────────┬───────────┘
           │                                     │
           ▼                                     ▼
┌──────────────────────┐              ┌──────────────────────────┐
│      courses         │              │ activity_schedule_days   │
├──────────────────────┤              ├──────────────────────────┤
│ id (PK)              │              │ id (PK)                  │
│ user_id (FK)         │              │ activity_id (FK)         │
│ academic_period_id   │              │ day_of_week              │
│   (FK)               │              │ day_name                 │
│ name                 │              └──────────────────────────┘
│ is_weekly_schedule   │
│ created_at           │
│ updated_at           │
└──────────┬───────────┘
           │
           ▼
┌──────────────────────────┐
│ course_schedule_days     │
├──────────────────────────┤
│ id (PK)                  │
│ course_id (FK)           │
│ day_of_week              │
│ day_name                 │
└──────────────────────────┘
```

---

## Relationships Summary

| Parent Table | Child Table | Relationship | Description |
|---|---|---|---|
| users | academic_periods | 1:N | One user has many academic periods |
| users | courses | 1:N | One user has many courses |
| users | activities | 1:N | One user has many activities |
| users | reminders | 1:N | One user has many reminders |
| academic_periods | courses | 1:N | One period can have many courses |
| courses | course_schedule_days | 1:N | One course has many scheduled days |
| activities | activity_schedule_days | 1:N | One activity has many scheduled days |
| courses | reminders | 1:N | One course can have many reminders |
| activities | reminders | 1:N | One activity can have many reminders |

---

## Key Features per Entity

### Users
- Authentication (email/password)
- Account management
- Owns all other data entities

### Academic Periods
- Define academic cycles/semesters
- Associated with courses
- Date range validation needed

### Courses
- Course/class information
- Optional link to academic period
- Weekly schedule (days of week)
- Associated reminders for classes

### Activities
- Health/wellness/hobby activities
- Budget tracking
- Frequency management (once, daily, weekly, etc.)
- Multiple day scheduling

### Reminders (Optional)
- Scheduled notifications
- Linked to activities or courses
- Tracks completion status
- Flexible date/time scheduling

---

## Data Types Reference
- **INTEGER**: Whole numbers (IDs, counts)
- **VARCHAR(n)**: Variable-length text up to n characters
- **TEXT**: Longer text content (notes, descriptions)
- **DATE**: Date values (YYYY-MM-DD)
- **TIME**: Time values (HH:MM:SS)
- **TIMESTAMP**: Date and time with timezone
- **DECIMAL(10,2)**: Decimal numbers (10 digits total, 2 after decimal)
- **BOOLEAN**: True/False values

---

## Implementation Notes

1. **Authentication**: Currently hardcoded ("admin"/"admin123"), should be moved to database with hashed passwords
2. **Foreign Keys**: Enable cascade deletes for related records when appropriate
3. **Indexes**: Add indexes on frequently queried fields (user_id, course_id, activity_id)
4. **Audit Fields**: created_at and updated_at timestamps for data tracking
5. **Day Scheduling**: Days stored as 0-6 (Monday-Sunday) with abbreviations for display
6. **Flexibility**: Reminders table is optional - can be added when notification feature is implemented
