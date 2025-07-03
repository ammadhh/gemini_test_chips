
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
    @Published var currentRoundBettingComplete: Bool = false
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
        var activePlayersInRound = players.filter { !$0.isFolded }

        if activePlayersInRound.isEmpty {
            determineWinner()
            return
        }

        var playersToAct = activePlayersInRound.filter { $0.currentBet < currentBet || $0.currentBet == 0 }

        if playersToAct.isEmpty { // All active players have matched the current bet or are all-in
            advanceRound()
            return
        }

        // Find the next player to act
        var nextPlayerIndex = (currentPlayerIndex + 1) % players.count
        while players[nextPlayerIndex].isFolded || players[nextPlayerIndex].chips == 0 || players[nextPlayerIndex].currentBet == currentBet {
            nextPlayerIndex = (nextPlayerIndex + 1) % players.count
            if nextPlayerIndex == currentPlayerIndex { // Looped through all players, and no one needs to act
                advanceRound()
                return
            }
        }
        currentPlayerIndex = nextPlayerIndex

        if players[currentPlayerIndex].isUser {
            // User's turn, wait for action
            return
        } else {
            // AI's turn, perform action immediately
            performAIAction()
        }
    }

    func resetBets() {
        for i in 0..<players.count {
            players[i].currentBet = 0
        }
        currentBet = 0
    }

    func advanceRound() {
        resetBets()
        switch gameState {
        case .preFlop:
            dealFlop()
            gameState = .flop
        case .flop:
            dealTurn()
            gameState = .turn
        case .turn:
            dealRiver()
            gameState = .river
        case .river:
            determineWinner()
            gameState = .showdown
        default:
            break
        }
        currentPlayerIndex = 0 // Reset turn to the first active player
    }

    func determineWinner() {
        // Mock winner for now
        let activePlayers = players.filter { !$0.isFolded }
        if let winningPlayer = activePlayers.randomElement() {
            lastAction = "\(winningPlayer.name) wins $\(pot)!""
            if let index = players.firstIndex(where: { $0.id == winningPlayer.id }) {
                players[index].chips += pot
                if players[index].isUser {
                    statsViewModel.logWin(amount: pot)
                } else {
                    statsViewModel.logLoss() // User loses if AI wins
                }
            }
        } else {
            lastAction = "No winner, pot returned."
        }
        pot = 0

        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            self.setupNewRound()
        }
    }
    
    func performAIAction() {
        let aiPlayer = players[currentPlayerIndex]
        let callAmount = currentBet - aiPlayer.currentBet

        // Simple AI logic
        if currentBet == 0 { // No bet yet, AI can check or bet
            if Int.random(in: 0...1) == 0 { // 50% chance to check
                lastAction = "\(aiPlayer.name) checks"
            } else { // 50% chance to bet
                let betAmount = min(aiPlayer.chips, 50) // Bet 50 or all-in
                players[currentPlayerIndex].chips -= betAmount
                pot += betAmount
                players[currentPlayerIndex].currentBet = betAmount
                currentBet = betAmount
                lastAction = "\(aiPlayer.name) bets $\(betAmount)"
            }
        } else { // There's a bet, AI can call, fold, or raise
            let randomAction = Int.random(in: 1...10)
            if randomAction <= 5 { // Call
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
                let raiseAmount = currentBet + min(50, aiPlayer.chips - callAmount) // Raise by 50 or all-in
                if aiPlayer.chips >= raiseAmount {
                    players[currentPlayerIndex].chips -= raiseAmount
                    pot += raiseAmount
                    currentBet = raiseAmount
                    players[currentPlayerIndex].currentBet = raiseAmount
                    lastAction = "\(aiPlayer.name) raises to $\(raiseAmount)"
                } else { // Not enough chips to raise, so call or fold
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
        }
        nextTurn()
    }

    func determineWinner() {
        let activePlayers = players.filter { !$0.isFolded }
        if activePlayers.count == 1 {
            let winningPlayer = activePlayers[0]
            lastAction = "\(winningPlayer.name) wins $\(pot)!"
            if let index = players.firstIndex(where: { $0.id == winningPlayer.id }) {
                players[index].chips += pot
                if players[index].isUser {
                    statsViewModel.logWin(amount: pot)
                } else {
                    statsViewModel.logLoss() // User loses if AI wins
                }
            }
        } else if let winningPlayer = activePlayers.randomElement() { // Mock winner for now
            lastAction = "\(winningPlayer.name) wins $\(pot)!"
            if let index = players.firstIndex(where: { $0.id == winningPlayer.id }) {
                players[index].chips += pot
                if players[index].isUser {
                    statsViewModel.logWin(amount: pot)
                } else {
                    statsViewModel.logLoss() // User loses if AI wins
                }
            }
        } else {
            lastAction = "No winner, pot returned."
        }
        pot = 0

        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            self.setupNewRound()
        }
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
