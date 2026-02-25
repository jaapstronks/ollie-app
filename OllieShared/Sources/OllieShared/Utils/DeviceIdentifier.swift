//
//  DeviceIdentifier.swift
//  OllieShared
//
//  Cross-platform device identifier for CloudKit sync

import Foundation
#if os(iOS)
import UIKit
#elseif os(watchOS)
import WatchKit
#endif

/// Provides a unique device identifier across platforms
public enum DeviceIdentifier {
    public static var current: String {
        #if os(iOS)
        UIDevice.current.identifierForVendor?.uuidString ?? UUID().uuidString
        #elseif os(watchOS)
        WKInterfaceDevice.current().identifierForVendor?.uuidString ?? UUID().uuidString
        #else
        UUID().uuidString
        #endif
    }
}
