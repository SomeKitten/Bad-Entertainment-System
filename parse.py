with open("nestest.log", "r") as f:
    with open("nestest_parsed.log", "w") as f2:
        for line in f:
            f2.write("PC:" + line[:4] + " " + line[48:48+25] + "\n")
