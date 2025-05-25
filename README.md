# StackCredit 🏦

## Decentralized Credit System on Stacks Layer 2

## Overview

**StackCredit** is a trustless, Bitcoin-native credit scoring and lending protocol built on **Stacks Layer 2**. It empowers users to access decentralized loans with **dynamic collateral requirements**, based on their **on-chain creditworthiness**.

By introducing a transparent credit scoring mechanism, StackCredit minimizes over-collateralization for reliable borrowers and creates a fairer and more accessible DeFi lending experience — all while leveraging the security and finality of Bitcoin.

---

## 🔑 Key Features

* **Dynamic Credit Scoring** (Range: 50–100)
* **Adaptive Collateral Requirements**
  Lower credit scores require higher collateral.
* **Reputation-Based Interest Rates**
  Higher scores yield better rates.
* **Multi-Loan Support**
  Up to 5 concurrent loans per user.
* **On-Chain Credit Profiles**
  Transparent credit history per user.
* **Default Detection & Penalties**
  Automatic marking of overdue loans with score impact.

---

## 💡 How It Works

1. **User Initialization**
   First-time users must initialize their credit profile (score starts at 50).

2. **Loan Request**
   Users with a minimum score of 70 can request loans with collateral based on their score.

3. **Repayment**
   Loans can be partially or fully repaid. On full repayment:

   * Credit score improves.
   * Collateral is released.

4. **Default Handling**
   Loans overdue past their due block are marked defaulted by the contract owner, decreasing the borrower's credit score.

5. **Score Adjustment**

   * Successful repayment: +2 points
   * Default: -10 points

---

## ⚙️ Smart Contract Components

### Constants & Limits

* `MIN-SCORE`: 50
* `MAX-SCORE`: 100
* `MIN-LOAN-SCORE`: 70
* `MAX-ACTIVE-LOANS`: 5
* `MAX-LOAN-DURATION`: 1 year (\~52,560 blocks)

### Key Data Structures

* `UserScores`
  Stores credit score, loan history, and lifetime borrowing/repayment data.
* `Loans`
  Tracks loan terms, status, repayments, and due height.
* `UserLoans`
  Lists active loan IDs per user.

---

## 🧩 System Architecture

```text
                  ┌──────────────────────────┐
                  │      Bitcoin Layer 1     │
                  └──────────┬───────────────┘
                             │
                     Secured via Stacks
                             │
                  ┌──────────▼──────────┐
                  │   Stacks Layer 2    │
                  └──────────┬──────────┘
                             │
           ┌────────────────▼────────────────┐
           │         StackCredit Smart       │
           │            Contract             │
           └──────────┬──────────┬───────────┘
                      │          │
    ┌─────────────────▼──┐   ┌───▼────────────────┐
    │   UserScores Map   │   │     Loans Map      │
    └────────────────────┘   └────────────────────┘
              │                       │
              ▼                       ▼
  ┌─────────────────────┐  ┌─────────────────────────┐
  │ On-chain credit data│  │Loan status & repayments │
  └─────────────────────┘  └─────────────────────────┘
              │                       ▲
              └────────────┬──────────┘
                           │
             ┌─────────────▼────────────┐
             │     Clarity Functions    │
             │  initialize-score()      │
             │  request-loan()          │
             │  repay-loan()            │
             │  mark-loan-defaulted()   │
             └──────────────────────────┘
```

---

## 📦 Functions Overview

### Public Functions

* `initialize-score`: Create credit profile
* `request-loan`: Request loan with dynamic collateral
* `repay-loan`: Make a repayment (partial or full)
* `mark-loan-defaulted`: Admin marks overdue loan as default

### Read-Only Functions

* `get-user-score`: Fetch user credit profile
* `get-loan`: Get loan details
* `get-user-active-loans`: List active loans for user
* `get-system-stats`: View total locked STX and next loan ID

---

## 🛡️ Security & Trust

* **Trustless & Permissionless**: No centralized authority controls user access or score adjustment.
* **Immutable History**: All credit and loan activity is stored on-chain.
* **Bitcoin-Backed**: Operates on Stacks Layer 2 secured by Bitcoin finality.

---

## 📘 Getting Started

### Prerequisites

* Clarity-compatible wallet (e.g., Hiro Wallet)
* STX tokens for collateral and transaction fees

### Deployment

To deploy this smart contract on a Stacks testnet or mainnet, use Clarity tooling:

```bash
clarinet check  # For local check
clarinet deployments  # For deploying to network
```

---

## 🙌 Contribution

Contributions are welcome! Please submit issues or pull requests for improvements, optimizations, or new features.
