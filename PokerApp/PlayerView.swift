
import SwiftUI

struct PlayerView: View {
    @ObservedObject var player: Player
    
    var body: some View {
        VStack {
            PlayerInfoView(player: player, isUser: player.isUser)
            if player.currentBet > 0 {
                Text("Bet: $\(player.currentBet)")
                    .foregroundColor(.white)
            }
        }
    }
}

struct PlayerView_Previews: PreviewProvider {
    static var previews: some View {
        PlayerView(player: Player(name: "Test Player", hand: [Card(suit: "hearts", rank: "ace"), Card(suit: "diamonds", rank: "king")], chips: 1000, isUser: true))
            .previewLayout(.sizeThatFits)
            .background(Color.green)
    }
}
