import Foundation

@propertyWrapper
struct Injected<Service> {
    typealias DelayedInjection = () -> Service

    var service: Service?
    var delayed: DelayedInjection?

    init() {
        delayed = { Dependencies.main.resolve() }
    }

    var wrappedValue: Service {
        mutating get {
            if let service = service {
                return service
            } else if let delayed = delayed {
                service = delayed()
                return service!
            } else {
                fatalError()
            }
        }
    }
}

// MARK: Dependencies
public class Dependencies {
    // Will hold all our factories
    public var factories: [ObjectIdentifier: Service] = [:]

    // Make sure that our init will stay private so they need to use the provider functionBuilder
    private init() { }

    // Make sure that all the dependencies are removed when we deinit
    deinit {
        factories.removeAll()
    }
}

public extension Dependencies {
    // Create a overridable main resolver
    static var main = Dependencies()

    func get<Service>() -> Service {
        return resolve()
    }

    // Function builder that accepts multiple services
    @_functionBuilder struct DependencyBuilder {
        public static func buildBlock(_ services: Service...) -> [Service] { services }
    }

    // Convienience init with our service builder
    convenience init(@DependencyBuilder _ services: () -> [Service]) {
        self.init()
        services().forEach { Self.main.register($0) }
    }

    static func setService(_ service: Service) {
        Self.main.register(service)
    }

    static func removeAllServices() {
        Self.main.factories.removeAll()
    }
}

public extension Dependencies {
    // Resolve a serice based on its ObjectIdentifier
    func resolve<Service>() -> Service {

        var service = self.factories[ObjectIdentifier(Service.self)]!

        guard let instance = service.instance, service.cycle == .global else {
            service.instance = service.createInstance(d: self)
            self.factories[service.name] = service
            return service.instance as! Service
        }

        return instance as! Service
    }

    // Register a service with our resolver
    private func register(_ service: Service) {
        self.factories[service.name] = service
    }
}

// MARK: Service
public enum LifeCycle {
   case global
   case oneOf
}

public struct Service {
    // Holds the lifecycle of the current service
    public var cycle: LifeCycle

    // Unique name for each service
    public let name: ObjectIdentifier

    // The closure that will resolve the service
    private let resolve: (Dependencies) -> Any

    var instance: Any?

    func createInstance(d: Dependencies) -> Any {
       return resolve(d)
    }

    // Initialize a service with a resolver
    public init<Service>(_ cycle: LifeCycle = .oneOf, _ resolve: @escaping (Dependencies) -> Service) {
        self.name = ObjectIdentifier(Service.self)
        self.resolve = resolve
        self.cycle = cycle
    }
}
