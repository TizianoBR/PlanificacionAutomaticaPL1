(define (problem drone_problem_d2_r2_l2_p2_c2_g2_ct2)
(:domain emergency-logistics-transporter)
(:objects
	drone1 - drone
	drone2 - drone
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
	transporter2 - transporter
	n0 - num
	n1 - num
	n2 - num
	n3 - num
	n4 - num
)
(:init
	(siguiente n0 n1)
	(siguiente n1 n2)
	(siguiente n2 n3)
	(siguiente n3 n4)
	(at-drone drone1 depot)
	(arm-free drone1)
	(drone-has drone1 transporter1)
	(at-drone drone2 depot)
	(arm-free drone2)
	(drone-has drone2 transporter2)
	(capacity transporter1 n0)
	(capacity transporter2 n0)
	(at-person person1 loc2)
	(at-person person2 loc1)
	(at-crate crate1 depot)
	(crate-content crate1 food)
	(at-crate crate2 depot)
	(crate-content crate2 medicine)
)
(:goal (and

	(at-drone drone1 depot)

	(at-drone drone2 depot)
	(person-has-content person1 food)
	(person-has-content person2 medicine)
	))
)
