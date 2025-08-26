import { FlashQuickEntranceLayout, SwiperSubView } from "./components/FlashQuickEntranceLayout"

@Component
export struct SwiperPage {
  aboutToAppear(): void {
  }

  build() {
    NavDestination() {
      Column() {
        FlashQuickEntranceLayout()
        // SwiperSubView({
        //   len: 8,
        // })
        Stack() {

        }.width('100%').height(100).backgroundColor(Color.Brown)
      }
    }
  }
}