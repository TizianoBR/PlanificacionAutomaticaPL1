(define (problem drone_problem_d1_r1_l2_p2_c2_g2_ct2)
(:domain emergency-logistics-transporter)
(:objects
	drone1 - drone
	depot - location
	loc1 - location
	loc2 - location
	crate1 - crate
	crate2 - crate
	food - content
	medicine - content
	person1 - person
	person2 - person
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
	(= (fly-cost depot loc1) 65)
	(= (fly-cost depot loc2) 165)
	(= (fly-cost loc1 depot) 65)
	(= (fly-cost loc1 loc1) 1)
	(= (fly-cost loc1 loc2) 101)
	(= (fly-cost loc2 depot) 165)
	(= (fly-cost loc2 loc1) 101)
	(= (fly-cost loc2 loc2) 1)
	(siguiente n0 n1)
	(siguiente n1 n2)
	(siguiente n2 n3)
	(siguiente n3 n4)
	(at-drone drone1 depot)
	(arm-free drone1)
	(drone-has drone1 transporter1)
	(capacity transporter1 n0)
	(at-person person1 loc1)
	(at-person person2 loc2)
	(at-crate crate1 depot)
	(crate-content crate1 food)
	(at-crate crate2 depot)
	(crate-content crate2 medicine)
)
(:goal (and

	(at-drone drone1 depot)
	(person-has-content person1 medicine)
	(person-has-content person2 food)
	))
(:metric minimize (total-cost))
)
