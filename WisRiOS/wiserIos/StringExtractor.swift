//
//  StringExtractor.swift
//  wiserIos
//
//  Created by Peter Helstrup Jensen on 03/09/2015.
//  Copyright © 2015 Peter Helstrup Jensen. All rights reserved.
//

import Foundation

class StringExtractor {
    
    /**
    Extracts the highest number in a string
    - parameter aString:	string with e.g. text and numbers
    - returns: The highest number represented in aString
    */
    static func highestNumberInString (aString: String) -> Int {
        var alphanumerics = String()
        var highest = Int()
        
        func determineHighest() {
            if let number = Int(alphanumerics) {
                if number > highest {
                    highest = number
                }
            }
            alphanumerics = String()
        }
        
        for c in aString.characters {
            if c >= "0" && c <= "9" {
                alphanumerics += String(c)
            }
            else {
                determineHighest()
            }
        }
        
        determineHighest()
        return highest
    }
    
    /**
    Shortens a string.
    - parameter aString:		The string to be shortened
    - parameter maxLength:	Max length of the string
    - returns: The shortened string.
    */
    static func shortenString(aString: String, maxLength: Int) -> String {
        var shortenedText = aString

        if aString.characters.count > maxLength {
            let endIndex = aString.startIndex.advancedBy(maxLength)
            shortenedText = aString.substringToIndex(endIndex) + "..."
        }
        
        return shortenedText
    }
    
}