import { DeviceUtil, DisplayUtil } from "@pura/harmony-utils"
import { hilog } from "@kit.PerformanceAnalysisKit";

const column = 5;

@Component
export struct FlashQuickEntranceLayout {
  @State containerHeight: number = 0
  controller: SwiperController = new SwiperController();
  subHeight1: number = 0;
  subHeight2: number = 0;
  onIndexChangedCall?: (index: number) => void

  aboutToAppear(): void {
  }

  swiping: boolean = false;
  index = 0;
  count = 0;

  build() {
    Swiper(this.controller) {
      ForEach(["", ""], (item: Object, index) => {
        SwiperSubView({
          len: index % 2 == 0 ? 5 : 8,
          pageIndex: index,
          onHeightCall: (height, pageIndex) => {
            setTimeout(() => {
              if (pageIndex == 0) {
                this.subHeight1 = height
                this.count++;
                if (this.count <= 2) {
                  this.containerHeight = height
                }
              } else {
                this.subHeight2 = height
              }
            }, 0)
          }
        })
          .id(`swiper_sub_view_${index}`)
          .height('auto')
          .width(index % 2 == 0 ? `${(1 - 1 / column / 2) * 100}%` : "100%")
          .backgroundColor(index % 2 == 0 ? Color.Yellow : Color.Orange)
      })
    }
    .width('100%')
    .height(this.containerHeight || 'auto')
    .onContentWillScroll((res) => {
      animateTo({
        duration: 200
      }, () => {
        this.index = res.currentIndex;
        this.updateContainerHeight();
      })
      return true
    })
    .onAnimationStart((index, extraInfo) => {
      this.swiping = true;
    })
    .onAnimationEnd((index, extraInfo) => {
      this.swiping = false;
      this.index = index;
      this.updateContainerHeight();
    })
    .indicator(false)
    .displayCount('auto')
    .cachedCount(2)
    .loop(false)
  }

  updateContainerHeight() {
    if (this.index == 0 && !this.swiping) {
      this.onIndexChangedCall?.(this.index);
      animateTo({
        duration: 200
      }, () => {
        this.containerHeight = this.subHeight1;
      })
    } else if (this.index == 1 && !this.swiping) {
      this.onIndexChangedCall?.(this.index);
      animateTo({
        duration: 200
      }, () => {
        this.containerHeight = this.subHeight2;
      })
    }
  }
}

@Component
export struct SwiperSubView {
  pageIndex = 0;
  len = 5;
  items: string[] = [];
  @State itemWidth: number = 0;
  onHeightCall?: (height: number, pageIndex: number) => void

  aboutToAppear(): void {
    for (let i = 0; i < this.len; i++) {
      this.items.push('');
    }
  }

  build() {
    Grid() {
      ForEach(this.items, (item: string, index) => {
        GridItem() {
          Column() {
            Stack().width(40).height(40).backgroundColor(Color.Green)
            Text(`${index}`).fontSize(15).fontColor('#333333')
          }
          .padding({ bottom: 10 })
        }
        .width(this.itemWidth)
        .backgroundColor(Color.Orange)
      })
    }
    .onAreaChange((o, n) => {
      this.onHeightCall?.(Number(n.height), this.pageIndex);
      const width = Number(n.width) / column;
      if (this.itemWidth != width) {
        this.itemWidth = width;
      }
    })
    .layoutDirection(GridDirection.Row)
    .maxCount(column)
    .width('100%')
    .height('auto')
    .backgroundColor(Color.Pink)
  }
}

