# Quick Start Guide - Multiple Quiz Categories

## What's New?
Your quiz app now supports **5 separate question sets** (one per competition category). Users select their category after entering their code, but all scores go to the same leaderboard.

## Quick Setup (5 Steps)

### 1. Launch Admin Interface
- Open the quiz app
- Click the **person icon** (top right)
- Sign in with admin credentials

### 2. Create Your 5 Categories
- Go to **Admin: Quiz Questions** page
- Click **category icon** (top right app bar)
- For each category, fill in:
  - **ID:** `webdev`, `mobile`, `algorithms`, etc. (lowercase, no spaces)
  - **Name:** Web Development, Mobile Development, etc.
  - **Description:** Short description (optional)
- Click **Add Category**

### 3. Prepare CSV Files
Create 5 CSV files (one per category):

```csv
What is HTML?,Hypertext Markup Language,High Transfer Method,Hyper Tool,Home Tool,0
What does CSS stand for?,Cascading Style Sheets,Computer Style Sheets,Creative Style,Code Sheets,0
```

Format: `question,option1,option2,option3,option4,correctIndex` (0-3)

### 4. Upload Questions
For **each category**:
- Select category from dropdown
- Click **Import CSV for Selected Category**
- Choose your CSV file
- Review upload results (uploaded vs skipped)
- Fix any validation errors and re-upload if needed

### 5. Test It Out
- Create a test code in your registration system
- Go to user home page
- Enter code → Select category → Take quiz
- Verify score saves correctly

## What Gets Validated?

✅ **Auto-skipped:**
- Empty rows
- Missing columns (need all 6)
- Empty questions or options
- Invalid answer index (not 0-3)

✅ **You'll see:**
- "X uploaded, Y skipped" message
- Detailed list of what was skipped and why
- Live preview of uploaded questions

## Key Files Modified

- [admin_questions_page.dart](coders_cup_minigame_quiz/lib/src/pages/admin_questions_page.dart) - Category selector + validation
- [category_selection_page.dart](coders_cup_minigame_quiz/lib/src/pages/category_selection_page.dart) - New category picker
- [user_home.dart](coders_cup_minigame_quiz/lib/src/pages/user_home.dart) - Routes to category selection
- [quiz_page.dart](coders_cup_minigame_quiz/lib/src/pages/quiz_page.dart) - Loads category-specific questions
- [category.dart](coders_cup_minigame_quiz/lib/src/models/category.dart) - Category data model

## Firestore Paths

```
quiz/meta/categories/{id}           → Category definitions
quiz/meta/questions_{id}/*          → Questions per category
games/{gameId}/responses/{code}     → Scores (now includes category)
```

## Need Help?

See detailed guides:
- [SETUP_CATEGORIES.md](coders_cup_minigame_quiz/SETUP_CATEGORIES.md) - Full setup instructions
- [TECHNICAL_CHANGES.md](coders_cup_minigame_quiz/TECHNICAL_CHANGES.md) - Technical details

## Example Category Setup

| ID | Name | Description |
|---|---|---|
| `webdev` | Web Development | HTML, CSS, JavaScript, frameworks |
| `mobile` | Mobile Development | iOS, Android, cross-platform |
| `algorithms` | Algorithms & DS | Problem solving, data structures |
| `databases` | Database Design | SQL, NoSQL, data modeling |
| `security` | Cybersecurity | Security principles, best practices |

---

**Important:** 
- Categories must be created **before** uploading questions
- Each registration code can only be used once (per usual)
- No changes to scoring formula or leaderboard display
- All categories share the same leaderboard
