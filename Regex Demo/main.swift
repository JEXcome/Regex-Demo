//
//  main.swift
//  Regex Demo
//
//  Created by (-.-) on 24.07.2020.
//  Copyright © 2020 Eugene Zimin. All rights reserved.
//

import Foundation

typealias UniqueStrings = Set<String>

extension String: Error
{
    
}

infix operator &&= :  AssignmentPrecedence
extension Bool
{
    static func &&=( lhs: inout Bool, rhs:Bool)
    {
        lhs = lhs && rhs
    }
}

extension String
{
    var regex : NSRegularExpression?
    {
        if let x = try? NSRegularExpression(pattern: self, options: [])
        {
            return x
        }
        
        return nil
    }
    
    var sequences : UniqueStrings
    {
        var result = UniqueStrings()
        
        if isEmpty
        {
            return result
        }

        for length in 1...self.count
        {
            inner: for index in self.indices
            {
                if let bound = self.index(index, offsetBy: length, limitedBy: self.endIndex)
                {
                    let seq = self[index..<bound]
                    result.insert(String(seq))
                }
                else
                {
                    break inner;
                }
            }
        }
        
        return result
    }
}

extension Sequence where Self.Element == String
{
    var maxCount :  Int
    {
        return self.max(by: {$1.count > $0.count})?.count ?? 0
    }
    
    var minCount :  Int
    {
        return self.min(by: {$1.count > $0.count})?.count ?? 0
    }
}

extension NSRegularExpression
{
    func matches(_ string: String) -> Bool
    {
        let range = NSRange(location: 0, length: string.utf16.count)
        return firstMatch(in: string, options: [], range: range) != nil
    }
}


struct Word
{
    let string : String
    
    let match : Bool
    
    var sequences : UniqueStrings

    init(_ string : String, _ match : Bool)
    {
        self.string = string
        
        self.match = match
        
        self.sequences = string.sequences
    }
}

struct RegexBuilder
{
    let match : [String]
    let non_match : [String]
    
    let words : [Word]

    
    init(match : [String], non_match : [String])
    {
        self.match = match
        self.non_match = non_match
        
        var input = [Word]()

        for word in match
        {
            input.append(Word(word, true))
        }
        
        for word in non_match
        {
            input.append(Word(word, false))
        }
        
        words = input
    }
    
    private func notMatch(_ str : String) -> String
    {
        return "^(?!\(str)$).*"
    }
    
    private func fullMatch(_ str : String) -> String
    {
        return "^\(str)$"
    }
    
    func regex() -> String
    {
        let match_seq = words
        .filter
        { word -> Bool in
            
            return word.match
        }
        .map
        { word -> UniqueStrings in
            
            return word.sequences
        }
        .reduce(into: [])
        { ( merged : inout UniqueStrings, next) in
            
            merged.formUnion(next)
        }
        
        let non_match_seq = words
        .filter
        { word -> Bool in
            
            return !word.match
        }
        .map
        { word -> UniqueStrings in
            
            return word.sequences
        }
        .reduce(into: [])
        { ( merged : inout UniqueStrings, next) in
            
            merged.formUnion(next)
        }
        
        let useless = match_seq.intersection(non_match_seq)
        
        let final = words.map
        { word -> Word in
            
            var up = word
            
            up.sequences.subtract(useless)
            
            return up
        }
        
        let match_final = final.filter
        { word -> Bool in
            return word.match
        }
        
        var res_seq = UniqueStrings()
        
        
        for word in match_final
        {
            if word.sequences.isEmpty
            {
                res_seq.insert(fullMatch(word.string))
            }
            else
            {
                let x = word.sequences.first
                { seq -> Bool in
                    
                    return seq.count == word.sequences.minCount
                }!
                
                res_seq.insert(x)
            }
        }
        
        return res_seq.joined(separator: "|")
    }
}


// assumes all input is valid
func create_regexp(match_words : [String], non_match_words : [String]) -> String
{
    let builder = RegexBuilder(match: match_words, non_match: non_match_words)
    
    return builder.regex()
}

func validate_solution(_ regexp : String, match_words: [String], non_match_words: [String]) throws
{
    if match_words.isEmpty || non_match_words.isEmpty,
        match_words.minCount == 0 || non_match_words.minCount == 0
    {
        // empty array or strings in arrays
        throw "Bad Argument"
    }
    
    let umatch = UniqueStrings(match_words)
    
    let unotmatch = UniqueStrings(non_match_words)
    
    if !umatch.intersection(unotmatch).isEmpty
    {
        // some words are in both arrays
        throw "Bad Argument"
    }
    
    let regex = regexp.regex!
    
    var valid = true
    
    for word in match_words
    {
        let x = regex.matches(word)
           
        valid &&= x
        
        if (!x)
        {
            print("\(word) failed")
        }
    }
    
    for word in non_match_words
    {
        let x = !regex.matches(word)
        
        valid &&= x
        
        if (!x)
        {
            print("\(word) failed")
        }
    }
    
    print(valid ? "All OK" : "Failed")
}


let match_words     = [ "youth" ,     "son" ,  "killer" , "grass" , "weather" ]
let non_match_words = [ "you"   , "nickson" ,   "ill"   , "glass" ,  "water"  ]


let regexp = create_regexp(match_words: match_words, non_match_words: non_match_words)

print("match_words: \(match_words)\n")
print("non_match_words: \(non_match_words)\n")

print("regexp: \"\(regexp)\"\n")


try! validate_solution(regexp, match_words: match_words, non_match_words: non_match_words)




