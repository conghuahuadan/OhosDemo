import { JinRefreshView } from "../lottie/components/JinRefreshView"
import { ComponentContent } from "@kit.ArkUI"


@Builder
function customRefreshingContent() {
  Row() {
    JinRefreshView()
    Text(true ? '刷新中…' : '下拉刷新').margin({ left: 8 })
  }
  .height(64)
  .justifyContent(FlexAlign.Center)
  .alignItems(VerticalAlign.Center)
  .width('100%')
}


@Component
export struct RefreshPage {
  @State isRefreshing: boolean = false
  @State items: string[] =
    ["", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", ""]
  contentNode?: ComponentContent<Object> = undefined

  aboutToAppear(): void {
    let uiContext = this.getUIContext();
    this.contentNode = new ComponentContent(uiContext, wrapBuilder(customRefreshingContent))
  }

  @Builder
  customHeader() {
    Row() {
      JinRefreshView()
      Text(this.isRefreshing ? '刷新中…' : '下拉刷新').margin({ left: 8 })
    }
    .height(64)
    .backgroundColor(Color.Yellow)
    .justifyContent(FlexAlign.Center)
    .alignItems(VerticalAlign.Center)
    .width('100%')
  }

  @Builder
  headerContent() {
    Row() {
      JinRefreshView()
      Text(this.isRefreshing ? '刷新中…' : '下拉刷新').margin({ left: 8 })
    }
    .height(64)
    .justifyContent(FlexAlign.Center)
    .alignItems(VerticalAlign.Center)
    .width('100%')
  }

  build() {
    NavDestination() {
      Column() {
        Refresh({
          refreshing: $$this.isRefreshing,
          refreshingContent: this.contentNode
        }) {
          List() {
            ForEach(this.items, (it: string) => {
              ListItem() {
                Text(it).height(56).width('100%').textAlign(TextAlign.Center)
              }
            })
          }
          .width('100%').height('100%')
        }
        .onRefreshing(() => {
          setTimeout(() => this.isRefreshing = false, 1200)
        })
        .onStateChange((s: RefreshStatus) => console.info(`state=${s}`))
      }
      .height('100%')
    }
  }
}