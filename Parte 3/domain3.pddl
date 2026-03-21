(define (domain emergency-logistics-concurrency)
    (:requirements :strips :typing :durative-actions :numeric-fluents)

    (:types
        drone person crate content location transporter num
    )

    (:predicates
        (at-drone ?d - drone ?l - location)
        (at-person ?p - person ?l - location)
        (at-crate ?c - crate ?l - location)
        (at-transporter ?t - transporter ?l - location)
        
        (crate-content ?c - crate ?ct - content)
        (person-has-content ?p - person ?ct - content)
        
        (arm-free ?d - drone)
        (holding ?d - drone ?c - crate)
        
        (in-transporter ?c - crate ?t - transporter)
        (capacity ?t - transporter ?n - num)
        
        (siguiente ?numA ?numB - num)

        ;; Nuevos predicados de concurrencia (locks)
        (drone-free ?d - drone)
        (transporter-free ?t - transporter)
        (person-free ?p - person)
        (crate-free ?c - crate)
    )

    (:functions
        (fly-cost ?from - location ?to - location)
    )

    ;; ----------------- DURATIVE ACTIONS -----------------

    (:durative-action fly
        :parameters (?d - drone ?from - location ?to - location)
        :duration (= ?duration (fly-cost ?from ?to))
        :condition (and
            (at start (at-drone ?d ?from))
            (at start (drone-free ?d))
        )
        :effect (and
            (at start (not (at-drone ?d ?from)))
            (at start (not (drone-free ?d)))
            (at end (at-drone ?d ?to))
            (at end (drone-free ?d))
        )
    )

    (:durative-action pick-up
        :parameters (?d - drone ?c - crate ?l - location)
        :duration (= ?duration 5)
        :condition (and
            (over all (at-drone ?d ?l))
            (at start (at-crate ?c ?l))
            (at start (arm-free ?d))
            (at start (drone-free ?d))
            (at start (crate-free ?c))
        )
        :effect (and
            (at start (not (at-crate ?c ?l)))
            (at start (not (arm-free ?d)))
            (at start (not (drone-free ?d)))
            (at start (not (crate-free ?c)))
            (at end (holding ?d ?c))
            (at end (drone-free ?d))
            ;; La caja ahora está agarrada, no se libera su lock hasta que se suelte.
        )
    )

    (:durative-action deliver
        :parameters (?d - drone ?c - crate ?p - person ?l - location ?ct - content)
        :duration (= ?duration 5)
        :condition (and
            (over all (at-drone ?d ?l))
            (over all (at-person ?p ?l))
            (at start (holding ?d ?c))
            (over all (crate-content ?c ?ct))
            (at start (drone-free ?d))
            (at start (person-free ?p))
        )
        :effect (and
            (at start (not (drone-free ?d)))
            (at start (not (person-free ?p)))
            (at end (person-has-content ?p ?ct))
            (at end (arm-free ?d))
            (at end (not (holding ?d ?c)))
            (at end (drone-free ?d))
            (at end (person-free ?p))
            (at end (crate-free ?c)) ;; La caja vuelve a estar libre (entregada)
        )
    )

    (:durative-action mover-transportador
        :parameters (?d - drone ?t - transporter ?from - location ?to - location)
        :duration (= ?duration (fly-cost ?from ?to))
        :condition (and
            (at start (at-drone ?d ?from))
            (at start (at-transporter ?t ?from))
            (over all (arm-free ?d))
            (at start (drone-free ?d))
            (at start (transporter-free ?t))
        )
        :effect (and
            (at start (not (at-drone ?d ?from)))
            (at start (not (at-transporter ?t ?from)))
            (at start (not (drone-free ?d)))
            (at start (not (transporter-free ?t)))
            (at end (at-drone ?d ?to))
            (at end (at-transporter ?t ?to))
            (at end (drone-free ?d))
            (at end (transporter-free ?t))
        )
    )

    (:durative-action poner-caja-en-transportador
        :parameters (?d - drone ?c - crate ?t - transporter ?l - location ?n-actual - num ?n-sig - num)
        :duration (= ?duration 5)
        :condition (and
            (over all (at-drone ?d ?l))
            (over all (at-transporter ?t ?l))
            (at start (holding ?d ?c))
            (at start (capacity ?t ?n-actual))
            (over all (siguiente ?n-actual ?n-sig))
            (at start (drone-free ?d))
            (at start (transporter-free ?t))
        )
        :effect (and
            (at start (not (holding ?d ?c)))
            (at start (not (capacity ?t ?n-actual)))
            (at start (not (drone-free ?d)))
            (at start (not (transporter-free ?t)))
            (at end (arm-free ?d))
            (at end (in-transporter ?c ?t))
            (at end (capacity ?t ?n-sig))
            (at end (drone-free ?d))
            (at end (transporter-free ?t))
            (at end (crate-free ?c))
        )
    )

    (:durative-action coger-caja-del-transportador
        :parameters (?d - drone ?c - crate ?t - transporter ?l - location ?n-actual - num ?n-ant - num)
        :duration (= ?duration 5)
        :condition (and
            (over all (at-drone ?d ?l))
            (over all (at-transporter ?t ?l))
            (at start (arm-free ?d))
            (at start (in-transporter ?c ?t))
            (at start (capacity ?t ?n-actual))
            (over all (siguiente ?n-ant ?n-actual))
            (at start (drone-free ?d))
            (at start (transporter-free ?t))
            (at start (crate-free ?c))
        )
        :effect (and
            (at start (not (arm-free ?d)))
            (at start (not (in-transporter ?c ?t)))
            (at start (not (capacity ?t ?n-actual)))
            (at start (not (drone-free ?d)))
            (at start (not (transporter-free ?t)))
            (at start (not (crate-free ?c)))
            (at end (holding ?d ?c))
            (at end (capacity ?t ?n-ant))
            (at end (drone-free ?d))
            (at end (transporter-free ?t))
        )
    )
)