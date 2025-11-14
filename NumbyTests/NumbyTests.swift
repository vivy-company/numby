//
//  NumbyTests.swift
//  NumbyTests
//

import XCTest
@testable import Numby

final class NumbyTests: XCTestCase {
    func testBasicEvaluation() {
        let wrapper = NumbyWrapper()
        let result = wrapper.evaluate("2 + 2")
        XCTAssertEqual(result.value, 4.0, accuracy: 0.0001)
        XCTAssertNil(result.error)
        XCTAssertEqual(wrapper.lastResult, "4")
    }

    func testUnitConversion() {
        let wrapper = NumbyWrapper()
        let result = wrapper.evaluate("5 km in miles")
        XCTAssertEqual(result.value, 3.10686, accuracy: 0.01)
        XCTAssertNotNil(result.unit)
        XCTAssertNil(result.error)
    }

    func testVariablePersistence() {
        let wrapper = NumbyWrapper()
        wrapper.setVariable(name: "x", value: 10.0, unit: "km")
        let result = wrapper.evaluate("x * 2")
        XCTAssertEqual(result.value, 20.0, accuracy: 0.0001)
        XCTAssertEqual(wrapper.lastResult, "20 km")
    }

    func testErrorHandling() {
        let wrapper = NumbyWrapper()
        let result = wrapper.evaluate("invalid expr")
        XCTAssertNotNil(result.error)
        XCTAssertTrue(wrapper.lastResult.contains("Error"))
    }
}