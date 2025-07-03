
import SwiftUI

struct StatsView: View {
    @EnvironmentObject var viewModel: StatsViewModel
    
    var body: some View {
        VStack {
            Text("Player Stats")
                .font(.largeTitle)
                .padding()
            
            List {
                Text("Hands Played: \(viewModel.handsPlayed)")
                Text(String(format: "Win/Loss Ratio: %.2f%%", viewModel.winLossRatio))
                Text("Average Pot Won: $\(viewModel.averagePotWon)")
            }
        }
    }
}

struct StatsView_Previews: PreviewProvider {
    static var previews: some View {
        StatsView().environmentObject(StatsViewModel())
    }
}
