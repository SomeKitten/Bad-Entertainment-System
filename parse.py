lines = []
oldlines = []
debug_lines = []
finish = False
write = False

line_number = 0
debug_line_number = 0

check_size = 10

with open("donkeykong_longer.log", "r") as f:
    oldlines = f.readlines()
    lines = [line[:7] + line[-42:-16] + "\n" for line in oldlines]

with open("debug.log", "r") as debug:
    debug_lines = [line[:33] + "\n" for line in debug.readlines()]

with open("donkeykong_parsed.log", "w") as f2:
    with open("donkeykong_portion.log", "w") as f3:
        with open("debug_portion.log", "w") as debug_portion:
            while line_number < len(lines):
                line_number += 1
                debug_line_number += 1

                while not lines[line_number - 1].startswith("PC"):
                    line_number += 1
                while not debug_lines[debug_line_number - 1].startswith("PC"):
                    debug_line_number += 1

                equal = debug_lines[debug_line_number -
                                    1] == lines[line_number - 1]

                if not equal:
                    finish = True

                    r = lines[line_number - 1:line_number + check_size]
                    for _ in range(check_size):
                        debug_line_number += 1

                        equal = debug_lines[debug_line_number - 1] in r

                        if equal:
                            line_number += r.index(
                                debug_lines[debug_line_number - 1])
                            finish = False
                            break

                if finish:
                    print("Original: " + str(line_number))
                    print("Debug: " + str(debug_line_number))

                    for i in range(line_number - 11):
                        f2.write("\n")
                    for i in range(debug_line_number - 11):
                        debug_portion.write("\n")

                    for j in range(-10, 89):
                        l = lines[line_number - 1 + j]
                        ol = oldlines[line_number - 1 + j]
                        dl = debug_lines[debug_line_number - 1 + j]

                        f2.write(l)
                        f3.write(ol)
                        debug_portion.write(dl)

                    break
