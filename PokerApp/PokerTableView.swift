
import SwiftUI

struct PokerTableView: View {
    @EnvironmentObject var gameViewModel: GameViewModel
    @State private var userName: String = ""
    @State private var showingNameInput: Bool = true
    @State private var betAmount: Double = 0.0

    var body: some View {
        ZStack {
            // Background (e.g., green felt)
            Color.green.edgesIgnoringSafeArea(.all)

            VStack {
                // AI Players (Top)
                HStack {
                    Spacer()
                    PlayerView(player: gameViewModel.players[1])
                        .border(gameViewModel.players[1].id == gameViewModel.currentPlayer.id ? Color.yellow : Color.clear, width: 3)
                    Spacer()
                    PlayerView(player: gameViewModel.players[2])
                        .border(gameViewModel.players[2].id == gameViewModel.currentPlayer.id ? Color.yellow : Color.clear, width: 3)
                    Spacer()
                }

                Spacer()

                // Community Cards and Pot
                VStack {
                    HStack {
                        ForEach(gameViewModel.communityCards) { card in
                            CardView(card: card, isFaceUp: true)
                        }
                    }
                    .padding(.bottom)

                    Text("Pot: $\(gameViewModel.pot)")
                        .font(.title)
                        .foregroundColor(.white)
                        .padding()
                        .background(Capsule().fill(Color.black.opacity(0.5)))
                        .animation(.easeInOut(duration: 0.5), value: gameViewModel.pot)

                    Text(gameViewModel.lastAction)
                        .font(.subheadline)
                        .foregroundColor(.yellow)
                        .padding(.top, 5)
                }

                Spacer()

                // User Player (Bottom Center)
                PlayerView(player: gameViewModel.players[0])
                    .border(gameViewModel.players[0].id == gameViewModel.currentPlayer.id ? Color.yellow : Color.clear, width: 3)

                // Action Buttons
                VStack {
                    Slider(value: $betAmount, in: Double(gameViewModel.currentBet)...Double(gameViewModel.players[0].chips), step: 10) {
                        Text("Bet Amount")
                    } minimumValueLabel: {
                        Text("$\(gameViewModel.currentBet)")
                    } maximumValueLabel: {
                        Text("$\(gameViewModel.players[0].chips)")
                    }
                    .padding(.horizontal)

                    Text("Your Bet: $\(Int(betAmount))")
                        .foregroundColor(.white)

                    HStack {
                        Button("Fold") {
                            gameViewModel.fold()
                        }
                        .buttonStyle(ActionButtonStyle())
                        .disabled(gameViewModel.players[0].id != gameViewModel.currentPlayer.id || gameViewModel.gameState == .gameOver)

                        Button("Check") {
                            gameViewModel.check()
                        }
                        .buttonStyle(ActionButtonStyle())
                        .disabled(gameViewModel.players[0].id != gameViewModel.currentPlayer.id || gameViewModel.currentBet > gameViewModel.players[0].currentBet || gameViewModel.gameState == .gameOver)

                        Button("Call") {
                            gameViewModel.bet(amount: gameViewModel.currentBet)
                        }
                        .buttonStyle(ActionButtonStyle())
                        .disabled(gameViewModel.players[0].id != gameViewModel.currentPlayer.id || gameViewModel.currentBet == gameViewModel.players[0].currentBet || gameViewModel.gameState == .gameOver)

                        Button("Bet") {
                            gameViewModel.bet(amount: Int(betAmount))
                        }
                        .buttonStyle(ActionButtonStyle())
                        .disabled(gameViewModel.players[0].id != gameViewModel.currentPlayer.id || gameViewModel.currentBet > gameViewModel.players[0].currentBet || gameViewModel.gameState == .gameOver)

                        Button("Raise") {
                            gameViewModel.raise(amount: Int(betAmount))
                        }
                        .buttonStyle(ActionButtonStyle())
                        .disabled(gameViewModel.players[0].id != gameViewModel.currentPlayer.id || Int(betAmount) <= gameViewModel.currentBet || gameViewModel.gameState == .gameOver)
                    }
                    .padding()
            }

            if showingNameInput {
                Color.black.opacity(0.7).edgesIgnoringSafeArea(.all)
                VStack {
                    TextField("Enter your name", text: $userName)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .padding()
                        .background(Color.white)
                        .cornerRadius(10)
                    Button("Start Game") {
                        gameViewModel.setUserName(name: userName)
                        showingNameInput = false
                    }
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }
                .padding(50)
            } else if gameViewModel.gameState == .gameOver {
                Color.black.opacity(0.7).edgesIgnoringSafeArea(.all)
                VStack {
                    Text("Game Over!")
                        .font(.largeTitle)
                        .foregroundColor(.white)
                        .padding()
                    Text(gameViewModel.lastAction)
                        .font(.title2)
                        .foregroundColor(.red)
                        .padding()
                    Button("Play Again") {
                        gameViewModel.resetGame()
                    }
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }
                .padding(50)
            }
        }
        .onAppear {
            gameViewModel.setupNewRound()
        }
    }
}

struct ActionButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding()
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(10)
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
    }
}

struct PokerTableView_Previews: PreviewProvider {
    static var previews: some View {
        PokerTableView()
            .environmentObject(GameViewModel(statsViewModel: StatsViewModel()))
    }
}
