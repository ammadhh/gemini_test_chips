
import Foundation

class GameViewModel: ObservableObject {
    @Published var players: [Player]
    @Published var pot: Int
    @Published var currentBet: Int
    @Published var communityCards: [Card]
    public var statsViewModel: StatsViewModel
    
    private var deck: [Card] = []
    
    init(statsViewModel: StatsViewModel) {
        self.players = [
            Player(name: "Player 1", hand: [], chips: 1000, isUser: true),
            Player(name: "AI 1", hand: [], chips: 1000),
            Player(name: "AI 2", hand: [], chips: 1000)
        ]
        self.pot = 0
        self.currentBet = 0
        self.communityCards = []
        self.statsViewModel = statsViewModel
        setupNewRound()
    }
    
    func setupNewRound() {
        deck = createDeck()
        deck.shuffle()
        
        for i in 0..<players.count {
            players[i].hand = []
            players[i].isFolded = false
            players[i].currentBet = 0
        }
        communityCards = []
        pot = 0
        currentBet = 0
        dealInitialHands()
    }
    
    func createDeck() -> [Card] {
        let suits = ["hearts", "diamonds", "clubs", "spades"]
        let ranks = ["2", "3", "4", "5", "6", "7", "8", "9", "10", "jack", "queen", "king", "ace"]
        var newDeck: [Card] = []
        for suit in suits {
            for rank in ranks {
                newDeck.append(Card(suit: suit, rank: rank))
            }
        }
        return newDeck
    }
    
    func dealInitialHands() {
        for _ in 0..<2 { // Deal two cards to each player
            for i in 0..<players.count {
                if let card = deck.popLast() {
                    players[i].hand.append(card)
                }
            }
        }
    }
    
    func setUserName(name: String) {
        if let index = players.firstIndex(where: { $0.isUser }) {
            players[index].name = name
        }
    }
    
    func fold() {
        if let index = players.firstIndex(where: { $0.isUser }) {
            players[index].isFolded = true
            statsViewModel.logLoss()
            // For now, just end the round and give the pot to the first AI
            pot = 0
            players[1].chips += pot
            setupNewRound()
        }
    }
    
    func check() {
        // For now, just advance to the next player
    }
    
    func bet(amount: Int) {
        if let index = players.firstIndex(where: { $0.isUser }) {
            players[index].chips -= amount
            pot += amount
            currentBet = amount
        }
    }
    
    func raise(amount: Int) {
        if let index = players.firstIndex(where: { $0.isUser }) {
            let raiseAmount = amount - currentBet
            players[index].chips -= raiseAmount
            pot += raiseAmount
            currentBet = amount
        }
    }
    
    func dealFlop() {
        // Burn a card
        _ = deck.popLast()
        for _ in 0..<3 {
            if let card = deck.popLast() {
                communityCards.append(card)
            }
        }
    }
    
    func dealTurn() {
        // Burn a card
        _ = deck.popLast()
        if let card = deck.popLast() {
            communityCards.append(card)
        }
    }
    
    func dealRiver() {
        // Burn a card
        _ = deck.popLast()
        if let card = deck.popLast() {
            communityCards.append(card)
        }
    }
}
