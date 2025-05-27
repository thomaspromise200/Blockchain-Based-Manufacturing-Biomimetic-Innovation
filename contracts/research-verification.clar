;; Research Institution Verification Contract
;; Manages verification and credentialing of biomimetic research institutions

(define-map verified-institutions
  { institution-id: uint }
  {
    name: (string-ascii 100),
    accreditation-level: uint,
    research-areas: (list 10 (string-ascii 50)),
    verified-by: principal,
    verification-date: uint,
    status: (string-ascii 20)
  }
)

(define-map institution-researchers
  { institution-id: uint, researcher-id: principal }
  {
    name: (string-ascii 100),
    specialization: (string-ascii 100),
    credentials: (string-ascii 200),
    active: bool
  }
)

(define-data-var next-institution-id uint u1)
(define-data-var contract-owner principal tx-sender)

;; Error codes
(define-constant ERR-NOT-AUTHORIZED (err u1001))
(define-constant ERR-INSTITUTION-NOT-FOUND (err u1002))
(define-constant ERR-ALREADY-VERIFIED (err u1003))
(define-constant ERR-INVALID-ACCREDITATION (err u1004))

;; Register a new research institution
(define-public (register-institution
  (name (string-ascii 100))
  (research-areas (list 10 (string-ascii 50))))
  (let
    ((institution-id (var-get next-institution-id)))
    (asserts! (is-eq tx-sender (var-get contract-owner)) ERR-NOT-AUTHORIZED)
    (map-set verified-institutions
      { institution-id: institution-id }
      {
        name: name,
        accreditation-level: u1,
        research-areas: research-areas,
        verified-by: tx-sender,
        verification-date: block-height,
        status: "pending"
      }
    )
    (var-set next-institution-id (+ institution-id u1))
    (ok institution-id)
  )
)

;; Verify an institution
(define-public (verify-institution (institution-id uint) (accreditation-level uint))
  (let
    ((institution (unwrap! (map-get? verified-institutions { institution-id: institution-id }) ERR-INSTITUTION-NOT-FOUND)))
    (asserts! (is-eq tx-sender (var-get contract-owner)) ERR-NOT-AUTHORIZED)
    (asserts! (<= accreditation-level u5) ERR-INVALID-ACCREDITATION)
    (map-set verified-institutions
      { institution-id: institution-id }
      (merge institution {
        accreditation-level: accreditation-level,
        status: "verified"
      })
    )
    (ok true)
  )
)

;; Add researcher to institution
(define-public (add-researcher
  (institution-id uint)
  (researcher principal)
  (name (string-ascii 100))
  (specialization (string-ascii 100))
  (credentials (string-ascii 200)))
  (let
    ((institution (unwrap! (map-get? verified-institutions { institution-id: institution-id }) ERR-INSTITUTION-NOT-FOUND)))
    (asserts! (is-eq (get status institution) "verified") ERR-NOT-AUTHORIZED)
    (map-set institution-researchers
      { institution-id: institution-id, researcher-id: researcher }
      {
        name: name,
        specialization: specialization,
        credentials: credentials,
        active: true
      }
    )
    (ok true)
  )
)

;; Read-only functions
(define-read-only (get-institution (institution-id uint))
  (map-get? verified-institutions { institution-id: institution-id })
)

(define-read-only (get-researcher (institution-id uint) (researcher principal))
  (map-get? institution-researchers { institution-id: institution-id, researcher-id: researcher })
)

(define-read-only (is-verified-researcher (institution-id uint) (researcher principal))
  (match (map-get? institution-researchers { institution-id: institution-id, researcher-id: researcher })
    researcher-data (get active researcher-data)
    false
  )
)
