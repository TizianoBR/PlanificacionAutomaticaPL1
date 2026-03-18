(define (problem drone_problem_d1_r1_l4_p4_c4_g4_ct2)
(:domain emergency-logistics-transporter)
(:objects
	drone1 - drone
	depot - location
	loc1 - location
	loc2 - location
	loc3 - location
	loc4 - location
	crate1 - crate
	crate2 - crate
	crate3 - crate
	crate4 - crate
	food - content
	medicine - content
	person1 - person
	person2 - person
	person3 - person
	person4 - person
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
	(= (fly-cost depot loc1) 54)
	(= (fly-cost depot loc2) 198)
	(= (fly-cost depot loc3) 279)
	(= (fly-cost depot loc4) 199)
	(= (fly-cost loc1 depot) 54)
	(= (fly-cost loc1 loc1) 1)
	(= (fly-cost loc1 loc2) 187)
	(= (fly-cost loc1 loc3) 237)
	(= (fly-cost loc1 loc4) 194)
	(= (fly-cost loc2 depot) 198)
	(= (fly-cost loc2 loc1) 187)
	(= (fly-cost loc2 loc2) 1)
	(= (fly-cost loc2 loc3) 166)
	(= (fly-cost loc2 loc4) 25)
	(= (fly-cost loc3 depot) 279)
	(= (fly-cost loc3 loc1) 237)
	(= (fly-cost loc3 loc2) 166)
	(= (fly-cost loc3 loc3) 1)
	(= (fly-cost loc3 loc4) 190)
	(= (fly-cost loc4 depot) 199)
	(= (fly-cost loc4 loc1) 194)
	(= (fly-cost loc4 loc2) 25)
	(= (fly-cost loc4 loc3) 190)
	(= (fly-cost loc4 loc4) 1)
	(siguiente n0 n1)
	(siguiente n1 n2)
	(siguiente n2 n3)
	(siguiente n3 n4)
	(at-drone drone1 depot)
	(arm-free drone1)
	(drone-has drone1 transporter1)
	(capacity transporter1 n0)
	(at-person person1 loc3)
	(at-person person2 loc3)
	(at-person person3 loc2)
	(at-person person4 loc4)
	(at-crate crate1 depot)
	(crate-content crate1 food)
	(at-crate crate2 depot)
	(crate-content crate2 food)
	(at-crate crate3 depot)
	(crate-content crate3 medicine)
	(at-crate crate4 depot)
	(crate-content crate4 medicine)
)
(:goal (and

	(at-drone drone1 depot)
	(person-has-content person1 medicine)
	(person-has-content person2 food)
	(person-has-content person2 medicine)
	(person-has-content person4 food)
	))
(:metric minimize (total-cost))
)
