-- Create and use database
CREATE DATABASE IF NOT EXISTS online_learning_system;
USE online_learning_system;

-- Student Table
CREATE TABLE Student_Table (
    StudentID INT PRIMARY KEY,
    FirstName VARCHAR(100),
    LastName VARCHAR(100),
    Email VARCHAR(50),
    Contact VARCHAR(100)
);

INSERT INTO Student_Table (StudentID, FirstName, LastName, Email, Contact) VALUES
(101, 'Pooja', 'Sharma', 'pooja@gmail.com', '9658743212'),
(102, 'Pari', 'Baisoya', 'pari@gmail.com', '9876543211'),
(103, 'Preeti', 'Patel', 'preeti@gmail.com', '9854673213'),
(104, 'Sarika', 'Shakya', 'sarika@gmail.com', '7854882134'),
(105, 'Lucky', 'Singh', 'lucky@gmail.com', '8546285235');

SELECT * FROM Student_Table;

-- Course Table
CREATE TABLE Course_Table (
    CourseID INT PRIMARY KEY,
    CourseName VARCHAR(100),
    CourseInstructor VARCHAR(100),
    CourseDuration VARCHAR(50)
);

INSERT INTO Course_Table (CourseID, CourseName, CourseInstructor, CourseDuration) VALUES
(10, 'AI', 'Deepika Singh', '1 Year'),
(11, 'Copa', 'Rajkumar', '1 Year'),
(12, 'CSA', 'Guruvulu', '1 Year'),
(13, 'IT', 'Raj Singh', '2 Year'),
(14, 'IBM', 'Anshika Sharma', '2 Year');

SELECT * FROM Course_Table;

-- Enrollment Table
CREATE TABLE Enrollment_Table (
    EnrollmentID INT PRIMARY KEY,
    StudentID INT NOT NULL,
    CourseID INT NOT NULL,
    EnrollmentDate DATE,
    FOREIGN KEY (StudentID) REFERENCES Student_Table(StudentID),
    FOREIGN KEY (CourseID) REFERENCES Course_Table(CourseID)
);

INSERT INTO Enrollment_Table (EnrollmentID, StudentID, CourseID, EnrollmentDate) VALUES
(1, 101, 10, '2024-10-30'),
(2, 102, 11, '2024-02-11'),
(3, 103, 12, '2024-06-17'),
(4, 104, 13, '2024-03-26'),
(5, 105, 14, '2024-01-10');

SELECT * FROM Enrollment_Table;

-- Payment Table
CREATE TABLE Payment_Table (
    PaymentID INT PRIMARY KEY,
    StudentID INT NOT NULL,
    CourseID INT NOT NULL,
    EnrollmentID INT NOT NULL,
    Amount DECIMAL(10,2) NOT NULL,
    FOREIGN KEY (StudentID) REFERENCES Student_Table(StudentID),
    FOREIGN KEY (CourseID) REFERENCES Course_Table(CourseID),
    FOREIGN KEY (EnrollmentID) REFERENCES Enrollment_Table(EnrollmentID)
);

INSERT INTO Payment_Table (PaymentID, StudentID, CourseID, EnrollmentID, Amount) VALUES
(1001, 101, 10, 1, 500.00),
(1002, 102, 11, 2, 550.00),
(1003, 103, 12, 3, 600.00),
(1004, 104, 13, 4, 650.00),
(1005, 105, 14, 5, 700.00);

SELECT * FROM Payment_Table;

-- Customer Table
CREATE TABLE Customer (
    CustomerID INT PRIMARY KEY,
    Name VARCHAR(100),
    Email VARCHAR(100)
);

-- Product Table
CREATE TABLE Product (
    ProductID INT PRIMARY KEY,
    Name VARCHAR(100),
    Price DECIMAL(10,2)
);

-- Orders Table
CREATE TABLE Orders (
    OrderID INT PRIMARY KEY,
    OrderDate DATE,
    CustomerID INT,
    FOREIGN KEY (CustomerID) REFERENCES Customer(CustomerID)
);

-- Order Items Table
CREATE TABLE OrderItem (
    OrderID INT,
    ProductID INT,
    Quantity INT,
    PRIMARY KEY (OrderID, ProductID),
    FOREIGN KEY (OrderID) REFERENCES Orders(OrderID),
    FOREIGN KEY (ProductID) REFERENCES Product(ProductID)
);

-- Use standard delimiter
START TRANSACTION;

-- Ensure new Enrollment ID (not duplicate)
INSERT INTO Enrollment_Table (EnrollmentID, StudentID, CourseID, EnrollmentDate)
VALUES (6, 101, 10, CURDATE());

-- Payment matching EnrollmentID 6
INSERT INTO Payment_Table (PaymentID, StudentID, CourseID, EnrollmentID, Amount)
VALUES (1006, 101, 10, 6, 500.00);

-- Commit if both successful
COMMIT;

DELIMITER $$

CREATE PROCEDURE HandlePaymentFailure(
    IN student_id INT,
    IN course_id INT,
    IN payment_amount DECIMAL(10,2)
)
BEGIN
    DECLARE enrollment_id INT;

    START TRANSACTION;

    -- Insert into Enrollment Table with new ID
    INSERT INTO Enrollment_Table (EnrollmentID, StudentID, CourseID, EnrollmentDate)
    VALUES ((SELECT IFNULL(MAX(EnrollmentID), 5) + 1 FROM Enrollment_Table), student_id, course_id, CURDATE());

    SET enrollment_id = LAST_INSERT_ID();

    -- Check payment validity
    IF payment_amount <= 0 THEN
        ROLLBACK;
        SELECT 'Transaction Failed - Payment not processed' AS Message;
    ELSE
        -- Insert Payment (assuming PaymentID is auto-increment or managed)
        INSERT INTO Payment_Table (PaymentID, StudentID, CourseID, EnrollmentID, Amount)
        VALUES ((SELECT IFNULL(MAX(PaymentID), 1005) + 1 FROM Payment_Table), student_id, course_id, enrollment_id, payment_amount);

        COMMIT;
        SELECT 'Transaction Completed - Enrollment and Payment Successful' AS Message;
    END IF;

END$$

DELIMITER ;

-- View procedure
SHOW CREATE PROCEDURE HandlePaymentFailure;


SELECT 
    s.StudentID,
    CONCAT(s.FirstName, ' ', s.LastName) AS StudentName,
    c.CourseID,
    c.CourseName AS CourseTitle,
    e.EnrollmentID,
    e.EnrollmentDate,
    p.PaymentID,
    p.Amount,
    'Completed' AS PaymentStatus  -- Assuming all are completed for now
FROM Enrollment_Table e
JOIN Student_Table s ON s.StudentID = e.StudentID
JOIN Course_Table c ON c.CourseID = e.CourseID
LEFT JOIN Payment_Table p ON p.EnrollmentID = e.EnrollmentID
WHERE c.CourseID = 10  -- change CourseID as needed
ORDER BY s.StudentID;
