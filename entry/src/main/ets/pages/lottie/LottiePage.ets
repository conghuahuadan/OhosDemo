import { StatusBar } from "../../components/StatusBar"
import { JinRefreshView } from "./components/JinRefreshView"

@Component
export struct LottiePage {

  build() {
    NavDestination() {
      Column() {
        StatusBar()
        JinRefreshView()
      }
    }
    .hideTitleBar(true)
  }
}