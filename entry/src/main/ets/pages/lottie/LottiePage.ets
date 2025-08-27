import { JinRefreshView } from "./components/JinRefreshView"

@Component
export struct LottiePage {

  build() {
    NavDestination() {
      Column() {
        JinRefreshView()
      }
    }
  }
}