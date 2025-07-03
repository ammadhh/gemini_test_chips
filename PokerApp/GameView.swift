
import SwiftUI

struct GameView: View {
    @StateObject private var viewModel = GameViewModel()
    
    var body: some View {
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
            
            // Action buttons
            HStack {
                Button("Fold") { }
                Button("Check") { }
                Button("Bet") { }
                Button("Raise") { }
            }
            .padding()
        }
    }
}

struct GameView_Previews: PreviewProvider {
    static var previews: some View {
        GameView()
    }
}
