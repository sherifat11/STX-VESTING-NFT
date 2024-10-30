;; stx-vesting-nft
;; A programmable vesting NFT contract with STX integration and enhanced safety checks

;; Define constants
(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-not-token-owner (err u101))
(define-constant err-invalid-token (err u102))
(define-constant err-insufficient-funds (err u103))
(define-constant err-invalid-params (err u104))    ;; New error for parameter validation
(define-constant err-zero-amount (err u105))       ;; New error for zero amount checks
(define-constant err-unauthorized (err u106))      ;; New error for unauthorized operations
(define-non-fungible-token programmable-vesting-nft uint)

;; Define data variables
(define-data-var token-id-nonce uint u0)
(define-data-var mint-price uint u200000000) ;; 100 STX
(define-data-var level-up-price uint u50000000) ;; 50 STX

;; Define data maps
(define-map tokens
  { token-id: uint }
  { 
    owner: principal, 
    created-at: uint, 
    vesting-period: uint, 
    current-level: uint 
  }
)

(define-map token-levels
  { token-id: uint, level: uint }
  { utility: (string-ascii 256) }
)

;; Mint new token with additional checks
(define-public (mint (vesting-period uint))
  (let
    (
      (token-id (+ (var-get token-id-nonce) u1))
      (owner tx-sender)
    )
    ;; Add validation for vesting period
    (asserts! (> vesting-period u0) (err err-invalid-params))

    ;; Check if token-id already exists
    (asserts! (is-none (map-get? tokens { token-id: token-id })) (err err-invalid-token))

    ;; Check balance with explicit amount
    (let ((price (var-get mint-price)))
      (asserts! (> price u0) (err err-zero-amount))
      (asserts! (>= (stx-get-balance tx-sender) price) (err err-insufficient-funds))

      ;; Handle STX transfer first
      (match (stx-transfer? price tx-sender contract-owner)
        success (begin
          ;; Then handle NFT mint
          (match (nft-mint? programmable-vesting-nft token-id owner)
            success2 (begin
              (map-set tokens
                { token-id: token-id }
                { 
                  owner: owner, 
                  created-at: block-height, 
                  vesting-period: vesting-period, 
                  current-level: u0 
                }
              )
              (var-set token-id-nonce token-id)
              (ok token-id))
            error2 (begin
              ;; Refund if NFT mint fails
              (unwrap-panic (stx-transfer? price contract-owner tx-sender))
              (err err-invalid-token)))
          )
        error (err err-insufficient-funds))
      )
  )
)


;; Enhanced token level update
(define-public (update-token-level (token-id uint))
  (let
    (
      (token-data (unwrap! (map-get? tokens { token-id: token-id }) (err err-invalid-token)))
      (owner (get owner token-data))
      (created-at (get created-at token-data))
      (vesting-period (get vesting-period token-data))
      (current-level (get current-level token-data))
    )
    ;; Validate ownership
    (asserts! (is-eq tx-sender owner) (err err-not-token-owner))

    ;; Validate vesting period
    (asserts! (> vesting-period u0) (err err-invalid-params))

    ;; Calculate new level with overflow protection
    (let 
      (
        (blocks-passed (- block-height created-at))
        (new-level (if (< blocks-passed vesting-period)
                      u0
                      (/ blocks-passed vesting-period)))
      )
      ;; Only proceed if there's an actual level increase
      (if (> new-level current-level)
        (let ((price (var-get level-up-price)))
          ;; Validate price
          (asserts! (> price u0) (err err-zero-amount))
          (asserts! (>= (stx-get-balance tx-sender) price) (err err-insufficient-funds))

          ;; Handle STX transfer
          (match (stx-transfer? price tx-sender contract-owner)
            success (begin
              (map-set tokens
                { token-id: token-id }
                (merge token-data { current-level: new-level })
              )
              (ok new-level))
            error (err err-insufficient-funds)))
        (ok current-level))
    )
  )
)


;; Enhanced utility setter
(define-public (set-level-utility (token-id uint) (level uint) (utility (string-ascii 256)))
  (begin
    (asserts! (is-eq tx-sender contract-owner) (err err-owner-only))
    ;; Check if token exists
    (asserts! (is-some (map-get? tokens { token-id: token-id })) (err err-invalid-token))
    ;; Validate utility string is not empty
    (asserts! (> (len utility) u0) (err err-invalid-params))
    (ok (map-set token-levels { token-id: token-id, level: level } { utility: utility }))
  )
)



;; Enhanced price setters
(define-public (set-mint-price (new-price uint))
  (begin
    (asserts! (is-eq tx-sender contract-owner) (err err-owner-only))
    (asserts! (> new-price u0) (err err-invalid-params))
    (ok (var-set mint-price new-price))
  )
)

(define-public (set-level-up-price (new-price uint))
  (begin
    (asserts! (is-eq tx-sender contract-owner) (err err-owner-only))
    (asserts! (> new-price u0) (err err-invalid-params))
    (ok (var-set level-up-price new-price))
  )
)

;; Enhanced STX withdrawal
(define-public (withdraw-stx (amount uint))
  (begin
    (asserts! (is-eq tx-sender contract-owner) (err err-owner-only))
    (asserts! (> amount u0) (err err-zero-amount))

    (let ((contract-balance (stx-get-balance (as-contract tx-sender))))
      (asserts! (>= contract-balance amount) (err err-insufficient-funds))

      (match (as-contract (stx-transfer? amount tx-sender contract-owner))
        success (ok amount)
        error (err err-insufficient-funds))
    )
  )
)

