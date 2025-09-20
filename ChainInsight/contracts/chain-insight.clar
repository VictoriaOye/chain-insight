;; ChainInsight - Blockchain Explorer & Analytics Contract
;; Provides on-chain transaction indexing, analytics, and explorer services
;; Tracks transaction patterns, address activity, and network statistics

;; Error constants
(define-constant ERR_NOT_AUTHORIZED (err u100))
(define-constant ERR_INVALID_BLOCK (err u101))
(define-constant ERR_ADDRESS_NOT_FOUND (err u102))
(define-constant ERR_TRANSACTION_NOT_FOUND (err u103))
(define-constant ERR_INVALID_TIMEFRAME (err u104))

;; Contract owner
(define-constant CONTRACT_OWNER tx-sender)

;; Data structures for transaction indexing
(define-map transaction-index
  { tx-hash: (buff 32) }
  {
    sender: principal,
    recipient: (optional principal),
    amount: uint,
    block-number: uint,
    tx-type: (string-ascii 20),
    fee-paid: uint,
    timestamp: uint
  }
)

;; Address activity tracking
(define-map address-stats
  { address: principal }
  {
    total-sent: uint,
    total-received: uint,
    transaction-count: uint,
    first-seen: uint,
    last-active: uint,
    largest-tx: uint
  }
)

;; Block statistics
(define-map block-stats
  { block-number: uint }
  {
    transaction-count: uint,
    total-volume: uint,
    total-fees: uint,
    largest-tx: uint,
    unique-addresses: uint
  }
)

;; Daily analytics
(define-map daily-metrics
  { date: uint } ;; block height / 144 for daily approximation
  {
    total-transactions: uint,
    total-volume: uint,
    active-addresses: uint,
    average-tx-size: uint,
    total-fees: uint
  }
)

;; Network-wide statistics
(define-data-var total-indexed-transactions uint u0)
(define-data-var total-network-volume uint u0)
(define-data-var total-unique-addresses uint u0)

;; Transaction type counters
(define-map tx-type-stats
  { tx-type: (string-ascii 20) }
  { count: uint, total-volume: uint }
)

;; Read-only functions for explorer queries
(define-read-only (get-transaction-info (tx-hash (buff 32)))
  (map-get? transaction-index { tx-hash: tx-hash })
)

(define-read-only (get-address-stats (address principal))
  (map-get? address-stats { address: address })
)

(define-read-only (get-block-stats (block-number uint))
  (map-get? block-stats { block-number: block-number })
)

(define-read-only (get-daily-metrics (date uint))
  (map-get? daily-metrics { date: date })
)

(define-read-only (get-network-stats)
  {
    total-transactions: (var-get total-indexed-transactions),
    total-volume: (var-get total-network-volume),
    unique-addresses: (var-get total-unique-addresses)
  }
)

(define-read-only (get-tx-type-stats (tx-type (string-ascii 20)))
  (map-get? tx-type-stats { tx-type: tx-type })
)

;; Calculate address activity score
(define-read-only (calculate-address-score (address principal))
  (let
    (
      (stats (get-address-stats address))
    )
    (match stats
      address-data (let
        (
          (tx-count (get transaction-count address-data))
          (volume (+ (get total-sent address-data) (get total-received address-data)))
          (activity-days (/ (- block-height (get first-seen address-data)) u144))
        )
        (if (> activity-days u0)
          (/ (+ tx-count (/ volume u1000000)) activity-days) ;; Simple scoring algorithm
          u0
        )
      )
      u0
    )
  )
)

;; Main indexing function - called by authorized indexers
(define-public (index-transaction 
  (tx-hash (buff 32))
  (sender principal)
  (recipient (optional principal))
  (amount uint)
  (tx-type (string-ascii 20))
  (fee-paid uint))
  (let
    (
      (current-block-height block-height)
      (current-date (/ current-block-height u144))
      (sender-stats (default-to 
        { total-sent: u0, total-received: u0, transaction-count: u0, 
          first-seen: current-block-height, last-active: current-block-height, largest-tx: u0 }
        (get-address-stats sender)))
      (current-daily (default-to
        { total-transactions: u0, total-volume: u0, active-addresses: u0, 
          average-tx-size: u0, total-fees: u0 }
        (get-daily-metrics current-date)))
      (current-block-stats-result (map-get? block-stats { block-number: current-block-height }))
      (current-block-stats (default-to
        { transaction-count: u0, total-volume: u0, total-fees: u0, 
          largest-tx: u0, unique-addresses: u0 }
        current-block-stats-result))
      (current-tx-type-stats (default-to
        { count: u0, total-volume: u0 }
        (get-tx-type-stats tx-type)))
    )
    
    ;; Store transaction data
    (map-set transaction-index
      { tx-hash: tx-hash }
      {
        sender: sender,
        recipient: recipient,
        amount: amount,
        block-number: current-block-height,
        tx-type: tx-type,
        fee-paid: fee-paid,
        timestamp: current-block-height
      }
    )
    
    ;; Update sender statistics
    (map-set address-stats
      { address: sender }
      {
        total-sent: (+ (get total-sent sender-stats) amount),
        total-received: (get total-received sender-stats),
        transaction-count: (+ (get transaction-count sender-stats) u1),
        first-seen: (get first-seen sender-stats),
        last-active: current-block-height,
        largest-tx: (if (> amount (get largest-tx sender-stats)) amount (get largest-tx sender-stats))
      }
    )
    
    ;; Update recipient statistics if present
    (match recipient
      recv-addr (let
        (
          (recv-stats (default-to
            { total-sent: u0, total-received: u0, transaction-count: u0,
              first-seen: current-block-height, last-active: current-block-height, largest-tx: u0 }
            (get-address-stats recv-addr)))
        )
        (map-set address-stats
          { address: recv-addr }
          {
            total-sent: (get total-sent recv-stats),
            total-received: (+ (get total-received recv-stats) amount),
            transaction-count: (+ (get transaction-count recv-stats) u1),
            first-seen: (get first-seen recv-stats),
            last-active: current-block-height,
            largest-tx: (if (> amount (get largest-tx recv-stats)) amount (get largest-tx recv-stats))
          }
        )
      )
      true ;; No recipient to update
    )
    
    ;; Update block statistics
    (map-set block-stats
      { block-number: current-block-height }
      {
        transaction-count: (+ (get transaction-count current-block-stats) u1),
        total-volume: (+ (get total-volume current-block-stats) amount),
        total-fees: (+ (get total-fees current-block-stats) fee-paid),
        largest-tx: (if (> amount (get largest-tx current-block-stats)) amount (get largest-tx current-block-stats)),
        unique-addresses: (get unique-addresses current-block-stats) ;; Would need separate tracking
      }
    )
    
    ;; Update daily metrics
    (map-set daily-metrics
      { date: current-date }
      {
        total-transactions: (+ (get total-transactions current-daily) u1),
        total-volume: (+ (get total-volume current-daily) amount),
        active-addresses: (get active-addresses current-daily),
        average-tx-size: (/ (+ (get total-volume current-daily) amount) 
                            (+ (get total-transactions current-daily) u1)),
        total-fees: (+ (get total-fees current-daily) fee-paid)
      }
    )
    
    ;; Update transaction type statistics
    (map-set tx-type-stats
      { tx-type: tx-type }
      {
        count: (+ (get count current-tx-type-stats) u1),
        total-volume: (+ (get total-volume current-tx-type-stats) amount)
      }
    )
    
    ;; Update global counters
    (var-set total-indexed-transactions (+ (var-get total-indexed-transactions) u1))
    (var-set total-network-volume (+ (var-get total-network-volume) amount))
    
    (ok true)
  )
)

;; Query functions for specific analytics
(define-read-only (get-top-addresses-by-volume (limit uint))
  ;; This would require additional data structures for efficient querying
  ;; Simplified version returns a success indicator
  (ok "Query would return top addresses by volume")
)

(define-read-only (get-recent-transactions (count uint))
  ;; This would require a separate index by block height
  ;; Simplified version returns a success indicator
  (ok "Query would return recent transactions")
)

(define-read-only (search-transactions-by-address (address principal) (limit uint))
  ;; This would require address-to-transactions mapping
  ;; Returns address stats as proxy
  (ok (get-address-stats address))
)

;; Administrative functions
(define-public (set-indexer-authorization (indexer principal) (authorized bool))
  (begin
    (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_NOT_AUTHORIZED)
    ;; In production, this would manage indexer permissions
    (ok authorized)
  )
)