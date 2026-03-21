#!/usr/bin/env python3

########################################################################################
# Problem instance generator skeleton for emergencies drones domain (Part 3).
########################################################################################

from optparse import OptionParser
import random
import math
import sys

########################################################################################
# Hard-coded options
########################################################################################

content_types = ["food", "medicine"]

########################################################################################
# Helper functions
########################################################################################

def distance(location_coords, location_num1, location_num2):
    x1 = location_coords[location_num1][0]
    y1 = location_coords[location_num1][1]
    x2 = location_coords[location_num2][0]
    y2 = location_coords[location_num2][1]
    return math.sqrt((x1 - x2) ** 2 + (y1 - y2) ** 2)

def flight_cost(location_coords, location_num1, location_num2):
    return int(distance(location_coords, location_num1, location_num2)) + 1

def setup_content_types(options):
    while True:
        num_crates_with_contents = []
        crates_left = options.crates
        for x in range(len(content_types) - 1):
            types_after_this = len(content_types) - x - 1
            max_now = crates_left - types_after_this
            num = random.randint(1, max_now)
            num_crates_with_contents.append(num)
            crates_left -= num
        num_crates_with_contents.append(crates_left)

        maxgoals = sum(min(num_crates, options.persons) for num_crates in num_crates_with_contents)

        if options.goals <= maxgoals:
            break

    print()
    print("Types\tQuantities")
    for x in range(len(num_crates_with_contents)):
        if num_crates_with_contents[x] > 0:
            print(content_types[x] + "\t " + str(num_crates_with_contents[x]))

    crates_with_contents = []
    counter = 1
    for x in range(len(content_types)):
        crates = []
        for y in range(num_crates_with_contents[x]):
            crates.append("crate" + str(counter))
            counter += 1
        crates_with_contents.append(crates)

    return crates_with_contents

def setup_location_coords(options):
    location_coords = [(0, 0)]  # For the depot
    for x in range(1, options.locations + 1):
        location_coords.append((random.randint(1, 200), random.randint(1, 200)))

    print("Location positions", location_coords)
    return location_coords

def setup_person_needs(options, crates_with_contents):
    need = [[False for i in range(len(content_types))] for j in range(options.persons)]
    goals_per_contents = [0 for i in range(len(content_types))]

    for goalnum in range(options.goals):
        generated = False
        while not generated:
            rand_person = random.randint(0, options.persons - 1)
            rand_content = random.randint(0, len(content_types) - 1)
            if (goals_per_contents[rand_content] < len(crates_with_contents[rand_content])
                    and not need[rand_person][rand_content]):
                need[rand_person][rand_content] = True
                goals_per_contents[rand_content] += 1
                generated = True
    return need

########################################################################################
# Main program
########################################################################################

def main():
    parser = OptionParser(usage='python generator.py [-help] options...')
    parser.add_option('-d', '--drones', metavar='NUM', dest='drones', action='store', type=int, help='the number of drones')
    parser.add_option('-r', '--transporters', metavar='NUM', type=int, dest='transporters', help='the number of transporters')
    parser.add_option('-l', '--locations', metavar='NUM', type=int, dest='locations', help='the number of locations apart from the depot ')
    parser.add_option('-p', '--persons', metavar='NUM', type=int, dest='persons', help='the number of persons')
    parser.add_option('-c', '--crates', metavar='NUM', type=int, dest='crates', help='the number of crates available')
    parser.add_option('-g', '--goals', metavar='NUM', type=int, dest='goals', help='the number of crates assigned in the goal')

    (options, args) = parser.parse_args()

    if None in [options.drones, options.transporters, options.locations, options.persons, options.crates, options.goals]:
        print("You must specify all parameters: -d -r -l -p -c -g (use --help for help)")
        sys.exit(1)

    if options.goals > options.crates:
        print("Cannot have more goals than crates")
        sys.exit(1)

    if len(content_types) > options.crates:
        print("Cannot have more content types than crates:", content_types)
        sys.exit(1)

    if options.goals > len(content_types) * options.persons:
        print("For", options.persons, "persons, you can have at most", len(content_types) * options.persons, "goals")
        sys.exit(1)

    print("Drones\t\t", options.drones)
    print("transporters\t", options.transporters)
    print("Locations\t", options.locations)
    print("Persons\t\t", options.persons)
    print("Crates\t\t", options.crates)
    print("Goals\t\t", options.goals)

    drone = []
    person = []
    crate = []
    transporter = []
    location = ["depot"]
    numbers = ["n0", "n1", "n2", "n3", "n4"]

    for x in range(options.locations):
        location.append("loc" + str(x + 1))
    for x in range(options.drones):
        drone.append("drone" + str(x + 1))
    for x in range(options.transporters):
        transporter.append("transporter" + str(x + 1))
    for x in range(options.persons):
        person.append("person" + str(x + 1))
    for x in range(options.crates):
        crate.append("crate" + str(x + 1))
    
    crates_with_contents = setup_content_types(options)
    location_coords = setup_location_coords(options)
    need = setup_person_needs(options, crates_with_contents)

    problem_name = "drone_problem_d" + str(options.drones) + "_r" + str(options.transporters) + \
                   "_l" + str(options.locations) + "_p" + str(options.persons) + "_c" + str(options.crates) + \
                   "_g" + str(options.goals) + "_ct" + str(len(content_types))

    with open(problem_name + ".pddl", 'w') as f:
        f.write("(define (problem " + problem_name + ")\n")
        f.write("(:domain emergency-logistics-concurrency)\n")
        f.write("(:objects\n")

        for x in drone: f.write("\t" + x + " - drone\n")
        for x in location: f.write("\t" + x + " - location\n")
        for x in crate: f.write("\t" + x + " - crate\n")
        for x in content_types: f.write("\t" + x + " - content\n")
        for x in person: f.write("\t" + x + " - person\n")
        for x in transporter: f.write("\t" + x + " - transporter\n")
        for x in numbers: f.write("\t" + x + " - num\n")

        f.write(")\n")
        f.write("(:init\n")

        # Distancias (fly-cost) - mantenidas como métricas funcionales
        for i, loc_from in enumerate(location):
            for j, loc_to in enumerate(location):
                cost = flight_cost(location_coords, i, j)
                f.write("\t(= (fly-cost " + loc_from + " " + loc_to + ") " + str(cost) + ")\n")

        # Relaciones numéricas
        for i in range(len(numbers) - 1):
            f.write("\t(siguiente " + numbers[i] + " " + numbers[i+1] + ")\n")

        # Inicializaciones Drones
        for x in drone:
            f.write("\t(at-drone " + x + " depot)\n")
            f.write("\t(arm-free " + x + ")\n")
            f.write("\t(drone-free " + x + ")\n") # LOCK DE DRON LIBRE
            
        # Inicializaciones Transportadores
        for y in transporter:
            f.write("\t(at-transporter " + y + " depot)\n")
            f.write("\t(capacity " + y + " n0)\n")
            f.write("\t(transporter-free " + y + ")\n") # LOCK DE TRANSPORTADOR LIBRE

        # Inicializaciones Personas
        loclist = location.copy()
        loclist.remove("depot")
        for x in person:
            f.write("\t(at-person " + x + " " + random.choice(loclist) + ")\n")
            f.write("\t(person-free " + x + ")\n") # LOCK DE PERSONA LIBRE

        # Inicializaciones Cajas
        for i in range(len(content_types)):
            content_name = content_types[i]
            for crate_name in crates_with_contents[i]:
                f.write("\t(at-crate " + crate_name + " depot)\n")
                f.write("\t(crate-content " + crate_name + " " + content_name + ")\n")
                f.write("\t(crate-free " + crate_name + ")\n") # LOCK DE CAJA LIBRE

        f.write(")\n")
        f.write("(:goal (and\n")

        for x in drone:
            f.write("\t(at-drone " + x + " depot)\n")

        for x in range(options.persons):
            for y in range(len(content_types)):
                if need[x][y]:
                    person_name = person[x]
                    content_name = content_types[y]
                    f.write("\t(person-has-content " + person_name + " " + content_name + ")\n")

        f.write("\t))\n")
        # Optic minimiza el makespan o total-time por defecto cuando hay durative-actions, 
        # así que la métrica de costo se omite para enfocarnos en tiempo de ejecución.
        f.write(")\n")


if __name__ == '__main__':
    main()