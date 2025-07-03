
import Foundation

class GameViewModel: ObservableObject {
    @Published var players: [Player]
    @Published var pot: Int
    
    init() {
        self.players = [
            Player(name: "Player 1", hand: [], chips: 1000),
            Player(name: "AI 1", hand: [], chips: 1000),
            Player(name: "AI 2", hand: [], chips: 1000)
        ]
        self.pot = 0
        dealInitialHands()
    }
    
    func dealInitialHands() {
        for i in 0..<players.count {
            players[i].hand = dealHand()
        }
    }
    
    func dealHand() -> [Card] {
        // For now, just return some dummy cards
        return [
            Card(suit: "♠", rank: "A"),
            Card(suit: "♠", rank: "K")
        ]
    }
}
