(define (problem drone_problem_d1_r1_l2_p2_c2_g2_ct2)
(:domain emergency-logistics-concurrency)
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
	(= (fly-cost depot depot) 1)
	(= (fly-cost depot loc1) 159)
	(= (fly-cost depot loc2) 158)
	(= (fly-cost loc1 depot) 159)
	(= (fly-cost loc1 loc1) 1)
	(= (fly-cost loc1 loc2) 19)
	(= (fly-cost loc2 depot) 158)
	(= (fly-cost loc2 loc1) 19)
	(= (fly-cost loc2 loc2) 1)
	(siguiente n0 n1)
	(siguiente n1 n2)
	(siguiente n2 n3)
	(siguiente n3 n4)
	(at-drone drone1 depot)
	(arm-free drone1)
	(drone-free drone1)
	(at-transporter transporter1 depot)
	(capacity transporter1 n0)
	(transporter-free transporter1)
	(at-person person1 loc2)
	(person-free person1)
	(at-person person2 loc2)
	(person-free person2)
	(at-crate crate1 depot)
	(crate-content crate1 food)
	(crate-free crate1)
	(at-crate crate2 depot)
	(crate-content crate2 medicine)
	(crate-free crate2)
)
(:goal (and
	(at-drone drone1 depot)
	(person-has-content person1 medicine)
	(person-has-content person2 food)
	))
)
