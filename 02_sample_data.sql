-- =====================================================================
-- File 2 of 3 : SAMPLE DATA  ("today" in the sample data = 2026-11-22)
-- =====================================================================
PRAGMA foreign_keys = ON;

-- 1-2. Lookup tables ---------------------------------------------------
INSERT INTO account_types (type_name, can_loan, can_save, can_money_back, max_members) VALUES
 ('Basic',   1, 0, 0, NULL),
 ('Premium', 1, 1, 1, 50);

INSERT INTO account_statuses (status_name, description) VALUES
 ('Active',   'Account can log in and transact'),
 ('Disabled', 'Account blocked, e.g. failed to settle a loan after the interim period');

-- 7. Administrators ----------------------------------------------------
INSERT INTO administrators (username, password_hash, full_name, email, role) VALUES
 ('admin.rosa', '$2y$10$Rk1pXq9Zr7sA0mC8vT3e1uQ5nB2hJ4dLwE6yU8iO0aS9fG7kH3zXe', 'Rosa Dimagiba', 'rosa.dimagiba@lendsave.ph', 'Super Admin'),
 ('admin.mike', '$2y$10$Tt8nWq2Ze5sB1mD7vY4f2uR6oC3kK5eMxF7zV9jP1bT0gH8lI4aYf', 'Michael Tan',   'michael.tan@lendsave.ph',  'Verifier'),
 ('admin.joy',  '$2y$10$Yy3mAq7Ze9sC2nE8wU5g3vS7pD4lL6fNyG8aW0kQ2cU1hI9mJ5bZg', 'Joy Navarro',   'joy.navarro@lendsave.ph',  'Finance');

-- 3. Users (PH names, 6+ char usernames) --------------------------------
INSERT INTO users (username, password_hash, email, account_type_id, status_id, is_verified, created_at) VALUES
 ('juan.delacruz',   '$2y$10$a1B2c3D4e5F6g7H8i9J0kuL1m2N3o4P5q6R7s8T9u0V1w2X3y4Z5a', 'juan.delacruz@gmail.com',    2, 1, 0, '2025-03-10 09:15:00'),
 ('maria.santos',    '$2y$10$b2C3d4E5f6G7h8I9j0K1lvM2n3O4p5Q6r7S8t9U0v1W2x3Y4z5A6b', 'maria.santos@yahoo.com',     2, 1, 0, '2025-04-02 10:30:00'),
 ('pedro.reyes',     '$2y$10$c3D4e5F6g7H8i9J0k1L2mwN3o4P5q6R7s8T9u0V1w2X3y4Z5a6B7c', 'pedro.reyes@gmail.com',      1, 1, 0, '2025-05-20 14:00:00'),
 ('ana.lopez',       '$2y$10$d4E5f6G7h8I9j0K1l2M3nxO4p5Q6r7S8t9U0v1W2x3Y4z5A6b7C8d', 'ana.lopez@outlook.com',      2, 1, 0, '2025-06-15 11:45:00'),
 ('carlo.mendoza',   '$2y$10$e5F6g7H8i9J0k1L2m3N4oyP5q6R7s8T9u0V1w2X3y4Z5a6B7c8D9e', 'carlo.mendoza@gmail.com',    1, 1, 0, '2026-02-11 08:20:00'),
 ('liza.bautista',   '$2y$10$f6G7h8I9j0K1l2M3n4O5pzQ6r7S8t9U0v1W2x3Y4z5A6b7C8d9E0f', 'liza.bautista@gmail.com',    1, 1, 0, '2026-03-01 13:10:00'),
 ('mark.villanueva', '$2y$10$g7H8i9J0k1L2m3N4o5P6qaR7s8T9u0V1w2X3y4Z5a6B7c8D9e0F1g', 'mark.villanueva@yahoo.com',  2, 1, 0, '2026-04-12 16:40:00'),
 ('jenny.ramos',     '$2y$10$h8I9j0K1l2M3n4O5p6Q7rbS8t9U0v1W2x3Y4z5A6b7C8d9E0f1G2h', 'jenny.ramos@gmail.com',      1, 1, 0, '2026-06-18 09:05:00'),
 ('ramon.torres',    '$2y$10$i9J0k1L2m3N4o5P6q7R8scT9u0V1w2X3y4Z5a6B7c8D9e0F1g2H3i', 'ramon.torres@gmail.com',     1, 1, 0, '2026-11-18 10:00:00'),
 ('sheila.cruz',     '$2y$10$j0K1l2M3n4O5p6Q7r8S9tdU0v1W2x3Y4z5A6b7C8d9E0f1G2h3I4j', 'sheila.cruz@mailinator.com', 2, 1, 0, '2026-10-10 15:25:00');

-- 4. Personal information ------------------------------------------------
INSERT INTO user_profiles (user_id, first_name, middle_name, last_name, address, gender, birthday, contact_number, tin_number) VALUES
 (1,  'Juan',   'Pablo',   'Dela Cruz', '12 Colon St., Cebu City',               'Male',   '1990-05-14', '09171234501', '123-456-789-001'),
 (2,  'Maria',  'Clara',   'Santos',    '45 Mango Ave., Cebu City',              'Female', '1993-09-02', '09181234502', '123-456-789-002'),
 (3,  'Pedro',  'Luis',    'Reyes',     '8 Osmena Blvd., Cebu City',             'Male',   '1988-01-27', '09191234503', '123-456-789-003'),
 (4,  'Ana',    'Marie',   'Lopez',     '77 Lahug Rd., Cebu City',               'Female', '1995-12-11', '09201234504', '123-456-789-004'),
 (5,  'Carlo',  NULL,      'Mendoza',   '3 Banilad St., Mandaue City',           'Male',   '1992-07-19', '09211234505', '123-456-789-005'),
 (6,  'Liza',   'Anne',    'Bautista',  '21 Gen. Maxilom Ave., Cebu City',       'Female', '1991-03-30', '09221234506', '123-456-789-006'),
 (7,  'Mark',   'Joseph',  'Villanueva','90 Escario St., Cebu City',             'Male',   '1989-11-05', '09231234507', '123-456-789-007'),
 (8,  'Jenny',  NULL,      'Ramos',     '14 M.L. Quezon Ave., Lapu-Lapu City',   'Female', '1996-04-22', '09241234508', '123-456-789-008'),
 (9,  'Ramon',  'Dela',    'Torres',    '5 Talamban Rd., Cebu City',             'Male',   '1994-08-08', '09251234509', '123-456-789-009'),
 (10, 'Sheila', NULL,      'Cruz',      '66 Mabolo St., Cebu City',              'Female', '1990-02-17', '09261234510', '123-456-789-010');

-- 5. Bank details ---------------------------------------------------------
INSERT INTO user_banks (user_id, bank_name, bank_account_number, card_holder_name) VALUES
 (1,  'BDO',         '001234567890', 'JUAN P DELA CRUZ'),
 (2,  'BPI',         '002345678901', 'MARIA C SANTOS'),
 (3,  'Metrobank',   '003456789012', 'PEDRO L REYES'),
 (4,  'UnionBank',   '004567890123', 'ANA M LOPEZ'),
 (5,  'BDO',         '005678901234', 'CARLO MENDOZA'),
 (6,  'Landbank',    '006789012345', 'LIZA A BAUTISTA'),
 (7,  'BPI',         '007890123456', 'MARK J VILLANUEVA'),
 (8,  'Metrobank',   '008901234567', 'JENNY RAMOS'),
 (9,  'BDO',         '009012345678', 'RAMON D TORRES'),
 (10, 'UnionBank',   '010123456789', 'SHEILA CRUZ');

-- 6. Employment information ---------------------------------------------
INSERT INTO user_employment (user_id, company_name, company_address, company_phone, hr_contact_number, position, monthly_earnings) VALUES
 (1,  'Cebu BPO Solutions',    'IT Park, Lahug, Cebu City',      '(032) 255-1001', '(032) 255-1010', 'Team Leader',        45000),
 (2,  'Visayas Marketing Inc.','Mandaue City',                   '(032) 255-2002', '(032) 255-2020', 'Account Executive',  32000),
 (3,  'Island Logistics Corp.','Mactan, Lapu-Lapu City',         '(032) 255-3003', '(032) 255-3030', 'Warehouse Supervisor',28000),
 (4,  'Metro Cebu Hospital',   'Osmena Blvd., Cebu City',        '(032) 255-4004', '(032) 255-4040', 'Nurse',              38000),
 (5,  'Sugbo Retail Group',    'Ayala Center, Cebu City',        '(032) 255-5005', '(032) 255-5050', 'Store Manager',      30000),
 (6,  'Cebu Pacific Foods',    'Mandaue City',                   '(032) 255-6006', '(032) 255-6060', 'Cashier',            18000),
 (7,  'Queen City Builders',   'Banilad, Cebu City',             '(032) 255-7007', '(032) 255-7070', 'Engineer',           52000),
 (8,  'Mactan Resort Hotel',   'Lapu-Lapu City',                 '(032) 255-8008', '(032) 255-8080', 'Front Desk Officer', 22000),
 (9,  'Talamban Tech Hub',     'Talamban, Cebu City',            '(032) 255-9009', '(032) 255-9090', 'Developer',          40000),
 (10, 'Phantom Trading Co.',   'Mabolo, Cebu City',              '(032) 255-0010', '(032) 255-0100', 'Manager',            90000);

-- 9. Registration applications (all start Pending, then admin decides) -----
INSERT INTO registration_applications (user_id, requested_type_id, status, submitted_at)
SELECT user_id, account_type_id, 'Pending', created_at FROM users ORDER BY user_id;

-- 10. Submitted documents (3 required uploads per application)
INSERT INTO submitted_documents (application_id, document_type, file_path, uploaded_at)
SELECT a.application_id, d.doc,
       'uploads/app' || a.application_id || '/' || lower(replace(d.doc, ' ', '_')) || '.pdf',
       a.submitted_at
  FROM registration_applications a
 CROSS JOIN (SELECT 'Proof of Billing' AS doc UNION ALL SELECT 'Valid ID Primary' UNION ALL SELECT 'COE') d
 ORDER BY a.application_id, d.doc;

-- Admin verifies documents of applicants 1-8 (legit); #10 has a fake COE; #9 is still waiting
UPDATE submitted_documents SET is_legit = 1, verified_by = 2, verified_at = '2026-01-05 10:00:00'
 WHERE application_id BETWEEN 1 AND 8;
UPDATE submitted_documents SET is_legit = 1, verified_by = 2, verified_at = '2026-10-14 09:30:00'
 WHERE application_id = 10 AND document_type <> 'COE';
UPDATE submitted_documents SET is_legit = 0, verified_by = 2, verified_at = '2026-10-14 09:30:00'
 WHERE application_id = 10 AND document_type = 'COE';

-- Approvals (fires trg_approve_registration -> users.is_verified = 1)
UPDATE registration_applications
   SET status = 'Approved', reviewed_by = 1, reviewed_at = datetime(submitted_at, '+2 days'),
       tin_verified = 1, company_verified = 1
 WHERE application_id BETWEEN 1 AND 8;

-- Rejection (fires trg_reject_registration -> delete_after = reviewed_at + 30 days)
UPDATE registration_applications
   SET status = 'Rejected', reviewed_by = 2, reviewed_at = '2026-10-15 09:00:00',
       company_verified = 0, tin_verified = 1,
       rejection_reason = 'Employer could not confirm employment; COE is not legit'
 WHERE application_id = 10;

-- 8. Blocked e-mail
INSERT INTO blocked_emails (email, reason, blocked_by_admin, blocked_at) VALUES
 ('sheila.cruz@mailinator.com', 'Fake employment documents', 1, '2026-10-15 09:05:00'),
 ('scammer123@tempmail.com',    'Reported fraudulent registration', 1, '2026-09-01 11:00:00');

-- 11. Loan applications (Pending first, then admin decision) ---------------
INSERT INTO loan_applications (user_id, principal_amount, term_months, applied_at) VALUES
 (1, 10000,  6, '2026-05-28 10:00:00'),   -- loan 1
 (2,  5000,  3, '2026-08-29 09:00:00'),   -- loan 2
 (3,  8000,  6, '2026-07-30 15:30:00'),   -- loan 3
 (6,  6000,  3, '2026-04-03 11:15:00'),   -- loan 4
 (4,  5000,  1, '2026-10-02 08:45:00'),   -- loan 5
 (5,  5000,  1, '2026-10-09 14:20:00'),   -- loan 6
 (5, 10000, 12, '2026-02-20 10:10:00'),   -- loan 7 (will be rejected)
 (7,  7000,  3, '2026-11-20 13:00:00');   -- loan 8 (stays Pending)

-- Approvals: money released -> fires trg_loan_approved -> payment schedule rows
UPDATE loan_applications SET status='Approved', reviewed_by=3, reviewed_at='2026-05-30 09:00:00', released_at='2026-06-01' WHERE loan_id = 1;
UPDATE loan_applications SET status='Approved', reviewed_by=3, reviewed_at='2026-08-31 09:00:00', released_at='2026-09-01' WHERE loan_id = 2;
UPDATE loan_applications SET status='Approved', reviewed_by=3, reviewed_at='2026-08-01 09:00:00', released_at='2026-08-03' WHERE loan_id = 3;
UPDATE loan_applications SET status='Approved', reviewed_by=3, reviewed_at='2026-04-05 09:00:00', released_at='2026-04-06' WHERE loan_id = 4;
UPDATE loan_applications SET status='Approved', reviewed_by=3, reviewed_at='2026-10-04 09:00:00', released_at='2026-10-05' WHERE loan_id = 5;
UPDATE loan_applications SET status='Approved', reviewed_by=3, reviewed_at='2026-10-11 09:00:00', released_at='2026-10-12' WHERE loan_id = 6;
UPDATE loan_applications SET status='Rejected', reviewed_by=1, reviewed_at='2026-02-22 09:00:00',
       rejection_reason='Monthly earnings are not enough for the requested amount and term' WHERE loan_id = 7;

-- 14. Billing statements: one statement is generated for every 28-day period
INSERT INTO billing_statements (schedule_id, date_generated, due_date, amount_due, interest_amount)
SELECT ps.schedule_id, date(ps.due_date, '-28 days'), ps.due_date, ps.amount_due,
       ROUND(la.principal_amount * la.interest_rate / la.term_months, 2)
  FROM payment_schedules ps
  JOIN loan_applications la USING (loan_id)
 WHERE date(ps.due_date, '-28 days') <= '2026-11-22';

-- 15. Loan payments (fires trg_payment_applied -> bill Completed, schedule Paid)
WITH p(loan_id, inst, paid_on, method, ref) AS (VALUES
 (1,1,'2026-06-27 10:00:00','Bank Transfer','PAY-0001'), (1,2,'2026-07-25 10:00:00','GCash','PAY-0002'),
 (1,3,'2026-08-22 10:00:00','Bank Transfer','PAY-0003'), (1,4,'2026-09-19 10:00:00','GCash','PAY-0004'),
 (1,5,'2026-10-17 10:00:00','Bank Transfer','PAY-0005'), (1,6,'2026-11-14 10:00:00','GCash','PAY-0006'),
 (2,1,'2026-09-27 09:30:00','GCash','PAY-0007'),         (2,2,'2026-10-25 09:30:00','GCash','PAY-0008'),
 (3,1,'2026-08-29 14:00:00','Bank Transfer','PAY-0009'), (3,2,'2026-09-26 14:00:00','Bank Transfer','PAY-0010'),
 (3,3,'2026-10-24 14:00:00','Over the Counter','PAY-0011'),
 (4,1,'2026-05-03 11:00:00','GCash','PAY-0012'),
 (5,1,'2026-10-30 16:00:00','Bank Transfer','PAY-0013'))
INSERT INTO loan_payments (billing_id, amount_paid, payment_date, payment_method, reference_no)
SELECT b.billing_id, b.total_amount, p.paid_on, p.method, p.ref
  FROM p
  JOIN payment_schedules ps ON ps.loan_id = p.loan_id AND ps.installment_no = p.inst
  JOIN billing_statements b ON b.schedule_id = ps.schedule_id;

-- Overdue job (this is what a CRON would run daily): 2% penalty on the missed month only
UPDATE billing_statements
   SET penalty_amount = ROUND(amount_due * 0.02, 2), status = 'Overdue'
 WHERE status = 'Unpaid' AND due_date < '2026-11-22';
UPDATE payment_schedules SET status = 'Overdue'
 WHERE schedule_id IN (SELECT schedule_id FROM billing_statements WHERE status = 'Overdue');

-- Loan 9: Juan finished loan 1 on time, so his limit grows to 15,000 and term to 15 months
INSERT INTO loan_applications (user_id, principal_amount, term_months, applied_at) VALUES
 (1, 15000, 12, '2026-11-20 10:30:00');

-- 12. Loan transactions
INSERT INTO loan_transactions (loan_id, user_id, txn_type, amount, term_months, status, remarks, processed_by, created_at)
SELECT loan_id, user_id, 'Loan Application', principal_amount, term_months, status, rejection_reason, reviewed_by, applied_at
  FROM loan_applications ORDER BY loan_id;
INSERT INTO loan_transactions (loan_id, user_id, txn_type, amount, term_months, status, remarks, processed_by, created_at) VALUES
 (1, 1, 'Loan Limit Increase', 15000, NULL, 'Approved', 'Loan 1 fully paid on time: limit 10,000 -> 15,000', 3, '2026-11-15 09:00:00'),
 (1, 1, 'Term Increase',        NULL,   15, 'Approved', 'Loan 1 fully paid on time: max term 12 -> 15 months', 3, '2026-11-15 09:00:00');

-- 16. Savings accounts (Premium only)
INSERT INTO savings_accounts (user_id, opened_at, zero_balance_since) VALUES
 (1, '2025-04-05', '2025-04-05'),
 (2, '2025-05-10', '2025-05-10'),
 (4, '2025-06-20', '2025-06-20'),
 (7, '2026-06-10', '2026-06-10');

-- 19. Money back: 2025 company income 1,000,000 x 2% / 3 premium members at that time
INSERT INTO money_back_earnings (income_year, total_company_income, share_rate, premium_member_count, computed_by, computed_at) VALUES
 (2025, 1000000, 0.02, 3, 3, '2026-01-15 09:00:00');

-- 17. Savings transactions (deposit 100-1000, withdrawal 500-5000)
INSERT INTO savings_transactions (savings_id, category, source, amount, status, created_at, processed_at) VALUES
 (1,'Deposit',   'Manual',    1000,'Completed','2025-04-05 10:00:00','2025-04-05 10:00:05'),
 (1,'Deposit',   'Manual',     500,'Completed','2025-05-10 10:00:00','2025-05-10 10:00:05'),
 (1,'Deposit',   'Manual',     300,'Completed','2025-06-20 10:00:00','2025-06-20 10:00:05'),
 (1,'Withdrawal','Manual',     500,'Completed','2025-08-02 09:00:00','2025-08-02 15:00:00'),
 (2,'Deposit',   'Manual',    1000,'Completed','2025-05-10 11:00:00','2025-05-10 11:00:05'),
 (2,'Deposit',   'Manual',    1000,'Completed','2025-06-10 11:00:00','2025-06-10 11:00:05'),
 (2,'Deposit',   'Manual',    1000,'Completed','2025-07-10 11:00:00','2025-07-10 11:00:05'),
 (3,'Deposit',   'Manual',     500,'Completed','2025-06-20 12:00:00','2025-06-20 12:00:05'),
 (3,'Deposit',   'Manual',     400,'Completed','2025-07-22 12:00:00','2025-07-22 12:00:05'),
 -- Money Back credits (Jan 2026)
 (1,'Deposit','Money Back', 6666.67,'Completed','2026-01-15 09:30:00','2026-01-15 09:30:00'),
 (2,'Deposit','Money Back', 6666.67,'Completed','2026-01-15 09:30:00','2026-01-15 09:30:00'),
 (3,'Deposit','Money Back', 6666.67,'Completed','2026-01-15 09:30:00','2026-01-15 09:30:00'),
 -- 2026 activity
 (1,'Deposit',   'Manual',     800,'Completed','2026-03-12 10:00:00','2026-03-12 10:00:05'),
 (1,'Deposit',   'Manual',     200,'Failed',   '2026-03-13 10:00:00', NULL),
 (4,'Deposit',   'Manual',    1000,'Completed','2026-06-10 10:00:00','2026-06-10 10:00:05'),
 (4,'Withdrawal','Manual',    1000,'Completed','2026-08-15 09:00:00','2026-08-15 14:00:00'),  -- balance = 0
 (4,'Withdrawal','Manual',    1000,'Rejected', '2026-09-01 09:00:00','2026-09-01 13:00:00'),  -- insufficient
 (3,'Withdrawal','Manual',    2000,'Completed','2026-09-15 09:00:00','2026-09-15 16:00:00'),
 (1,'Withdrawal','Manual',     700,'Pending',  '2026-11-21 09:00:00', NULL);

-- 18. Withdrawal requests (one request form per withdrawal transaction)
INSERT INTO withdrawal_requests (txn_no, reason, request_status, requested_at, reviewed_by, reviewed_at, admin_note)
SELECT txn_no, 'Personal expenses',
       CASE status WHEN 'Completed' THEN 'Approved' WHEN 'Rejected' THEN 'Rejected' ELSE 'Pending' END,
       created_at,
       CASE WHEN status = 'Pending' THEN NULL ELSE 3 END,
       processed_at,
       CASE WHEN status = 'Rejected' THEN 'Requested amount is greater than the available savings' END
  FROM savings_transactions WHERE category = 'Withdrawal';

-- 20. Money back allocations (link each premium member to the savings credit)
INSERT INTO money_back_allocations (earning_id, user_id, savings_txn_no, amount, allocated_at)
SELECT 1, sa.user_id, st.txn_no, st.amount, st.created_at
  FROM savings_transactions st JOIN savings_accounts sa USING (savings_id)
 WHERE st.source = 'Money Back';

-- Account disabled: failed to settle loan after the interim period
UPDATE users SET status_id = 2, disabled_reason = 'Failed to settle loan 4 after the interim period',
       updated_at = '2026-07-05 00:00:00' WHERE user_id = 6;

-- 21. Admin activity records
INSERT INTO admin_activity_logs (admin_id, action_type, target_table, target_id, description, created_at) VALUES
 (1, 'Approve Registration', 'registration_applications', 1,  'Approved registration of juan.delacruz', '2025-03-12 09:00:00'),
 (2, 'Verify Documents',     'submitted_documents',       28, 'Fake COE found for application 10',      '2026-10-14 09:30:00'),
 (2, 'Reject Registration',  'registration_applications', 10, 'Rejected sheila.cruz - COE not legit',   '2026-10-15 09:00:00'),
 (1, 'Block Email',          'blocked_emails',            1,  'Blocked sheila.cruz@mailinator.com',     '2026-10-15 09:05:00'),
 (3, 'Approve Loan',         'loan_applications',         1,  'Approved loan 1 (10,000 / 6 months)',    '2026-05-30 09:00:00'),
 (1, 'Reject Loan',          'loan_applications',         7,  'Rejected loan 7: insufficient earnings', '2026-02-22 09:00:00'),
 (3, 'Approve Withdrawal',   'withdrawal_requests',       1,  'Approved withdrawal of 500',             '2025-08-02 15:00:00'),
 (3, 'Reject Withdrawal',    'withdrawal_requests',       5,  'Rejected: insufficient savings',         '2026-09-01 13:00:00'),
 (3, 'Compute Money Back',   'money_back_earnings',       1,  '2025 income x 2% / 3 premium members',   '2026-01-15 09:00:00'),
 (1, 'Disable Account',      'users',                     6,  'Disabled liza.bautista (unpaid loan)',   '2026-07-05 00:00:00');
