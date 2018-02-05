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
        case writeCode
    }
    
    enum State {
        case fueld(Code)
        case empty
    }

    var repo: Repo
    
    var state: State {
        didSet {
            switch state {
                
            case .fueld(let code):
                repo.append(code)
                
            case .empty:
                break
            }
        }
    }
}

extension Developer {
    
    func handle(command: Developer.Command) -> Developer {
        
        switch (self.state, command) {
            
        case (.empty, .drinkCoffee):
            
            let code = "let add1: (Int) -> Int = { $0 + 1 }"
            var developer = Developer(repo: self.repo, state: self.state)
            developer.state = .fueld(code)
            
            return developer
            
        case (.fueld, .drinkCoffee):
            fatalError() // TODO: Can we handle this at compile time??
            
        case (.empty, .writeCode):
            fatalError() // TODO: Can we handle this at compile time??
            
        case (.fueld, .writeCode):
            return Developer(repo: self.repo, state: .empty)
        }
    }
}



// Side effecting method to handle data embedded in particular state
func doRender(_ developer: Developer) -> Void {
    print("Got some code from a developer: \n > \(developer.repo)")
}

Developer(repo: [], state: .empty)
    .handle(command: .drinkCoffee)
    .handle(command: .writeCode)
    .handle(command: .drinkCoffee)
    .handle(command: .writeCode)
    |> doRender


let add1ThenAdd2 = { (x: Int) -> Int in x + 1 } >> { (x: Int) -> Int in x + 2 }

print("\n---------------\n")

Developer(repo: [], state: .empty) |> { (dev: Developer) -> Developer in dev.handle(command: .drinkCoffee) } |> doRender

let commander: (Developer) -> (Developer.Command) -> Developer = {
    (dev: Developer) in
        return { (command: Developer.Command) in
            return dev.handle(command: command)
    }
}

((Developer(repo: [], state: .empty) |> commander)(.drinkCoffee) |> commander)(.writeCode)

Developer(repo: [], state: .empty)
    |> { $0.handle(command: .drinkCoffee) }
    |> doRender

protocol Empty {}; protocol Fueld {}
struct TypedDeveloper<T> {
    let developer: Developer
    
    static func drinkCoffee(_ emptyDeveloper: TypedDeveloper<Empty>) -> TypedDeveloper<Fueld> {
        let code = "let add1: (Int) -> Int = { $0 + 1 }"
        var developer = emptyDeveloper.developer
        developer.state = .fueld(code)
        
        return TypedDeveloper<Fueld>(developer: developer)
    }
    
    static func writeCode(_ fueldDeveloper: TypedDeveloper<Fueld>) -> TypedDeveloper<Empty> {
        var developer = fueldDeveloper.developer
        developer.state = .empty
        
        return TypedDeveloper<Empty>(developer: developer)
    }

}

TypedDeveloper<Empty>.drinkCoffee(TypedDeveloper<Empty>(developer: Developer(repo: [], state: .empty)))

print("\n---------------\n")

TypedDeveloper<Empty>(developer: Developer(repo: [], state: .empty))
    |> TypedDeveloper<Empty>.drinkCoffee
    >> TypedDeveloper<Fueld>.writeCode
    >> TypedDeveloper<Empty>.drinkCoffee
    >> TypedDeveloper<Fueld>.writeCode
    |> { doRender($0.developer) }

struct Thing<T> {}
protocol Cool {}; protocol Hot {}

func takeThing(_ thing: Thing<Cool>) -> Thing<Hot> {
    return Thing<Hot>()
}

let t = Thing<Hot>()
// takeThing(t)

let t1 = Thing<Cool>()
takeThing(t1)
