import { image } from "@kit.ImageKit";
import axios, { AxiosResponse } from "@ohos/axios";
import { HDImageViewer } from "hdimageviewer";
import { common2D } from "@kit.ArkGraphics2D";
import { ImageKnife, ImageKnifeComponent, ImageKnifeOption, ImageKnifeOptionV2, } from "@ohos/imageknife";
import { DisplayUtil } from "@pura/harmony-utils";
import fs from '@ohos.file.fs';
import { hilog } from "@kit.PerformanceAnalysisKit";

@Component
export struct ImageSubView {
  paths: string[] = [];
  path: string = ""
  pixelMap: image.PixelMap | undefined;
  @State srcInfo: HDImageViewer.ImageResourceInfo = {
    src: ""
  };
  @State imgType: number = 0;
  @Consume pageInfos: NavPathStack;
  controller: HDImageViewer.Controller = new HDImageViewer.Controller();
  @State imageKnifeOption: ImageKnifeOption = {
    loadSrc: '',
    objectFit: ImageFit.Contain,
  };
  dw = 0;
  dh = 0;
  @State offsetX: number = 0;
  @State offsetY: number = 0;
  @State imgScale: number = 1;
  @State imgAlpha: number = 1;
  offsetXBefore: number = 0;
  offsetYBefore: number = 0;
  @Link alpha: number;
  onDismiss: () => void = () => {
  };
  @State loading: Visibility = Visibility.Visible;

  aboutToAppear(): void {
    this.imageKnifeOption.loadSrc = this.path;
    this.dw = DisplayUtil.getWidth();
    this.dh = DisplayUtil.getHeight();
    this.controller.setDoubleTapZoomDuration(300)
    this.controller.setImageEventListener(new CustomOnImageEventListener(() => {
      this.fitImageToScreen();
    }))
    this.load();
  }

  load() {
    ImageKnife.getInstance().preload(new ImageKnifeOptionV2({
      loadSrc: this.path,
      onLoadListener: {
        onLoadSuccess: async (data) => {
          this.loading = Visibility.Hidden;
          if (data === undefined) {
            return
          }
          if (typeof data === 'string') {
            if (data.toLowerCase().includes("gif")) {
              this.imgType = 1;
            } else {
              this.imgType = 0;
            }
            this.srcInfo.src = data!;
          } else {
            this.pixelMap = data as image.PixelMap;
            const mimeType = this.pixelMap.getImageInfoSync().mimeType;
            if (mimeType.toLowerCase().includes("gif")) {
              this.imgType = 1;
            } else {
              this.imgType = 0;
            }
            this.srcInfo.src = data!;
          }
          animateTo({
            duration: 200,
            onFinish: () => {
            }
          }, () => {
            this.imgAlpha = 1;
          })
        },
        onLoadStart: () => {
          this.loading = Visibility.Visible;
          this.imgAlpha = 0;
        },
        onLoadFailed: () => {
        },
      }
    }))
  }

  async fitImageToScreen() {
    const info = this.pixelMap!.getImageInfoSync()
    const size = info.size;
    const pw = size.width;
    const ph = size.height;
    const dw = DisplayUtil.getWidth();
    const dh = DisplayUtil.getHeight();
    let defaultScale = 1;
    let center: common2D.Point = { x: pw / 2, y: 0 };
    if (pw / ph < dw / dh) {
      center = { x: pw / 2, y: 0 };
      defaultScale = dw / pw;
      this.controller.setMaxScale(defaultScale * 3)
      this.controller.setDoubleTapZoomScale(defaultScale)
      this.controller.setScaleAndCenter(defaultScale, center);
      this.controller.modifier?.doInvalidate();
    } else if (pw / ph > dw / dh) {
      center = { x: pw / 2, y: ph / 2 };
      defaultScale = dh / ph;
      this.controller.setMaxScale(defaultScale * 3)
      this.controller.setDoubleTapZoomScale(defaultScale)
    }
  }

  build() {
    Stack() {
      LoadingProgress()
        .color("#F5F5F5")
        .opacity(1 - this.imgAlpha)
        .visibility(this.loading)
        .size({ width: 40, height: 40 })
      Stack({
        alignContent: Alignment.Center
      }) {
        if (this.imgType == 1) {
          ImageKnifeComponent({
            imageKnifeOption: this.imageKnifeOption
          })
        } else {
          HDImageViewer({
            srcInfo: this.srcInfo,
            controller: this.controller,
          })
        }
      }
      .opacity(this.imgAlpha)
      .height("100%")
      .scale({
        x: this.imgScale,
        y: this.imgScale,
      })
      .offset({
        x: px2vp(this.offsetX),
        y: px2vp(this.offsetY)
      })
      .parallelGesture(GestureGroup(GestureMode.Exclusive,
        TapGesture({ count: 2, fingers: 1, distanceThreshold: 10 }),
        TapGesture({ count: 1, fingers: 1, distanceThreshold: 10 })
          .onAction((event: GestureEvent) => {
            if (!event) {
              return;
            }
            this.pageInfos.pop();
          })
      ))
      .gesture(GestureGroup(GestureMode.Parallel,
        PanGesture({
          direction: this.paths.length > 1 ? PanDirection.Vertical : PanDirection.All,
          fingers: 1,
          distance: 5,
        })
          .onActionStart((event: GestureEvent) => {
          })
          .onActionUpdate((event: GestureEvent) => {
            this.offsetX = this.offsetXBefore + vp2px(event.offsetX);
            this.offsetY = this.offsetYBefore + vp2px(event.offsetY);
            const distance = Math.sqrt(this.offsetX * this.offsetX + this.offsetY * this.offsetY);
            const scale = 1 - (distance / Math.max(this.dw, this.dh));
            this.imgScale = scale;
            this.alpha = scale;
          })
          .onActionEnd((event) => {
            this.offsetXBefore = this.offsetX;
            this.offsetYBefore = this.offsetY;
            const distance =
              Math.sqrt(this.offsetXBefore * this.offsetXBefore + this.offsetYBefore * this.offsetYBefore);
            const scale = 1 - (distance / Math.max(this.dw, this.dh));
            this.imgScale = scale;
            this.alpha = scale;
            if (Math.abs(distance) > px2vp(300)) {
              this.onDismiss?.();
            } else {
              animateTo({
                duration: 200,
                onFinish: () => {
                }
              }, () => {
                this.offsetX = 0;
                this.offsetY = 0;
                this.offsetXBefore = 0;
                this.offsetYBefore = 0;
                this.alpha = 1;
                this.imgScale = 1;
              })
            }
          }),
      ))
    }
  }
}

class CustomOnImageEventListener extends HDImageViewer.ImageEventListener {
  onImageLoadedCall: () => void = () => {
  };

  constructor(onImageLoadedCall: () => void) {
    super();
    this.onImageLoadedCall = onImageLoadedCall;
  }

  onImageReady() {
  }

  onImageLoaded() {
    this.onImageLoadedCall();
  }

  onImageLoadError(error: string) {
  }

  onTileLoadError(error: string) {
  }

  onPreviewImageReady() {
  }

  onPreviewImageReleased() {
  }

  onPreviewImageLoadError(error: string) {
  }
}