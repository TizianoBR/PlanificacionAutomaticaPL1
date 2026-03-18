(define (problem drone_problem_d1_r1_l3_p3_c3_g3_ct2)
(:domain emergency-logistics-transporter)
(:objects
	drone1 - drone
	depot - location
	loc1 - location
	loc2 - location
	loc3 - location
	crate1 - crate
	crate2 - crate
	crate3 - crate
	food - content
	medicine - content
	person1 - person
	person2 - person
	person3 - person
	transporter1 - transporter
	n0 - num
	n1 - num
	n2 - num
	n3 - num
	n4 - num
)
(:init
	(= (total-cost) 0)
	(= (fly-cost depot depot) 1)
	(= (fly-cost depot loc1) 274)
	(= (fly-cost depot loc2) 157)
	(= (fly-cost depot loc3) 249)
	(= (fly-cost loc1 depot) 274)
	(= (fly-cost loc1 loc1) 1)
	(= (fly-cost loc1 loc2) 121)
	(= (fly-cost loc1 loc3) 27)
	(= (fly-cost loc2 depot) 157)
	(= (fly-cost loc2 loc1) 121)
	(= (fly-cost loc2 loc2) 1)
	(= (fly-cost loc2 loc3) 98)
	(= (fly-cost loc3 depot) 249)
	(= (fly-cost loc3 loc1) 27)
	(= (fly-cost loc3 loc2) 98)
	(= (fly-cost loc3 loc3) 1)
	(siguiente n0 n1)
	(siguiente n1 n2)
	(siguiente n2 n3)
	(siguiente n3 n4)
	(at-drone drone1 depot)
	(arm-free drone1)
	(drone-has drone1 transporter1)
	(capacity transporter1 n0)
	(at-person person1 loc2)
	(at-person person2 loc1)
	(at-person person3 loc3)
	(at-crate crate1 depot)
	(crate-content crate1 food)
	(at-crate crate2 depot)
	(crate-content crate2 food)
	(at-crate crate3 depot)
	(crate-content crate3 medicine)
)
(:goal (and

	(at-drone drone1 depot)
	(person-has-content person1 food)
	(person-has-content person1 medicine)
	(person-has-content person2 food)
	))
(:metric minimize (total-cost))
)
