//
//  NSView+Extensions.swift
//  Numby
//
//  Helper extensions for view hierarchy traversal
//

import Cocoa

extension NSView {
    var swiftClassName: String {
        return String(describing: type(of: self))
    }

    func contains(className: String) -> Bool {
        if swiftClassName.contains(className) {
            return true
        }

        for subview in subviews {
            if subview.contains(className: className) {
                return true
            }
        }

        return false
    }

    func firstDescendant(withClassName className: String) -> NSView? {
        for subview in subviews {
            if subview.swiftClassName.contains(className) {
                return subview
            }
            if let found = subview.firstDescendant(withClassName: className) {
                return found
            }
        }
        return nil
    }

    func firstDescendant<T: NSView>(ofType type: T.Type) -> T? {
        if let view = self as? T {
            return view
        }
        for subview in subviews {
            if let found: T = subview.firstDescendant(ofType: type) {
                return found
            }
        }
        return nil
    }
}
