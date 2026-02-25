(define (problem emergency-problem-1)
    (:domain emergency-logistics)

    (:objects
        dron1 - drone
        deposito loc1 - location
        persona1 - person
        caja1 - crate
        comida - content
    )

    (:init
        (at-drone dron1 deposito)
        (arm-free-left dron1)
        (arm-free-right dron1)

        (at-crate caja1 deposito)
        (crate-content caja1 comida)

        (at-person persona1 loc1)
    )

    (:goal (and
        (person-has-content persona1 comida)
    ))
)