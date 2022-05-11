lines = []
debug_lines = []
finish = False

debug_line_number = 0

with open("donkeykong_longer.log", "r") as f:
    oldlines = f.readlines()
    lines = [line[:7] for line in oldlines]

with open("debug.log", "r") as debug:
    debug_lines = [line[:7] for line in debug.readlines()]

with open("debug_portion.log", "w") as debug_portion:
    for l, line in enumerate(debug_lines):
        if line not in lines:
            print(str(l) + ": " + line)
            break
