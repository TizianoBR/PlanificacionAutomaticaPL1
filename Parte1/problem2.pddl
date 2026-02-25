(define (problem emergency-problem-2)
    (:domain emergency-logistics)

    (:objects
        dron1 - drone
        deposito loc1 loc2 - location
        persona1 persona2 - person
        caja1 caja2 caja3 - crate
        comida medicina - content
    )

    (:init
        (at-drone dron1 deposito)
        (arm-free-left dron1)
        (arm-free-right dron1)

        (at-crate caja1 deposito)
        (crate-content caja1 comida)
        (at-crate caja2 deposito)
        (crate-content caja2 medicina)
        (at-crate caja3 deposito)
        (crate-content caja3 comida)

        (at-person persona1 loc1)
        (at-person persona2 loc2)
    )

    (:goal (and
        (person-has-content persona1 comida)
        (person-has-content persona1 medicina)
        (person-has-content persona2 comida)
    ))
)