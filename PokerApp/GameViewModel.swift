
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
    @Published var currentActorIndex: Int = 0
    @Published var lastAction: String = ""
    @Published var currentBettingRound: BettingRound = .preFlop
    @Published var chipAnimationTrigger: Bool = false
    public var statsViewModel: StatsViewModel

    enum BettingRound {
        case preFlop
        case flop
        case turn
        case river
        case showdown
    }
    
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
        return players[currentActorIndex]
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
        currentActorIndex = 0 // User starts
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
                    DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * 0.1) {
                        var newCard = card
                        if self.players[i].isUser {
                            newCard.isFaceUp = true
                        } else {
                            newCard.isFaceUp = false
                        }
                        self.players[i].hand.append(newCard)
                    }
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
            chipAnimationTrigger.toggle()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.nextTurn()
            }
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
            chipAnimationTrigger.toggle()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.nextTurn()
            }
        }
    }
    
    func nextTurn() {
        var activePlayersInRound = players.filter { !$0.isFolded }

        if activePlayersInRound.isEmpty {
            determineWinner()
            return
        }

        var playersToAct = activePlayersInRound.filter { $0.currentBet < currentBet || ($0.currentBet == currentBet && currentBet == 0) }

        if playersToAct.isEmpty { // All active players have matched the current bet or are all-in
            advanceRound()
            return
        }

        // Find the next player to act
        var nextPlayerIndex = (currentActorIndex + 1) % players.count
        var loopCount = 0
        while (players[nextPlayerIndex].isFolded || players[nextPlayerIndex].chips == 0 || players[nextPlayerIndex].currentBet == currentBet) && loopCount < players.count * 2 {
            nextPlayerIndex = (nextPlayerIndex + 1) % players.count
            loopCount += 1
        }

        if loopCount >= players.count * 2 { // Looped through all players, and no one needs to act
            advanceRound()
            return
        }
        
        currentActorIndex = nextPlayerIndex

        if players[currentActorIndex].isUser {
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
        switch currentBettingRound {
        case .preFlop:
            dealCommunityCards(count: 3) // Flop
            currentBettingRound = .flop
        case .flop:
            dealCommunityCards(count: 1) // Turn
            currentBettingRound = .turn
        case .turn:
            dealCommunityCards(count: 1) // River
            currentBettingRound = .river
        case .river:
            determineWinner()
            currentBettingRound = .showdown
        case .showdown:
            // This case should ideally lead to a new round setup after winner is determined
            break
        }
        currentActorIndex = 0 // Reset turn to the first active player
        // Trigger AI action if it's an AI's turn after advancing round
        if !players[currentActorIndex].isUser && !players[currentActorIndex].isFolded {
            performAIAction()
        }
    }

    func dealCommunityCards(count: Int) {
        _ = deck.popLast() // Burn a card
        for i in 0..<count {
            if let card = deck.popLast() {
                DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * 0.2) {
                    var newCard = card
                    newCard.isFaceUp = true
                    self.communityCards.append(newCard)
                }
            }
        }
    }

    func nextTurn() {
        var activePlayersInRound = players.filter { !$0.isFolded && $0.chips > 0 }

        if activePlayersInRound.isEmpty {
            determineWinner()
            return
        }

        var playersToAct = activePlayersInRound.filter { $0.currentBet < currentBet || ($0.currentBet == currentBet && currentBet == 0) }

        if playersToAct.isEmpty { // All active players have matched the current bet or are all-in
            advanceRound()
            return
        }

        // Find the next player to act
        var nextPlayerIndex = (currentActorIndex + 1) % players.count
        var loopCount = 0
        while (players[nextPlayerIndex].isFolded || players[nextPlayerIndex].chips == 0 || players[nextPlayerIndex].currentBet == currentBet) && loopCount < players.count * 2 {
            nextPlayerIndex = (nextPlayerIndex + 1) % players.count
            loopCount += 1
        }

        if loopCount >= players.count * 2 { // Looped through all players, and no one needs to act
            advanceRound()
            return
        }
        
        currentActorIndex = nextPlayerIndex

        if players[currentActorIndex].isUser {
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
        switch currentBettingRound {
        case .preFlop:
            dealCommunityCards(count: 3) // Flop
            currentBettingRound = .flop
        case .flop:
            dealCommunityCards(count: 1) // Turn
            currentBettingRound = .turn
        case .turn:
            dealCommunityCards(count: 1) // River
            currentBettingRound = .river
        case .river:
            determineWinner()
            currentBettingRound = .showdown
        case .showdown:
            // This case should ideally lead to a new round setup after winner is determined
            break
        }
        currentActorIndex = 0 // Reset turn to the first active player
        // Trigger AI action if it's an AI's turn after advancing round
        if !players[currentActorIndex].isUser && !players[currentActorIndex].isFolded {
            performAIAction()
        }
    }

    func dealCommunityCards(count: Int) {
        _ = deck.popLast() // Burn a card
        for i in 0..<count {
            if let card = deck.popLast() {
                DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * 0.2) {
                    var newCard = card
                    newCard.isFaceUp = true
                    self.communityCards.append(newCard)
                }
            }
        }
    }

    func determineWinner() {
        // A more realistic (but still simplified) winner determination
        let activePlayers = players.filter { !$0.isFolded && $0.chips > 0 }

        if activePlayers.count == 1 {
            let winningPlayer = activePlayers[0]
            lastAction = "\(winningPlayer.name) wins $\(pot)!""
            if let index = players.firstIndex(where: { $0.id == winningPlayer.id }) {
                players[index].chips += pot
                if players[index].isUser {
                    statsViewModel.logWin(amount: pot)
                } else {
                    statsViewModel.logLoss() // User loses if AI wins
                }
            }
        } else { // Multiple players, determine winner based on hand strength (mocked)
            // In a real game, you'd evaluate poker hands here.
            // For now, let's just pick a random active player as the winner.
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
        }
        pot = 0

        // Check for game over condition
        if players.first(where: { $0.isUser })?.chips == 0 {
            gameState = .gameOver
            lastAction = "Game Over! You ran out of chips."
        } else {
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                self.setupNewRound()
            }
        }
    }

    func resetGame() {
        players = [
            Player(name: "Player", hand: [], chips: 1000, isUser: true)
        ]
        for i in 1...2 {
            players.append(Player(name: "AI Player \(i)", hand: [], chips: 1000))
        }
        setupNewRound()
    }
    
    func performAIAction() {
        let aiPlayer = players[currentActorIndex]
        let callAmount = currentBet - aiPlayer.currentBet

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            guard let self = self else { return }
            // Simple AI logic
            if self.currentBet == 0 { // No bet yet, AI can check or bet
                if Int.random(in: 0...1) == 0 { // 50% chance to check
                    self.lastAction = "\(aiPlayer.name) checks"
                } else { // 50% chance to bet
                    let betAmount = min(aiPlayer.chips, 50) // Bet 50 or all-in
                    self.players[self.currentActorIndex].chips -= betAmount
                    self.pot += betAmount
                    self.players[self.currentActorIndex].currentBet = betAmount
                    self.currentBet = betAmount
                    self.lastAction = "\(aiPlayer.name) bets $\(betAmount)"
                    self.chipAnimationTrigger.toggle()
                }
            } else { // There's a bet, AI can call, fold, or raise
                let randomAction = Int.random(in: 1...10)
                if randomAction <= 5 { // Call
                    if aiPlayer.chips >= callAmount {
                        self.players[self.currentActorIndex].chips -= callAmount
                        self.pot += callAmount
                        self.players[self.currentActorIndex].currentBet = self.currentBet
                        self.lastAction = "\(aiPlayer.name) calls"
                        self.chipAnimationTrigger.toggle()
                    } else { // Not enough chips to call, so fold
                        self.players[self.currentActorIndex].isFolded = true
                        self.lastAction = "\(aiPlayer.name) folds (not enough chips to call)"
                    }
                } else if randomAction <= 8 { // Fold
                    self.players[self.currentActorIndex].isFolded = true
                    self.lastAction = "\(aiPlayer.name) folds"
                } else { // Raise
                    let raiseAmount = self.currentBet + min(50, aiPlayer.chips - callAmount) // Raise by 50 or all-in
                    if aiPlayer.chips >= raiseAmount {
                        self.players[self.currentActorIndex].chips -= raiseAmount
                        self.pot += raiseAmount
                        self.currentBet = raiseAmount
                        self.players[self.currentActorIndex].currentBet = raiseAmount
                        self.lastAction = "\(aiPlayer.name) raises to $\(raiseAmount)"
                        self.chipAnimationTrigger.toggle()
                    } else { // Not enough chips to raise, so call or fold
                        if aiPlayer.chips >= callAmount {
                            self.players[self.currentActorIndex].chips -= callAmount
                            self.pot += callAmount
                            self.players[self.currentActorIndex].currentBet = self.currentBet
                            self.lastAction = "\(aiPlayer.name) calls (not enough chips to raise)"
                            self.chipAnimationTrigger.toggle()
                        } else {
                            self.players[self.currentActorIndex].isFolded = true
                            self.lastAction = "\(aiPlayer.name) folds (not enough chips to call or raise)"
                        }
                    }
                }
            }
            self.nextTurn()
        }
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
        currentActorIndex = 0 // Start betting from the first active player
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
