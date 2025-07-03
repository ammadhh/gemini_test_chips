
import Foundation

class GameViewModel: ObservableObject {
    @Published var players: [Player]
    @Published var pot: Int
    @Published var currentBet: Int
    public var statsViewModel: StatsViewModel
    
    init(statsViewModel: StatsViewModel) {
        self.players = [
            Player(name: "Player 1", hand: [], chips: 1000),
            Player(name: "AI 1", hand: [], chips: 1000),
            Player(name: "AI 2", hand: [], chips: 1000)
        ]
        self.pot = 0
        self.currentBet = 0
        self.statsViewModel = statsViewModel
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
    
    func fold() {
        // For now, just end the round and give the pot to the first AI
        statsViewModel.logLoss()
        pot = 0
        players[1].chips += pot
        dealInitialHands()
    }
    
    func check() {
        // For now, just advance to the next player
    }
    
    func bet(amount: Int) {
        players[0].chips -= amount
        pot += amount
        currentBet = amount
    }
    
    func raise(amount: Int) {
        let raiseAmount = amount - currentBet
        players[0].chips -= raiseAmount
        pot += raiseAmount
        currentBet = amount
    }
}
