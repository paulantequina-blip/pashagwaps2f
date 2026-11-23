-- =====================================================================
-- File 3 of 3 : DATABASE OPERATIONS
-- INSERT / SELECT / UPDATE / DELETE / JOIN / WHERE + ORDER BY /
-- Aggregates / GROUP BY.   Run the statements one block at a time
-- (select a block, then Ctrl+Enter in the Letos SQL editor).
-- =====================================================================
PRAGMA foreign_keys = ON;

-- ============================ 1. INSERT ==============================
-- 1a. New user (Basic) with profile, bank, employment and registration application
INSERT INTO users (username, password_hash, email, account_type_id)
VALUES ('rico.fernandez', '$2y$10$k1L2m3N4o5P6q7R8s9T0ueV1w2X3y4Z5a6B7c8D9e0F1g2H3i4J5k',
        'rico.fernandez@gmail.com', 1);

INSERT INTO user_profiles (user_id, first_name, last_name, address, gender, birthday, contact_number, tin_number)
VALUES ((SELECT user_id FROM users WHERE username = 'rico.fernandez'),
        'Rico', 'Fernandez', '18 Guadalupe St., Cebu City', 'Male', '1997-06-09', '09271234511', '123-456-789-011');

INSERT INTO user_banks (user_id, bank_name, bank_account_number, card_holder_name)
VALUES ((SELECT user_id FROM users WHERE username = 'rico.fernandez'), 'BDO', '011234567890', 'RICO FERNANDEZ');

INSERT INTO user_employment (user_id, company_name, company_address, company_phone, hr_contact_number, position, monthly_earnings)
VALUES ((SELECT user_id FROM users WHERE username = 'rico.fernandez'),
        'Cebu Digital Agency', 'Ayala Center, Cebu City', '(032) 255-1100', '(032) 255-1101', 'Designer', 27000);

INSERT INTO registration_applications (user_id, requested_type_id)
VALUES ((SELECT user_id FROM users WHERE username = 'rico.fernandez'), 1);   -- status defaults to Pending

-- 1b. New loan application (user 2 Maria, 5,000 for 1 month) + its transaction record
INSERT INTO loan_applications (user_id, principal_amount, term_months) VALUES (2, 5000, 1);
INSERT INTO loan_transactions (loan_id, user_id, txn_type, amount, term_months)
VALUES ((SELECT MAX(loan_id) FROM loan_applications), 2, 'Loan Application', 5000, 1);

-- 1c. New savings deposit (Juan, 500) and a withdrawal request (Ana, 1000)
INSERT INTO savings_transactions (savings_id, category, amount, status)
VALUES (1, 'Deposit', 500, 'Pending');
INSERT INTO savings_transactions (savings_id, category, amount, status)
VALUES (3, 'Withdrawal', 1000, 'Pending');
INSERT INTO withdrawal_requests (txn_no, reason)
VALUES ((SELECT MAX(txn_no) FROM savings_transactions), 'School tuition');

-- 1d. These MUST fail (rules enforced by triggers/CHECK) - run one at a time to see the error:
-- INSERT INTO savings_transactions (savings_id, category, amount) VALUES (1, 'Deposit', 50);        -- below 100
-- INSERT INTO savings_transactions (savings_id, category, amount) VALUES (1, 'Withdrawal', 6000);   -- above 5000
-- INSERT INTO loan_applications (user_id, principal_amount, term_months) VALUES (3, 5500, 3);       -- not in thousands
-- INSERT INTO loan_applications (user_id, principal_amount, term_months) VALUES (6, 5000, 3);       -- account disabled
-- INSERT INTO users (username, password_hash, email, account_type_id)
--   VALUES ('scam.user', '$2y$10$k1L2m3N4o5P6q7R8s9T0ueV1w2X3y4Z5a6B7c8D9e0F1g2H3i4J5k', 'scammer123@tempmail.com', 1); -- blocked email

-- ============================ 2. SELECT ==============================
SELECT * FROM users;
SELECT user_id, username, email, is_verified FROM users;
SELECT * FROM v_user_age;                              -- age calculated automatically

-- ============================ 3. UPDATE ==============================
-- 3a. Admin approves the new registration (trigger gives the verified tag)
UPDATE registration_applications
   SET status = 'Approved', reviewed_by = 2, reviewed_at = datetime('now'), tin_verified = 1, company_verified = 1
 WHERE user_id = (SELECT user_id FROM users WHERE username = 'rico.fernandez');

-- 3b. Admin approves Maria's new loan (money released today -> payment schedule is generated)
UPDATE loan_applications
   SET status = 'Approved', reviewed_by = 3, reviewed_at = datetime('now'), released_at = date('now')
 WHERE loan_id = (SELECT MAX(loan_id) FROM loan_applications);
UPDATE loan_transactions SET status = 'Approved', processed_by = 3
 WHERE loan_id = (SELECT MAX(loan_id) FROM loan_applications);

-- 3c. Admin rejects Mark's loan and gives the reason
UPDATE loan_applications
   SET status = 'Rejected', reviewed_by = 1, reviewed_at = datetime('now'),
       rejection_reason = 'Employment could not be confirmed by HR'
 WHERE loan_id = 8;

-- 3d. Admin approves Juan's deposit & Ana's withdrawal -> balances update automatically
UPDATE savings_transactions SET status = 'Completed', processed_at = datetime('now')
 WHERE txn_no = (SELECT MAX(txn_no) - 1 FROM savings_transactions);     -- Juan's deposit
UPDATE savings_transactions SET status = 'Completed', processed_at = datetime('now')
 WHERE txn_no = (SELECT MAX(txn_no) FROM savings_transactions);         -- Ana's withdrawal
UPDATE withdrawal_requests SET request_status = 'Approved', reviewed_by = 3, reviewed_at = datetime('now')
 WHERE txn_no = (SELECT MAX(txn_no) FROM savings_transactions);

-- 3e. Admin changes account status / type
UPDATE users SET status_id = (SELECT status_id FROM account_statuses WHERE status_name = 'Active'),
       disabled_reason = NULL, updated_at = datetime('now')
 WHERE username = 'liza.bautista';

-- 3f. Premium members whose savings stayed 0 for 3 months are downgraded to Basic
--     (query-based, so no CRON job is needed: run it when the user logs in or when admin opens the page)
UPDATE users SET account_type_id = (SELECT account_type_id FROM account_types WHERE type_name = 'Basic')
 WHERE user_id IN (SELECT user_id FROM savings_accounts
                    WHERE balance = 0 AND zero_balance_since <= date('now', '-3 months'));

-- 3g. Overdue job: mark late bills and add the 2% penalty on that month only
UPDATE billing_statements SET penalty_amount = ROUND(amount_due * 0.02, 2), status = 'Overdue'
 WHERE status = 'Unpaid' AND due_date < date('now');
UPDATE payment_schedules SET status = 'Overdue'
 WHERE schedule_id IN (SELECT schedule_id FROM billing_statements WHERE status = 'Overdue');

-- ============================ 4. DELETE ==============================
-- 4a. Rejected registrations are removed 30 days after rejection
--     (profile, bank, employment, application and documents are removed by ON DELETE CASCADE)
DELETE FROM users
 WHERE user_id IN (SELECT user_id FROM registration_applications
                    WHERE status = 'Rejected' AND delete_after <= date('now'));

-- 4b. Remove a failed savings deposit that has no request attached
DELETE FROM savings_transactions
 WHERE status = 'Failed' AND category = 'Deposit'
   AND txn_no NOT IN (SELECT txn_no FROM withdrawal_requests);

-- 4c. Business rule demo: this FAILS because the user has loan history (FK RESTRICT)
-- DELETE FROM users WHERE user_id = 1;

-- ============================ 5. JOIN ================================
-- 5a. Users with account type, status, profile and employer
SELECT u.user_id, u.username, p.first_name || ' ' || p.last_name AS full_name,
       t.type_name, s.status_name, e.company_name, e.monthly_earnings
  FROM users u
  JOIN user_profiles   p ON p.user_id = u.user_id
  JOIN account_types   t ON t.account_type_id = u.account_type_id
  JOIN account_statuses s ON s.status_id = u.status_id
  JOIN user_employment e ON e.user_id = u.user_id;

-- 5b. Loans with borrower and approving admin (LEFT JOIN keeps pending loans)
SELECT l.loan_id, u.username, l.principal_amount, l.term_months, l.received_amount,
       l.status, a.full_name AS reviewed_by
  FROM loan_applications l
  JOIN users u ON u.user_id = l.user_id
  LEFT JOIN administrators a ON a.admin_id = l.reviewed_by;

-- 5c. Billing statement (the "format" a borrower sees)
SELECT b.billing_id, b.date_generated, p.first_name || ' ' || p.last_name AS borrower,
       t.type_name AS account_type, l.principal_amount AS loaned_amount, l.received_amount,
       b.amount_due, b.interest_amount, b.penalty_amount, b.total_amount, b.status
  FROM billing_statements b
  JOIN payment_schedules ps ON ps.schedule_id = b.schedule_id
  JOIN loan_applications l  ON l.loan_id = ps.loan_id
  JOIN users u              ON u.user_id = l.user_id
  JOIN user_profiles p      ON p.user_id = u.user_id
  JOIN account_types t      ON t.account_type_id = u.account_type_id;

-- 5d. Savings page: all transactions from all users
SELECT * FROM v_savings_transactions;

-- 5e. Payments with the bill and the borrower
SELECT lp.reference_no, lp.payment_date, lp.amount_paid, lp.payment_method, u.username, ps.installment_no
  FROM loan_payments lp
  JOIN billing_statements b ON b.billing_id = lp.billing_id
  JOIN payment_schedules ps ON ps.schedule_id = b.schedule_id
  JOIN loan_applications l  ON l.loan_id = ps.loan_id
  JOIN users u              ON u.user_id = l.user_id;

-- 5f. Admin "users" page (loans / savings / billing per user)
SELECT * FROM v_user_summary;

-- 5g. Money back allocations per premium member
SELECT m.income_year, m.total_company_income, m.share_per_member, u.username, ma.amount, st.txn_id
  FROM money_back_allocations ma
  JOIN money_back_earnings m ON m.earning_id = ma.earning_id
  JOIN users u               ON u.user_id = ma.user_id
  JOIN savings_transactions st ON st.txn_no = ma.savings_txn_no;

-- ======================= 6. WHERE and ORDER BY =======================
SELECT * FROM billing_statements WHERE status = 'Overdue' ORDER BY due_date ASC;
SELECT * FROM loan_applications WHERE status = 'Approved' AND principal_amount >= 8000 ORDER BY principal_amount DESC;
SELECT * FROM v_savings_transactions WHERE category = 'Withdrawal' ORDER BY created_at DESC;   -- withdrawals only
SELECT * FROM v_savings_transactions WHERE category = 'Deposit'    ORDER BY created_at DESC;   -- deposits only
SELECT * FROM v_savings_transactions WHERE "Transaction ID" LIKE 'STX-%';                      -- search by txn ID
SELECT username, email FROM users WHERE email LIKE '%@gmail.com' ORDER BY username;
SELECT * FROM registration_applications WHERE status = 'Pending' ORDER BY submitted_at;
SELECT * FROM v_billing WHERE user_id = 5 AND bill_year = '2026' ORDER BY due_date;           -- billing history by year/month

-- ======================= 7. AGGREGATE FUNCTIONS ======================
SELECT COUNT(*)                 AS total_loans,
       SUM(principal_amount)    AS total_principal,
       AVG(principal_amount)    AS avg_loan,
       MIN(principal_amount)    AS smallest_loan,
       MAX(principal_amount)    AS biggest_loan
  FROM loan_applications WHERE status = 'Approved';

SELECT COUNT(*) AS premium_members FROM users u JOIN account_types t USING (account_type_id)
 WHERE t.type_name = 'Premium' AND u.is_verified = 1;                    -- 50 max

SELECT SUM(balance) AS total_savings, AVG(balance) AS avg_savings,
       MIN(balance) AS lowest, MAX(balance) AS highest FROM savings_accounts;

-- Company earnings: 3% interest collected upfront on all released loans + yearly income record
SELECT SUM(interest_amount) AS total_interest_earned FROM loan_applications WHERE status = 'Approved';
SELECT income_year, total_company_income, ROUND(total_company_income * share_rate, 2) AS money_back_pool,
       share_per_member FROM money_back_earnings;

-- ============================ 8. GROUP BY ============================
-- Total loans per user
SELECT u.username, COUNT(l.loan_id) AS loans, SUM(l.principal_amount) AS total_loaned
  FROM users u JOIN loan_applications l ON l.user_id = u.user_id
 GROUP BY u.user_id ORDER BY total_loaned DESC;

-- Loans per status
SELECT status, COUNT(*) AS loans, SUM(principal_amount) AS amount FROM loan_applications GROUP BY status;

-- Savings transactions per category and status
SELECT category, status, COUNT(*) AS transactions, SUM(amount) AS total_amount
  FROM savings_transactions GROUP BY category, status ORDER BY category, status;

-- Total savings transactions per user
SELECT u.username, COUNT(*) AS transactions, SUM(st.amount) AS total
  FROM savings_transactions st JOIN savings_accounts sa USING (savings_id) JOIN users u ON u.user_id = sa.user_id
 GROUP BY u.user_id;

-- Billing per month (billing history grouped by year -> month), with HAVING
SELECT strftime('%Y', due_date) AS year, strftime('%m', due_date) AS month,
       COUNT(*) AS bills, SUM(total_amount) AS total_billed, SUM(penalty_amount) AS penalties
  FROM billing_statements GROUP BY year, month HAVING COUNT(*) >= 1 ORDER BY year, month;

-- Users per account type and status
SELECT t.type_name, s.status_name, COUNT(*) AS users
  FROM users u JOIN account_types t USING (account_type_id) JOIN account_statuses s USING (status_id)
 GROUP BY t.type_name, s.status_name;

-- Admin workload
SELECT a.full_name, l.action_type, COUNT(*) AS times
  FROM admin_activity_logs l JOIN administrators a USING (admin_id) GROUP BY a.admin_id, l.action_type;
