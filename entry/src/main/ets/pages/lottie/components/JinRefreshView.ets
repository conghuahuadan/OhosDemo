import lottie, { AnimationItem } from "@ohos/lottie";
import { hilog } from "@kit.PerformanceAnalysisKit";

@Component
export struct JinRefreshView {
  renderingSettings: RenderingContextSettings = new RenderingContextSettings(true);
  canvasRenderingContext: CanvasRenderingContext2D = new CanvasRenderingContext2D(this.renderingSettings);
  animateItem: AnimationItem | null = null;
  animateName: string = 'animation';

  aboutToAppear(): void {
    hilog.info(0, "JinRefreshView", `aboutToAppear`)
  }

  aboutToDisappear(): void {
    lottie.destroy();
    hilog.info(0, "JinRefreshView", `aboutToDisappear`)
  }

  build() {
    Canvas(this.canvasRenderingContext)
      .width(60)
      .height(60)
      .backgroundColor(Color.Orange)
      .onReady(() => {
        if (this.animateItem != null) {
          this.animateItem?.resize();
        } else {
          this.canvasRenderingContext.imageSmoothingEnabled = true;
          this.canvasRenderingContext.imageSmoothingQuality = 'medium';
          this.loadAnimation();
        }
      }) //
  }

  loadAnimation() {
    this.animateItem = lottie.loadAnimation({
      container: this.canvasRenderingContext,
      renderer: 'canvas',
      loop: true,
      autoplay: false,
      name: this.animateName,
      contentMode: 'Contain',
      path: 'common/lottie/pullToRefresh.json',
    })
    this.animateItem.addEventListener('DOMLoaded', (args: Object): void => {
      this.animateItem?.play();
    });
  }

  destroy() {
    this.animateItem?.removeEventListener('DOMLoaded');
    lottie.destroy(this.animateName);
    this.animateItem = null;
  }
}