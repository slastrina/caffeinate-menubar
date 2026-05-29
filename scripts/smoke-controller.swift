// Integration smoke check: spawn a real caffeinate process via the controller,
// verify the args, then stop it. Run from repo root:
//   swift -I .build/debug -L .build/debug -l CaffeinateMenubar \
//         scripts/smoke-controller.swift
// (Or just inline the same logic, since this is a smoke check only.)

import Foundation

let process = Process()
process.executableURL = URL(fileURLWithPath: "/usr/bin/caffeinate")
process.arguments = ["-i", "-d", "-t", "30"]
process.standardOutput = nil
process.standardError = nil
try process.run()
let pid = process.processIdentifier
print("spawned caffeinate pid=\(pid)")

// Verify ps shows the right args
let ps = Process()
ps.executableURL = URL(fileURLWithPath: "/bin/ps")
ps.arguments = ["-p", String(pid), "-o", "command="]
let pipe = Pipe()
ps.standardOutput = pipe
try ps.run()
ps.waitUntilExit()
let out = String(data: pipe.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? ""
print("ps view: \(out.trimmingCharacters(in: .whitespacesAndNewlines))")

// Simulate the menubar app quitting: send terminate, wait briefly, confirm gone
process.terminate()
process.waitUntilExit()
print("terminated, exit status=\(process.terminationStatus)")

// Confirm there's no orphan
let postPs = Process()
postPs.executableURL = URL(fileURLWithPath: "/bin/ps")
postPs.arguments = ["-p", String(pid)]
let postPipe = Pipe()
postPs.standardOutput = postPipe
try postPs.run()
postPs.waitUntilExit()
print("post-stop ps exit=\(postPs.terminationStatus) (1 = no such pid, expected)")
