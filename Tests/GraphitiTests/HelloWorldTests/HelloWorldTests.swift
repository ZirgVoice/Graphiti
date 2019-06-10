import XCTest
@testable import Graphiti
import GraphQL
import NIO

extension Float : InputType, OutputType {}

class HelloWorldTests : XCTestCase {
    struct MyContext {
        
    }
    
    struct MyRoot : FieldKeyProvider {
        typealias FieldKey = FieldKeys
        
        enum FieldKeys : String {
            case hello
        }
        
        
        func hello(context: MyContext, arguments: NoArguments) -> String {
            return "world"
        }
    }
    
    let schema = Schema<MyRoot, MyContext> {
        Query {
            Field(.hello, at: MyRoot.hello)
        }
    }

    func testHello() throws {
        let eventLoopGroup = MultiThreadedEventLoopGroup(numberOfThreads: 1)
        
        defer {
            XCTAssertNoThrow(try eventLoopGroup.syncShutdownGracefully())
        }

        let query = "{ hello }"
        
        let expected = GraphQLResult(
            data: [
                "hello": "world"
            ]
        )
        
        let result = try schema.execute(
            request: query,
            root: MyRoot(),
            context: MyContext(),
            eventLoopGroup: eventLoopGroup
        ).wait()
        
        XCTAssertEqual(result, expected)
    }

    func testBoyhowdy() throws {
        let eventLoopGroup = MultiThreadedEventLoopGroup(numberOfThreads: 1)
        defer {
            XCTAssertNoThrow(try eventLoopGroup.syncShutdownGracefully())
        }

        let query = "{ boyhowdy }"

        let expectedErrors = GraphQLResult(
            errors: [
                GraphQLError(
                    message: "Cannot query field \"boyhowdy\" on type \"Query\".",
                    locations: [SourceLocation(line: 1, column: 3)]
                )
            ]
        )

        let result = try schema.execute(
            request: query,
            root: MyRoot(),
            context: MyContext(),
            eventLoopGroup: eventLoopGroup
        ).wait()
        
        XCTAssertEqual(result, expectedErrors)
    }
    
    struct ID : Codable, InputType, OutputType {
        let id: String
        
        init(from decoder: Decoder) throws {
            let container = try decoder.singleValueContainer()
            self.id = try container.decode(String.self)
        }
        
        func encode(to encoder: Encoder) throws {
            var container = encoder.singleValueContainer()
            try container.encode(self.id)
        }
    }

    func testScalar() throws {
        let eventLoopGroup = MultiThreadedEventLoopGroup(numberOfThreads: 1)
        defer {
            XCTAssertNoThrow(try eventLoopGroup.syncShutdownGracefully())
        }
        
        struct ScalarRoot : FieldKeyProvider {
            typealias FieldKey = FieldKeys
            
            enum FieldKeys : String {
                case float
                case id
            }
            
            struct FloatArguments : ArgumentType {
                let float: Float
            }
            
            func float(context: NoContext, arguments: FloatArguments) -> Float {
                return arguments.float
            }
            
            struct DateArguments : ArgumentType {
                let id: ID
            }
            
            func id(context: NoContext, arguments: DateArguments) -> ID {
                return arguments.id
            }
        }

        let schema = Schema<ScalarRoot, NoContext> {
            Scalar(Float.self)
            .description("The `Float` scalar type represents signed double-precision fractional values as specified by [IEEE 754](http://en.wikipedia.org/wiki/IEEE_floating_point).")
            
            Scalar(ID.self)

            Query {
                Field(.float, at: ScalarRoot.float)
                Field(.id, at: ScalarRoot.id)
            }
        }

        var query: String
        var expected = GraphQLResult(data: ["float": 4.0])
        var result: GraphQLResult

        query = "query Query($float: Float!) { float(float: $float) }"
        
        result = try schema.execute(
            request: query,
            root: ScalarRoot(),
            context: NoContext(),
            eventLoopGroup: eventLoopGroup,
            variables: ["float": 4]
        ).wait()

        XCTAssertEqual(result, expected)

        query = "query Query { float(float: 4) }"
        
        result = try schema.execute(
            request: query,
            root: ScalarRoot(),
            context: NoContext(),
            eventLoopGroup: eventLoopGroup
        ).wait()
        
        XCTAssertEqual(result, expected)
        
        query = "query Query($id: String!) { id(id: $id) }"
        expected = GraphQLResult(data: ["id": "85b8d502-8190-40ab-b18f-88edd297d8b6"])
        
        result = try schema.execute(
            request: query,
            root: ScalarRoot(),
            context: NoContext(),
            eventLoopGroup: eventLoopGroup,
            variables: ["id": "85b8d502-8190-40ab-b18f-88edd297d8b6"]
        ).wait()
        
        XCTAssertEqual(result, expected)
        
        query = #"query Query { id(id: "85b8d502-8190-40ab-b18f-88edd297d8b6") }"#
        
        result = try schema.execute(
            request: query,
            root: ScalarRoot(),
            context: NoContext(),
            eventLoopGroup: eventLoopGroup
        ).wait()
        
        XCTAssertEqual(result, expected)
    }

    func testInput() throws {
        let group = MultiThreadedEventLoopGroup(numberOfThreads: 1)
        
        defer {
            XCTAssertNoThrow(try group.syncShutdownGracefully())
        }

        struct Foo : OutputType, FieldKeyProvider {
            typealias FieldKey = FieldKeys
            
            enum FieldKeys : String {
                case id
                case name
            }
            
            let id: String
            let name: String?

            static func fromInput(_ input: FooInput) -> Foo {
                return Foo(id: input.id, name: input.name)
            }
        }

        struct FooInput : InputType, OutputType, FieldKeyProvider {
            typealias FieldKey = FieldKeys
            
            enum FieldKeys : String {
                case id
                case name
            }
            
            let id: String
            let name: String?
        }
        
        struct FooRoot : FieldKeyProvider {
            typealias FieldKey = FieldKeys
            
            enum FieldKeys : String {
                case foo
                case addFoo
            }
            
            func foo(context: NoContext, arguments: NoArguments) -> Foo {
                return Foo(id: "123", name: "bar")
            }
            
            struct AddFooArguments : ArgumentType {
                let input: FooInput
            }
            
            func addFoo(context: NoContext, arguments: AddFooArguments) -> Foo {
                return Foo.fromInput(arguments.input)
            }
        }

        let schema = Schema<FooRoot, NoContext> {
            Type(Foo.self) {
                Field(.id, at: \.id)
                Field(.name, at: \.name)
            }

            Query {
                Field(.foo, at: FooRoot.foo)
            }

            Input(FooInput.self) {
                InputField(.id, at: \.id)
                InputField(.name, at: \.name)
            }
            
            Mutation {
                Field(.addFoo, at: FooRoot.addFoo)
            }
        }

        let mutation = "mutation addFoo($input: FooInput!) { addFoo(input:$input) { id, name } }"
        let variables: [String: Map] = ["input" : [ "id" : "123", "name" : "bob" ]]
        
        let expected = GraphQLResult(
            data: ["addFoo" : [ "id" : "123", "name" : "bob" ]]
        )
        
        do {
            let result = try schema.execute(
                request: mutation,
                root: FooRoot(),
                context: NoContext(),
                eventLoopGroup: group,
                variables: variables
            ).wait()
            
            XCTAssertEqual(result, expected)
            debugPrint(result)
        } catch {
            debugPrint(error)
        }
    }
}

extension HelloWorldTests {
    static var allTests: [(String, (HelloWorldTests) -> () throws -> Void)] {
        return [
            ("testHello", testHello),
            ("testBoyhowdy", testBoyhowdy),
        ]
    }
}
