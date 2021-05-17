# DependencyInjection

A description of this package.


 how to use when one item depends on another:
 Dependencies {
     Service { _ in Bar.init() }
     Service { Foo(bar: $0.get()) }
     Service(.global) { _ in ViewModel.init() }
 }
 Single register:
 Dependencies.setService(Service { _ in Bar.init()})

