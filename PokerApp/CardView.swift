
import SwiftUI

struct CardView: View {
    let card: Card
    var isFaceUp: Bool
    
    var body: some View {
        Image(isFaceUp ? card.imageName : "card_back")
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(width: 50, height: 70)
            .background(Color.white)
            .cornerRadius(5)
            .shadow(radius: 2)
    }
}

struct CardView_Previews: PreviewProvider {
    static var previews: some View {
        HStack {
            CardView(card: Card(suit: "hearts", rank: "ace"), isFaceUp: true)
            CardView(card: Card(suit: "spades", rank: "king"), isFaceUp: false)
        }
    }
}
