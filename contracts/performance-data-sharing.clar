;; Performance Data Sharing Contract
;; Enables equipment benchmarking through secure data sharing

(define-constant err-not-found (err u201))
(define-constant err-unauthorized (err u202))
(define-constant err-invalid-data (err u203))

;; Performance data structure
(define-map performance-data
  { data-id: uint }
  {
    equipment-id: uint,
    submitter: principal,
    efficiency-score: uint,
    uptime-percentage: uint,
    energy-consumption: uint,
    output-rate: uint,
    submitted-at: uint,
    public: bool
  }
)

;; Data access permissions
(define-map data-access
  { data-id: uint, accessor: principal }
  { granted: bool, granted-at: uint }
)

;; Data counter
(define-data-var data-counter uint u0)

;; Submit performance data
(define-public (submit-performance-data
  (equipment-id uint)
  (efficiency-score uint)
  (uptime-percentage uint)
  (energy-consumption uint)
  (output-rate uint)
  (public bool)
)
  (let
    (
      (data-id (+ (var-get data-counter) u1))
    )
    (asserts! (<= uptime-percentage u100) err-invalid-data)
    (asserts! (<= efficiency-score u100) err-invalid-data)
    (map-set performance-data
      { data-id: data-id }
      {
        equipment-id: equipment-id,
        submitter: tx-sender,
        efficiency-score: efficiency-score,
        uptime-percentage: uptime-percentage,
        energy-consumption: energy-consumption,
        output-rate: output-rate,
        submitted-at: block-height,
        public: public
      }
    )
    (var-set data-counter data-id)
    (ok data-id)
  )
)

;; Grant data access
(define-public (grant-data-access (data-id uint) (accessor principal))
  (let
    (
      (data (unwrap! (map-get? performance-data { data-id: data-id }) err-not-found))
    )
    (asserts! (is-eq tx-sender (get submitter data)) err-unauthorized)
    (map-set data-access
      { data-id: data-id, accessor: accessor }
      { granted: true, granted-at: block-height }
    )
    (ok true)
  )
)

;; Get performance data (with access control)
(define-read-only (get-performance-data (data-id uint))
  (let
    (
      (data (map-get? performance-data { data-id: data-id }))
    )
    (match data
      data-info
        (if (or
              (get public data-info)
              (is-eq tx-sender (get submitter data-info))
              (default-to false (get granted (map-get? data-access { data-id: data-id, accessor: tx-sender })))
            )
          (some data-info)
          none
        )
      none
    )
  )
)

;; Calculate average efficiency for equipment
(define-read-only (get-average-efficiency (equipment-id uint))
  ;; Simplified calculation - in practice would iterate through all data
  u75 ;; Placeholder return value
)

;; Get total data submissions
(define-read-only (get-data-count)
  (var-get data-counter)
)
