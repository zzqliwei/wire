//
//  Copyright © 2020 Square Inc. All rights reserved.
//

import Foundation
import XCTest
@testable import Wire

final class ProtoWriterTests: XCTestCase {

    // MARK: - Tests - Encoding Integers

    func testEncodeFixedInt32() throws {
        let writer = ProtoWriter()
        try writer.encode(tag: 1, value: Int32(-5), encoding: .fixed)

        // 0D is (tag 1 << 3 | .fixed32)
        XCTAssertEqual(writer.data, Data(hexEncoded: "0D_FBFFFFFF"))
    }

    func testEncodeFixedInt64() throws {
        let writer = ProtoWriter()
        try writer.encode(tag: 1, value: Int64(-5), encoding: .fixed)

        // 09 is (tag 1 << 3 | .fixed64)
        XCTAssertEqual(writer.data, Data(hexEncoded: "09_FBFFFFFFFFFFFFFF"))
    }

    func testEncodeFixedUInt32() throws {
        let writer = ProtoWriter()
        try writer.encode(tag: 1, value: UInt32(5), encoding: .fixed)

        // 0D is (tag 1 << 3 | .fixed32)
        XCTAssertEqual(writer.data, Data(hexEncoded: "0D_05000000"))
    }

    func testEncodeFixedUInt64() throws {
        let writer = ProtoWriter()
        try writer.encode(tag: 1, value: UInt64(5), encoding: .fixed)

        // 09 is (tag 1 << 3 | .fixed64)
        XCTAssertEqual(writer.data, Data(hexEncoded: "09_0500000000000000"))
    }

    func testEncodeSignedInt32() throws {
        let writer = ProtoWriter()
        try writer.encode(tag: 1, value: Int32(-5), encoding: .signed)

        // 08 is (tag 1 << 3 | .varint)
        XCTAssertEqual(writer.data, Data(hexEncoded: "08_09"))
    }

    func testEncodeSignedInt64() throws {
        let writer = ProtoWriter()
        try writer.encode(tag: 1, value: Int64(-5), encoding: .signed)

        // 08 is (tag 1 << 3 | .varint)
        XCTAssertEqual(writer.data, Data(hexEncoded: "08_09"))
    }

    func testEncodeVarintInt32() throws {
        let writer = ProtoWriter()
        try writer.encode(tag: 1, value: Int32(-5), encoding: .variable)

        // 08 is (tag 1 << 3 | .varint)
        XCTAssertEqual(writer.data, Data(hexEncoded: "08_FBFFFFFF0F"))
    }

    func testEncodeVarintInt64() throws {
        let writer = ProtoWriter()
        try writer.encode(tag: 1, value: Int64(-5), encoding: .variable)

        // 08 is (tag 1 << 3 | .varint)
        XCTAssertEqual(writer.data, Data(hexEncoded: "08_FBFFFFFFFFFFFFFFFF01"))
    }

    func testEncodeVarintUInt32() throws {
        let writer = ProtoWriter()
        try writer.encode(tag: 1, value: UInt32(5), encoding: .variable)

        // 08 is (tag 1 << 3 | .varint)
        XCTAssertEqual(writer.data, Data(hexEncoded: "08_05"))
    }

    func testEncodeVarintUInt64() throws {
        let writer = ProtoWriter()
        try writer.encode(tag: 1, value: UInt64(5), encoding: .variable)

        // 08 is (tag 1 << 3 | .varint)
        XCTAssertEqual(writer.data, Data(hexEncoded: "08_05"))
    }

    // MARK: - Tests - Encoding Floats

    func testEncodeDouble() throws {
        let writer = ProtoWriter()
        try writer.encode(tag: 1, value: Double(1.2345))

        // 09 is (tag 1 << 3 | .fixed64)
        XCTAssertEqual(writer.data, Data(hexEncoded: "09_8D976E1283C0F33F")!)
    }

    func testEncodeFloat() throws {
        let writer = ProtoWriter()
        try writer.encode(tag: 1, value: Float(1.2345))

        // 0D is (tag 1 << 3 | .fixed32)
        XCTAssertEqual(writer.data, Data(hexEncoded: "0D_19049E3F")!)
    }

    // MARK: - Tests - Encoding Messages And More

    func testEncodeBool() throws {
        let writer = ProtoWriter()
        try writer.encode(tag: 1, value: true)

        // 08 is (tag 1 << 3 | .varint)
        XCTAssertEqual(writer.data, Data(hexEncoded: "08_01")!)
    }

    func testEncodeData() throws {
        let writer = ProtoWriter()
        let data = Data(hexEncoded: "001122334455")
        try writer.encode(tag: 1, value: data)

        XCTAssertEqual(writer.data, Data(hexEncoded: """
            0A           // (Tag 1 | Length Delimited)
            06           // Length 6
            001122334455 // Data value
        """)!)
    }

    func testEncodeMessage() throws {
        let writer = ProtoWriter()
        let message = Person(name: "Luke", id: 5)
        try writer.encode(tag: 1, value: message)

        XCTAssertEqual(writer.data, Data(hexEncoded: """
            0A       // (Tag 1 | Length Delimited)
            08       // Length 8
              0A       // (Tag 1 | Length Delimited)
              04       // Length 4 for name
              4C756B65 // Value "Luke"
              10       // (Tag 2 | Varint)
              05       // Value 5
        """)!)
    }

    func testEncodeString() throws {
        let writer = ProtoWriter()
        try writer.encode(tag: 1, value: "foo")

        XCTAssertEqual(writer.data, Data(hexEncoded: """
            0A     // (Tag 1 | Length Delimited)
            03     // Length 3
            666F6F // Value "foo"
        """)!)
    }

    // MARK: - Tests - Encoding Enums

    func testEncodeEnum() throws {
        let writer = ProtoWriter()
        let value: Person.PhoneType = .HOME
        try writer.encode(tag: 1, value: value)

        XCTAssertEqual(writer.data, Data(hexEncoded: "08_01"))
    }

    // MARK: - Tests - Encoding Repeated Fields

    func testEncodeRepeatedBools() throws {
        let writer = ProtoWriter()
        let values: [Bool] = [true, false]
        try writer.encode(tag: 1, value: values, packed: false)

        XCTAssertEqual(writer.data, Data(hexEncoded: "08_01_08_00")!)
    }

    func testEncodePackedRepeatedBools() throws {
        let writer = ProtoWriter()
        let values: [Bool] = [true, false]
        try writer.encode(tag: 1, value: values, packed: true)

        XCTAssertEqual(writer.data, Data(hexEncoded: "0A_02_01_00")!)
    }

    func testEncodeRepeatedEnums() throws {
        let writer = ProtoWriter()
        let values: [Person.PhoneType] = [.HOME, .MOBILE]
        try writer.encode(tag: 1, value: values, packed: false)

        XCTAssertEqual(writer.data, Data(hexEncoded: "08_01_08_00")!)
    }

    func testEncodePackedRepeatedEnums() throws {
        let writer = ProtoWriter()
        let values: [Person.PhoneType] = [.HOME, .MOBILE]
        try writer.encode(tag: 1, value: values, packed: true)

        XCTAssertEqual(writer.data, Data(hexEncoded: "0A_02_01_00")!)
    }

    func testEncodeRepeatedDoubles() throws {
        let writer = ProtoWriter()
        let doubles: [Double] = [1.2345, 6.7890]
        try writer.encode(tag: 1, value: doubles, packed: false)

        XCTAssertEqual(writer.data, Data(hexEncoded: "09_8D976E1283C0F33F_09_0E2DB29DEF271B40")!)
    }

    func testEncodePackedRepeatedDoubles() throws {
        let writer = ProtoWriter()
        let doubles: [Double] = [1.2345, 6.7890]
        try writer.encode(tag: 1, value: doubles, packed: true)

        XCTAssertEqual(writer.data, Data(hexEncoded: "0A_10_8D976E1283C0F33F_0E2DB29DEF271B40")!)
    }

    func testEncodeRepeatedFloats() throws {
        let writer = ProtoWriter()
        let floats: [Float] = [1.2345, 6.7890]
        try writer.encode(tag: 1, value: floats, packed: false)

        XCTAssertEqual(writer.data, Data(hexEncoded: "0D_19049E3F_0D_7D3FD940")!)
    }

    func testEncodePackedRepeatedFloats() throws {
        let writer = ProtoWriter()
        let floats: [Float] = [1.2345, 6.7890]
        try writer.encode(tag: 1, value: floats, packed: true)

        XCTAssertEqual(writer.data, Data(hexEncoded: "0A_08_19049E3F_7D3FD940")!)
    }

    func testEncodeRepeatedString() throws {
        let writer = ProtoWriter()
        let strings = ["foo", "bar"]
        try writer.encode(tag: 1, value: strings)

        XCTAssertEqual(writer.data, Data(hexEncoded: "0A_03_666F6F_0A_03_626172")!)
    }

    func testEncodeRepeatedFixedUInt32s() throws {
        let writer = ProtoWriter()
        let values: [UInt32] = [1, .max]
        try writer.encode(tag: 1, value: values, encoding: .fixed, packed: false)

        XCTAssertEqual(writer.data, Data(hexEncoded: "0D_01000000_0D_FFFFFFFF")!)
    }

    func testEncodePackedRepeatedFixedUInt32s() throws {
        let writer = ProtoWriter()
        let values: [UInt32] = [1, .max]
        try writer.encode(tag: 1, value: values, encoding: .fixed, packed: true)

        XCTAssertEqual(writer.data, Data(hexEncoded: "0A_08_01000000_FFFFFFFF")!)
    }

    func testEncodeRepeatedVarintUInt32s() throws {
        let writer = ProtoWriter()
        let values: [UInt32] = [1, .max]
        try writer.encode(tag: 1, value: values, encoding: .variable, packed: false)

        XCTAssertEqual(writer.data, Data(hexEncoded: "08_01_08_FFFFFFFF0F")!)
    }

    func testEncodePackedRepeatedVarintUInt32s() throws {
        let writer = ProtoWriter()
        let values: [UInt32] = [1, .max]
        try writer.encode(tag: 1, value: values, encoding: .variable, packed: true)

        XCTAssertEqual(writer.data, Data(hexEncoded: "0A_06_01_FFFFFFFF0F")!)
    }

    // MARK: - Tests - Encoding Maps

    func testEncodeUInt32ToUInt32FixedMap() throws {
        let writer = ProtoWriter()
        writer.outputFormatting = .sortedKeys
        let values: [UInt32: UInt32] = [1: 2, 3: 4]
        try writer.encode(tag: 1, value: values, keyEncoding: .fixed, valueEncoding: .fixed)

        XCTAssertEqual(writer.data, Data(hexEncoded: """
            // Key/Value 1
            0A       // (Tag 1 | Length Delimited)
            0A       // Length 10
            0D       // (Tag 1 | Fixed32)
            01000000 // Value 1
            15       // (Tag 2 | Fixed32)
            02000000 // Value 2

            // Key/Value 2
            0A       // (Tag 1 | Length Delimited)
            0A       // Length 10
            0D       // (Tag 1 | Fixed32)
            03000000 // Value 3
            15       // (Tag 2 | Fixed32)
            04000000 // Value 4
        """))
    }

    func testEncodeUInt32ToUInt64VarintMap() throws {
        let writer = ProtoWriter()
        writer.outputFormatting = .sortedKeys
        let values: [UInt32: UInt64] = [1: 2, 3: 4]
        try writer.encode(tag: 1, value: values, keyEncoding: .variable, valueEncoding: .variable)

        XCTAssertEqual(writer.data, Data(hexEncoded: """
            // Key/Value 1
            0A // (Tag 1 | Length Delimited)
            04 // Length 4
            08 // (Tag 1 | Varint)
            01 // Value 1
            10 // (Tag 2 | Varint)
            02 // Value 2

            // Key/Value 2
            0A // (Tag 1 | Length Delimited)
            04 // Length 4
            08 // (Tag 1 | Varint)
            03 // Value 3
            10 // (Tag 2 | Varint)
            04 // Value 4
        """))
    }

    func testEncodeSignedInt64ToEnumMap() throws {
        let writer = ProtoWriter()
        writer.outputFormatting = .sortedKeys
        let values: [Int64: Person.PhoneType] = [1: .HOME, 2: .MOBILE]
        try writer.encode(tag: 1, value: values, keyEncoding: .signed)

        XCTAssertEqual(writer.data, Data(hexEncoded: """
            // Key/Value 1
            0A // (Tag 1 | Length Delimited)
            04 // Length 4
            08 // (Tag 1 | Varint)
            02 // Value 1
            10 // (Tag 2 | Varint)
            01 // Value .HOME

            // Key/Value 2
            0A // (Tag 1 | Length Delimited)
            04 // Length 4
            08 // (Tag 1 | Varint)
            04 // Value 3
            10 // (Tag 2 | Varint)
            00 // Value .MOBILE
        """))
    }

    func testEncodeUInt32ToStringMap() throws {
        let writer = ProtoWriter()
        writer.outputFormatting = .sortedKeys
        let values: [UInt32: String] = [1: "two", 3: "four"]
        try writer.encode(tag: 1, value: values, keyEncoding: .variable)

        XCTAssertEqual(writer.data, Data(hexEncoded: """
            // Key/Value 1
            0A     // (Tag 1 | Length Delimited)
            07     // Length 7
            08     // (Tag 1 | Varint)
            01     // Value 1
            12     // (Tag 2 | Length Delimited)
            03     // Length 3
            74776F // Value "two"

            // Key/Value 2
            0A       // (Tag 1 | Length Delimited)
            08       // Length 8
            08       // (Tag 1 | Varint)
            03       // Value 3
            12       // (Tag 2 | Length Delimited)
            04       // Length 4
            666F7572 // Value "four"
        """))
    }

    func testEncodeStringToInt32FixedMap() throws {
        let writer = ProtoWriter()
        writer.outputFormatting = .sortedKeys
        let values: [String: Int32] = ["a": -1, "b": -2]
        try writer.encode(tag: 1, value: values, valueEncoding: .fixed)

        XCTAssertEqual(writer.data, Data(hexEncoded: """
            // Key/Value 1
            0A       // (Tag 1 | Length Delimited)
            08       // Length 8
            0A       // (Tag 1 | Length Delimited)
            01       // Length 1
            61       // Value "a"
            15       // (Tag 2 | Fixed32)
            FFFFFFFF // Value "two"

            // Key/Value 2
            0A       // (Tag 1 | Length Delimited)
            08       // Length 8
            0A       // (Tag 1 | Length Delimited)
            01       // Length 1
            62       // Value "b"
            15       // (Tag 2 | Fixed32)
            FEFFFFFF // Value "four"
        """))
    }

    func testEncodeStringToStringMap() throws {
        let writer = ProtoWriter()
        writer.outputFormatting = .sortedKeys
        let values: [String: String] = ["a": "two", "b": "four"]
        try writer.encode(tag: 1, value: values)

        XCTAssertEqual(writer.data, Data(hexEncoded: """
            // Key/Value 1
            0A     // (Tag 1 | Length Delimited)
            08     // Length 8
            0A     // (Tag 1 | Length Delimited)
            01     // Length 1
            61     // Value "a"
            12     // (Tag 2 | Length Delimited)
            03     // Length 3
            74776F // Value "two"

            // Key/Value 2
            0A       // (Tag 1 | Length Delimited)
            09       // Length 9
            0A       // (Tag 1 | Length Delimited)
            01       // Length 1
            62       // Value "b"
            12       // (Tag 2 | Length Delimited)
            04       // Length 4
            666F7572 // Value "four"
        """))
    }

    // MARK: - Tests - Writing Primitives

    func testWriteFixed32() {
        let writer = ProtoWriter()
        writer.writeFixed32(5)
        XCTAssertEqual(writer.data, Data(hexEncoded: "05000000"))

        writer.writeFixed32(UInt32.max)
        XCTAssertEqual(writer.data, Data(hexEncoded: "05000000_FFFFFFFF"))
    }

    func testWriteFixed64() {
        let writer = ProtoWriter()
        writer.writeFixed64(5)
        XCTAssertEqual(writer.data, Data(hexEncoded: "0500000000000000"))

        writer.writeFixed64(UInt64.max)
        XCTAssertEqual(writer.data, Data(hexEncoded: "0500000000000000_FFFFFFFFFFFFFFFF"))
    }

    func testWriteVarint32() {
        let writer = ProtoWriter()
        writer.writeVarint(UInt32(5))
        XCTAssertEqual(writer.data, Data(hexEncoded: "05"))

        writer.writeVarint(UInt32(300))
        XCTAssertEqual(writer.data, Data(hexEncoded: "05_AC02"))

        writer.writeVarint(UInt32.max)
        XCTAssertEqual(writer.data, Data(hexEncoded: "05_AC02_FFFFFFFF0F"))
    }

    func testWriteVarint64() {
        let writer = ProtoWriter()
        writer.writeVarint(UInt64(5))
        XCTAssertEqual(writer.data, Data(hexEncoded: "05"))

        writer.writeVarint(UInt64(300))
        XCTAssertEqual(writer.data, Data(hexEncoded: "05_AC02"))

        writer.writeVarint(UInt64.max)
        XCTAssertEqual(writer.data, Data(hexEncoded: "05_AC02_FFFFFFFFFFFFFFFFFF01"))
    }

}
