//
//  Copyright © 2021 Apparata AB. All rights reserved.
//

import Foundation
import os.log

/// Logging without timestamp.
func log(debug message: String) {
    #if DEBUG
    print("ℹ︎", message)
    #endif
}

/// Debug-level messages are only captured in memory when debug logging is
/// enabled through a configuration change. They’re purged in accordance with
/// the configuration’s persistence setting. Messages logged at this level
/// contain information that may be useful during development or while
/// troubleshooting a specific problem. Debug logging is intended for use in
/// a development environment and not in shipping software.
///
/// **Example:**
/// ```
/// log("This is a debug level log.")
/// ```
func log(_ message: @autoclosure () -> String) {
    #if DEBUG
    os_log("%@", log: .default, type: .debug, message())
    #endif
}

/// Default-level messages are initially stored in memory buffers. Without a
/// configuration change, they are compressed and moved to the data store as
/// memory buffers fill. They remain there until a storage quota is exceeded,
/// at which point, the oldest messages are purged. Use this level to capture
/// information about things that might result a failure.
///
/// **Example:**
/// ```
/// log(default: "This is a default level log.")
/// ```
func log(default message: @autoclosure () -> String) {
    os_log("%@", log: .default, type: .default, message())
}

/// Info-level messages are initially stored in memory buffers. Without a
/// configuration change, they are not moved to the data store and are purged
/// as memory buffers fill. They are, however, captured in the data store
/// when faults and, optionally, errors occur. When info-level messages are
/// added to the data store, they remain there until a storage quota is
/// exceeded, at which point, the oldest messages are purged. Use this
/// level to capture information that may be helpful, but isn’t essential,
/// for troubleshooting errors.
///
/// **Example:**
/// ```
/// log(info: "This is an info level log.")
/// ```
func log(info message: @autoclosure () -> String) {
    os_log("%@", log: .default, type: .info, message())
}

/// Error-level messages are always saved in the data store. They remain there
/// until a storage quota is exceeded, at which point, the oldest messages are
/// purged. Error-level messages are intended for reporting process-level
/// errors. If an activity object exists, logging at this level captures
/// information for the entire process chain.
///
/// **Example:**
/// ```
/// log(error: "This is an error level log.")
/// ```
func log(error message: @autoclosure () -> String) {
    os_log("%@", log: .default, type: .error, message())
}

/// Error-level messages are always saved in the data store. They remain there
/// until a storage quota is exceeded, at which point, the oldest messages are
/// purged. Error-level messages are intended for reporting process-level
/// errors. If an activity object exists, logging at this level captures
/// information for the entire process chain.
///
/// **Example:**
/// ```
/// let error: Error = ...
/// log(error: error)
/// ```
func log(error: Error) {
    log(error: "Error: \(error.localizedDescription)")
}

/// Fault-level messages are always saved in the data store. They remain there
/// until a storage quota is exceeded, at which point, the oldest messages are
/// purged. Fault-level messages are intended for capturing system-level or
/// multi-process errors only. If an activity object exists, logging at this
/// level captures information for the entire process chain.
///
/// **Example:**
/// ```
/// log(default: "This is a fault level log.")
/// ```
func log(fault message: @autoclosure () -> String) {
    os_log("%@", log: .default, type: .fault, message())
}

