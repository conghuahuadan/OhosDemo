@Component
export struct FlashQuickEntranceIndicator {
  @Prop index: number = 0;

  build() {
    Row() {
      Stack().width(6).height(3).backgroundColor(this.index == 0 ? Color.Blue : Color.Gray).borderRadius(2)
      Stack().width(4)
      Stack().width(16).height(3).backgroundColor(this.index == 1 ? Color.Blue : Color.Gray).borderRadius(2)
    }
    .width('100%')
    .justifyContent(FlexAlign.Center)
  }
}