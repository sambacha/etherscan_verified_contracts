from mythril.ether.soliditycontract import SolidityContract
from mythril.analysis.symbolic import SymExecWrapper
from mythril.analysis.security import fire_lasers
from mythril.analysis.report import Report
import os


solidity_files = []


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

    sym = SymExecWrapper(contract, address, 'dfs', max_depth=22, execution_timeout=30, create_timeout=30)
    issues = fire_lasers(sym, ['ether_send', 'suicide'])

    if len(issues):
        report = Report(issues)

        f = open(os.path.join("results", "%s.json" % file), 'w')
        f.write("%s\n" % report.as_json())
        f.close()
        f = open(os.path.join("results", "%s.txt" % file), 'w')
        f.write("%s\n" % report.as_text())
        f.close()

        print(report.as_text())
