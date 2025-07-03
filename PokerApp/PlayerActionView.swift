
import SwiftUI

struct PlayerActionView: View {
    let playerName: String
    let action: String
    
    var body: some View {
        VStack {
            Text(playerName)
                .font(.caption)
                .foregroundColor(.white)
            Text(action)
                .font(.caption2)
                .foregroundColor(.yellow)
        }
        .padding(5)
        .background(Color.black.opacity(0.5))
        .cornerRadius(5)
    }
}

struct PlayerActionView_Previews: PreviewProvider {
    static var previews: some View {
        PlayerActionView(playerName: "Player 1", action: "Bets $100")
            .previewLayout(.sizeThatFits)
            .background(Color.green)
    }
}
