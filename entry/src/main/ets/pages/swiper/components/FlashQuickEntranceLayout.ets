import { DeviceUtil, DisplayUtil } from "@pura/harmony-utils"

@Component
export struct FlashQuickEntranceLayout {
  @State containerHeight: number = 0
  controller: SwiperController = new SwiperController();
  containerHeight1: number = 0;
  containerHeight2: number = 0;

  aboutToAppear(): void {
    const obs = this.getUIContext().getUIInspector().createComponentObserver('swiper_sub_view_0');
    obs.on('layout', () => {
      if (this.containerHeight2 == 0) {
        this.containerHeight2 = px2vp(this.getUIContext()
          .getComponentUtils()
          .getRectangleById('swiper_sub_view_1')
          .size
          .height);
      }

        this.containerHeight1 = px2vp(this.getUIContext()
          .getComponentUtils()
          .getRectangleById('swiper_sub_view_0')
          .size
          .height);
        this.containerHeight = this.containerHeight1;
    });
  }

  build() {
    Swiper(this.controller) {
      ForEach(["", ""], (item: Object, index) => {
        SwiperSubView({
          len: index % 2 == 0 ? 5 : 8
        })
          .onAreaChange((o, n) => {

          })
          .id(`swiper_sub_view_${index}`)
          .width(index % 2 == 0 ? `${(5 / 5.5) * 100}%` : "100%")
          .backgroundColor(index % 2 == 0 ? Color.Yellow : Color.Orange)
      })
    }
    .displayCount('auto')
    .height(this.containerHeight || 'auto')
    .width('100%')
    .cachedCount(2)
    .loop(false)
  }
}

@Component
export struct SwiperSubView {
  len = 5;
  items: string[] = [];
  column = 5;
  @State itemWidth: number = 0;

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
          .margin({ bottom: 10 })
        }
        .width(this.itemWidth)
        .backgroundColor(Color.Orange)
      })
    }
    .onAreaChange((o, n) => {
      // console.info(`父容器宽高：${n.width} × ${n.height}`);
      const width = Number(n.width) / this.column;
      if (this.itemWidth != width) {
        this.itemWidth = width;
      }
    })
    .layoutDirection(GridDirection.Row)
    .maxCount(this.column)
    .height('auto')
    .width('100%')
    .backgroundColor(Color.Pink)
  }
}