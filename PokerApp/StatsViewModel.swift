
import Foundation

class StatsViewModel: ObservableObject {
    @Published var handsPlayed: Int = 0
    @Published var gamesWon: Int = 0
    @Published var totalWinnings: Int = 0
    
    var winLossRatio: Double {
        return handsPlayed > 0 ? (Double(gamesWon) / Double(handsPlayed)) * 100 : 0
    }
    
    var averagePotWon: Int {
        return gamesWon > 0 ? totalWinnings / gamesWon : 0
    }
    
    func logWin(amount: Int) {
        gamesWon += 1
        totalWinnings += amount
        handsPlayed += 1
    }
    
    func logLoss() {
        handsPlayed += 1
    }
}
