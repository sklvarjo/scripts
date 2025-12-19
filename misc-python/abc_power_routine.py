################################
#
# ABC power routine
#
# Author: sklvarjo
#
################################

from datetime import datetime, timedelta

# Starting values
squat_1rm=150 
bench_1rm=125
deadlift_1rm=185
smallest_increment=2.5
first_day_of_first_week = "2025-12-24"
how_many_cycles= 2
weekly_routine = ["Rest|NaN", "L_Squat|H_Bench", "Rest|NaN", "H_Deadlift|NaN", "Rest|NaN", "Rest|NaN","H_Squat|L_Bench"] 

#DO NOT CHANGE THESE
WEEKS=9
LIGHT=0
HEAVY=1
LIGHT_REPS = ["6x2x", "6x2x", "6x2x", "6x2x", "6x2x", "6x2x", "6x2x", "6x2x", "6x2x"]
HEAVY_REPS = ["6x3x", "6x4x", "6x5x", "6x6x", "5x5x", "4x4x", "3x3x", "2x2x", "1x1x"]
DAY_NAMES = ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"]
first_weeks_dates = []

def create_first_week():
    # Create the first weeks dates.
    for i in range(0,7):
        first_weeks_dates.append(datetime.strptime(first_day_of_first_week, "%Y-%m-%d") + timedelta(days=i))

def print_stats(c, s, b, d):
    print("")
    print(f"1RM Stats (Cycle {c}):", end = "")
    print(f" Squat (S): {s} Kg", end = "")
    print(f" Bench (B): {b} Kg", end = "")
    print(f" Deadlift (DL): {d} Kg")

def get_kgs( one_rm, week, weight ):
    coefficient = 0.8
    coefficient_increase = 0.05
    round_digits = 0
    weeks_before_increment = 4
    if weight == HEAVY:
        if week > weeks_before_increment:
            coefficient = coefficient + ( ( week + 1 - weeks_before_increment ) * coefficient_increase )
        #print(f" coef {coefficient} week {week}")
        return ( round( ( one_rm * coefficient ) / smallest_increment, round_digits ) * smallest_increment )
    else:
        return ( round( ( one_rm * coefficient ) / smallest_increment, round_digits ) * smallest_increment )

def print_a_list():
    current_squat_1rm = squat_1rm
    current_bench_1rm = bench_1rm 
    current_deadlift_1rm = deadlift_1rm 

    for cycle in range(1, how_many_cycles+1):
        for week in range(0, WEEKS):
            print(f"Week {week+1} (cycle {cycle})")
            for i in range(0, 7):
                # week*7 moves to next week. 
                # + (cycle*7*WEEKS) moves to next cycle WEEKS forward 
                dt = first_weeks_dates[i] + timedelta(days=(week*7)+(cycle*7*WEEKS))
                #dt = first_weeks_dates[i] + timedelta(days=(week*(cycle*7)))
                line = f'{dt.strftime("%Y-%m-%d")} {DAY_NAMES[i]}\t'
                exs = weekly_routine[i].split('|')
                for e in exs:
                    if "Squat" in e:
                        line += " Squat"
                        if "L_" in e:
                            line += f" Light {LIGHT_REPS[week]}{get_kgs(current_squat_1rm, week, LIGHT)}"
                        else:
                            line += f" Heavy {HEAVY_REPS[week]}{get_kgs(current_squat_1rm, week, HEAVY)}"
                    if "Bench" in e: 
                        line+= " Bench"
                        if "L_" in e:
                            line += f" Light {LIGHT_REPS[week]}{get_kgs(current_bench_1rm, week, LIGHT)}"
                        else:
                            line += f" Heavy {HEAVY_REPS[week]}{get_kgs(current_bench_1rm, week, HEAVY)}"
                    if "Deadlift" in e:
                        line += " Deadlift"
                        if "L_" in e:
                            line += f" Light {LIGHT_REPS[week]}{get_kgs(current_deadlift_1rm, week, LIGHT)}"
                        else:
                            line += f" Heavy {HEAVY_REPS[week]}{get_kgs(current_deadlift_1rm, week, HEAVY)}"
                    if "Rest" in weekly_routine[i]:
                        line += " Rest"
                    #if "NaN" in weekly_routine[i]:
                    #    line += " NaN"
                print(line.lstrip())
            if week == (WEEKS -1):
                # last week so take the 1rms
                current_squat_1rm = get_kgs(current_squat_1rm, week, HEAVY)
                current_bench_1rm = get_kgs(current_bench_1rm, week, HEAVY)
                current_deadlift_1rm = get_kgs(current_deadlift_1rm, week, HEAVY)
                print_stats(cycle, current_squat_1rm, current_bench_1rm, current_deadlift_1rm)

def print_a_week():
    current_squat_1rm = squat_1rm
    current_bench_1rm = bench_1rm 
    current_deadlift_1rm = deadlift_1rm 

    for cycle in range(1, how_many_cycles+1):
        for week in range(0, WEEKS):
            print("")
            print(f"Week {week+1} (cycle {cycle})")
            day_line = ""
            for i in range(0, 7):
               day_line += f"{DAY_NAMES[i][0:3]:13}"
            print(day_line)
            # to how many lines do we have to split
            how_many_maxs_exs_per_day = 0
            for i in range(0,7):
                exs = weekly_routine[i].split('|')
                if len(exs) > how_many_maxs_exs_per_day:
                    how_many_maxs_exs_per_day = len(exs)
            lines = ["" for x in range(2)]
            for i in range(0,7):
                exs = weekly_routine[i].split('|')
                for j in range(0, len(exs)):
                    #lines[j] += f" {j}\t"
                    e = exs[j]
                    if "Squat" in e:
                        if "L_" in e:
                            t = f"S {LIGHT_REPS[week]}{get_kgs(current_squat_1rm, week, LIGHT)}"
                            lines[j] += f"{t:13}"
                        else:
                            t = f"S {HEAVY_REPS[week]}{get_kgs(current_squat_1rm, week, HEAVY)}"
                            lines[j] += f"{t:13}"
                    if "Bench" in e:
                        if "L_" in e:
                            t = f"B {LIGHT_REPS[week]}{get_kgs(current_bench_1rm, week, LIGHT)}"
                            lines[j] += f"{t:13}"
                        else:
                            t = f"B {HEAVY_REPS[week]}{get_kgs(current_bench_1rm, week, HEAVY)}"
                            lines[j] += f"{t:13}"
                    if "Deadlift" in e:
                        if "L_" in e:
                            t = f"DL {LIGHT_REPS[week]}{get_kgs(current_deadlift_1rm, week, LIGHT)}"
                            lines[j] += f"{t:13}"
                        else:
                            t = f"DL {HEAVY_REPS[week]}{get_kgs(current_deadlift_1rm, week, HEAVY)}"
                            lines[j] += f"{t:13}"
                    if "Rest" in e:
                        t = "Rest"
                        lines[j] += f"{t:13}"
                    if "NaN" in e:
                        t = ' ' #empty as there is nothing
                        lines[j] += t*13
            for x in range(0,len(lines)):
                print(lines[x])
            if week == (WEEKS -1):
                # last week so take the 1rms
                current_squat_1rm = get_kgs(current_squat_1rm, week, HEAVY)
                current_bench_1rm = get_kgs(current_bench_1rm, week, HEAVY)
                current_deadlift_1rm = get_kgs(current_deadlift_1rm, week, HEAVY)
                print_stats(cycle, current_squat_1rm, current_bench_1rm, current_deadlift_1rm)

if __name__ == "__main__":
    print_stats(1, squat_1rm, bench_1rm, deadlift_1rm)
    create_first_week()
    #print_a_list()
    print_a_week()
    print("")

