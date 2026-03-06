import { FlashQuickEntranceLayout, SwiperSubView } from "./components/FlashQuickEntranceLayout"
import { FlashQuickEntranceIndicator } from "./components/FlashQuickEntrnaceIndicator";
import { hilog } from "@kit.PerformanceAnalysisKit";
import { StatusBar } from "../../components/StatusBar";
import { ProjectUtil } from "../../utils/ProjectUtil";

@Component
export struct SwiperPage {
  @State flashIndex: number = 0;

  aboutToAppear(): void {
  }

  build() {
    NavDestination() {
      Column() {
        StatusBar()
        FlashQuickEntranceLayout({
          onIndexChangedCall: (index) => {
            this.flashIndex = index;
            hilog.info(0, "FlashQuickEntranceLayout", `${this.flashIndex}`)
          }
        })
        FlashQuickEntranceIndicator({
          index: this.flashIndex
        });
        Stack().width('100%').height(100).backgroundColor(Color.Brown)
      }
    }
    .hideTitleBar(true)
  }
}