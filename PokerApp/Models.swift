
import Foundation

struct Card {
    let suit: String
    let rank: String
}

struct Player {
    let name: String
    var hand: [Card]
    var chips: Int
}
