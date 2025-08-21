import { LengthMetrics } from "@kit.ArkUI"
import { JinNav, JinNavUtil, JinPage } from "./Jin10Navigation"

@Component
export struct MainPage {
  build() {
    NavDestination() {
      Column() {
        Stack() {
        }.height(44 + 24)
        Flex({ wrap: FlexWrap.Wrap, space: { main: LengthMetrics.vp(12), cross: LengthMetrics.vp(12) } }) {
          Button("大图")
            .onClick((e) => {
              JinNavUtil.pushPathByName(JinPage.imageViewerTestPage, null)
            })
        }
      }
    }
    .padding({ left: 16, right: 16, })
    .hideTitleBar(true)
  }
}