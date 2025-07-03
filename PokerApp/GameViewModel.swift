
import Foundation

class GameViewModel: ObservableObject {
    enum GameState {
        case waitingForPlayers
        case preFlop
        case bettingRound
        case flop
        case turn
        case river
        case showdown
        case gameOver
    }

    @Published var players: [Player]
    @Published var pot: Int
    @Published var currentBet: Int
    @Published var communityCards: [Card]
    @Published var gameState: GameState = .waitingForPlayers
    @Published var currentPlayerIndex: Int = 0
    @Published var lastAction: String = ""
    public var statsViewModel: StatsViewModel
    
    private var deck: [Card] = []
    
    init(statsViewModel: StatsViewModel) {
        self.statsViewModel = statsViewModel
        self.players = [
            Player(name: "Player", hand: [], chips: 1000, isUser: true)
        ]
        // Add AI players with random names
        for i in 1...2 {
            self.players.append(Player(name: "AI Player \(i)", hand: [], chips: 1000))
        }
        self.pot = 0
        self.currentBet = 0
        self.communityCards = []
        setupNewRound()
    }

    var currentPlayer: Player {
        return players[currentPlayerIndex]
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
        lastAction = ""
        dealInitialHands()
        gameState = .preFlop
        currentPlayerIndex = 0 // User starts
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
            lastAction = "\(players[index].name) folds"
            nextTurn()
        }
    }
    
    func check() {
        lastAction = "\(currentPlayer.name) checks"
        nextTurn()
    }
    
    func bet(amount: Int) {
        if let index = players.firstIndex(where: { $0.isUser }) {
            let betDifference = amount - players[index].currentBet
            players[index].chips -= betDifference
            pot += betDifference
            players[index].currentBet = amount
            currentBet = amount
            lastAction = "\(players[index].name) bets $\(amount)"
            nextTurn()
        }
    }
    
    func raise(amount: Int) {
        if let index = players.firstIndex(where: { $0.isUser }) {
            let raiseAmount = amount - players[index].currentBet
            players[index].chips -= raiseAmount
            pot += raiseAmount
            players[index].currentBet = amount
            currentBet = amount
            lastAction = "\(players[index].name) raises to $\(amount)"
            nextTurn()
        }
    }
    
    func nextTurn() {
        var playersInRound = players.filter { !$0.isFolded }
        if playersInRound.isEmpty { // All players folded
            // Handle end of hand (e.g., pot goes to last remaining player)
            return
        }

        var originalPlayerIndex = currentPlayerIndex
        repeat {
            currentPlayerIndex = (currentPlayerIndex + 1) % players.count
        } while players[currentPlayerIndex].isFolded

        // Check if a full round of betting is complete
        let allPlayersActed = playersInRound.allSatisfy { player in
            player.currentBet == currentBet || player.isFolded
        }

        if allPlayersActed && currentPlayerIndex == 0 { // All active players have matched the current bet or folded, and it's the user's turn again
            advanceRound()
        } else if players[currentPlayerIndex].isUser == false {
            performAIAction()
        }
    }
    
    func performAIAction() {
        // Simple AI: 50% chance to call, 30% to fold, 20% to raise
        let randomAction = Int.random(in: 1...10)
        let aiPlayer = players[currentPlayerIndex]
        
        if randomAction <= 5 { // Call
            let callAmount = currentBet - aiPlayer.currentBet
            if aiPlayer.chips >= callAmount {
                players[currentPlayerIndex].chips -= callAmount
                pot += callAmount
                players[currentPlayerIndex].currentBet = currentBet
                lastAction = "\(aiPlayer.name) calls"
            } else { // Not enough chips to call, so fold
                players[currentPlayerIndex].isFolded = true
                lastAction = "\(aiPlayer.name) folds (not enough chips to call)"
            }
        } else if randomAction <= 8 { // Fold
            players[currentPlayerIndex].isFolded = true
            lastAction = "\(aiPlayer.name) folds"
        } else { // Raise
            let raiseAmount = currentBet + 50 // AI raises by 50
            if aiPlayer.chips >= raiseAmount {
                players[currentPlayerIndex].chips -= raiseAmount
                pot += raiseAmount
                currentBet = raiseAmount
                players[currentPlayerIndex].currentBet = raiseAmount
                lastAction = "\(aiPlayer.name) raises to $\(raiseAmount)"
            } else { // Not enough chips to raise, so call or fold
                let callAmount = currentBet - aiPlayer.currentBet
                if aiPlayer.chips >= callAmount {
                    players[currentPlayerIndex].chips -= callAmount
                    pot += callAmount
                    players[currentPlayerIndex].currentBet = currentBet
                    lastAction = "\(aiPlayer.name) calls (not enough chips to raise)"
                } else {
                    players[currentPlayerIndex].isFolded = true
                    lastAction = "\(aiPlayer.name) folds (not enough chips to call or raise)"
                }
            }
        }
        nextTurn()
    }
    
    func advanceRound() {
        switch gameState {
        case .preFlop:
            dealFlop()
            gameState = .flop
            break
        case .flop:
            dealTurn()
            gameState = .turn
            break
        case .turn:
            dealRiver()
            gameState = .river
            break
        case .river:
            // Determine winner and distribute pot (mocked for now)
            determineWinner()
            gameState = .showdown
            break
        default:
            break
        }
        // Reset current bets for the new round
        for i in 0..<players.count {
            players[i].currentBet = 0
        }
        currentBet = 0
        currentPlayerIndex = 0 // Start betting from the first active player
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
    
    func determineWinner() {
        // Mock winner for now
        let winningPlayerIndex = Int.random(in: 0..<players.count)
        let winningPlayer = players[winningPlayerIndex]
        
        lastAction = "\(winningPlayer.name) wins $\(pot)!"
        players[winningPlayerIndex].chips += pot
        statsViewModel.logWin(amount: pot)
        pot = 0
        
        // Start a new round after a short delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            self.setupNewRound()
        }
    }
