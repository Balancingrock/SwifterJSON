// =====================================================================================================================
//
//  File:       UnicodeSupport.swift
//  Project:    VJson
//
//  Version:    0.13.0
//
//  Author:     Marinus van der Lugt
//  Company:    http://balancingrock.nl
//  Website:    http://swiftfire.nl/projects/swifterjson/swifterjson.html
//  Git:        https://github.com/Balancingrock/VJson
//
//  Copyright:  (c) 2018 Marinus van der Lugt, All rights reserved.
//
//  License:    Use or redistribute this code any way you like with the following two provision:
//
//  1) You ACCEPT this source code AS IS without any guarantees that it will work as intended. Any liability from its
//  use is YOURS.
//
//  2) You WILL NOT seek damages from the author or balancingrock.nl.
//
//  I also ask you to please leave this header with the source code.
//
//  I strongly believe that the Non Agression Principle is the way for societies to function optimally. I thus reject
//  the implicit use of force to extract payment. Since I cannot negotiate with you about the price of this code, I
//  have choosen to leave it up to you to determine its price. You pay me whatever you think this code is worth to you.
//
//   - You can send payment via paypal to: sales@balancingrock.nl
//   - Or wire bitcoins to: 1GacSREBxPy1yskLMc9de2nofNv2SNdwqH
//
//  I prefer the above two, but if these options don't suit you, you might also send me a gift from my amazon.co.uk
//  wishlist: http://www.amazon.co.uk/gp/registry/wishlist/34GNMPZKAQ0OO/ref=cm_sw_em_r_wsl_cE3Tub013CKN6_wb
//
//  If you like to pay in another way, please contact me at rien@balancingrock.nl
//
//  (It is always a good idea to check the website http://www.balancingrock.nl before payment)
//
//  For private and non-profit use the suggested price is the price of 1 good cup of coffee, say $4.
//  For commercial use the suggested price is the price of 1 good meal, say $20.
//
//  You are however encouraged to pay more ;-)
//
//  Prices/Quotes for support, modifications or enhancements can be obtained from: rien@balancingrock.nl
//
// =====================================================================================================================
//
//  This JSON implementation was written using the definitions as found on: http://json.org (2015.01.01)
//
// =====================================================================================================================
//
// History
//
// 0.13.0  - Initial version
// =====================================================================================================================

import Foundation
import Ascii


private enum ScanMode { case none, backslash, fourHexadecimals, threeHexadecimals, twoHexadecimals, oneHexadecimal }


/// Maps JSON escape sequences to string fragments

public struct JsonStringSequenceLUT {

    /// Replace the "\b" with this character
    var b: Character = Character._BACKSPACE

    /// Replace the "\f" with this character
    var f: Character = Character._FORMFEED

    /// Replace the "\n" with this character
    var n: Character = Character._NEWLINE

    /// Replace the "\r" with this character
    var r: Character = Character._RETURN

    /// Replace the "\t" with this character
    var t: Character = Character._TAB
    
    init(b: Character? = nil, f: Character? = nil, n: Character? = nil, r: Character? = nil, t: Character? = nil) {
        if let b = b { self.b = b }
        if let f = f { self.f = f }
        if let n = n { self.n = n }
        if let r = r { self.r = r }
        if let t = t { self.t = t }
    }
}

public let defaultJsonStringSequenceLUT = JsonStringSequenceLUT()
public let printableJsonStringSequenceLUT = JsonStringSequenceLUT(b: "␈", f: "␌", n:"␊", r: "␍", t: "␉")

public extension String {
    
    
    /// Converts self into a sequence of unicode characters. All JSON escape sequences will be converted into their respective characters.
    ///
    /// - Note: Self must be a fully compliant JSON string, escaped where necessary, no double quotes, no characters with UTF16 > 255.
    ///
    /// - Returns: Nil if the conversion failed (the string is not JSON compliant). Otherwise the converted string.
    
    public func jsonStringToString(lut: JsonStringSequenceLUT = defaultJsonStringSequenceLUT) -> String? {
        
        // The result will be assembled in this variable until it is finally converted into a string
        var utf16Array: Array<UInt16> = []

        // Adding characters to the UTF16 array
        func appendToUtf16Array(_ char: Character) {
            for unicode in char.unicodeScalars {
                for scalar in Array(unicode.utf16) {
                    utf16Array.append(scalar)
                }
            }
        }
        
        // Will be set according to the current mode of operation
        var mode: ScanMode = .none

        // Used for the unicode sequences
        var unicodeScalar = ""
        
        // Parse all characters in self
        for char in self {
            
            // Action depends on the current mode
            switch mode {
                
            // Normal or no mode, add the character to the result
            case .none:
                
                // Double quotes are not allowed
                guard char != Character._DOUBLE_QUOTES else { return nil }
                
                // All sequences start with a backslash
                if char == Character._BACKSLASH {
                    mode = .backslash
                } else {
                    // Add the character to the result
                    appendToUtf16Array(char)
                }
            
            // The first backslash will trigger the backslash mode
            case .backslash:
                mode = .none // will be overwritten when necessary
                switch char {
                case Character._DOUBLE_QUOTES: utf16Array.append(UInt16(Ascii._DOUBLE_QUOTES))
                case Character._BACKSLASH: utf16Array.append(UInt16(Ascii._BACKSLASH))
                case Character._FOREWARD_SLASH: utf16Array.append(UInt16(Ascii._FOREWARD_SLASH))
                case Character._b: appendToUtf16Array(lut.b)
                case Character._f: appendToUtf16Array(lut.f)
                case Character._n: appendToUtf16Array(lut.n)
                case Character._r: appendToUtf16Array(lut.r)
                case Character._t: appendToUtf16Array(lut.t)
                case Character._u: mode = .fourHexadecimals
                default: return nil
                }
            
            // Collect 4 more hexadecimal characters
            case .fourHexadecimals:
                unicodeScalar.append(char)
                mode = .threeHexadecimals
            
            // Collect 3 more hexadecimal characters
            case .threeHexadecimals:
                unicodeScalar.append(char)
                mode = .twoHexadecimals
            
            // Collect 2 more hexadecimal characters
            case .twoHexadecimals:
                unicodeScalar.append(char)
                mode = .oneHexadecimal
            
            // Collect 1 more hexadecimal character
            case .oneHexadecimal:
                unicodeScalar.append(char)
                
                // Convert the hexadecimals to a unicode scalar and append that to the result
                guard let scalar: UInt16 = UInt16(hexString: unicodeScalar) else { return nil }
                
                utf16Array.append(scalar)
                
                // Switch to normal again
                mode = .none
                
                // Reset storage
                unicodeScalar = ""
            }
        }
        
        // Make sure all started sequences are finished
        guard mode == .none else { return nil }
        
        // Ready
        return String(utf16CodeUnits: &utf16Array, count: utf16Array.count)
    }
    
    
    /// Returns self with all special characters and multi-byte unicode characters converted into JSON escaped sequences. In addition to the default characters that must be converted into sequences, it will also convert the characters in the given JsonStringLUT to escaped sequences.
    
    public func stringToJsonString(lut: JsonStringSequenceLUT = defaultJsonStringSequenceLUT) -> String {

        // The result is collected in this variable
        var res = ""
        
        // Itterate by character
        for char in self {
            
            switch char {

                // Handle backspace
            case lut.b, Character._BACKSPACE:
                res.append(Character._BACKSLASH)
                res.append(Character._b)
                
                // Handle form-feed
            case lut.f, Character._FORMFEED:
                res.append(Character._BACKSLASH)
                res.append(Character._f)

                // Handle newline
            case lut.n, Character._NEWLINE:
                res.append(Character._BACKSLASH)
                res.append(Character._n)

                // Handle return
            case lut.r, Character._CARRIAGE_RETURN:
                res.append(Character._BACKSLASH)
                res.append(Character._r)

                // Handle backspace
            case lut.t, Character._BACKSPACE:
                res.append(Character._BACKSLASH)
                res.append(Character._t)

                // Handle double quotes, backslash and foreward slash
            case Character._DOUBLE_QUOTES, Character._BACKSLASH, Character._FOREWARD_SLASH:
                res.append(Character._BACKSLASH)
                res.append(char)

                // Handle all other characters
            default:
                
                // Create an array of 16 bit UTF scalars
                var utf16s: Array<UInt16> = []
                
                // Append each scalar
                for scalar in char.unicodeScalars {
                    utf16s.append(contentsOf: Array(scalar.utf16))
                }
                
                // Handle extended ascii set characters first (1 byte)
                if utf16s.count == 1 {
                    let c = utf16s.first!
                    if c < 256 {
                        res.append(char)
                    } else {
                    
                        // All > 255 must be added as an escaped sequence
                        res.append(Character._BACKSLASH)
                        res.append(Character._u)
                        res.append(contentsOf: c.hexString)
                    }
                } else {
                    
                    // All the rest must be appended as escaped sequences
                    for c in utf16s {
                        res.append(Character._BACKSLASH)
                        res.append(Character._u)
                        res.append(contentsOf: c.hexString)
                    }
                }
            }
        }
        
        return res
    }
}