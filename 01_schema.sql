-- =====================================================================
-- LOAN AND SAVINGS MANAGEMENT SYSTEM  |  Platform: Letos (SQLite 3)
-- File 1 of 3 : SCHEMA  (21 tables + triggers + views)
-- Run order   : 01_schema.sql -> 02_sample_data.sql -> 03_operations.sql
-- =====================================================================
PRAGMA foreign_keys = ON;

-- ---------------------------------------------------------------------
-- A. USER MANAGEMENT
-- ---------------------------------------------------------------------
CREATE TABLE account_types (                       -- 1
    account_type_id INTEGER PRIMARY KEY AUTOINCREMENT,
    type_name       TEXT    NOT NULL UNIQUE CHECK (type_name IN ('Basic','Premium')),
    can_loan        INTEGER NOT NULL DEFAULT 1 CHECK (can_loan IN (0,1)),
    can_save        INTEGER NOT NULL DEFAULT 0 CHECK (can_save IN (0,1)),
    can_money_back  INTEGER NOT NULL DEFAULT 0 CHECK (can_money_back IN (0,1)),
    max_members     INTEGER CHECK (max_members IS NULL OR max_members > 0)  -- NULL = unlimited
);

CREATE TABLE account_statuses (                    -- 2
    status_id   INTEGER PRIMARY KEY AUTOINCREMENT,
    status_name TEXT NOT NULL UNIQUE CHECK (status_name IN ('Active','Disabled')),
    description TEXT
);

CREATE TABLE users (                               -- 3  (login credentials + account)
    user_id         INTEGER PRIMARY KEY AUTOINCREMENT,
    username        TEXT    NOT NULL UNIQUE CHECK (length(username) >= 6),
    password_hash   TEXT    NOT NULL CHECK (length(password_hash) >= 20), -- store a bcrypt/argon2 hash, never plain text
    email           TEXT    NOT NULL UNIQUE CHECK (email LIKE '%_@_%._%'),
    account_type_id INTEGER NOT NULL REFERENCES account_types(account_type_id),
    status_id       INTEGER NOT NULL DEFAULT 1 REFERENCES account_statuses(status_id),
    is_verified     INTEGER NOT NULL DEFAULT 0 CHECK (is_verified IN (0,1)),  -- "verified" tag
    disabled_reason TEXT,
    created_at      TEXT    NOT NULL DEFAULT (datetime('now')),
    updated_at      TEXT
);

CREATE TABLE user_profiles (                       -- 4  (personal information)
    profile_id     INTEGER PRIMARY KEY AUTOINCREMENT,
    user_id        INTEGER NOT NULL UNIQUE REFERENCES users(user_id) ON DELETE CASCADE,
    first_name     TEXT NOT NULL,
    middle_name    TEXT,
    last_name      TEXT NOT NULL,
    address        TEXT NOT NULL,
    gender         TEXT CHECK (gender IN ('Male','Female','Other')),
    birthday       TEXT NOT NULL CHECK (birthday GLOB '[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]'),
    contact_number TEXT NOT NULL UNIQUE                       -- PH mobile: 09XXXXXXXXX
                   CHECK (contact_number GLOB '09[0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9]'),
    tin_number     TEXT NOT NULL UNIQUE                       -- 000-000-000-000
                   CHECK (tin_number GLOB '[0-9][0-9][0-9]-[0-9][0-9][0-9]-[0-9][0-9][0-9]-[0-9][0-9][0-9]')
);                                                            -- age is calculated in view v_user_age

CREATE TABLE user_banks (                          -- 5  (bank details)
    bank_id             INTEGER PRIMARY KEY AUTOINCREMENT,
    user_id             INTEGER NOT NULL UNIQUE REFERENCES users(user_id) ON DELETE CASCADE,
    bank_name           TEXT NOT NULL,
    bank_account_number TEXT NOT NULL CHECK (bank_account_number NOT GLOB '*[^0-9]*'),
    card_holder_name    TEXT NOT NULL   -- UI must warn: "make sure the card holder's name is correct"
);

CREATE TABLE user_employment (                     -- 6  (employment information)
    employment_id     INTEGER PRIMARY KEY AUTOINCREMENT,
    user_id           INTEGER NOT NULL UNIQUE REFERENCES users(user_id) ON DELETE CASCADE,
    company_name      TEXT NOT NULL,
    company_address   TEXT NOT NULL,
    company_phone     TEXT NOT NULL,
    hr_contact_number TEXT NOT NULL,   -- number directed to HR to confirm employment
    position          TEXT NOT NULL,
    monthly_earnings  REAL NOT NULL CHECK (monthly_earnings > 0)
);

-- ---------------------------------------------------------------------
-- B. ADMINISTRATOR MANAGEMENT
-- ---------------------------------------------------------------------
CREATE TABLE administrators (                      -- 7
    admin_id      INTEGER PRIMARY KEY AUTOINCREMENT,
    username      TEXT NOT NULL UNIQUE CHECK (length(username) >= 6),
    password_hash TEXT NOT NULL CHECK (length(password_hash) >= 20),
    full_name     TEXT NOT NULL,
    email         TEXT NOT NULL UNIQUE CHECK (email LIKE '%_@_%._%'),
    role          TEXT NOT NULL DEFAULT 'Verifier' CHECK (role IN ('Super Admin','Verifier','Finance')),
    is_active     INTEGER NOT NULL DEFAULT 1 CHECK (is_active IN (0,1)),
    created_at    TEXT NOT NULL DEFAULT (datetime('now'))
);

CREATE TABLE blocked_emails (                      -- 8
    blocked_id       INTEGER PRIMARY KEY AUTOINCREMENT,
    email            TEXT NOT NULL UNIQUE COLLATE NOCASE,
    reason           TEXT,
    blocked_by_admin INTEGER NOT NULL REFERENCES administrators(admin_id),
    blocked_at       TEXT NOT NULL DEFAULT (datetime('now'))
);

-- ---------------------------------------------------------------------
-- C. REGISTRATION AND VERIFICATION
-- ---------------------------------------------------------------------
CREATE TABLE registration_applications (           -- 9
    application_id    INTEGER PRIMARY KEY AUTOINCREMENT,
    user_id           INTEGER NOT NULL UNIQUE REFERENCES users(user_id) ON DELETE CASCADE,
    requested_type_id INTEGER NOT NULL REFERENCES account_types(account_type_id),
    status            TEXT NOT NULL DEFAULT 'Pending' CHECK (status IN ('Pending','Approved','Rejected')),
    submitted_at      TEXT NOT NULL DEFAULT (datetime('now')),
    reviewed_by       INTEGER REFERENCES administrators(admin_id),
    reviewed_at       TEXT,
    tin_verified      INTEGER NOT NULL DEFAULT 0 CHECK (tin_verified IN (0,1)),      -- confirmed with BIR
    company_verified  INTEGER NOT NULL DEFAULT 0 CHECK (company_verified IN (0,1)),  -- confirmed with employer
    rejection_reason  TEXT,
    delete_after      TEXT,   -- rejected applications are deleted 30 days after rejection
    CHECK (status = 'Pending' OR (reviewed_by IS NOT NULL AND reviewed_at IS NOT NULL)),
    CHECK (status <> 'Rejected' OR rejection_reason IS NOT NULL)
);

CREATE TABLE submitted_documents (                 -- 10
    document_id   INTEGER PRIMARY KEY AUTOINCREMENT,
    application_id INTEGER NOT NULL REFERENCES registration_applications(application_id) ON DELETE CASCADE,
    document_type TEXT NOT NULL CHECK (document_type IN ('Proof of Billing','Valid ID Primary','COE')),
    file_path     TEXT NOT NULL,
    uploaded_at   TEXT NOT NULL DEFAULT (datetime('now')),
    is_legit      INTEGER CHECK (is_legit IN (0,1)),   -- NULL = not yet checked
    verified_by   INTEGER REFERENCES administrators(admin_id),
    verified_at   TEXT,
    UNIQUE (application_id, document_type)
);

-- ---------------------------------------------------------------------
-- D. LOAN MANAGEMENT
-- ---------------------------------------------------------------------
CREATE TABLE loan_applications (                   -- 11
    loan_id          INTEGER PRIMARY KEY AUTOINCREMENT,
    user_id          INTEGER NOT NULL REFERENCES users(user_id),
    principal_amount REAL    NOT NULL CHECK (principal_amount BETWEEN 5000 AND 50000
                                              AND principal_amount % 1000 = 0),     -- thousands only
    term_months      INTEGER NOT NULL CHECK (term_months BETWEEN 1 AND 32),
    interest_rate    REAL    NOT NULL DEFAULT 0.03 CHECK (interest_rate >= 0),
    interest_amount  REAL GENERATED ALWAYS AS (ROUND(principal_amount * interest_rate, 2)) STORED,
    received_amount  REAL GENERATED ALWAYS AS (ROUND(principal_amount - principal_amount * interest_rate, 2)) STORED,
    monthly_amount   REAL GENERATED ALWAYS AS (ROUND(principal_amount * 1.0 / term_months, 2)) STORED,
    status           TEXT NOT NULL DEFAULT 'Pending' CHECK (status IN ('Pending','Approved','Rejected')),
    applied_at       TEXT NOT NULL DEFAULT (datetime('now')),
    reviewed_by      INTEGER REFERENCES administrators(admin_id),
    reviewed_at      TEXT,
    released_at      TEXT,
    rejection_reason TEXT,
    CHECK (status <> 'Rejected' OR rejection_reason IS NOT NULL),
    CHECK (status <> 'Approved' OR (reviewed_by IS NOT NULL AND released_at IS NOT NULL))
);

CREATE TABLE loan_transactions (                   -- 12
    txn_no       INTEGER PRIMARY KEY AUTOINCREMENT,                    -- "No." auto-increment
    txn_id       TEXT NOT NULL UNIQUE DEFAULT ('LTX-' || upper(hex(randomblob(5)))),  -- random unique ID
    loan_id      INTEGER NOT NULL REFERENCES loan_applications(loan_id),
    user_id      INTEGER NOT NULL REFERENCES users(user_id),
    txn_type     TEXT NOT NULL CHECK (txn_type IN ('Loan Application','Loan Limit Increase','Term Increase')),
    amount       REAL,
    term_months  INTEGER,
    status       TEXT NOT NULL DEFAULT 'Pending' CHECK (status IN ('Pending','Approved','Rejected')),
    remarks      TEXT,                                                 -- reason when rejected
    processed_by INTEGER REFERENCES administrators(admin_id),
    created_at   TEXT NOT NULL DEFAULT (datetime('now')),
    CHECK (status <> 'Rejected' OR remarks IS NOT NULL)
);

CREATE TABLE payment_schedules (                   -- 13  (monthly payment schedule)
    schedule_id    INTEGER PRIMARY KEY AUTOINCREMENT,
    loan_id        INTEGER NOT NULL REFERENCES loan_applications(loan_id) ON DELETE CASCADE,
    installment_no INTEGER NOT NULL CHECK (installment_no >= 1),
    due_date       TEXT NOT NULL,
    amount_due     REAL NOT NULL CHECK (amount_due > 0),
    status         TEXT NOT NULL DEFAULT 'Pending' CHECK (status IN ('Pending','Paid','Overdue')),
    UNIQUE (loan_id, installment_no)
);

CREATE TABLE billing_statements (                  -- 14
    billing_id     INTEGER PRIMARY KEY AUTOINCREMENT,
    schedule_id    INTEGER NOT NULL UNIQUE REFERENCES payment_schedules(schedule_id) ON DELETE CASCADE,
    date_generated TEXT NOT NULL DEFAULT (date('now')),
    due_date       TEXT NOT NULL,
    amount_due     REAL NOT NULL CHECK (amount_due > 0),        -- monthly amount WITHOUT interest
    interest_amount REAL NOT NULL DEFAULT 0 CHECK (interest_amount >= 0), -- 3% share, already deducted upfront (display only)
    penalty_amount REAL NOT NULL DEFAULT 0 CHECK (penalty_amount >= 0),   -- 2% of the missed month only
    total_amount   REAL GENERATED ALWAYS AS (ROUND(amount_due + penalty_amount, 2)) STORED,
    status         TEXT NOT NULL DEFAULT 'Unpaid' CHECK (status IN ('Unpaid','Completed','Overdue')),
    paid_at        TEXT
);

CREATE TABLE loan_payments (                       -- 15
    payment_id     INTEGER PRIMARY KEY AUTOINCREMENT,
    billing_id     INTEGER NOT NULL REFERENCES billing_statements(billing_id),
    amount_paid    REAL NOT NULL CHECK (amount_paid > 0),
    payment_date   TEXT NOT NULL DEFAULT (datetime('now')),
    payment_method TEXT NOT NULL DEFAULT 'Bank Transfer'
                   CHECK (payment_method IN ('Bank Transfer','GCash','Over the Counter')),
    reference_no   TEXT NOT NULL UNIQUE
);

-- ---------------------------------------------------------------------
-- E. SAVINGS MANAGEMENT  (Premium only)
-- ---------------------------------------------------------------------
CREATE TABLE savings_accounts (                    -- 16
    savings_id         INTEGER PRIMARY KEY AUTOINCREMENT,
    user_id            INTEGER NOT NULL UNIQUE REFERENCES users(user_id),
    balance            REAL NOT NULL DEFAULT 0 CHECK (balance >= 0 AND balance <= 100000),  -- max 100k
    opened_at          TEXT NOT NULL DEFAULT (date('now')),
    zero_balance_since TEXT   -- date balance became 0 (3 months at 0 => downgrade to Basic)
);

CREATE TABLE savings_transactions (                -- 17
    txn_no       INTEGER PRIMARY KEY AUTOINCREMENT,                    -- "No." auto-increment
    txn_id       TEXT NOT NULL UNIQUE DEFAULT ('STX-' || upper(hex(randomblob(5)))),  -- random unique ID
    savings_id   INTEGER NOT NULL REFERENCES savings_accounts(savings_id),
    category     TEXT NOT NULL CHECK (category IN ('Deposit','Withdrawal')),
    source       TEXT NOT NULL DEFAULT 'Manual' CHECK (source IN ('Manual','Money Back')),
    amount       REAL NOT NULL CHECK (amount > 0),
    status       TEXT NOT NULL DEFAULT 'Pending' CHECK (status IN ('Pending','Failed','Rejected','Completed')),
    created_at   TEXT NOT NULL DEFAULT (datetime('now')),
    processed_at TEXT,
    CHECK (status <> 'Rejected' OR category = 'Withdrawal'),          -- Rejected only for withdrawals
    CHECK (source = 'Manual' OR category = 'Deposit'),
    CHECK ( (category = 'Deposit'    AND source = 'Manual'     AND amount BETWEEN 100 AND 1000)
         OR (category = 'Deposit'    AND source = 'Money Back')
         OR (category = 'Withdrawal' AND amount BETWEEN 500 AND 5000) )
);

CREATE TABLE withdrawal_requests (                 -- 18  (savings withdrawal request form)
    request_id     INTEGER PRIMARY KEY AUTOINCREMENT,
    txn_no         INTEGER NOT NULL UNIQUE REFERENCES savings_transactions(txn_no),
    reason         TEXT,
    request_status TEXT NOT NULL DEFAULT 'Pending' CHECK (request_status IN ('Pending','Approved','Rejected')),
    requested_at   TEXT NOT NULL DEFAULT (datetime('now')),
    reviewed_by    INTEGER REFERENCES administrators(admin_id),
    reviewed_at    TEXT,
    admin_note     TEXT,
    CHECK (request_status <> 'Rejected' OR admin_note IS NOT NULL)
);

-- ---------------------------------------------------------------------
-- F. MONEY BACK EARNINGS
-- ---------------------------------------------------------------------
CREATE TABLE money_back_earnings (                 -- 19  (annual income + computation record)
    earning_id           INTEGER PRIMARY KEY AUTOINCREMENT,
    income_year          INTEGER NOT NULL UNIQUE CHECK (income_year >= 2020),
    total_company_income REAL    NOT NULL CHECK (total_company_income >= 0),
    share_rate           REAL    NOT NULL DEFAULT 0.02,
    premium_member_count INTEGER NOT NULL CHECK (premium_member_count > 0),
    share_per_member     REAL GENERATED ALWAYS AS
                         (ROUND(total_company_income * share_rate / premium_member_count, 2)) STORED,
    computed_by          INTEGER NOT NULL REFERENCES administrators(admin_id),
    computed_at          TEXT NOT NULL DEFAULT (datetime('now'))
);

CREATE TABLE money_back_allocations (              -- 20  (premium allocation + savings credit)
    allocation_id  INTEGER PRIMARY KEY AUTOINCREMENT,
    earning_id     INTEGER NOT NULL REFERENCES money_back_earnings(earning_id),
    user_id        INTEGER NOT NULL REFERENCES users(user_id),
    savings_txn_no INTEGER UNIQUE REFERENCES savings_transactions(txn_no),   -- the credit to savings
    amount         REAL NOT NULL CHECK (amount > 0),
    allocated_at   TEXT NOT NULL DEFAULT (datetime('now')),
    UNIQUE (earning_id, user_id)
);

-- ---------------------------------------------------------------------
-- G. ADMIN ACTIVITY RECORDS
-- ---------------------------------------------------------------------
CREATE TABLE admin_activity_logs (                 -- 21
    log_id       INTEGER PRIMARY KEY AUTOINCREMENT,
    admin_id     INTEGER NOT NULL REFERENCES administrators(admin_id),
    action_type  TEXT NOT NULL,
    target_table TEXT,
    target_id    INTEGER,
    description  TEXT,
    created_at   TEXT NOT NULL DEFAULT (datetime('now'))
);

-- ---------------------------------------------------------------------
-- INDEXES
-- ---------------------------------------------------------------------
CREATE INDEX idx_users_type          ON users(account_type_id);
CREATE INDEX idx_loans_user          ON loan_applications(user_id, status);
CREATE INDEX idx_sched_due           ON payment_schedules(due_date, status);
CREATE INDEX idx_bill_status         ON billing_statements(status, due_date);
CREATE INDEX idx_sav_txn_account     ON savings_transactions(savings_id, category, status);
CREATE INDEX idx_logs_admin          ON admin_activity_logs(admin_id, created_at);

-- ---------------------------------------------------------------------
-- TRIGGERS  (business rules that cannot be written as plain CHECKs)
-- ---------------------------------------------------------------------
-- R1: max 50 Premium members (Basic unlimited)
CREATE TRIGGER trg_premium_limit_ins BEFORE INSERT ON users
WHEN (SELECT max_members FROM account_types WHERE account_type_id = NEW.account_type_id) IS NOT NULL
BEGIN
    SELECT RAISE(ABORT, 'Premium slots are full (max 50 members)')
    WHERE (SELECT COUNT(*) FROM users WHERE account_type_id = NEW.account_type_id)
       >= (SELECT max_members FROM account_types WHERE account_type_id = NEW.account_type_id);
END;

CREATE TRIGGER trg_premium_limit_upd BEFORE UPDATE OF account_type_id ON users
WHEN NEW.account_type_id <> OLD.account_type_id
 AND (SELECT max_members FROM account_types WHERE account_type_id = NEW.account_type_id) IS NOT NULL
BEGIN
    SELECT RAISE(ABORT, 'Premium slots are full (max 50 members)')
    WHERE (SELECT COUNT(*) FROM users WHERE account_type_id = NEW.account_type_id)
       >= (SELECT max_members FROM account_types WHERE account_type_id = NEW.account_type_id);
END;

-- R2: blocked e-mail addresses cannot register
CREATE TRIGGER trg_block_email BEFORE INSERT ON users
BEGIN
    SELECT RAISE(ABORT, 'This email address is blocked')
    WHERE EXISTS (SELECT 1 FROM blocked_emails WHERE email = NEW.email);
END;

-- R3: rejected registration is scheduled for automatic deletion after 30 days
CREATE TRIGGER trg_reject_registration AFTER UPDATE OF status ON registration_applications
WHEN NEW.status = 'Rejected' AND OLD.status <> 'Rejected'
BEGIN
    UPDATE registration_applications
       SET delete_after = date(COALESCE(NEW.reviewed_at, datetime('now')), '+30 days')
     WHERE application_id = NEW.application_id;
END;

-- R4: approved registration => account gets the "verified" tag
CREATE TRIGGER trg_approve_registration AFTER UPDATE OF status ON registration_applications
WHEN NEW.status = 'Approved' AND OLD.status <> 'Approved'
BEGIN
    UPDATE users SET is_verified = 1, updated_at = datetime('now') WHERE user_id = NEW.user_id;
END;

-- R5: loan rules (active account, loan limit/term grow after fully paid loans)
--     limit  = min(50000, 10000 + 5000 x fully-paid loans)
--     months = 1/3/6/12 at first, then 12 + 3 x fully-paid loans (max 32)
CREATE TRIGGER trg_loan_rules BEFORE INSERT ON loan_applications
BEGIN
    SELECT RAISE(ABORT, 'Account is disabled - cannot apply for a loan')
    WHERE (SELECT status_id FROM users WHERE user_id = NEW.user_id) <> 1;

    SELECT RAISE(ABORT, 'Account is not verified yet')
    WHERE (SELECT is_verified FROM users WHERE user_id = NEW.user_id) = 0;

    SELECT RAISE(ABORT, 'Amount exceeds the current loan limit')
    WHERE NEW.principal_amount >
        MIN(50000, 10000 + 5000 * (SELECT COUNT(*) FROM loan_applications la
                                    WHERE la.user_id = NEW.user_id AND la.status = 'Approved'
                                      AND NOT EXISTS (SELECT 1 FROM payment_schedules ps
                                                       WHERE ps.loan_id = la.loan_id AND ps.status <> 'Paid')));

    SELECT RAISE(ABORT, 'Payable months must be 1, 3, 6 or 12 (or an unlocked longer term)')
    WHERE NEW.term_months <= 12 AND NEW.term_months NOT IN (1,3,6,12);

    SELECT RAISE(ABORT, 'Term exceeds the currently unlocked payable months')
    WHERE NEW.term_months > 12 AND NEW.term_months >
        MIN(32, 12 + 3 * (SELECT COUNT(*) FROM loan_applications la
                           WHERE la.user_id = NEW.user_id AND la.status = 'Approved'
                             AND NOT EXISTS (SELECT 1 FROM payment_schedules ps
                                              WHERE ps.loan_id = la.loan_id AND ps.status <> 'Paid')));
END;

-- R6: when a loan is approved, build the monthly payment schedule (due every 28 days)
CREATE TRIGGER trg_loan_approved AFTER UPDATE OF status ON loan_applications
WHEN NEW.status = 'Approved' AND OLD.status <> 'Approved'
BEGIN
    INSERT INTO payment_schedules (loan_id, installment_no, due_date, amount_due)
    WITH RECURSIVE n(i) AS (SELECT 1 UNION ALL SELECT i + 1 FROM n WHERE i < NEW.term_months)
    SELECT NEW.loan_id, i, date(NEW.released_at, '+' || (28 * i) || ' days'), NEW.monthly_amount
      FROM n;
END;

-- R7: a payment that covers the bill marks the bill Completed and the schedule Paid
CREATE TRIGGER trg_payment_applied AFTER INSERT ON loan_payments
BEGIN
    UPDATE billing_statements
       SET status = 'Completed', paid_at = NEW.payment_date
     WHERE billing_id = NEW.billing_id
       AND (SELECT SUM(amount_paid) FROM loan_payments WHERE billing_id = NEW.billing_id) >= total_amount;
    UPDATE payment_schedules SET status = 'Paid'
     WHERE schedule_id = (SELECT schedule_id FROM billing_statements WHERE billing_id = NEW.billing_id)
       AND EXISTS (SELECT 1 FROM billing_statements WHERE billing_id = NEW.billing_id AND status = 'Completed');
END;

-- R8: only Premium accounts can have savings
CREATE TRIGGER trg_savings_premium_only BEFORE INSERT ON savings_accounts
BEGIN
    SELECT RAISE(ABORT, 'Only Premium accounts can have savings')
    WHERE (SELECT t.can_save FROM users u JOIN account_types t USING (account_type_id)
            WHERE u.user_id = NEW.user_id) = 0;
END;

-- R9: withdrawals: max 5 per day and max 5,000 per day
CREATE TRIGGER trg_withdraw_limits BEFORE INSERT ON savings_transactions
WHEN NEW.category = 'Withdrawal'
BEGIN
    SELECT RAISE(ABORT, 'Maximum of 5 withdrawals per day reached')
    WHERE (SELECT COUNT(*) FROM savings_transactions
            WHERE savings_id = NEW.savings_id AND category = 'Withdrawal'
              AND status IN ('Pending','Completed')
              AND date(created_at) = date(NEW.created_at)) >= 5;

    SELECT RAISE(ABORT, 'Daily withdrawal limit of 5,000 exceeded')
    WHERE (SELECT COALESCE(SUM(amount),0) FROM savings_transactions
            WHERE savings_id = NEW.savings_id AND category = 'Withdrawal'
              AND status IN ('Pending','Completed')
              AND date(created_at) = date(NEW.created_at)) + NEW.amount > 5000;
END;

-- R10: Completed transactions update the savings balance (CHECK keeps 0..100,000)
CREATE TRIGGER trg_sav_balance_ins AFTER INSERT ON savings_transactions
WHEN NEW.status = 'Completed'
BEGIN
    UPDATE savings_accounts
       SET balance = balance + CASE NEW.category WHEN 'Deposit' THEN NEW.amount ELSE -NEW.amount END,
           zero_balance_since = CASE
               WHEN balance + CASE NEW.category WHEN 'Deposit' THEN NEW.amount ELSE -NEW.amount END = 0
               THEN COALESCE(date(NEW.processed_at), date(NEW.created_at)) ELSE NULL END
     WHERE savings_id = NEW.savings_id;
END;

CREATE TRIGGER trg_sav_balance_upd AFTER UPDATE OF status ON savings_transactions
WHEN NEW.status = 'Completed' AND OLD.status <> 'Completed'
BEGIN
    UPDATE savings_accounts
       SET balance = balance + CASE NEW.category WHEN 'Deposit' THEN NEW.amount ELSE -NEW.amount END,
           zero_balance_since = CASE
               WHEN balance + CASE NEW.category WHEN 'Deposit' THEN NEW.amount ELSE -NEW.amount END = 0
               THEN COALESCE(date(NEW.processed_at), date('now')) ELSE NULL END
     WHERE savings_id = NEW.savings_id;
END;

-- ---------------------------------------------------------------------
-- VIEWS
-- ---------------------------------------------------------------------
-- Age is auto-calculated from birthday (no stored/duplicated age column)
CREATE VIEW v_user_age AS
SELECT u.user_id, u.username,
       p.first_name || ' ' || p.last_name AS full_name,
       p.birthday,
       CAST((julianday('now') - julianday(p.birthday)) / 365.25 AS INTEGER) AS age
  FROM users u JOIN user_profiles p USING (user_id);

-- Admin "Users" page: loans / savings / billing per user
CREATE VIEW v_user_summary AS
SELECT u.user_id, u.username, t.type_name AS account_type, s.status_name AS account_status,
       (SELECT COUNT(*) FROM loan_applications l WHERE l.user_id = u.user_id)                         AS loans,
       (SELECT COALESCE(SUM(principal_amount),0) FROM loan_applications l
         WHERE l.user_id = u.user_id AND l.status = 'Approved')                                        AS total_borrowed,
       COALESCE((SELECT balance FROM savings_accounts sa WHERE sa.user_id = u.user_id), 0)           AS savings_balance,
       (SELECT COUNT(*) FROM billing_statements b
          JOIN payment_schedules ps USING (schedule_id) JOIN loan_applications l USING (loan_id)
         WHERE l.user_id = u.user_id AND b.status = 'Overdue')                                         AS overdue_bills
  FROM users u
  JOIN account_types t    ON t.account_type_id = u.account_type_id
  JOIN account_statuses s ON s.status_id       = u.status_id;

-- Admin "Savings page": all transactions from all users
CREATE VIEW v_savings_transactions AS
SELECT st.txn_no AS "No.", st.txn_id AS "Transaction ID", u.username, st.category,
       st.source, st.amount, st.status, st.created_at, st.processed_at
  FROM savings_transactions st
  JOIN savings_accounts sa USING (savings_id)
  JOIN users u ON u.user_id = sa.user_id;

-- Billing page for a borrower (current/overdue bills)
CREATE VIEW v_billing AS
SELECT b.billing_id, l.user_id, l.loan_id, b.date_generated, b.due_date,
       strftime('%Y', b.due_date) AS bill_year, strftime('%m', b.due_date) AS bill_month,
       l.principal_amount AS loaned_amount, l.received_amount,
       b.amount_due, b.interest_amount, b.penalty_amount, b.total_amount, b.status
  FROM billing_statements b
  JOIN payment_schedules ps USING (schedule_id)
  JOIN loan_applications l  USING (loan_id);
