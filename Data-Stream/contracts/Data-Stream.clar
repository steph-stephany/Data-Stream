;; Predictive Analytics Data Stream with Reputation System
;; Built on Stacks blockchain using Clarity

;; Contract constants
(define-constant CONTRACT-OWNER tx-sender)
(define-constant ERR-UNAUTHORIZED (err u100))
(define-constant ERR-NOT-FOUND (err u101))
(define-constant ERR-INVALID-DATA (err u102))
(define-constant ERR-INSUFFICIENT-REPUTATION (err u103))
(define-constant ERR-ALREADY-EXISTS (err u104))

;; Minimum reputation required to submit predictions
(define-constant MIN-REPUTATION u50)

;; Data structures
(define-map data-providers principal {
    reputation-score: uint,
    total-submissions: uint,
    correct-predictions: uint,
    last-submission: uint,
    is-active: bool
})

(define-map data-streams uint {
    provider: principal,
    data-hash: (buff 32),
    prediction-value: uint,
    confidence-score: uint,
    timestamp: uint,
    category: (string-ascii 50),
    is-validated: bool,
    validation-score: uint
})

(define-map ml-models uint {
    model-hash: (buff 32),
    accuracy: uint,
    creator: principal,
    creation-time: uint,
    usage-count: uint
})

(define-map validation-records uint {
    stream-id: uint,
    validator: principal,
    is-correct: bool,
    timestamp: uint,
    reward-given: uint
})

;; State variables
(define-data-var next-stream-id uint u1)
(define-data-var next-model-id uint u1)
(define-data-var next-validation-id uint u1)
(define-data-var total-staked uint u0)

;; Events
(define-data-var contract-initialized bool false)

;; Initialize contract
(define-public (initialize-contract)
    (begin
        (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-UNAUTHORIZED)
        (asserts! (not (var-get contract-initialized)) ERR-ALREADY-EXISTS)
        (var-set contract-initialized true)
        (ok true)
    )
)

;; Register as a data provider
(define-public (register-provider)
    (let ((provider-info (map-get? data-providers tx-sender)))
        (if (is-some provider-info)
            ERR-ALREADY-EXISTS
            (begin
                (map-set data-providers tx-sender {
                    reputation-score: u100,
                    total-submissions: u0,
                    correct-predictions: u0,
                    last-submission: u0,
                    is-active: true
                })
                (ok true)
            )
        )
    )
)

;; Submit data stream with prediction
(define-public (submit-data-stream 
    (data-hash (buff 32))
    (prediction-value uint)
    (confidence-score uint)
    (category (string-ascii 50)))
    (let (
        (provider-info (unwrap! (map-get? data-providers tx-sender) ERR-NOT-FOUND))
        (current-stream-id (var-get next-stream-id))
        (current-time stacks-block-height)
    )
        (asserts! (get is-active provider-info) ERR-UNAUTHORIZED)
        (asserts! (>= (get reputation-score provider-info) MIN-REPUTATION) ERR-INSUFFICIENT-REPUTATION)
        (asserts! (<= confidence-score u100) ERR-INVALID-DATA)
        
        ;; Create data stream record
        (map-set data-streams current-stream-id {
            provider: tx-sender,
            data-hash: data-hash,
            prediction-value: prediction-value,
            confidence-score: confidence-score,
            timestamp: current-time,
            category: category,
            is-validated: false,
            validation-score: u0
        })
        
        ;; Update provider info
        (map-set data-providers tx-sender 
            (merge provider-info {
                total-submissions: (+ (get total-submissions provider-info) u1),
                last-submission: current-time
            })
        )
        
        ;; Increment stream ID
        (var-set next-stream-id (+ current-stream-id u1))
        (ok current-stream-id)
    )
)

;; Register ML model
(define-public (register-ml-model (model-hash (buff 32)))
    (let (
        (current-model-id (var-get next-model-id))
        (current-time stacks-block-height)
    )
        (map-set ml-models current-model-id {
            model-hash: model-hash,
            accuracy: u0,
            creator: tx-sender,
            creation-time: current-time,
            usage-count: u0
        })
        
        (var-set next-model-id (+ current-model-id u1))
        (ok current-model-id)
    )
)

;; Validate prediction (can be called by anyone with sufficient reputation)
(define-public (validate-prediction 
    (stream-id uint)
    (is-correct bool))
    (let (
        (stream-info (unwrap! (map-get? data-streams stream-id) ERR-NOT-FOUND))
        (validator-info (unwrap! (map-get? data-providers tx-sender) ERR-NOT-FOUND))
        (provider-info (unwrap! (map-get? data-providers (get provider stream-info)) ERR-NOT-FOUND))
        (current-validation-id (var-get next-validation-id))
        (current-time stacks-block-height)
        (reward-amount (if is-correct u10 u0))
    )
        (asserts! (>= (get reputation-score validator-info) u75) ERR-INSUFFICIENT-REPUTATION)
        (asserts! (not (get is-validated stream-info)) ERR-ALREADY-EXISTS)
        
        ;; Record validation
        (map-set validation-records current-validation-id {
            stream-id: stream-id,
            validator: tx-sender,
            is-correct: is-correct,
            timestamp: current-time,
            reward-given: reward-amount
        })
        
        ;; Update stream validation status
        (map-set data-streams stream-id 
            (merge stream-info {
                is-validated: true,
                validation-score: (if is-correct u100 u0)
            })
        )
        
        ;; Update provider reputation
        (let ((new-reputation 
                (if is-correct 
                    (+ (get reputation-score provider-info) u5)
                    (if (> (get reputation-score provider-info) u5)
                        (- (get reputation-score provider-info) u5)
                        u0))))
            (map-set data-providers (get provider stream-info)
                (merge provider-info {
                    reputation-score: new-reputation,
                    correct-predictions: (if is-correct 
                                            (+ (get correct-predictions provider-info) u1)
                                            (get correct-predictions provider-info))
                })
            )
        )
        
        ;; Update validator reputation (smaller reward)
        (map-set data-providers tx-sender
            (merge validator-info {
                reputation-score: (+ (get reputation-score validator-info) u2)
            })
        )
        
        (var-set next-validation-id (+ current-validation-id u1))
        (ok true)
    )
)

;; Update ML model accuracy
(define-public (update-model-accuracy 
    (model-id uint)
    (new-accuracy uint))
    (let ((model-info (unwrap! (map-get? ml-models model-id) ERR-NOT-FOUND)))
        (asserts! (is-eq tx-sender (get creator model-info)) ERR-UNAUTHORIZED)
        (asserts! (<= new-accuracy u100) ERR-INVALID-DATA)
        
        (map-set ml-models model-id 
            (merge model-info {
                accuracy: new-accuracy,
                usage-count: (+ (get usage-count model-info) u1)
            })
        )
        (ok true)
    )
)

;; Penalize provider for bad behavior
(define-public (penalize-provider 
    (provider principal)
    (penalty-amount uint))
    (let ((provider-info (unwrap! (map-get? data-providers provider) ERR-NOT-FOUND)))
        (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-UNAUTHORIZED)
        
        (let ((new-reputation 
                (if (> (get reputation-score provider-info) penalty-amount)
                    (- (get reputation-score provider-info) penalty-amount)
                    u0)))
            (map-set data-providers provider
                (merge provider-info {
                    reputation-score: new-reputation,
                    is-active: (> new-reputation u25)
                })
            )
        )
        (ok true)
    )
)

;; Read-only functions

;; Get provider information
(define-read-only (get-provider-info (provider principal))
    (map-get? data-providers provider)
)

;; Get data stream information
(define-read-only (get-stream-info (stream-id uint))
    (map-get? data-streams stream-id)
)

;; Get ML model information
(define-read-only (get-model-info (model-id uint))
    (map-get? ml-models model-id)
)

;; Calculate provider success rate
(define-read-only (get-provider-success-rate (provider principal))
    (match (map-get? data-providers provider)
        provider-info
        (let ((total (get total-submissions provider-info))
              (correct (get correct-predictions provider-info)))
            (if (> total u0)
                (some (/ (* correct u100) total))
                (some u0)))
        none)
)

;; Get top providers by reputation
(define-read-only (get-provider-reputation (provider principal))
    (match (map-get? data-providers provider)
        provider-info (some (get reputation-score provider-info))
        none)
)

;; Check if provider can submit data
(define-read-only (can-submit-data (provider principal))
    (match (map-get? data-providers provider)
        provider-info 
        (and 
            (get is-active provider-info)
            (>= (get reputation-score provider-info) MIN-REPUTATION))
        false)
)

;; Get validation record
(define-read-only (get-validation-record (validation-id uint))
    (map-get? validation-records validation-id)
)

;; Get current stream ID
(define-read-only (get-current-stream-id)
    (var-get next-stream-id)
)

;; Get current model ID
(define-read-only (get-current-model-id)
    (var-get next-model-id)
)