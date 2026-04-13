import WidgetKit
import SwiftUI

@main
struct SaraBabyWidgetBundle: WidgetBundle {
    var body: some Widget {
        SleepWidget()
        BreastfeedWidget()
        PumpWidget()
    }
}
