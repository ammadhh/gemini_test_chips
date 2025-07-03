
import Foundation

struct Card: Identifiable {
    let id = UUID()
    let suit: String
    let rank: String
    var isFaceUp: Bool = false

    var imageName: String {
        return "\(rank)_of_\(suit)"
    }
}

struct Player: Identifiable {
    let id = UUID()
    let name: String
    var hand: [Card]
    var chips: Int
    var isFolded: Bool = false
    var currentBet: Int = 0
    var isUser: Bool = false
}
