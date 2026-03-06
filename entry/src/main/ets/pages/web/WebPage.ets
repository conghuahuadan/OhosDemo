import { StatusBar } from "../../components/StatusBar";
import { webview } from "@kit.ArkWeb";

@Component
export struct WebPage {
  controller: webview.WebviewController = new webview.WebviewController();

  build() {
    NavDestination() {
      Column() {
        StatusBar()
        Web({
          src: 'https://www.jin10.com/',
          controller: this.controller
        })
          .width('100%')
          .height('100%')
          .layoutWeight(1)
      }
      .width('100%')
      .height('100%')
    }
    .hideTitleBar(true)
  }
}