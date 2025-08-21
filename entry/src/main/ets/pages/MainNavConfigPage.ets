import { ImageViewerPage, ImageViewerTestPage } from "imageviewer";
import { JinNavUtil, JinPage } from "./Jin10Navigation";
import { MainPage } from "./MainPage";

@Entry
@Component
export struct MainNavConfigPage {
  @Provide("Jin10Navigation") pageInfos: NavPathStack = new NavPathStack();

  build() {
    Navigation(this.pageInfos) {
      Column() {

      }
    }
    .onAppear(() => {
      JinNavUtil.pageInfos = this.pageInfos;
      this.pageInfos.pushPathByName(JinPage.main, null, false);
    })
    .titleMode(NavigationTitleMode.Full)
    .hideTitleBar(false)
    .hideToolBar(false)
    .mode(NavigationMode.Stack)
    .navDestination(this.PageMap)
  }

  @Builder
  PageMap(name: string, params?: Record<string, Object>) {
    if (name === JinPage.main) {
      MainPage()
    } else if (name == JinPage.imageViewerTestPage) {
      ImageViewerTestPage()
    } else if (name == JinPage.imageViewerPage) {
      ImageViewerPage({ params: params })
    }
  }
}