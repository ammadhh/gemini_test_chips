
import SwiftUI

struct GameView: View {
    @StateObject private var viewModel: GameViewModel
    @StateObject private var statsViewModel = StatsViewModel()
    @State private var betAmount: Double = 10.0
    
    init() {
        _viewModel = StateObject(wrappedValue: GameViewModel(statsViewModel: statsViewModel))
    }
    
    var body: some View {
        NavigationView {
            VStack {
                Text("Poker Table")
                    .font(.largeTitle)
                    .padding()
                
                Spacer()
                
                // Player and AI hands
                HStack {
                    VStack {
                        Text(viewModel.players[0].name)
                        Text("\(viewModel.players[0].hand[0].rank)\(viewModel.players[0].hand[0].suit) \(viewModel.players[0].hand[1].rank)\(viewModel.players[0].hand[1].suit)")
                    }
                    Spacer()
                    VStack {
                        Text(viewModel.players[1].name)
                        Text("??")
                    }
                    Spacer()
                    VStack {
                        Text(viewModel.players[2].name)
                        Text("??")
                    }
                }
                .padding()
                
                Spacer()
                
                // Pot and chip counts
                HStack {
                    Text("Pot: $\(viewModel.pot)")
                    Spacer()
                    Text("Your Chips: $\(viewModel.players[0].chips)")
                }
                .padding()
                
                // Bet slider
                Slider(value: $betAmount, in: 10...Double(viewModel.players[0].chips), step: 10)
                Text("Bet: $\(Int(betAmount))")
                
                // Action buttons
                HStack {
                    Button("Fold") { viewModel.fold() }
                    Button("Check") { viewModel.check() }
                    Button("Bet") { viewModel.bet(amount: Int(betAmount)) }
                    Button("Raise") { viewModel.raise(amount: Int(betAmount)) }
                }
                .padding()
                
                NavigationLink(destination: StatsView().environmentObject(statsViewModel)) {
                    Text("View Stats")
                }
            }
        }
    }
}

struct GameView_Previews: PreviewProvider {
    static var previews: some View {
        GameView()
    }
}
