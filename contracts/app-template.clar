;; App Template Contract
;; Base template for new apps

;; Constants
(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))

;; Data Variables
(define-data-var app-name (string-ascii 64) "")
(define-data-var app-version (string-ascii 16) "1.0.0")
(define-data-var app-status (string-ascii 16) "inactive")

;; Public Functions
(define-public (initialize (name (string-ascii 64)))
  (begin
    (asserts! (is-eq tx-sender contract-owner) err-owner-only)
    (var-set app-name name)
    (var-set app-status "active")
    (ok true))
)

;; Read Only Functions
(define-read-only (get-app-info)
  (ok {
    name: (var-get app-name),
    version: (var-get app-version),
    status: (var-get app-status)
  })
)
