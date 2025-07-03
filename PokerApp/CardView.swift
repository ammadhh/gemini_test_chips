
import SwiftUI

struct CardView: View {
    let card: Card
    var isFaceUp: Bool
    
    @State private var flipped: Bool = false

    var body: some View {
        Image(flipped ? card.imageName : "card_back")
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(width: 50, height: 70)
            .background(Color.white)
            .cornerRadius(5)
            .shadow(radius: 2)
            .rotation3DEffect(Angle.degrees(flipped ? 0 : 180), axis: (x: 0, y: 1, z: 0))
            .onAppear {
                flipped = isFaceUp
            }
            .onChange(of: isFaceUp) { newValue in
                withAnimation(.linear(duration: 0.3)) {
                    flipped = newValue
                }
            }
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
