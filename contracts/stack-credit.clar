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

;; STATE VARIABLES

;; Auto-incrementing loan ID counter
(define-data-var next-loan-id uint u0)

;; Total STX locked as collateral across all loans
(define-data-var total-stx-locked uint u0)

;; PUBLIC FUNCTIONS

;; Initialize User Credit Profile
;; Creates a new credit profile with minimum score for first-time users
;; Must be called before requesting any loans
(define-public (initialize-score)
  (let ((sender tx-sender))
    (asserts! (is-none (map-get? UserScores { user: sender })) ERR-UNAUTHORIZED)
    (ok (map-set UserScores { user: sender } {
      score: MIN-SCORE,
      total-borrowed: u0,
      total-repaid: u0,
      loans-taken: u0,
      loans-repaid: u0,
      last-update: stacks-block-height,
    }))
  )
)

;; Request New Loan
;; Creates a new loan with dynamic collateral requirements based on credit score
;; Higher credit scores require less collateral and receive better interest rates
(define-public (request-loan
    (amount uint)
    (collateral uint)
    (duration uint)
  )
  (let (
      (sender tx-sender)
      (loan-id (+ (var-get next-loan-id) u1))
      (user-score (unwrap! (map-get? UserScores { user: sender }) ERR-UNAUTHORIZED))
      (active-loans (default-to { active-loans: (list) } (map-get? UserLoans { user: sender })))
    )
    ;; Validate loan request parameters
    (asserts! (>= (get score user-score) MIN-LOAN-SCORE) ERR-INSUFFICIENT-SCORE)
    (asserts! (<= (len (get active-loans active-loans)) MAX-ACTIVE-LOANS)
      ERR-ACTIVE-LOAN
    )
    (asserts! (> amount u0) ERR-INVALID-AMOUNT)
    (asserts! (and (> duration u0) (<= duration MAX-LOAN-DURATION))
      ERR-INVALID-DURATION
    )
    ;; Calculate and validate collateral requirements
    (let ((required-collateral (calculate-required-collateral amount (get score user-score))))
      (asserts! (>= collateral required-collateral) ERR-INSUFFICIENT-BALANCE)
      ;; Lock collateral from borrower
      (try! (stx-transfer? collateral sender (as-contract tx-sender)))
      ;; Create loan record
      (map-set Loans { loan-id: loan-id } {
        borrower: sender,
        amount: amount,
        collateral: collateral,
        due-height: (+ stacks-block-height duration),
        interest-rate: (calculate-interest-rate (get score user-score)),
        is-active: true,
        is-defaulted: false,
        repaid-amount: u0,
      })
      ;; Update user's active loan list
      (try! (update-user-loans sender loan-id))
      ;; Transfer loan amount to borrower
      (as-contract (try! (stx-transfer? amount tx-sender sender)))
      ;; Update system counters
      (var-set next-loan-id loan-id)
      (var-set total-stx-locked (+ (var-get total-stx-locked) collateral))
      (ok loan-id)
    )
  )
)

;; Repay Loan
;; Allows partial or full loan repayment with automatic collateral release
;; Successful repayments improve credit score
(define-public (repay-loan
    (loan-id uint)
    (amount uint)
  )
  (let (
      (sender tx-sender)
      (loan (unwrap! (map-get? Loans { loan-id: loan-id }) ERR-LOAN-NOT-FOUND))
    )
    ;; Validate repayment request
    (asserts! (is-eq sender (get borrower loan)) ERR-UNAUTHORIZED)
    (asserts! (get is-active loan) ERR-LOAN-NOT-FOUND)
    (asserts! (not (get is-defaulted loan)) ERR-LOAN-DEFAULTED)
    (asserts! (<= loan-id (var-get next-loan-id)) ERR-INVALID-LOAN-ID)
    ;; Process repayment
    (let ((total-due (calculate-total-due loan)))
      (asserts! (>= amount u0) ERR-INVALID-AMOUNT)
      ;; Transfer repayment to contract
      (try! (stx-transfer? amount sender (as-contract tx-sender)))
      ;; Update loan repayment status
      (let ((new-repaid-amount (+ (get repaid-amount loan) amount)))
        (map-set Loans { loan-id: loan-id }
          (merge loan {
            repaid-amount: new-repaid-amount,
            is-active: (< new-repaid-amount total-due),
          })
        )
        ;; Handle full repayment: improve credit score and release collateral
        (if (>= new-repaid-amount total-due)
          (begin
            (try! (update-credit-score sender true loan))
            (as-contract (try! (stx-transfer? (get collateral loan) tx-sender sender)))
            (var-set total-stx-locked
              (- (var-get total-stx-locked) (get collateral loan))
            )
          )
          true
        )
        (ok true)
      )
    )
  )
)

;; ADMINISTRATIVE FUNCTIONS

;; Mark Loan as Defaulted
;; Allows contract owner to mark overdue loans as defaulted
;; Defaulted loans negatively impact borrower's credit score
(define-public (mark-loan-defaulted (loan-id uint))
  (let ((loan (unwrap! (map-get? Loans { loan-id: loan-id }) ERR-LOAN-NOT-FOUND)))
    (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-UNAUTHORIZED)
    (asserts! (>= stacks-block-height (get due-height loan)) ERR-NOT-DUE)
    (asserts! (get is-active loan) ERR-LOAN-NOT-FOUND)
    (asserts! (<= loan-id (var-get next-loan-id)) ERR-INVALID-LOAN-ID)
    ;; Mark loan as defaulted and inactive
    (map-set Loans { loan-id: loan-id }
      (merge loan {
        is-defaulted: true,
        is-active: false,
      })
    )
    ;; Apply credit score penalty for default
    (try! (update-credit-score (get borrower loan) false loan))
    (ok true)
  )
)

;; PRIVATE HELPER FUNCTIONS

;; Calculate Required Collateral
;; Determines collateral amount based on credit score
;; Higher scores = lower collateral requirements
(define-private (calculate-required-collateral
    (amount uint)
    (score uint)
  )
  (let ((collateral-ratio (- u100 (/ (* score u50) u100))))
    (/ (* amount collateral-ratio) u100)
  )
)