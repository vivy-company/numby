//
//  CalculationSession+Extensions.swift
//  Numby
//
//  Extensions for CalculationSession CoreData entity
//

import Foundation
import CoreData

extension CalculationSession {
    nonisolated public override func awakeFromInsert() {
        super.awakeFromInsert()

        // Set default values for required attributes using setValue to avoid actor isolation issues
        setPrimitiveValue(NSUUID(), forKey: "id")
        setPrimitiveValue(NSDate(), forKey: "timestamp")
        setPrimitiveValue(NSData(), forKey: "sessionData")
    }

    // Helper properties for working with Swift types
    var swiftId: UUID {
        get { (id as? UUID) ?? UUID() }
        set { id = newValue as NSUUID }
    }

    var swiftTimestamp: Date {
        get { (timestamp as? Date) ?? Date() }
        set { timestamp = newValue as NSDate }
    }

    var swiftSessionData: Data {
        get { (sessionData as? Data) ?? Data() }
        set { sessionData = newValue as NSData }
    }
}
