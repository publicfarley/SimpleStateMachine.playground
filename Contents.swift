precedencegroup ForwardApplication { // Nomencalture as per pointfree.co (https://www.pointfree.co/episodes/ep1-functions)
    associativity: left
}

infix operator |> : ForwardApplication

func |> <T,U>(lhs: T, rhs: (T) -> U) -> U {
    return rhs(lhs)
}

func composeOrdered<A,B,C>(_ f: @escaping (A) -> B, then g: @escaping (B) -> C)
    -> (A) -> C {
        
        return { a in g(f(a)) }
}

// Forward Compose infix opperator (mimics F# operator)
precedencegroup ForwardComposition { // Nomencalture as per pointfree.co (https://www.pointfree.co/episodes/ep1-functions)
    associativity: left
    higherThan: ForwardApplication
}

infix operator >> : ForwardComposition

func >> <A,B,C>(lhs: @escaping (A) -> B, rhs: @escaping (B) -> C) -> (A) -> C {
    return composeOrdered(lhs, then: rhs)
}

// ---------------------------------------------------------
typealias Code = String
typealias Repo = Array<Code>

struct Developer {
    
    enum Command {
        case drinkCoffee
        case writeCode(Code)
    }
    
    enum State {
        case fueld
        case empty
    }

    var repo: Repo
    var state: State
}

extension Developer {
    
    func handle(command: Developer.Command) -> Developer {
        
        switch (self.state, command) {
            
        case (.empty, .drinkCoffee):
            var updatedDev = self
            updatedDev.state = .fueld
            return updatedDev
            
        case (.fueld, .drinkCoffee):
            // Invalid to receive drinkCoffee command when already fueld, so just return self (no state change).
            return self
            
        case (.empty, .writeCode):
            // Invalid to receive writeCode command when already empty, so just return self (no state change).
            return self
            
        case (.fueld, .writeCode(let code)):
            var updatedDev = self
            updatedDev.repo.append(code)
            updatedDev.state = .empty
            return updatedDev
        }
    }
}



// Side effecting method to handle data embedded in particular state
func doRender(_ developer: Developer) -> Void {
    print("Got some code from a developer: \n > \(developer.repo)")
}

let dev = Developer(repo: [], state: .empty)
    .handle(command: .drinkCoffee)
    .handle(command: .drinkCoffee) // Has no effect (since already in fueld state)
    .handle(command: .writeCode("let add1: (Int) -> Int = { $0 + 1 }"))
    .handle(command: .drinkCoffee)
    .handle(command: .writeCode("let mult5: (Int) -> Int = { $0 * 5 }"))

print("\n1. ---------------")
dev |> doRender

dev.repo == ["let add1: (Int) -> Int = { $0 + 1 }","let mult5: (Int) -> Int = { $0 * 5 }"]

let add1ThenAdd2 = { (x: Int) -> Int in x + 1 } >> { (x: Int) -> Int in x + 2 }

print("\n2. ---------------")
Developer(repo: [], state: .empty) |> { (dev: Developer) -> Developer in dev.handle(command: .drinkCoffee) } |> doRender

let commander: (Developer) -> (Developer.Command) -> Developer = {
    (dev: Developer) in
        return { (command: Developer.Command) in
            return dev.handle(command: command)
    }
}

print("\n3. ---------------")
((Developer(repo: [], state: .empty) |> commander)(.drinkCoffee) |> commander)(.writeCode("struct Stuff {}")) |> doRender

print("\n4. ---------------")
Developer(repo: [], state: .empty)
    |> { $0.handle(command: .drinkCoffee) }
    |> doRender



// *** Handle illegal state transitions via the type system (phantom types)
protocol Empty {}; protocol Fueld {}
struct AnnotatedDeveloper<T> {
    let developer: Developer

    static func drinkCoffee(_ emptyDeveloper: AnnotatedDeveloper<Empty>) -> AnnotatedDeveloper<Fueld> {
        var developer = emptyDeveloper.developer
        developer.state = .fueld

        return AnnotatedDeveloper<Fueld>(developer: developer)
    }

    static func writeCode(_ fueldDeveloper: AnnotatedDeveloper<Fueld>, code: Code) -> AnnotatedDeveloper<Empty> {
        var developer = fueldDeveloper.developer
        developer.repo.append(code)
        developer.state = .empty

        return AnnotatedDeveloper<Empty>(developer: developer)
    }

}

AnnotatedDeveloper<Empty>.drinkCoffee(AnnotatedDeveloper<Empty>(developer: Developer(repo: [], state: .empty)))

print("\n5. ---------------")
AnnotatedDeveloper<Empty>(developer: Developer(repo: [], state: .empty))
    |> AnnotatedDeveloper<Empty>.drinkCoffee
    >> { AnnotatedDeveloper<Fueld>.writeCode($0, code: "struct Thing<T> {}") }
    >> AnnotatedDeveloper<Empty>.drinkCoffee
    >> { AnnotatedDeveloper<Fueld>.writeCode($0, code: "protocol Cool {}; protocol Hot {}") }
    |> { doRender($0.developer) }

struct Thing<T> {}
protocol Cool {}; protocol Hot {}

func turnCoolThingHot(_ thing: Thing<Cool>) -> Thing<Hot> {
    return Thing<Hot>()
}

let hotThing = Thing<Hot>()
// turnCoolThingHot(hotThing) -- Compiler error. Illegal operation.

let coolThing = Thing<Cool>()
let thing = turnCoolThingHot(coolThing) // 👍

type(of: thing) == Thing<Hot>.self

