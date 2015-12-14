//
//  main.swift
//  efetch
//
//  Created by Kenneth Durbrow on 9/12/15.
//  Copyright © 2015 Kenneth Durbrow. All rights reserved.
//

import Foundation

for arg in Process.arguments[1..<Process.arguments.endIndex] {
    try! EUtils.FASTA(arg) {
        print($0)
        return false
    }
}
