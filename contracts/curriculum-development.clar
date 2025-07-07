;; Curriculum Development Contract
;; Manages curriculum creation, versioning, and approval

(define-constant CONTRACT_OWNER tx-sender)
(define-constant ERR_UNAUTHORIZED (err u200))
(define-constant ERR_NOT_FOUND (err u201))
(define-constant ERR_ALREADY_EXISTS (err u202))
(define-constant ERR_INVALID_VERSION (err u203))

(define-data-var curriculum-count uint u0)
(define-data-var next-curriculum-id uint u1)

(define-map curricula
  { curriculum-id: uint }
  {
    title: (string-ascii 100),
    developer: principal,
    version: uint,
    approved: bool,
    creation-block: uint,
    last-updated: uint,
    difficulty-level: uint,
    estimated-hours: uint
  }
)

(define-map curriculum-content
  { curriculum-id: uint, version: uint }
  {
    modules: (list 20 (string-ascii 50)),
    learning-objectives: (list 10 (string-ascii 100)),
    prerequisites: (list 5 (string-ascii 50)),
    assessment-criteria: (string-ascii 200)
  }
)

(define-map curriculum-approvals
  { curriculum-id: uint }
  {
    approver: principal,
    approval-block: uint,
    comments: (string-ascii 200)
  }
)

(define-public (create-curriculum
  (title (string-ascii 100))
  (modules (list 20 (string-ascii 50)))
  (learning-objectives (list 10 (string-ascii 100)))
  (difficulty-level uint)
  (estimated-hours uint))
  (let ((curriculum-id (var-get next-curriculum-id)))

    (map-set curricula
      { curriculum-id: curriculum-id }
      {
        title: title,
        developer: tx-sender,
        version: u1,
        approved: false,
        creation-block: block-height,
        last-updated: block-height,
        difficulty-level: difficulty-level,
        estimated-hours: estimated-hours
      }
    )

    (map-set curriculum-content
      { curriculum-id: curriculum-id, version: u1 }
      {
        modules: modules,
        learning-objectives: learning-objectives,
        prerequisites: (list),
        assessment-criteria: ""
      }
    )

    (var-set next-curriculum-id (+ curriculum-id u1))
    (var-set curriculum-count (+ (var-get curriculum-count) u1))
    (ok curriculum-id)
  )
)

(define-public (update-curriculum
  (curriculum-id uint)
  (modules (list 20 (string-ascii 50)))
  (learning-objectives (list 10 (string-ascii 100))))
  (let ((curriculum-data (unwrap! (map-get? curricula { curriculum-id: curriculum-id }) ERR_NOT_FOUND))
        (new-version (+ (get version curriculum-data) u1)))

    (asserts! (is-eq tx-sender (get developer curriculum-data)) ERR_UNAUTHORIZED)

    (map-set curricula
      { curriculum-id: curriculum-id }
      (merge curriculum-data
             { version: new-version,
               last-updated: block-height,
               approved: false })
    )

    (map-set curriculum-content
      { curriculum-id: curriculum-id, version: new-version }
      {
        modules: modules,
        learning-objectives: learning-objectives,
        prerequisites: (list),
        assessment-criteria: ""
      }
    )
    (ok new-version)
  )
)

(define-public (approve-curriculum (curriculum-id uint) (comments (string-ascii 200)))
  (let ((curriculum-data (unwrap! (map-get? curricula { curriculum-id: curriculum-id }) ERR_NOT_FOUND)))
    (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_UNAUTHORIZED)

    (map-set curricula
      { curriculum-id: curriculum-id }
      (merge curriculum-data { approved: true })
    )

    (map-set curriculum-approvals
      { curriculum-id: curriculum-id }
      {
        approver: tx-sender,
        approval-block: block-height,
        comments: comments
      }
    )
    (ok true)
  )
)

(define-read-only (get-curriculum (curriculum-id uint))
  (map-get? curricula { curriculum-id: curriculum-id })
)

(define-read-only (get-curriculum-content (curriculum-id uint) (version uint))
  (map-get? curriculum-content { curriculum-id: curriculum-id, version: version })
)

(define-read-only (is-curriculum-approved (curriculum-id uint))
  (match (map-get? curricula { curriculum-id: curriculum-id })
    curriculum-data (get approved curriculum-data)
    false
  )
)

(define-read-only (get-curriculum-count)
  (var-get curriculum-count)
)
