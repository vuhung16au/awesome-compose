-- Sample data migration script for Moodle database
-- This script generates sample data for various Moodle tables

-- Clear existing data (if needed)
SET FOREIGN_KEY_CHECKS=0;
TRUNCATE TABLE mdl_user;
TRUNCATE TABLE mdl_course;
TRUNCATE TABLE mdl_user_enrolments;
TRUNCATE TABLE mdl_enrol;
TRUNCATE TABLE mdl_assign;
TRUNCATE TABLE mdl_assign_grades;
TRUNCATE TABLE mdl_forum;
TRUNCATE TABLE mdl_forum_posts;
TRUNCATE TABLE mdl_forum_discussions;
TRUNCATE TABLE mdl_comments;
TRUNCATE TABLE mdl_quiz;
TRUNCATE TABLE mdl_question;
TRUNCATE TABLE mdl_question_bank_entries;
SET FOREIGN_KEY_CHECKS=1;

-- Insert sample users
INSERT INTO mdl_user (id, username, password, firstname, lastname, email, confirmed, mnethostid, auth, timecreated, timemodified)
VALUES 
(100, 'student1', MD5('password'), 'John', 'Smith', 'student1@example.com', 1, 1, 'manual', UNIX_TIMESTAMP(), UNIX_TIMESTAMP()),
(101, 'student2', MD5('password'), 'Sarah', 'Johnson', 'student2@example.com', 1, 1, 'manual', UNIX_TIMESTAMP(), UNIX_TIMESTAMP()),
(102, 'student3', MD5('password'), 'Michael', 'Williams', 'student3@example.com', 1, 1, 'manual', UNIX_TIMESTAMP(), UNIX_TIMESTAMP()),
(103, 'teacher1', MD5('password'), 'Emma', 'Brown', 'teacher1@example.com', 1, 1, 'manual', UNIX_TIMESTAMP(), UNIX_TIMESTAMP()),
(104, 'teacher2', MD5('password'), 'David', 'Jones', 'teacher2@example.com', 1, 1, 'manual', UNIX_TIMESTAMP(), UNIX_TIMESTAMP()),
(105, 'admin1', MD5('password'), 'Admin', 'User', 'admin@example.com', 1, 1, 'manual', UNIX_TIMESTAMP(), UNIX_TIMESTAMP());

-- Insert sample courses
INSERT INTO mdl_course (id, category, fullname, shortname, summary, format, startdate, timecreated, timemodified)
VALUES 
(100, 1, 'Introduction to Computer Science', 'CS101', 'An introductory course to computer science fundamentals', 'topics', UNIX_TIMESTAMP(), UNIX_TIMESTAMP(), UNIX_TIMESTAMP()),
(101, 1, 'Web Development', 'WD200', 'Learn HTML, CSS and JavaScript', 'topics', UNIX_TIMESTAMP(), UNIX_TIMESTAMP(), UNIX_TIMESTAMP()),
(102, 2, 'Database Systems', 'DB301', 'Fundamentals of database design and SQL', 'topics', UNIX_TIMESTAMP(), UNIX_TIMESTAMP(), UNIX_TIMESTAMP()),
(103, 2, 'Machine Learning', 'ML400', 'Introduction to machine learning algorithms', 'topics', UNIX_TIMESTAMP(), UNIX_TIMESTAMP(), UNIX_TIMESTAMP());

-- Insert enrol methods
INSERT INTO mdl_enrol (id, enrol, status, courseid, sortorder, timecreated, timemodified)
VALUES
(100, 'manual', 0, 100, 0, UNIX_TIMESTAMP(), UNIX_TIMESTAMP()),
(101, 'manual', 0, 101, 0, UNIX_TIMESTAMP(), UNIX_TIMESTAMP()),
(102, 'manual', 0, 102, 0, UNIX_TIMESTAMP(), UNIX_TIMESTAMP()),
(103, 'manual', 0, 103, 0, UNIX_TIMESTAMP(), UNIX_TIMESTAMP());

-- Insert enrollments (connecting users to courses)
INSERT INTO mdl_user_enrolments (id, status, userid, enrolid, timestart, timeend, timecreated, timemodified)
VALUES 
(100, 0, 100, 100, UNIX_TIMESTAMP(), UNIX_TIMESTAMP()+31536000, UNIX_TIMESTAMP(), UNIX_TIMESTAMP()),
(101, 0, 101, 100, UNIX_TIMESTAMP(), UNIX_TIMESTAMP()+31536000, UNIX_TIMESTAMP(), UNIX_TIMESTAMP()),
(102, 0, 102, 100, UNIX_TIMESTAMP(), UNIX_TIMESTAMP()+31536000, UNIX_TIMESTAMP(), UNIX_TIMESTAMP()),
(103, 0, 100, 101, UNIX_TIMESTAMP(), UNIX_TIMESTAMP()+31536000, UNIX_TIMESTAMP(), UNIX_TIMESTAMP()),
(104, 0, 101, 101, UNIX_TIMESTAMP(), UNIX_TIMESTAMP()+31536000, UNIX_TIMESTAMP(), UNIX_TIMESTAMP()),
(105, 0, 103, 100, UNIX_TIMESTAMP(), UNIX_TIMESTAMP()+31536000, UNIX_TIMESTAMP(), UNIX_TIMESTAMP()),
(106, 0, 104, 101, UNIX_TIMESTAMP(), UNIX_TIMESTAMP()+31536000, UNIX_TIMESTAMP(), UNIX_TIMESTAMP());

-- Insert assignments
INSERT INTO mdl_assign (id, course, name, intro, introformat, duedate, grade, timemodified)
VALUES 
(100, 100, 'Programming Assignment 1', 'Write a simple program in Python', 1, UNIX_TIMESTAMP()+604800, 100, UNIX_TIMESTAMP()),
(101, 100, 'Programming Assignment 2', 'Create a data structure in Python', 1, UNIX_TIMESTAMP()+1209600, 100, UNIX_TIMESTAMP()),
(102, 101, 'HTML/CSS Project', 'Build a responsive website', 1, UNIX_TIMESTAMP()+864000, 100, UNIX_TIMESTAMP()),
(103, 102, 'Database Design Project', 'Design a normalized database schema', 1, UNIX_TIMESTAMP()+1728000, 100, UNIX_TIMESTAMP());

-- Insert grades
INSERT INTO mdl_assign_grades (id, assignment, userid, timecreated, timemodified, grader, grade)
VALUES
(100, 100, 100, UNIX_TIMESTAMP(), UNIX_TIMESTAMP(), 103, 85),
(101, 100, 101, UNIX_TIMESTAMP(), UNIX_TIMESTAMP(), 103, 92),
(102, 100, 102, UNIX_TIMESTAMP(), UNIX_TIMESTAMP(), 103, 78),
(103, 101, 100, UNIX_TIMESTAMP(), UNIX_TIMESTAMP(), 103, 88),
(104, 102, 100, UNIX_TIMESTAMP(), UNIX_TIMESTAMP(), 104, 95),
(105, 102, 101, UNIX_TIMESTAMP(), UNIX_TIMESTAMP(), 104, 89);

-- Insert forums
INSERT INTO mdl_forum (id, course, type, name, intro, introformat, timemodified)
VALUES
(100, 100, 'general', 'Course Announcements', 'Important announcements for CS101', 1, UNIX_TIMESTAMP()),
(101, 100, 'general', 'General Discussion', 'General discussion forum for CS101', 1, UNIX_TIMESTAMP()),
(102, 101, 'general', 'Web Development Forum', 'Discuss web development topics', 1, UNIX_TIMESTAMP()),
(103, 102, 'general', 'Database Discussion', 'Discuss database concepts', 1, UNIX_TIMESTAMP());

-- Insert forum discussions
INSERT INTO mdl_forum_discussions (id, forum, name, userid, timemodified, timestart, timeend)
VALUES
(100, 100, 'Welcome to the course', 103, UNIX_TIMESTAMP(), UNIX_TIMESTAMP(), 0),
(101, 101, 'Help with Assignment 1', 100, UNIX_TIMESTAMP(), UNIX_TIMESTAMP(), 0),
(102, 101, 'Study Group Formation', 101, UNIX_TIMESTAMP(), UNIX_TIMESTAMP(), 0),
(103, 102, 'CSS Frameworks Discussion', 100, UNIX_TIMESTAMP(), UNIX_TIMESTAMP(), 0);

-- Insert forum posts
INSERT INTO mdl_forum_posts (id, discussion, parent, userid, created, modified, subject, message, messageformat)
VALUES
(100, 100, 0, 103, UNIX_TIMESTAMP(), UNIX_TIMESTAMP(), 'Welcome to CS101', 'Welcome to Introduction to Computer Science. Please read the syllabus carefully.', 1),
(101, 101, 0, 100, UNIX_TIMESTAMP(), UNIX_TIMESTAMP(), 'Question about Assignment 1', 'I am having trouble with the second part of the assignment. Can anyone help?', 1),
(102, 101, 101, 101, UNIX_TIMESTAMP(), UNIX_TIMESTAMP(), 'Re: Question about Assignment 1', 'I had the same issue. Try using a different approach with lists.', 1),
(103, 102, 0, 101, UNIX_TIMESTAMP(), UNIX_TIMESTAMP(), 'Study Group', 'Would anyone like to form a study group for the midterm?', 1),
(104, 103, 0, 100, UNIX_TIMESTAMP(), UNIX_TIMESTAMP(), 'Bootstrap vs Tailwind', 'Which CSS framework do you prefer and why?', 1);

-- Insert comments
INSERT INTO mdl_comments (id, contextid, component, commentarea, itemid, content, userid, timecreated)
VALUES
(100, 100, 'mod_assign', 'submission_comments', 100, 'Good work, but could improve code documentation', 103, UNIX_TIMESTAMP()),
(101, 100, 'mod_assign', 'submission_comments', 101, 'Excellent submission, very clean code', 103, UNIX_TIMESTAMP()),
(102, 101, 'mod_assign', 'submission_comments', 103, 'Please add more comments to your code', 103, UNIX_TIMESTAMP()),
(103, 102, 'mod_assign', 'submission_comments', 104, 'Great work with the responsive design', 104, UNIX_TIMESTAMP());

-- Insert quizzes
INSERT INTO mdl_quiz (id, course, name, intro, introformat, timeopen, timeclose, grade, timemodified)
VALUES
(100, 100, 'Programming Fundamentals Quiz', 'Test your knowledge of programming basics', 1, UNIX_TIMESTAMP(), UNIX_TIMESTAMP()+604800, 100, UNIX_TIMESTAMP()),
(101, 100, 'Data Structures Quiz', 'Test your understanding of data structures', 1, UNIX_TIMESTAMP(), UNIX_TIMESTAMP()+604800, 100, UNIX_TIMESTAMP()),
(102, 101, 'HTML/CSS Quiz', 'Test your knowledge of HTML and CSS', 1, UNIX_TIMESTAMP(), UNIX_TIMESTAMP()+604800, 100, UNIX_TIMESTAMP()),
(103, 102, 'SQL Quiz', 'Test your knowledge of SQL syntax and queries', 1, UNIX_TIMESTAMP(), UNIX_TIMESTAMP()+604800, 100, UNIX_TIMESTAMP());

-- Insert question bank entries
INSERT INTO mdl_question_bank_entries (id, questioncategoryid, idnumber, ownerid, timecreated, timemodified)
VALUES
(100, 1, 'CS101-Q1', 103, UNIX_TIMESTAMP(), UNIX_TIMESTAMP()),
(101, 1, 'CS101-Q2', 103, UNIX_TIMESTAMP(), UNIX_TIMESTAMP()),
(102, 1, 'CS101-Q3', 103, UNIX_TIMESTAMP(), UNIX_TIMESTAMP()),
(103, 2, 'WD200-Q1', 104, UNIX_TIMESTAMP(), UNIX_TIMESTAMP()),
(104, 2, 'WD200-Q2', 104, UNIX_TIMESTAMP(), UNIX_TIMESTAMP()),
(105, 3, 'DB301-Q1', 104, UNIX_TIMESTAMP(), UNIX_TIMESTAMP());

-- Insert questions
INSERT INTO mdl_question (id, category, parent, name, questiontext, questiontextformat, defaultmark, penalty, qtype, timecreated, timemodified)
VALUES
(100, 1, 0, 'Python Variable Types', 'Which of these is not a standard data type in Python?', 1, 1.0, 0.33, 'multichoice', UNIX_TIMESTAMP(), UNIX_TIMESTAMP()),
(101, 1, 0, 'Time Complexity', 'What is the time complexity of binary search?', 1, 1.0, 0.33, 'multichoice', UNIX_TIMESTAMP(), UNIX_TIMESTAMP()),
(102, 1, 0, 'Algorithm Definition', 'Define what an algorithm is and give an example.', 1, 5.0, 0.0, 'essay', UNIX_TIMESTAMP(), UNIX_TIMESTAMP()),
(103, 2, 0, 'HTML5 Elements', 'Which element is not a semantic HTML5 element?', 1, 1.0, 0.33, 'multichoice', UNIX_TIMESTAMP(), UNIX_TIMESTAMP()),
(104, 2, 0, 'CSS Selectors', 'Write a CSS selector that targets all paragraph elements inside a div with class "content".', 1, 2.0, 0.0, 'shortanswer', UNIX_TIMESTAMP(), UNIX_TIMESTAMP()),
(105, 3, 0, 'SQL Joins', 'Explain the difference between INNER JOIN and LEFT JOIN.', 1, 3.0, 0.0, 'essay', UNIX_TIMESTAMP(), UNIX_TIMESTAMP());
