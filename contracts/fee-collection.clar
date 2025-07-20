;; Fee Collection Contract
;; Processes court rental payments and annual passes

;; Constants
(define-constant CONTRACT-OWNER tx-sender)
(define-constant ERR-NOT-AUTHORIZED (err u500))
(define-constant ERR-INSUFFICIENT-PAYMENT (err u501))
(define-constant ERR-PAYMENT-NOT-FOUND (err u502))
(define-constant ERR-REFUND-NOT-ALLOWED (err u503))
(define-constant ERR-PASS-NOT-FOUND (err u504))
(define-constant ERR-PASS-EXPIRED (err u505))
(define-constant ERR-INVALID-AMOUNT (err u506))

;; Data Variables
(define-data-var payment-counter uint u0)
(define-data-var pass-counter uint u0)
(define-data-var total-revenue uint u0)
(define-data-var annual-pass-price uint u2000)
(define-data-var refund-window uint u7200)

;; Data Maps
(define-map payments
  { payment-id: uint }
  {
    payer: principal,
    amount: uint,
    payment-type: (string-ascii 20),
    reference-id: uint,
    timestamp: uint,
    status: (string-ascii 20),
    refund-amount: uint
  }
)

(define-map annual-passes
  { pass-id: uint }
  {
    holder: principal,
    purchase-date: uint,
    expiry-date: uint,
    amount-paid: uint,
    bookings-used: uint,
    status: (string-ascii 20)
  }
)

(define-map user-balances
  { user: principal }
  {
    total-paid: uint,
    total-refunded: uint,
    active-passes: uint,
    last-payment: uint
  }
)

(define-map daily-revenue
  { date: uint }
  {
    court-rentals: uint,
    pass-sales: uint,
    tournament-fees: uint,
    total: uint
  }
)

(define-map pricing-tiers
  { tier-name: (string-ascii 20) }
  {
    hourly-rate: uint,
    discount-percentage: uint,
    minimum-hours: uint
  }
)

;; Initialize pricing tiers
(define-private (initialize-pricing)
  (begin
    (map-set pricing-tiers { tier-name: "standard" }
      { hourly-rate: u50, discount-percentage: u0, minimum-hours: u1 })
    (map-set pricing-tiers { tier-name: "premium" }
      { hourly-rate: u70, discount-percentage: u0, minimum-hours: u1 })
    (map-set pricing-tiers { tier-name: "bulk-discount" }
      { hourly-rate: u50, discount-percentage: u15, minimum-hours: u4 })
    (map-set pricing-tiers { tier-name: "member-rate" }
      { hourly-rate: u40, discount-percentage: u20, minimum-hours: u1 })
  )
)

;; Initialize the contract
(initialize-pricing)

;; Read-only functions
(define-read-only (get-payment-info (payment-id uint))
  (map-get? payments { payment-id: payment-id })
)

(define-read-only (get-annual-pass-info (pass-id uint))
  (map-get? annual-passes { pass-id: pass-id })
)

(define-read-only (get-user-balance (user principal))
  (map-get? user-balances { user: user })
)

(define-read-only (get-daily-revenue (date uint))
  (map-get? daily-revenue { date: date })
)

(define-read-only (get-pricing-tier (tier-name (string-ascii 20)))
  (map-get? pricing-tiers { tier-name: tier-name })
)

(define-read-only (get-total-revenue)
  (var-get total-revenue)
)

(define-read-only (get-annual-pass-price)
  (var-get annual-pass-price)
)

(define-read-only (calculate-court-fee (hours uint) (tier-name (string-ascii 20)))
  (match (get-pricing-tier tier-name)
    tier-info
      (let (
        (base-cost (* hours (get hourly-rate tier-info)))
        (discount (/ (* base-cost (get discount-percentage tier-info)) u100))
      )
        (if (>= hours (get minimum-hours tier-info))
          (- base-cost discount)
          base-cost
        )
      )
    u0
  )
)

(define-read-only (is-pass-valid (pass-id uint))
  (match (get-annual-pass-info pass-id)
    pass-info
      (and
        (is-eq (get status pass-info) "active")
        (> (get expiry-date pass-info) block-height)
      )
    false
  )
)

;; Public functions
(define-public (process-court-payment (amount uint) (reference-id uint))
  (let (
    (payment-id (+ (var-get payment-counter) u1))
    (current-date (/ block-height u144))
    (existing-revenue (default-to { court-rentals: u0, pass-sales: u0, tournament-fees: u0, total: u0 }
                       (get-daily-revenue current-date)))
    (user-balance (default-to { total-paid: u0, total-refunded: u0, active-passes: u0, last-payment: u0 }
                   (get-user-balance tx-sender)))
  )
    (asserts! (> amount u0) ERR-INVALID-AMOUNT)

    ;; Record payment
    (map-set payments
      { payment-id: payment-id }
      {
        payer: tx-sender,
        amount: amount,
        payment-type: "court-rental",
        reference-id: reference-id,
        timestamp: block-height,
        status: "completed",
        refund-amount: u0
      }
    )

    ;; Update user balance
    (map-set user-balances
      { user: tx-sender }
      (merge user-balance {
        total-paid: (+ (get total-paid user-balance) amount),
        last-payment: block-height
      })
    )

    ;; Update daily revenue
    (map-set daily-revenue
      { date: current-date }
      (merge existing-revenue {
        court-rentals: (+ (get court-rentals existing-revenue) amount),
        total: (+ (get total existing-revenue) amount)
      })
    )

    ;; Update total revenue
    (var-set total-revenue (+ (var-get total-revenue) amount))
    (var-set payment-counter payment-id)

    (ok payment-id)
  )
)

(define-public (purchase-annual-pass)
  (let (
    (pass-id (+ (var-get pass-counter) u1))
    (pass-price (var-get annual-pass-price))
    (expiry-date (+ block-height u52560))
    (current-date (/ block-height u144))
    (existing-revenue (default-to { court-rentals: u0, pass-sales: u0, tournament-fees: u0, total: u0 }
                       (get-daily-revenue current-date)))
    (user-balance (default-to { total-paid: u0, total-refunded: u0, active-passes: u0, last-payment: u0 }
                   (get-user-balance tx-sender)))
  )
    ;; Create annual pass
    (map-set annual-passes
      { pass-id: pass-id }
      {
        holder: tx-sender,
        purchase-date: block-height,
        expiry-date: expiry-date,
        amount-paid: pass-price,
        bookings-used: u0,
        status: "active"
      }
    )

    ;; Update user balance
    (map-set user-balances
      { user: tx-sender }
      (merge user-balance {
        total-paid: (+ (get total-paid user-balance) pass-price),
        active-passes: (+ (get active-passes user-balance) u1),
        last-payment: block-height
      })
    )

    ;; Update daily revenue
    (map-set daily-revenue
      { date: current-date }
      (merge existing-revenue {
        pass-sales: (+ (get pass-sales existing-revenue) pass-price),
        total: (+ (get total existing-revenue) pass-price)
      })
    )

    ;; Update total revenue
    (var-set total-revenue (+ (var-get total-revenue) pass-price))
    (var-set pass-counter pass-id)

    (ok pass-id)
  )
)

(define-public (process-refund (payment-id uint))
  (let (
    (payment-info (unwrap! (get-payment-info payment-id) ERR-PAYMENT-NOT-FOUND))
    (refund-deadline (+ (get timestamp payment-info) (var-get refund-window)))
    (user-balance (default-to { total-paid: u0, total-refunded: u0, active-passes: u0, last-payment: u0 }
                   (get-user-balance (get payer payment-info))))
  )
    (asserts! (is-eq (get payer payment-info) tx-sender) ERR-NOT-AUTHORIZED)
    (asserts! (is-eq (get status payment-info) "completed") ERR-REFUND-NOT-ALLOWED)
    (asserts! (< block-height refund-deadline) ERR-REFUND-NOT-ALLOWED)

    ;; Update payment status
    (map-set payments
      { payment-id: payment-id }
      (merge payment-info {
        status: "refunded",
        refund-amount: (get amount payment-info)
      })
    )

    ;; Update user balance
    (map-set user-balances
      { user: tx-sender }
      (merge user-balance {
        total-refunded: (+ (get total-refunded user-balance) (get amount payment-info))
      })
    )

    ;; Update total revenue
    (var-set total-revenue (- (var-get total-revenue) (get amount payment-info)))

    (ok (get amount payment-info))
  )
)

(define-public (use-annual-pass (pass-id uint))
  (let ((pass-info (unwrap! (get-annual-pass-info pass-id) ERR-PASS-NOT-FOUND)))
    (asserts! (is-eq (get holder pass-info) tx-sender) ERR-NOT-AUTHORIZED)
    (asserts! (is-pass-valid pass-id) ERR-PASS-EXPIRED)

    (map-set annual-passes
      { pass-id: pass-id }
      (merge pass-info {
        bookings-used: (+ (get bookings-used pass-info) u1)
      })
    )

    (ok true)
  )
)

(define-public (update-annual-pass-price (new-price uint))
  (begin
    (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-NOT-AUTHORIZED)
    (asserts! (> new-price u0) ERR-INVALID-AMOUNT)

    (var-set annual-pass-price new-price)
    (ok true)
  )
)

(define-public (update-pricing-tier (tier-name (string-ascii 20)) (hourly-rate uint) (discount-percentage uint) (minimum-hours uint))
  (begin
    (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-NOT-AUTHORIZED)
    (asserts! (> hourly-rate u0) ERR-INVALID-AMOUNT)
    (asserts! (<= discount-percentage u100) ERR-INVALID-AMOUNT)

    (map-set pricing-tiers
      { tier-name: tier-name }
      {
        hourly-rate: hourly-rate,
        discount-percentage: discount-percentage,
        minimum-hours: minimum-hours
      }
    )
    (ok true)
  )
)

(define-public (expire-annual-pass (pass-id uint))
  (let ((pass-info (unwrap! (get-annual-pass-info pass-id) ERR-PASS-NOT-FOUND)))
    (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-NOT-AUTHORIZED)

    (map-set annual-passes
      { pass-id: pass-id }
      (merge pass-info { status: "expired" })
    )

    ;; Update user balance
    (let ((user-balance (default-to { total-paid: u0, total-refunded: u0, active-passes: u0, last-payment: u0 }
                         (get-user-balance (get holder pass-info)))))
      (map-set user-balances
        { user: (get holder pass-info) }
        (merge user-balance {
          active-passes: (if (> (get active-passes user-balance) u0)
                           (- (get active-passes user-balance) u1)
                           u0)
        })
      )
    )

    (ok true)
  )
)

(define-public (get-revenue-report (start-date uint) (end-date uint))
  (begin
    (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-NOT-AUTHORIZED)
    (asserts! (<= start-date end-date) ERR-INVALID-AMOUNT)

    (ok {
      total-revenue: (var-get total-revenue),
      period-start: start-date,
      period-end: end-date,
      active-passes: (var-get pass-counter)
    })
  )
)
