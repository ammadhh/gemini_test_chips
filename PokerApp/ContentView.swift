
import SwiftUI

struct ContentView: View {
    var body: some View {
        PokerTableView()
            .environmentObject(GameViewModel(statsViewModel: StatsViewModel()))
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
