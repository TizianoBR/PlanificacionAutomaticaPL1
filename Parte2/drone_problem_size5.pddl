(define (problem drone_problem_d1_r1_l5_p5_c5_g5_ct2)
(:domain emergency-logistics-transporter)
(:objects
	drone1 - drone
	depot - location
	loc1 - location
	loc2 - location
	loc3 - location
	loc4 - location
	loc5 - location
	crate1 - crate
	crate2 - crate
	crate3 - crate
	crate4 - crate
	crate5 - crate
	food - content
	medicine - content
	person1 - person
	person2 - person
	person3 - person
	person4 - person
	person5 - person
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
	(= (fly-cost depot loc1) 232)
	(= (fly-cost depot loc2) 86)
	(= (fly-cost depot loc3) 91)
	(= (fly-cost depot loc4) 264)
	(= (fly-cost depot loc5) 181)
	(= (fly-cost loc1 depot) 232)
	(= (fly-cost loc1 loc1) 1)
	(= (fly-cost loc1 loc2) 179)
	(= (fly-cost loc1 loc3) 175)
	(= (fly-cost loc1 loc4) 33)
	(= (fly-cost loc1 loc5) 125)
	(= (fly-cost loc2 depot) 86)
	(= (fly-cost loc2 loc1) 179)
	(= (fly-cost loc2 loc2) 1)
	(= (fly-cost loc2 loc3) 6)
	(= (fly-cost loc2 loc4) 207)
	(= (fly-cost loc2 loc5) 98)
	(= (fly-cost loc3 depot) 91)
	(= (fly-cost loc3 loc1) 175)
	(= (fly-cost loc3 loc2) 6)
	(= (fly-cost loc3 loc3) 1)
	(= (fly-cost loc3 loc4) 202)
	(= (fly-cost loc3 loc5) 93)
	(= (fly-cost loc4 depot) 264)
	(= (fly-cost loc4 loc1) 33)
	(= (fly-cost loc4 loc2) 207)
	(= (fly-cost loc4 loc3) 202)
	(= (fly-cost loc4 loc4) 1)
	(= (fly-cost loc4 loc5) 141)
	(= (fly-cost loc5 depot) 181)
	(= (fly-cost loc5 loc1) 125)
	(= (fly-cost loc5 loc2) 98)
	(= (fly-cost loc5 loc3) 93)
	(= (fly-cost loc5 loc4) 141)
	(= (fly-cost loc5 loc5) 1)
	(siguiente n0 n1)
	(siguiente n1 n2)
	(siguiente n2 n3)
	(siguiente n3 n4)
	(at-drone drone1 depot)
	(arm-free drone1)
	(drone-has drone1 transporter1)
	(capacity transporter1 n0)
	(at-person person1 loc5)
	(at-person person2 loc3)
	(at-person person3 loc4)
	(at-person person4 loc3)
	(at-person person5 loc2)
	(at-crate crate1 depot)
	(crate-content crate1 food)
	(at-crate crate2 depot)
	(crate-content crate2 food)
	(at-crate crate3 depot)
	(crate-content crate3 medicine)
	(at-crate crate4 depot)
	(crate-content crate4 medicine)
	(at-crate crate5 depot)
	(crate-content crate5 medicine)
)
(:goal (and

	(at-drone drone1 depot)
	(person-has-content person1 medicine)
	(person-has-content person3 food)
	(person-has-content person3 medicine)
	(person-has-content person4 medicine)
	(person-has-content person5 food)
	))
(:metric minimize (total-cost))
)
