# Loan and Savings Management System - Letos (SQLite) database

Letos is the SQLite manager formerly known as SQLiteStudio, so the database is a SQLite file.

## Files
| File | Purpose |
|---|---|
| loan_savings.db | Ready-made database (schema + sample data). Open directly in Letos. |
| 01_schema.sql | 21 tables, constraints, indexes, 12 triggers, 4 views |
| 02_sample_data.sql | Sample users, loans, billing, savings, money back, admin logs ("today" = 2026-11-22) |
| 03_operations.sql | INSERT / SELECT / UPDATE / DELETE / JOIN / WHERE+ORDER BY / aggregates / GROUP BY |
| ERD.mmd, ERD.html | Crow's Foot ERD (Mermaid). Open ERD.html in a browser (needs internet), or paste ERD.mmd into mermaid.live |

## Process (in Letos)
1. Database > Add a database > select loan_savings.db  (quick way), OR
   Database > Add a database > New file (e.g. my_loans.db) to build it yourself:
2. Open the SQL editor (Tools > Open SQL editor, Alt+E) on that database.
3. Open 01_schema.sql in the editor -> Execute all (F9). Tables appear in the left tree (Refresh with F5).
4. Open 02_sample_data.sql -> Execute all (F9).
5. Open 03_operations.sql. Select ONE block and press Ctrl+Enter to run it; results show in the grid below.
6. ERD: use Letos' ERD editor plugin (if enabled) or the supplied ERD.html.
Tip: Run `PRAGMA foreign_keys = ON;` first in each SQL editor tab so foreign keys are enforced.

## Design notes
* 21 tables, all in 3NF. Age is not stored: view v_user_age calculates it from birthday.
* Loan: interest 3% charged upfront (received = principal x 0.97); monthly bill = principal / months; due every 28 days after release; late bill gets 2% penalty on that month only.
* Savings: balance 0..100,000; deposit 100-1,000; withdrawal 500-5,000, max 5 per day and 5,000 per day (triggers); balance updates only when a transaction becomes Completed.
* Transaction IDs are random and unique (LTX-/STX- + random hex); "No." is AUTOINCREMENT.
* 3-month zero-savings downgrade is a plain UPDATE query (no CRON needed) - see 03_operations.sql 3f.
* Passwords: store hashes only (sample hashes are fake). Password strength must be validated in the application before hashing.
* Billing status uses Unpaid/Completed/Overdue (Unpaid added for the current month's open bill).
