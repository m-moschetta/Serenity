//
//  Diagnostics.swift
//  Serenity
//
//  Simple shared diagnostics store
//

import Foundation

final class Diagnostics {
    static let shared = Diagnostics()
    private init() {}
    var lastAIError: String?
}

