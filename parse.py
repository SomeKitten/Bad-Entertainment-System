lines = []
oldlines = []
debug_lines = []
write = False

with open("donkeykong_trimmed.log", "r") as f:
    with open("donkeykong_parsed.log", "w") as f2:
        with open("donkeykong_portion.log", "w") as f3:
            with open("debug.log", "r") as debug:
                with open("debug_portion.log", "w") as debug_portion:
                    line_number = 0
                    i = 0
                    for line in f:
                        line_number += 1

                        if line.startswith("["):
                            continue

                        oldlines.append(line)
                        oldlines = oldlines[-10:]

                        # line = "PC:" + line[:4] + " " + \
                        #     line[49:49+25].strip() + " " + \
                        #     line.strip().split(" ")[-1] + "\n"
                        line = "PC:" + line[:4] + " " + \
                            line[49:49+25].strip() + "\n"

                        lines.append(line)
                        lines = lines[-10:]

                        debug_line = debug.readline()
                        # debug_lines.append(debug_line[:33] + " " +
                        #                    debug_line.split(" ")[-1])
                        debug_lines.append(debug_line[:33] + "\n")
                        debug_lines = debug_lines[-10:]

                        test = debug_lines[-1] != lines[-1]

                        if not write and test:
                            for _ in range(10000):
                                debug_line = debug.readline()
                                # debug_lines.append(debug_line[:33] + " " +
                                #                    debug_line.split(" ")[-1])
                                debug_lines.append(debug_line[:33] + "\n")
                                test = debug_lines[-1] != lines[-1]
                                if not test:
                                    break

                        if not write and test:
                            print(line_number)

                        if write or test:
                            write = True

                            for l in lines:
                                f2.write(l)
                            lines.clear()
                            for ol in oldlines:
                                f3.write(ol)
                            oldlines.clear()
                            for dl in debug_lines:
                                debug_portion.write(dl)
                            debug_lines.clear()

                            i += 1

                            if i > 100:
                                break
