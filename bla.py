from mythril.ether.soliditycontract import SolidityContract
from mythril.mythril import Mythril
import os


solidity_files = []
myth = Mythril()

for filename in os.listdir('contracts'):
    if filename.endswith(".sol"):
        solidity_files.append(filename)

try:
    resume = open("./.resume", "r")
    resume_file = resume.read()
    resume.close()

    for filename in solidity_files:
        if resume_file == filename:
            break
        else:
            solidity_files.remove(filename)

    print("Resuming analysis from %s" % resume_file)
except:
    pass


for file in solidity_files:

    address = file[:42]
    name = file[43:]

    print("## Analyzing %s at %s ##" % (name, address))

    try:
        contract = SolidityContract(os.path.join("contracts", file))
    except:
        print("Compilation error.")

    resume = open("./.resume", "w")
    resume.write(file)
    resume.close()

    report = myth.fire_lasers(
        "dfs",
        contracts=[contract],
        modules=['ether_send', 'suicide'],
        verbose_report=True,
        max_depth=22,
        execution_timeout=30,
        create_timeout=30
    )

    if len(report.issues):

        f = open(os.path.join("results", "%s.json" % file), 'w')
        f.write("%s\n" % report.as_json())
        f.close()
        f = open(os.path.join("results", "%s.txt" % file), 'w')
        f.write("%s\n" % report.as_text())
        f.close()

        print(report.as_text())
