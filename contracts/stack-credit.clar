;; StackCredit - Decentralized Credit System on Stacks Layer 2
;;
;; Summary: A trustless, Bitcoin-native credit scoring and lending platform
;; that leverages Stacks Layer 2 to provide decentralized loans with dynamic
;; collateral requirements based on on-chain credit history.
;;
;; Description: StackCredit revolutionizes DeFi lending by introducing a
;; sophisticated credit scoring mechanism that reduces over-collateralization
;; for creditworthy borrowers. Users build reputation through successful loan
;; repayments, unlocking better terms and lower collateral requirements over
;; time. The protocol is fully decentralized, transparent, and secured by
;; Bitcoin's robust infrastructure through Stacks Layer 2.
;;
;; Key Features:
;; - Dynamic credit scoring (50-100 range)
;; - Adaptive collateral requirements (lower scores = higher collateral)
;; - Interest rates tied to creditworthiness
;; - Multi-loan support per user (up to 5 active loans)
;; - Automatic default handling with score penalties
;; - Transparent on-chain loan history and reputation

;; CONSTANTS & CONFIGURATION

;; Contract Administration
(define-constant CONTRACT-OWNER tx-sender)

;; Error Codes
(define-constant ERR-UNAUTHORIZED (err u1))
(define-constant ERR-INSUFFICIENT-BALANCE (err u2))
(define-constant ERR-INVALID-AMOUNT (err u3))
(define-constant ERR-LOAN-NOT-FOUND (err u4))
(define-constant ERR-LOAN-DEFAULTED (err u5))
(define-constant ERR-INSUFFICIENT-SCORE (err u6))
(define-constant ERR-ACTIVE-LOAN (err u7))
(define-constant ERR-NOT-DUE (err u8))
(define-constant ERR-INVALID-DURATION (err u9))
(define-constant ERR-INVALID-LOAN-ID (err u10))

;; Credit Score Parameters
(define-constant MIN-SCORE u50) ;; Minimum possible credit score
(define-constant MAX-SCORE u100) ;; Maximum possible credit score
(define-constant MIN-LOAN-SCORE u70) ;; Minimum score required for loan eligibility

;; System Limits
(define-constant MAX-ACTIVE-LOANS u5) ;; Maximum active loans per user
(define-constant MAX-LOAN-DURATION u52560) ;; ~1 year in blocks (10min blocks)

;; DATA STRUCTURES

;; User Credit Profiles
;; Stores comprehensive credit history and scoring data for each user
(define-map UserScores
  { user: principal }
  {
    score: uint, ;; Current credit score (50-100)
    total-borrowed: uint, ;; Lifetime STX borrowed
    total-repaid: uint, ;; Lifetime STX repaid
    loans-taken: uint, ;; Total number of loans taken
    loans-repaid: uint, ;; Total number of loans repaid
    last-update: uint, ;; Block height of last score update
  }
)

;; Individual Loan Records
;; Comprehensive loan data including terms, status, and repayment progress
(define-map Loans
  { loan-id: uint }
  {
    borrower: principal, ;; Loan recipient
    amount: uint, ;; Principal amount in STX
    collateral: uint, ;; Collateral locked in STX
    due-height: uint, ;; Block height when loan is due
    interest-rate: uint, ;; Interest rate percentage
    is-active: bool, ;; Whether loan is currently active
    is-defaulted: bool, ;; Whether loan has defaulted
    repaid-amount: uint, ;; Amount repaid so far
  }
)

;; User Active Loan Tracking
;; Maps users to their currently active loan IDs for quick lookup
(define-map UserLoans
  { user: principal }
  { active-loans: (list 20 uint) }
)