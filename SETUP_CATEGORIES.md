# Quiz Category Setup Guide

This guide explains how to set up and manage multiple quiz categories for your competition event.

## Overview

The quiz app now supports multiple question sets (categories), allowing you to showcase different quizzes for each competition category at your booth. All categories share a unified leaderboard and scoring system.

## Changes Made

### 1. **Category Management System**
- Categories are stored in Firestore at: `quiz/meta/categories/{categoryId}`
- Each category has: `id`, `name`, `description` (optional)
- Admin interface includes a "Manage Categories" page (accessible via the category icon in the app bar)

### 2. **Category-Specific Question Storage**
- Questions are now stored in separate subcollections per category
- Path format: `quiz/meta/questions_{categoryId}`
- Example: `quiz/meta/questions_webdev`, `quiz/meta/questions_mobile`, etc.

### 3. **User Flow**
1. User enters registration code
2. User selects quiz category from available options
3. Quiz loads 10 random questions from the selected category
4. Score is saved with category information

### 4. **CSV Upload with Validation**
- Admin uploads one CSV per category
- Invalid rows are automatically skipped with detailed feedback
- Validation checks:
  - All 6 columns present (question + 4 options + correctIndex)
  - Non-empty question and options
  - Valid correctIndex (0-3)
  - Proper formatting

### 5. **Score Tracking**
- Each response now includes:
  - `category`: Category ID
  - `categoryName`: Display name
  - `score`: Composite score (existing)
  - Other metrics (timeTakenSeconds, correctRate, rawCorrect)

## Setup Instructions

### Step 1: Create Categories

1. Launch the admin interface (click the person icon on the home screen)
2. Log in with Firebase Auth credentials
3. Navigate to "Admin: Quiz Questions"
4. Click the category icon (top-right) to open "Manage Categories"

5. Add each of your 5 competition categories:

   **Example Categories:**
   - **ID:** `webdev` | **Name:** Web Development | **Description:** HTML, CSS, JavaScript, and frameworks
   - **ID:** `mobile` | **Name:** Mobile Development | **Description:** iOS, Android, React Native, Flutter
   - **ID:** `algorithms` | **Name:** Algorithms & Data Structures | **Description:** Problem solving and computational thinking
   - **ID:** `databases` | **Name:** Database Design | **Description:** SQL, NoSQL, data modeling
   - **ID:** `security` | **Name:** Cybersecurity | **Description:** Security principles and best practices

   **Important:** 
   - Use lowercase IDs with no spaces (use hyphens or underscores)
   - IDs cannot be changed after creation
   - Names and descriptions can be updated in Firestore console if needed

### Step 2: Prepare CSV Files

Create one CSV file for each category with this format:

```csv
What is HTML?,Hypertext Markup Language,High Transfer Method Language,Hyper Tool Markup Language,Home Tool Markup Language,0
What is CSS used for?,Styling web pages,Creating databases,Server-side logic,Image processing,0
```

**CSV Format Rules:**
- **Column 1:** Question text
- **Columns 2-5:** Four answer options
- **Column 6:** Correct answer index (0 = first option, 1 = second, 2 = third, 3 = fourth)
- **No header row**
- Questions can include LaTeX math notation (e.g., `$x^2$`)

**Validation (automatic):**
- Rows with missing data will be skipped
- Empty questions or options will be skipped
- Invalid correctIndex values will be skipped
- You'll see a summary after upload showing uploaded vs. skipped questions

### Step 3: Upload Questions

For each category:

1. Go to "Admin: Quiz Questions"
2. Select the category from the dropdown
3. Click "Import CSV for Selected Category"
4. Choose your prepared CSV file
5. Review the upload summary
6. If questions were skipped, click "OK" to see detailed error messages
7. Fix any issues in your CSV and re-upload if needed

**Pro Tips:**
- Test with 2-3 questions first to verify format
- Keep at least 15-20 questions per category for variety
- Use the preview section to verify questions loaded correctly

### Step 4: Test the Flow

1. Create a test registration code in your admin system (coders_cup_minigame_admin)
2. Go to the user home page
3. Enter the test code
4. Verify all 5 categories appear on the selection page
5. Select a category and take a short quiz
6. Confirm score is saved with category information

## Managing Questions

### View Questions by Category
- Select category from dropdown
- Preview shows all questions in that category
- Each question displays: number, question text, options, and correct answer

### Clear Questions
- Select the category
- Click "Clear All Questions in Category" (red button)
- Confirm the deletion
- This only removes questions, not the category itself

### Update Categories
- To rename: Go to Firebase Console → `quiz/meta/categories/{id}` → Edit `name` field
- To delete: Use "Manage Categories" page → Click delete icon
- Note: Deleting a category does NOT delete its questions

## Firestore Data Structure

```
quiz/
  meta/
    categories/
      webdev/
        name: "Web Development"
        description: "HTML, CSS, JavaScript, and frameworks"
      mobile/
        name: "Mobile Development"
        description: "iOS, Android, React Native, Flutter"
      ...
    questions_webdev/
      {documentId}/
        question: "What is HTML?"
        options: ["Hypertext Markup Language", "...", "...", "..."]
        correctIndex: 0
    questions_mobile/
      ...
```

```
games/
  {gameId}/
    name: "Tech Trivia"
    responses/
      {CODE}/
        score: 85.234
        category: "webdev"
        categoryName: "Web Development"
        timeTakenSeconds: 45.2
        correctRate: 0.8
        rawCorrect: 8
```

## Troubleshooting

### "No questions available in {category} yet"
- You haven't uploaded questions for that category yet
- Go to admin page, select the category, and upload a CSV

### CSV upload shows "0 uploaded, X skipped"
- Check CSV format (6 columns per row)
- Ensure correctIndex is 0-3
- Verify no empty cells
- Click to see detailed error messages for each skipped row

### Category doesn't appear in selection
- Verify category exists in Firestore: `quiz/meta/categories`
- Check Firebase console for any permission errors
- Ensure category has at least one question

### User already played message
- Each registration code can only be used once
- Score is already recorded in the database
- Create a new test code if needed

## Notes

- **No Question Limit:** Categories can have any number of questions (quiz will select up to 10 randomly)
- **Unified Leaderboard:** All scores go to the same leaderboard regardless of category
- **Score Formula:** `(correct × 10) + (10 / time_in_seconds)`
- **Backward Compatibility:** Old questions in `quiz/meta/questions` are not used anymore

## Support

For issues or questions:
1. Check Firebase Console for data integrity
2. Review browser console for JavaScript errors
3. Verify Firestore security rules allow reads/writes
4. Test with a simple category first before adding all 5
