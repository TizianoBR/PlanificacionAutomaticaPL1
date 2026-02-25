(define (domain emergency-logistics)
    (:requirements :strips :typing)

    (:types
        drone person crate content location
    )

    (:predicates
        (at-drone ?d - drone ?l - location)
        (at-person ?p - person ?l - location)
        (at-crate ?c - crate ?l - location)
        (crate-content ?c - crate ?ct - content)
        (person-has-content ?p - person ?ct - content)
        (arm-free-left ?d - drone)
        (arm-free-right ?d - drone)
        (holding-left ?d - drone ?c - crate)
        (holding-right ?d - drone ?c - crate)
    )

    (:action fly
        :parameters (?d - drone ?from - location ?to - location)
        :precondition (and
            (at-drone ?d ?from)
        )
        :effect (and
            (at-drone ?d ?to)
            (not (at-drone ?d ?from))
        )
    )

    (:action pick-up-left
        :parameters (?d - drone ?c - crate ?l - location)
        :precondition (and
            (at-drone ?d ?l)
            (at-crate ?c ?l)
            (arm-free-left ?d)
        )
        :effect (and
            (holding-left ?d ?c)
            (not (at-crate ?c ?l))
            (not (arm-free-left ?d))
        )
    )

    (:action pick-up-right
        :parameters (?d - drone ?c - crate ?l - location)
        :precondition (and
            (at-drone ?d ?l)
            (at-crate ?c ?l)
            (arm-free-right ?d)
        )
        :effect (and
            (holding-right ?d ?c)
            (not (at-crate ?c ?l))
            (not (arm-free-right ?d))
        )
    )

    (:action deliver-left
        :parameters (?d - drone ?c - crate ?p - person ?l - location ?ct - content)
        :precondition (and
            (at-drone ?d ?l)
            (at-person ?p ?l)
            (holding-left ?d ?c)
            (crate-content ?c ?ct)
        )
        :effect (and
            (person-has-content ?p ?ct)
            (arm-free-left ?d)
            (not (holding-left ?d ?c))
        )
    )

    (:action deliver-right
        :parameters (?d - drone ?c - crate ?p - person ?l - location ?ct - content)
        :precondition (and
            (at-drone ?d ?l)
            (at-person ?p ?l)
            (holding-right ?d ?c)
            (crate-content ?c ?ct)
        )
        :effect (and
            (person-has-content ?p ?ct)
            (arm-free-right ?d)
            (not (holding-right ?d ?c))
        )
    )
)