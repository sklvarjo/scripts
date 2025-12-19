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
line_length = 14*7+1 # 14 chars times the weekdays plus ending char 

class bcolors:
    HEADER = '\033[95m'
    OKBLUE = '\033[94m'
    OKCYAN = '\033[96m'
    OKGREEN = '\033[92m'
    WARNING = '\033[93m'
    FAIL = '\033[91m'
    ENDC = '\033[0m'
    BOLD = '\033[1m'
    UNDERLINE = '\033[4m'

def divider(char):
    t = char*line_length
    print(t)

def internal_divider(char):
    return char*13 

def calc_padding(title_len):
    # Sometimes you cannot divide a char so you are left with 
    # half a char on both sides. Add it to the end 
    padding = int(round(((line_length - title_len)/2) - 1, 0))
    addition = line_length -((title_len) + 2 * padding) - 2 # '|' chars
    return padding, (padding + addition)

def week_title(w, c, fill_char):
    title = f"Week {w} (cycle {c})"
    l_padding, r_padding = calc_padding(len(title))
    line = '|' + fill_char*l_padding + bcolors.BOLD +  bcolors.OKBLUE + title + bcolors.ENDC + fill_char*r_padding + '|'
    print(line)
    divider('-')

def create_first_week():
    # Create the first weeks dates.
    for i in range(0,7):
        first_weeks_dates.append(datetime.strptime(first_day_of_first_week, "%Y-%m-%d") + timedelta(days=i))

def print_stats(c, s, b, d, fill_char):
    divider('=')
    title = f"1RM Stats (Cycle {c}): Squat (S): {s} Kg Bench (B): {b} Kg Deadlift (DL): {d} Kg"
    l_padding, r_padding = calc_padding(len(title))
    line = '|' + fill_char*l_padding + bcolors.OKGREEN + title + bcolors.ENDC + fill_char*r_padding + '|'
    print(line)
    divider('=')

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
                dt = first_weeks_dates[i] + timedelta(days=(week*7)+((cycle-1)*7*WEEKS))
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
            week_title(week+1, cycle, ' ')
            day_line = ""
            for i in range(0, 7):
               day_line += f"|{DAY_NAMES[i]:13}"
            print(day_line + '|')
            date_line = ""
            for i in range(0, 7):
                dt = first_weeks_dates[i] + timedelta(days=(week*7)+((cycle-1)*7*WEEKS))
                t = f"{dt.strftime("%Y-%m-%d")}"
                date_line += f"|{t:13}"
            print(date_line + '|')
            div_line = ""
            for i in range(0,7):
                div_line += f"|{internal_divider('.')}"
            print(div_line + '|')
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
                            lines[j] += f"|{t:13}"
                        else:
                            t = f"S {HEAVY_REPS[week]}{get_kgs(current_squat_1rm, week, HEAVY)}"
                            lines[j] += f"|{t:13}"
                    if "Bench" in e:
                        if "L_" in e:
                            t = f"B {LIGHT_REPS[week]}{get_kgs(current_bench_1rm, week, LIGHT)}"
                            lines[j] += f"|{t:13}"
                        else:
                            t = f"B {HEAVY_REPS[week]}{get_kgs(current_bench_1rm, week, HEAVY)}"
                            lines[j] += f"|{t:13}"
                    if "Deadlift" in e:
                        if "L_" in e:
                            t = f"DL {LIGHT_REPS[week]}{get_kgs(current_deadlift_1rm, week, LIGHT)}"
                            lines[j] += f"|{t:13}"
                        else:
                            t = f"DL {HEAVY_REPS[week]}{get_kgs(current_deadlift_1rm, week, HEAVY)}"
                            lines[j] += f"|{t:13}"
                    if "Rest" in e:
                        t = "Rest"
                        lines[j] += f"|{t:13}"
                    if "NaN" in e:
                        t = ' ' #empty as there is nothing
                        lines[j] += '|' + t*13
            for x in range(0,len(lines)):
                print(lines[x] + '|')
            if week == (WEEKS -1):
                # last week so take the 1rms
                current_squat_1rm = get_kgs(current_squat_1rm, week, HEAVY)
                current_bench_1rm = get_kgs(current_bench_1rm, week, HEAVY)
                current_deadlift_1rm = get_kgs(current_deadlift_1rm, week, HEAVY)
                print_stats(cycle, current_squat_1rm, current_bench_1rm, current_deadlift_1rm, ' ')
            else:
                divider('-')
if __name__ == "__main__":
    create_first_week()
    #print(first_weeks_dates)

    print_stats(1, squat_1rm, bench_1rm, deadlift_1rm, ' ')
    
    #print_a_list()
    
    print_a_week()
