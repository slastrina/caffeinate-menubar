import Foundation

struct CaffeinateFlags: OptionSet, Hashable, Codable {
    let rawValue: Int

    static let preventIdleSleep    = CaffeinateFlags(rawValue: 1 << 0)  // -i
    static let preventDisplaySleep = CaffeinateFlags(rawValue: 1 << 1)  // -d
    static let preventDiskSleep    = CaffeinateFlags(rawValue: 1 << 2)  // -m
    static let preventSystemSleep  = CaffeinateFlags(rawValue: 1 << 3)  // -s

    var arguments: [String] {
        var args: [String] = []
        if contains(.preventIdleSleep)    { args.append("-i") }
        if contains(.preventDisplaySleep) { args.append("-d") }
        if contains(.preventDiskSleep)    { args.append("-m") }
        if contains(.preventSystemSleep)  { args.append("-s") }
        return args
    }
}
