//
//  Stack.swift
//  Swift Calculator
//
//  Created by Alex Mueller on 2021-04-20.
//  Copyright © 2021 Alexander Mueller. All rights reserved.
//

import Foundation

fileprivate class LinkedList<T: Hashable> {
    var seen = false
    var value: T
    var next: LinkedList?
    var description: String {
        var data: [T] = []
        var currentLink: LinkedList? = self
        
        while let link = currentLink, !link.seen {
            link.seen = true
            data += [link.value]
            currentLink = link.next
        }
        
        resetSeen()
        
        var description = data.map({ "\($0)" }).joined(separator: "->")
        
        if let link = currentLink {
            description += "->[\(link.value)...]"
        }
        
        return description
    }
    
    init(value: T, next: LinkedList? = nil) {
        self.value = value
        self.next = next
    }
    
    func resetSeen() {
        var currentLink: LinkedList? = self
        
        while let link = currentLink, link.seen {
            link.seen = false
            currentLink = link.next
        }
    }
    
    func add(link: LinkedList? = nil) {
        next = link
    }
    
    func next(_ n: Int) -> LinkedList? {
        var nthLink: LinkedList? = self
        
        for _ in 0 ..< n {
            guard let link = nthLink else {
                return nil
            }
            
            nthLink = link.next
        }
        
        return nthLink
    }

    public class func from(_ values: [T]) -> LinkedList? {
        guard values.count > 0 else {
            return nil
        }
        
        var linkedList: LinkedList? = nil
        
        for value in values.reversed() {
            linkedList = LinkedList(value: value, next: linkedList)
        }
        
        return linkedList
    }
}

class Stack<T: Hashable> {
    fileprivate var topLink: LinkedList<T>? = nil
    var description: String {
        return topLink?.description ?? ""
    }
    
    init(from list: [T] = []) {
        topLink = LinkedList<T>.from(list)
    }
    
    @discardableResult func pop() -> T? {
        let top = topLink
        topLink = topLink?.next
        
        return top?.value
    }
    
    func push(_ value: T) {
        let top = LinkedList(value: value, next: topLink)
        topLink = top
    }
    
    func peek() -> T? {
        return topLink?.value
    }
}
