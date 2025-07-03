
import SwiftUI

struct PlayerView: View {
    @ObservedObject var player: Player
    var isUser: Bool
    
    var body: some View {
        VStack {
            Text(player.name)
                .font(.headline)
                .foregroundColor(.white)
            Text("Chips: $\(player.chips)")
                .font(.subheadline)
                .foregroundColor(.white)
            HStack {
                ForEach(player.hand) { card in
                    CardView(card: card, isFaceUp: isUser || player.isFolded)
                }
            }
        }
        .padding(5)
        .background(Color.black.opacity(0.3))
        .cornerRadius(10)
    }
}

struct PlayerView_Previews: PreviewProvider {
    static var previews: some View {
        PlayerView(player: Player(name: "Test Player", hand: [Card(suit: "hearts", rank: "ace"), Card(suit: "diamonds", rank: "king")], chips: 1000, isUser: true), isUser: true)
            .previewLayout(.sizeThatFits)
            .background(Color.green)
    }
}
