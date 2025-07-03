
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
                    PlayerView(player: gameViewModel.players[1], isUser: false)
                    Spacer()
                    PlayerView(player: gameViewModel.players[2], isUser: false)
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
                }

                Spacer()

                // User Player (Bottom Center)
                PlayerView(player: gameViewModel.players[0], isUser: true)

                // Action Buttons
                VStack {
                    Slider(value: $betAmount, in: 0...Double(gameViewModel.players[0].chips), step: 10) {
                        Text("Bet Amount")
                    } minimumValueLabel: {
                        Text("$0")
                    } maximumValueLabel: {
                        Text("$\(gameViewModel.players[0].chips)")
                    }
                    .padding(.horizontal)

                    Text("Current Bet: $\(Int(betAmount))")
                        .foregroundColor(.white)

                    HStack {
                        Button("Fold") { gameViewModel.fold() }
                            .buttonStyle(ActionButtonStyle())
                        Button("Check") { gameViewModel.check() }
                            .buttonStyle(ActionButtonStyle())
                        Button("Bet") { gameViewModel.bet(amount: Int(betAmount)) }
                            .buttonStyle(ActionButtonStyle())
                        Button("Raise") { gameViewModel.raise(amount: Int(betAmount)) }
                            .buttonStyle(ActionButtonStyle())
                    }
                    .padding()
                }
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
