//
//  eutilsTests.swift
//  eutilsTests
//
//  Created by Kenneth Durbrow on 9/12/15.
//  Copyright © 2015 Kenneth Durbrow. All rights reserved.
//

import XCTest
@testable import eutils

class eutilsTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
   
    func testSRARunList() {
        for run in EUtils.SRARunList("SRS107532" /*"SRP003186"*/) {
            print(run.accession)
        }
    }
    
    func testFASTA() {
        var seqlen = 0
        try! EUtils.FASTA("CM000670.1") { (line) in
            if line.hasPrefix(">") {
                XCTAssert(line == ">gi|224384761|gb|CM000670.1| Homo sapiens chromosome 8, GRCh37 primary reference assembly")
            }
            else {
                seqlen += line.characters.count
            }
            return false
        }
        XCTAssert(seqlen == 146364022)
    }
    
    func testSummary() {
        do {
            let summary = EUtils.summary("nuccore", accession: "CM000670.1")
            let seqId = summary["extra"] as! String
            let title = summary["title"] as! String
            let slen = summary["slen"] as! Int
            print(">\(seqId) \(title) Length:\(slen)")
        }
        do {
            let summary = EUtils.summary("nuccore", accession: "NC_000008")
            let seqId = summary["extra"] as! String
            let title = summary["title"] as! String
            let slen = summary["slen"] as! Int
            print(">\(seqId) \(title) Length:\(slen)")
        }
    }
    
    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measureBlock {
            var seqlen = 0
            try! EUtils.FASTA("CM000683.1") { (line) in
                if line.hasPrefix(">") {
                    print(line)
                }
                else {
                    seqlen += line.characters.count
                }
                return false
            }
            print("\(seqlen) bases")
        }
    }
    
}
