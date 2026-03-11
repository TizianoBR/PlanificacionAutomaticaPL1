(define (domain emergency-logistics-transporter)
    (:requirements :strips :typing)

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
        
        ;; Dron con un único brazo
        (arm-free ?d - drone)
        (holding ?d - drone ?c - crate)
        
        ;; Transportador
        (in-transporter ?c - crate ?t - transporter)
        (capacity ?t - transporter ?n - num)
        
        ;; Lógica numérica
        (siguiente ?numA ?numB - num)
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

    (:action pick-up
        :parameters (?d - drone ?c - crate ?l - location)
        :precondition (and
            (at-drone ?d ?l)
            (at-crate ?c ?l)
            (arm-free ?d)
        )
        :effect (and
            (holding ?d ?c)
            (not (at-crate ?c ?l))
            (not (arm-free ?d))
        )
    )

    (:action deliver
        :parameters (?d - drone ?c - crate ?p - person ?l - location ?ct - content)
        :precondition (and
            (at-drone ?d ?l)
            (at-person ?p ?l)
            (holding ?d ?c)
            (crate-content ?c ?ct)
        )
        :effect (and
            (person-has-content ?p ?ct)
            (arm-free ?d)
            (not (holding ?d ?c))
        )
    )

    ;; --- NUEVAS ACCIONES EJERCICIO 2.1 ---

    (:action mover-transportador
        :parameters (?d - drone ?t - transporter ?from - location ?to - location)
        :precondition (and
            (at-drone ?d ?from)
            (at-transporter ?t ?from)
        )
        :effect (and
            (at-drone ?d ?to)
            (not (at-drone ?d ?from))
            (at-transporter ?t ?to)
            (not (at-transporter ?t ?from))
        )
    )

    (:action poner-caja-en-transportador
        :parameters (?d - drone ?c - crate ?t - transporter ?l - location ?n-actual - num ?n-sig - num)
        :precondition (and
            (at-drone ?d ?l)
            (at-transporter ?t ?l)
            (holding ?d ?c)
            (capacity ?t ?n-actual)
            (siguiente ?n-actual ?n-sig) ; Verifica que no hayamos llegado al máximo
        )
        :effect (and
            (not (holding ?d ?c))
            (arm-free ?d)
            (in-transporter ?c ?t)
            (not (capacity ?t ?n-actual))
            (capacity ?t ?n-sig) ; Aumentamos la carga
        )
    )

    (:action coger-caja-del-transportador
        :parameters (?d - drone ?c - crate ?t - transporter ?l - location ?n-actual - num ?n-ant - num)
        :precondition (and
            (at-drone ?d ?l)
            (at-transporter ?t ?l)
            (arm-free ?d)
            (in-transporter ?c ?t)
            (capacity ?t ?n-actual)
            (siguiente ?n-ant ?n-actual) ; Usamos 'siguiente' al revés para restar
        )
        :effect (and
            (holding ?d ?c)
            (not (arm-free ?d))
            (not (in-transporter ?c ?t))
            (not (capacity ?t ?n-actual))
            (capacity ?t ?n-ant) ; Reducimos la carga
        )
    )
)