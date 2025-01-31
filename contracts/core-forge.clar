;; CoreForge Main Contract
;; Handles app creation and management

;; Constants
(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-invalid-app (err u101))
(define-constant err-unauthorized (err u102))
(define-constant err-invalid-status (err u103))

;; Data Maps
(define-map apps
  { app-id: uint }
  {
    owner: principal,
    name: (string-ascii 64),
    version: (string-ascii 16),
    status: (string-ascii 16)
  }
)

(define-map app-permissions
  { app-id: uint, user: principal }
  { can-manage: bool }
)

;; Data Variables 
(define-data-var next-app-id uint u1)

;; Public Functions
(define-public (create-app (name (string-ascii 64)) (version (string-ascii 16)))
  (let 
    ((app-id (var-get next-app-id)))
    (try! (create-new-app app-id name version tx-sender))
    (var-set next-app-id (+ app-id u1))
    (ok app-id))
)

(define-public (update-app-version (app-id uint) (new-version (string-ascii 16)))
  (let ((app (unwrap! (get-app app-id) err-invalid-app)))
    (asserts! (is-authorized app-id tx-sender) err-unauthorized)
    (try! (map-set apps 
      { app-id: app-id }
      (merge app { version: new-version })))
    (ok true))
)

(define-public (update-app-status (app-id uint) (new-status (string-ascii 16)))
  (let ((app (unwrap! (get-app app-id) err-invalid-app)))
    (asserts! (is-authorized app-id tx-sender) err-unauthorized)
    (asserts! (is-valid-status new-status) err-invalid-status)
    (try! (map-set apps
      { app-id: app-id }
      (merge app { status: new-status })))
    (ok true))
)

;; Private Functions
(define-private (create-new-app (id uint) (name (string-ascii 64)) (version (string-ascii 16)) (owner principal))
  (map-set apps
    { app-id: id }
    {
      owner: owner,
      name: name,
      version: version,
      status: "active"
    }
  )
  (ok true)
)

(define-private (is-valid-status (status (string-ascii 16)))
  (or
    (is-eq status "active")
    (is-eq status "inactive")
    (is-eq status "deprecated")
  )
)

;; Read Only Functions
(define-read-only (get-app (app-id uint))
  (map-get? apps { app-id: app-id })
)

(define-read-only (is-authorized (app-id uint) (user principal))
  (let ((app (unwrap! (get-app app-id) false)))
    (or 
      (is-eq (get owner app) user)
      (default-to 
        false
        (get can-manage (map-get? app-permissions { app-id: app-id, user: user })))
    )
  )
)
