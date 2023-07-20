import SwiftUI

public protocol SettingsWithDefaults: ParameterizableSettingsWithDefaults {
    init()
}

extension SettingsWithDefaults {
    static var defaults: Self { Self() }
}

public protocol ParameterizableSettingsWithDefaults {
    static var defaults: Self { get }
}

extension AppStorage {
    
    /// Creates a property that can read and write to a string user default.
    public init<Repository: ParameterizableSettingsWithDefaults>(_ keyPath: KeyPath<Repository, Value>) where Value == String {
        let key = Self.keyFromKeyPath(keyPath)
        self.init(wrappedValue: Repository.defaults[keyPath: keyPath], key)
    }

    /// Creates a property that can read and write to an integer user default,
    /// transforming that to RawRepresentable data type.
    public init<Repository: ParameterizableSettingsWithDefaults>(_ keyPath: KeyPath<Repository, Value>) where Value : RawRepresentable, Value.RawValue == Int {
        let key = Self.keyFromKeyPath(keyPath)
        self.init(wrappedValue: Repository.defaults[keyPath: keyPath], key)
    }

    /// Creates a property that can read and write to a user default as data.
    public init<Repository: ParameterizableSettingsWithDefaults>(_ keyPath: KeyPath<Repository, Value>) where Value == Data {
        let key = Self.keyFromKeyPath(keyPath)
        self.init(wrappedValue: Repository.defaults[keyPath: keyPath], key)
    }
    
    /// Creates a property that can read and write to an integer user default.
    public init<Repository: ParameterizableSettingsWithDefaults>(_ keyPath: KeyPath<Repository, Value>) where Value == Int {
        let key = Self.keyFromKeyPath(keyPath)
        self.init(wrappedValue: Repository.defaults[keyPath: keyPath], key)
    }
    
    /// Creates a property that can read and write to a string user default,
    /// transforming that to RawRepresentable data type.
    public init<Repository: ParameterizableSettingsWithDefaults>(_ keyPath: KeyPath<Repository, Value>) where Value : RawRepresentable, Value.RawValue == String {
        let key = Self.keyFromKeyPath(keyPath)
        self.init(wrappedValue: Repository.defaults[keyPath: keyPath], key)
    }

    /// Creates a property that can read and write to a url user default.
    public init<Repository: ParameterizableSettingsWithDefaults>(_ keyPath: KeyPath<Repository, Value>) where Value == URL {
        let key = Self.keyFromKeyPath(keyPath)
        self.init(wrappedValue: Repository.defaults[keyPath: keyPath], key)
    }
    
    /// Creates a property that can read and write to a double user default.
    public init<Repository: ParameterizableSettingsWithDefaults>(_ keyPath: KeyPath<Repository, Value>) where Value == Double {
        let key = Self.keyFromKeyPath(keyPath)
        self.init(wrappedValue: Repository.defaults[keyPath: keyPath], key)
    }

    /// Creates a property that can read and write to a boolean user default.
    public init<Repository: ParameterizableSettingsWithDefaults>(_ keyPath: KeyPath<Repository, Value>) where Value == Bool {
        let key = Self.keyFromKeyPath(keyPath)
        self.init(wrappedValue: Repository.defaults[keyPath: keyPath], key)
    }
    
    private static func keyFromKeyPath<Repository: ParameterizableSettingsWithDefaults>(_ keyPath: KeyPath<Repository, Value>) -> String {
        let key = "setting.\(String("\(keyPath)".trimmingPrefix(/\\/)))"
        return key
    }
}
