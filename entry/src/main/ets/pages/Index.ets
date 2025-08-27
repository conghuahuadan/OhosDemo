import { LengthMetrics, router } from '@kit.ArkUI';
import { ImageViewerPage, ImageViewerTestPage } from 'imageviewer';
import { LottiePage } from './lottie/LottiePage';
import { Pages } from './Pages';
import { RefreshPage } from './refresh/RefreshPage';
import { SwiperPage } from './swiper/SwiperPage';

@Entry
@Component
struct Index {
  @Provide("Jin10Navigation") pageInfos: NavPathStack = new NavPathStack();

  aboutToAppear(): void {
  }

  build() {
    Navigation(this.pageInfos) {
      Column() {
        Stack() {
        }.height(44 + 24)

        Flex({ wrap: FlexWrap.Wrap, space: { main: LengthMetrics.vp(12), cross: LengthMetrics.vp(12) } }) {
          Button("大图")
            .onClick((e) => {
              this.pageInfos.pushPathByName(Pages.ImageViewerTestPage, null)
            })
          Button("Swiper")
            .onClick((e) => {
              this.pageInfos.pushPathByName(Pages.SwiperPage, null)
            })
          Button("Lottie")
            .onClick((e) => {
              this.pageInfos.pushPathByName(Pages.LottiePage, null)
            })
          Button("Refresh")
            .onClick((e) => {
              this.pageInfos.pushPathByName(Pages.RefreshPage, null)
            })
        }
      }
      .padding({ left: 16, right: 16, })
    }
    .onAppear(() => {
    })
    .titleMode(NavigationTitleMode.Full)
    .hideTitleBar(false)
    .hideToolBar(false)
    .mode(NavigationMode.Stack)
    .navDestination(this.PageMap)
  }

  @Builder
  PageMap(name: string, params?: Record<string, Object>) {
    if (name == Pages.ImageViewerTestPage) {
      ImageViewerTestPage()
    }  else if (name == Pages.SwiperPage) {
      SwiperPage()
    } else if (name == Pages.LottiePage) {
      LottiePage()
    } else if (name == Pages.RefreshPage) {
      RefreshPage()
    }
  }
}