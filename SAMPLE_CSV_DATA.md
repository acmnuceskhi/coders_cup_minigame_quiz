# Example CSV Files for Each Category

This file contains sample questions for each of the 5 competition categories. Copy and paste into separate CSV files for testing.

## Category 1: Web Development (webdev.csv)

```csv
What does HTML stand for?,Hypertext Markup Language,High Transfer Method Language,Hyper Tool Markup Language,Home Tool Markup Language,0
What is CSS primarily used for?,Styling web pages,Creating databases,Server-side logic,Image processing,0
Which JavaScript framework is maintained by Facebook?,React,Angular,Vue,Ember,0
What does the DOM stand for?,Document Object Model,Data Object Management,Digital Output Module,Dynamic Operation Method,0
Which HTTP method is used to retrieve data?,GET,POST,PUT,DELETE,0
What port does HTTP typically use?,80,443,8080,3000,0
Which HTML tag is used for creating hyperlinks?,<a>,<link>,<href>,<url>,0
What does JSON stand for?,JavaScript Object Notation,Java Standard Object Naming,JavaScript Ordered Numbers,Java Syntax Object Network,0
Which CSS property controls text size?,font-size,text-size,font-height,text-height,0
What is the latest version of HTML?,HTML5,HTML4,HTML6,XHTML,0
```

## Category 2: Mobile Development (mobile.csv)

```csv
Which language is primarily used for iOS development?,Swift,Java,Kotlin,Python,0
What is the official IDE for Android development?,Android Studio,Eclipse,Visual Studio,Xcode,0
Which framework allows cross-platform mobile development?,Flutter,Swift,Kotlin,Objective-C,1
What does SDK stand for?,Software Development Kit,System Design Kit,Software Debugging Kernel,System Deployment Kit,0
Which language does Flutter use?,Dart,JavaScript,Python,Ruby,0
What is the minimum Android API level for most modern apps?,21 (Lollipop),19 (KitKat),23 (Marshmallow),16 (Jelly Bean),0
Which company develops React Native?,Facebook (Meta),Google,Apple,Microsoft,0
What is the primary layout system in iOS?,Auto Layout,LinearLayout,GridLayout,FlexBox,0
Which file format is used for iOS app distribution?,IPA,APK,DMG,ZIP,0
What does APK stand for?,Android Package Kit,Application Program Kit,Android Program Kernel,Application Package Key,0
```

## Category 3: Algorithms & Data Structures (algorithms.csv)

```csv
What is the time complexity of binary search?,O(log n),O(n),O(n^2),O(1),0
Which data structure uses FIFO?,Queue,Stack,Tree,Graph,0
What is the time complexity of bubble sort in worst case?,O(n^2),O(n log n),O(n),O(log n),0
Which traversal visits the root node first in a binary tree?,Pre-order,In-order,Post-order,Level-order,0
What data structure is used for DFS?,Stack,Queue,Array,Linked List,0
Which sorting algorithm has the best average time complexity?,Merge Sort,Bubble Sort,Selection Sort,Insertion Sort,0
What is a linked list?,A linear collection of nodes,A hierarchical structure,A circular array,A hash table,0
Which data structure allows O(1) average lookup?,Hash Table,Binary Tree,Linked List,Array,0
What is recursion?,A function calling itself,A loop structure,A sorting method,A tree traversal,0
What does BFS stand for?,Breadth-First Search,Binary File System,Best-First Search,Backward Forward Search,0
```

## Category 4: Database Design (databases.csv)

```csv
What does SQL stand for?,Structured Query Language,Standard Question Language,System Query Logic,Sequential Query List,0
Which SQL command is used to retrieve data?,SELECT,INSERT,UPDATE,DELETE,0
What is a primary key?,A unique identifier for a record,A foreign reference,An index,A constraint,0
Which database is known as NoSQL?,MongoDB,MySQL,PostgreSQL,Oracle,0
What does CRUD stand for?,Create Read Update Delete,Calculate Read Upload Download,Copy Read Update Display,Create Retrieve Upload Download,0
Which normal form eliminates transitive dependencies?,3NF,1NF,2NF,4NF,0
What is an index in a database?,A structure to speed up queries,A backup copy,A data type,A constraint,0
Which SQL clause filters results?,WHERE,SELECT,FROM,ORDER BY,0
What is a foreign key?,A reference to another table's primary key,A unique identifier,An index,A data type,0
Which command creates a new database?,CREATE DATABASE,NEW DATABASE,MAKE DATABASE,ADD DATABASE,0
```

## Category 5: Cybersecurity (security.csv)

```csv
What does HTTPS stand for?,Hypertext Transfer Protocol Secure,High Transfer Protection System,Hypertext Transaction Protocol Safe,High Tech Protection Standard,0
Which port is commonly used for HTTPS?,443,80,22,21,0
What is encryption?,Converting data to coded form,Deleting sensitive data,Backing up files,Compressing data,0
What does VPN stand for?,Virtual Private Network,Very Private Network,Variable Protocol Network,Verified Protection Node,0
Which hashing algorithm is commonly used for passwords?,bcrypt,MD5,Base64,AES,0
What is two-factor authentication?,Using two methods to verify identity,Having two passwords,Using two devices,Encrypting data twice,0
What does SSL stand for?,Secure Sockets Layer,System Security Layer,Safe Server Link,Secure System Login,0
Which attack involves overwhelming a server with traffic?,DDoS,Phishing,SQL Injection,XSS,0
What is a firewall?,A security system that monitors network traffic,An antivirus program,A password manager,A backup system,0
What does XSS stand for?,Cross-Site Scripting,Extra System Security,Extended Server Service,External Site Scanning,0
```

## Using These Files

### Method 1: Copy to Spreadsheet
1. Copy the CSV content (without the triple backticks)
2. Paste into Google Sheets or Excel
3. Export as CSV

### Method 2: Create Text File
1. Create a new `.csv` file (e.g., `webdev.csv`)
2. Paste the content directly
3. Save with UTF-8 encoding

### Method 3: Use Provided Script (Optional)
```bash
# If you want to create all files at once
echo "question,option1,option2,option3,option4,correctIndex" > webdev.csv
# ... add content ...
```

## Important Notes

- **No header row** - Start directly with questions
- **Exactly 6 columns** per row
- **correctIndex** must be 0, 1, 2, or 3
- **No commas** in questions/options (or escape them properly)
- **Empty cells not allowed** - All 6 columns must have values

## Testing the Upload

1. Start with **one category** (e.g., webdev)
2. Upload the CSV
3. Check the preview to verify questions loaded correctly
4. Test taking a quiz with that category
5. Repeat for remaining categories

## Expanding Your Question Sets

After verifying the system works:
- Aim for **20-30 questions** per category minimum
- Mix difficulty levels
- Include practical, competition-relevant questions
- Test questions with colleagues before event day
- Keep questions concise (long questions may not fit on screen)

## Need More Questions?

Consider:
- Competition past papers
- Online quiz databases
- Course textbooks
- Professional certification practice tests
- Custom questions tailored to your event focus
