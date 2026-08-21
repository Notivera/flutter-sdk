//
//  Unsafely.swift
//  PushSDKDemo
//
//  Created by Phil on 27/05/2022.
//  Copyright © 2026 Notivera. All rights reserved.
//

import Foundation

public func unsafeUnwrap<T>(
    _ value: @autoclosure () -> T?,
    _ file: StaticString = #file,
    _ line: UInt = #line
) -> T {
    if let value = value() {
        return value
    } else {
        let message = "Expected to unwrap value in \(file):\(line), but got nil"
        fatalError(message, file: file, line: line)
    }
}

public func unsafelyCasting<Source, Target>(
    _ instance: Source,
    targetType: Target.Type = Target.self,
    _ file: StaticString = #file,
    _ line: UInt = #line
) -> Target {
    guard let castedInstance = instance as? Target else {
        fatalError("Could not cast \(instance) into \(Target.self)", file: file, line: line)
    }
    
    return castedInstance
}

public func unsafelyTrying<T>(
    _ block: @autoclosure () throws -> T,
    _ file: StaticString = #file,
    _ line: UInt = #line
) -> T {
    do {
        return try block()
    } catch {
        fatalError("\(error)", file: file, line: line)
    }
}
