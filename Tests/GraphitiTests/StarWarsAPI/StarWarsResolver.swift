import Graphiti

public extension Character {
    var secretBackstory: String? {
        nil
    }

    func getFriends(context _: StarWarsContext, arguments _: NoArguments) -> [Character] {
        []
    }
}

public extension Human {
    func getFriends(context: StarWarsContext, arguments _: NoArguments) -> [Character] {
        context.getFriends(of: self)
    }

    func getSecretBackstory(context: StarWarsContext, arguments _: NoArguments) throws -> String? {
        try context.getSecretBackStory()
    }
}

public extension Droid {
    func getFriends(context: StarWarsContext, arguments _: NoArguments) -> [Character] {
        context.getFriends(of: self)
    }

    func getSecretBackstory(context: StarWarsContext, arguments _: NoArguments) throws -> String? {
        try context.getSecretBackStory()
    }
}

public struct StarWarsResolver {
    public init() {}

    public struct HeroArguments: Codable {
        public let episode: Episode?
    }

    public func hero(context: StarWarsContext, arguments: HeroArguments) -> Character {
        context.getHero(of: arguments.episode)
    }

    public struct HumanArguments: Codable {
        public let id: String
    }

    public func human(context: StarWarsContext, arguments: HumanArguments) -> Human? {
        context.getHuman(id: arguments.id)
    }

    public struct DroidArguments: Codable {
        public let id: String
        public let testInt: Int
        public let testBool: Bool
    }

    public func droid(context: StarWarsContext, arguments: DroidArguments) -> Droid? {
        context.getDroid(id: arguments.id)
    }

    public struct SearchArguments: Codable {
        public let query: String
    }

    public func search(context: StarWarsContext, arguments: SearchArguments) -> [SearchResult] {
        context.search(query: arguments.query)
    }
}
