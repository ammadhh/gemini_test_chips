
import SwiftUI

struct GameView: View {
    var body: some View {
        VStack {
            Text("Poker Table")
                .font(.largeTitle)
                .padding()
            
            Spacer()
            
            // Player and AI hands
            HStack {
                Text("Player Hand")
                Spacer()
                Text("AI Hand")
            }
            .padding()
            
            Spacer()
            
            // Pot and chip counts
            HStack {
                Text("Pot: $100")
                Spacer()
                Text("Your Chips: $1000")
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
